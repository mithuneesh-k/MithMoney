package com.blixcode.mithmoney

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MithMoneyWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.mith_money_widget).apply {
                // Get data from HomeWidget
                val balance = widgetData.getFloat("total_balance", 0.0f)
                val symbol = widgetData.getString("currency_symbol", "₹")
                val lastNote = widgetData.getString("last_tx_note", "No recent transactions")
                val lastAmount = widgetData.getFloat("last_tx_amount", 0.0f)

                setTextViewText(R.id.total_balance, "$symbol ${String.format("%.2f", balance)}")
                
                if (lastAmount != 0.0f) {
                    setTextViewText(R.id.last_tx, "Last: $lastNote ($symbol $lastAmount)")
                } else {
                    setTextViewText(R.id.last_tx, lastNote)
                }

                // Intent to open the app
                val pendingIntent = HomeWidgetProvider.getPendingIntent(context, Uri.parse("mithmoney://add_expense"))
                setOnClickPendingIntent(R.id.add_expense, pendingIntent)
                
                // Also open app when clicking balance
                val openAppIntent = HomeWidgetProvider.getPendingIntent(context, Uri.parse("mithmoney://home"))
                setOnClickPendingIntent(R.id.total_balance, openAppIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
