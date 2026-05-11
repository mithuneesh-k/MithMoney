import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: kTransactionTypeEnumId)
enum TransactionType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
  @HiveField(2)
  transfer,
}

@HiveType(typeId: kTransactionTypeId)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  TransactionType type;

  @HiveField(3)
  String categoryId;

  @HiveField(4)
  String note;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  DateTime date;

  @HiveField(7)
  String? receiptImagePath;

  @HiveField(8)
  bool isFromSms;

  @HiveField(9)
  String? smsSource;

  @HiveField(12)
  String? accountId;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note = '',
    List<String>? tags,
    required this.date,
    this.receiptImagePath,
    this.isFromSms = false,
    this.smsSource,
    this.accountId,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? note,
    List<String>? tags,
    DateTime? date,
    String? receiptImagePath,
    bool? isFromSms,
    String? smsSource,
    String? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      date: date ?? this.date,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      isFromSms: isFromSms ?? this.isFromSms,
      smsSource: smsSource ?? this.smsSource,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'note': note,
        'tags': tags,
        'date': date.toIso8601String(),
        'receiptImagePath': receiptImagePath,
        'isFromSms': isFromSms,
        'smsSource': smsSource,
        'accountId': accountId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      date: DateTime.parse(json['date'] as String),
      receiptImagePath: json['receiptImagePath'] as String?,
      isFromSms: json['isFromSms'] as bool? ?? false,
      smsSource: json['smsSource'] as String?,
      accountId: json['accountId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
