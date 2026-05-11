import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/bank_sms_message.dart';
import '../../data/repositories/sms_repository.dart';
import '../../core/utils/sms_parser.dart';

class SmsService {
  final SmsRepository _repo;

  SmsService(this._repo);

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    return Permission.sms.isGranted;
  }

  /// Reads SMS inbox for each sender and stores new bank transaction messages.
  /// Returns count of newly added messages.
  Future<int> syncSms(List<String> senderIds) async {
    if (kIsWeb || !await hasPermission()) return 0;

    final query = SmsQuery();
    int newCount = 0;

    try {
      final messages = await query.querySms(
        kinds: [SmsQueryKind.inbox],
      );

      for (final sms in messages) {
        final id = sms.id?.toString() ?? '';
        if (id.isEmpty || _repo.exists(id)) continue;

        final address = sms.address ?? '';
        final isKnownSender = senderIds
            .any((s) => address.toUpperCase().contains(s.toUpperCase()));
        if (!isKnownSender) continue;

        final body = sms.body ?? '';
        if (!SmsParser.isBankTransactionSms(body)) continue;

        final parsed = SmsParser.parse(body);
        final msg = BankSmsMessage(
          id: id,
          sender: address,
          rawBody: body,
          parsedAmount: parsed.amount,
          parsedType: parsed.type,
          parsedMerchant: parsed.merchant,
          parsedDate: sms.date,
          receivedAt: sms.date ?? DateTime.now(),
        );

        await _repo.save(msg);
        newCount++;
      }
    } catch (_) {
      // Return whatever we got
    }

    return newCount;
  }
}
