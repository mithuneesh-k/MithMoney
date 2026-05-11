import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'transaction_repository.dart';
import 'category_repository.dart';
import 'account_repository.dart';
import '../../core/utils/app_logger.dart';

class ImportRepository {
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final AccountRepository _accountRepo;

  ImportRepository(this._txRepo, this._catRepo, this._accountRepo);

  Future<int> importFromCsv(String filePath) async {
    try {
      final input = File(filePath).openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      return await _processRows(fields);
    } catch (e, stack) {
      AppLogger.e('ImportRepository', 'CSV Import failed', e, stack);
      rethrow;
    }
  }

  Future<int> importFromExcel(String filePath) async {
    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final List<List<dynamic>> rows = [];

      // Assume the first sheet is the one we want
      final firstSheet = excel.tables.values.first;
      for (var row in firstSheet.rows) {
        rows.add(row.map((cell) => cell?.value).toList());
      }

      return await _processRows(rows);
    } catch (e, stack) {
      AppLogger.e('ImportRepository', 'Excel Import failed', e, stack);
      rethrow;
    }
  }

  Future<int> _processRows(List<List<dynamic>> rows) async {
    if (rows.isEmpty) return 0;

    // Detect headers and mapping
    // Common columns: Date, Type, Category, Amount, Note, Tags, Account
    int startIndex = 0;
    
    // Check if the first row looks like a header
    final firstRowStr = rows[0].map((e) => e?.toString().toLowerCase() ?? '').toList();
    bool hasHeader = firstRowStr.any((s) => s.contains('date') || s.contains('amount') || s.contains('category'));
    
    if (hasHeader) {
      startIndex = 1;
    }

    int count = 0;
    final categories = _catRepo.getAll();
    final accounts = _accountRepo.getAll();
    final defaultAccount = accounts.isNotEmpty ? accounts.first : null;

    for (int i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((element) => element == null)) continue;
      if (row.length < 2) continue; // Need at least date and amount?

      try {
        // Simple heuristic mapping:
        // Index 0: Date
        // Index 1: Type (income/expense)
        // Index 2: Category
        // Index 3: Amount
        // Index 4: Note
        // Index 5: Tags (semicolon separated)
        // Index 6: Account Name

        // 1. Date
        DateTime date = DateTime.now();
        if (row.length > 0 && row[0] != null) {
          final val = row[0].toString();
          date = DateTime.tryParse(val) ?? _parseCustomDate(val) ?? DateTime.now();
        }

        // 2. Type
        TransactionType type = TransactionType.expense;
        if (row.length > 1 && row[1] != null) {
          final val = row[1].toString().toLowerCase();
          if (val.contains('income')) type = TransactionType.income;
          if (val.contains('transfer')) type = TransactionType.transfer;
        }

        // 3. Category
        String categoryId = categories.first.id;
        if (row.length > 2 && row[2] != null) {
          final val = row[2].toString().toLowerCase();
          try {
            final cat = categories.firstWhere(
              (c) => c.name.toLowerCase() == val || c.id.toLowerCase() == val,
            );
            categoryId = cat.id;
          } catch (_) {
            // Use default category for the type
            final typeCats = categories.where((c) => c.type == CategoryType.values.firstWhere((e) => e.name == type.name, orElse: () => CategoryType.expense)).toList();
            if (typeCats.isNotEmpty) categoryId = typeCats.first.id;
          }
        }

        // 4. Amount
        double amount = 0.0;
        if (row.length > 3 && row[3] != null) {
          final val = row[3].toString().replaceAll(RegExp(r'[^0-9.]'), '');
          amount = double.tryParse(val) ?? 0.0;
        }

        // 5. Note
        String note = (row.length > 4 && row[4] != null) ? row[4].toString() : '';

        // 6. Tags
        List<String> tags = [];
        if (row.length > 5 && row[5] != null) {
          tags = row[5].toString().split(RegExp(r'[;,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }

        // 7. Account
        String? accountId = defaultAccount?.id;
        if (row.length > 6 && row[6] != null) {
          final val = row[6].toString().toLowerCase();
          try {
            final acc = accounts.firstWhere((a) => a.name.toLowerCase() == val);
            accountId = acc.id;
          } catch (_) {}
        }

        final tx = TransactionModel(
          id: const Uuid().v4(),
          amount: amount,
          type: type,
          categoryId: categoryId,
          note: note,
          tags: tags,
          date: date,
          accountId: accountId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _txRepo.add(tx);
        
        // Update account balance if repository is available
        if (accountId != null) {
          final factor = type == TransactionType.income ? 1.0 : -1.0;
          await _accountRepo.updateBalance(accountId, amount * factor);
        }

        count++;
      } catch (e) {
        AppLogger.w('ImportRepository', 'Failed to parse row $i: $e');
      }
    }

    return count;
  }

  DateTime? _parseCustomDate(String val) {
    // Try some common formats like DD/MM/YYYY or DD-MM-YYYY
    try {
      final parts = val.split(RegExp(r'[/\-]'));
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }
}
