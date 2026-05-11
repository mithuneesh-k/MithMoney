import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/app_settings.dart';
import 'transaction_repository.dart';
import 'category_repository.dart';
import 'settings_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

class BackupRepository {
  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;
  final SettingsRepository _settingsRepo;

  BackupRepository(this._txRepo, this._catRepo, this._settingsRepo);

  Future<io.Directory?> get _backupDir async {
    if (kIsWeb) return null;
    final base = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final dir = io.Directory('${base.path}/$kBackupFolder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> createBackup() async {
    if (kIsWeb) throw UnsupportedError('Backup not supported on Web');
    final dir = await _backupDir;
    if (dir == null) throw Exception('Could not access backup directory');
    final fileName = AppFormatters.backupFileName();
    final file = io.File('${dir.path}/$fileName');

    final transactions = _txRepo.getAll();
    final categories = _catRepo.getAll();
    final settings = _settingsRepo.settings;

    final data = {
      'meta': {
        'version': kAppVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'transactionCount': transactions.length,
        'categoryCount': categories.length,
      },
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'settings': settings.toJson(),
    };

    await file.writeAsString(jsonEncode(data));

    // Update last backup time
    await _settingsRepo.updateField((s) => s.lastBackupAt = DateTime.now());

    // Clean up old backups
    await _pruneOldBackups(settings.backupRetentionDays);

    return file.path;
  }

  Future<void> restoreFromFile(String filePath) async {
    if (kIsWeb) throw UnsupportedError('Restore not supported on Web');
    final file = io.File(filePath);
    final raw = await file.readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    // Clear existing data
    await _txRepo.deleteAll();
    await _catRepo.deleteAll();

    // Restore categories
    final cats = (data['categories'] as List<dynamic>?) ?? [];
    for (final c in cats) {
      await _catRepo.add(CategoryModel.fromJson(c as Map<String, dynamic>));
    }

    // Restore transactions
    final txs = (data['transactions'] as List<dynamic>?) ?? [];
    for (final t in txs) {
      await _txRepo.add(TransactionModel.fromJson(t as Map<String, dynamic>));
    }

    // Restore settings
    if (data['settings'] != null) {
      final restored =
          AppSettings.fromJson(data['settings'] as Map<String, dynamic>);
      await _settingsRepo.save(restored);
    }
  }

  Future<String> exportToCsv() async {
    if (kIsWeb) throw UnsupportedError('Export not supported on Web');
    final dir = await _backupDir;
    if (dir == null) throw Exception('Could not access backup directory');
    final now = DateTime.now();
    final fileName =
        'transactions_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.csv';
    final file = io.File('${dir.path}/$fileName');

    final transactions = _txRepo.getAll();
    final categories = _catRepo.getAll();
    final catMap = {for (final c in categories) c.id: c.name};

    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Note,Tags');
    for (final t in transactions) {
      final catName = catMap[t.categoryId] ?? t.categoryId;
      final tags = t.tags.join(';');
      buffer.writeln(
        '${t.date.toIso8601String()},'
        '${t.type.name},'
        '$catName,'
        '${t.amount},'
        '"${t.note.replaceAll('"', '""')}",'
        '"$tags"',
      );
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<List<io.FileSystemEntity>> listBackups() async {
    if (kIsWeb) return [];
    final dir = await _backupDir;
    if (dir == null) return [];
    final files = await dir.list().toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files.where((f) => f.path.endsWith('.json')).toList();
  }

  Future<void> _pruneOldBackups(int retentionDays) async {
    if (kIsWeb) return;
    final backups = await listBackups();
    if (backups.length > retentionDays) {
      final toDelete = backups.sublist(retentionDays);
      for (final f in toDelete) {
        await f.delete();
      }
    }
  }

  Future<void> deleteBackup(String path) async {
    if (kIsWeb) return;
    final file = io.File(path);
    if (await file.exists()) await file.delete();
  }
}
