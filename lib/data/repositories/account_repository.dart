import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account_model.dart';
import '../../core/constants/app_constants.dart';

class AccountRepository {
  Box<AccountModel> get _box => Hive.box<AccountModel>(kAccountsBox);

  List<AccountModel> getAll() {
    return _box.values.toList();
  }

  AccountModel? getById(String id) {
    return _box.get(id);
  }

  Future<void> add(AccountModel account) async {
    await _box.put(account.id, account);
  }

  Future<void> update(AccountModel account) async {
    await _box.put(account.id, account);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> updateBalance(String id, double amount) async {
    final account = _box.get(id);
    if (account != null) {
      account.balance += amount;
      await account.save();
    }
  }

  ValueListenable<Box<AccountModel>> get listenable => _box.listenable();
}
