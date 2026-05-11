import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'account_model.g.dart';

@HiveType(typeId: kAccountTypeEnumId)
enum AccountType {
  @HiveField(0)
  bank,
  @HiveField(1)
  wallet,
  @HiveField(2)
  cash,
  @HiveField(3)
  savings,
  @HiveField(4)
  other,
}

@HiveType(typeId: kAccountTypeId)
class AccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  AccountType type;

  @HiveField(3)
  double balance;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  int iconCode;

  @HiveField(6)
  DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    required this.colorValue,
    required this.iconCode,
    required this.createdAt,
  });

  Color get color => Color(colorValue);
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  AccountModel copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    int? colorValue,
    int? iconCode,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'colorValue': colorValue,
        'iconCode': iconCode,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.bank,
      ),
      balance: (json['balance'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      iconCode: json['iconCode'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
