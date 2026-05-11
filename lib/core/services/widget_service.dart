import 'package:home_widget/home_widget.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/app_logger.dart';

class WidgetService {
  static const String _androidWidgetName = 'MithMoneyWidget';

  static Future<void> updateWidget({
    required double totalBalance,
    required String currencySymbol,
    TransactionModel? lastTransaction,
  }) async {
    try {
      AppLogger.i('WidgetService', 'Updating widget data');
      
      await HomeWidget.saveWidgetData<double>('total_balance', totalBalance);
      await HomeWidget.saveWidgetData<String>('currency_symbol', currencySymbol);
      
      if (lastTransaction != null) {
        await HomeWidget.saveWidgetData<String>('last_tx_note', lastTransaction.note.isEmpty ? 'Transaction' : lastTransaction.note);
        await HomeWidget.saveWidgetData<double>('last_tx_amount', lastTransaction.amount);
      } else {
        await HomeWidget.saveWidgetData<String>('last_tx_note', 'No recent transactions');
        await HomeWidget.saveWidgetData<double>('last_tx_amount', 0.0);
      }
      
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e, stack) {
      AppLogger.e('WidgetService', 'Failed to update widget', e, stack);
    }
  }

  /// Sets up background sync for the widget (if needed)
  static Future<void> init() async {
    // Register background callback if necessary
  }
}
