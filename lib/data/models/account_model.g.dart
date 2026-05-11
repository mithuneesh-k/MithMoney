// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountModelAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 7;

  @override
  AccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as AccountType,
      balance: fields[3] as double,
      colorValue: fields[4] as int,
      iconCode: fields[5] as int,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.colorValue)
      ..writeByte(5)
      ..write(obj.iconCode)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 8;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.bank;
      case 1:
        return AccountType.wallet;
      case 2:
        return AccountType.cash;
      case 3:
        return AccountType.savings;
      case 4:
        return AccountType.other;
      default:
        return AccountType.bank;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.bank:
        writer.writeByte(0);
        break;
      case AccountType.wallet:
        writer.writeByte(1);
        break;
      case AccountType.cash:
        writer.writeByte(2);
        break;
      case AccountType.savings:
        writer.writeByte(3);
        break;
      case AccountType.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
