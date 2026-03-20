package com.company.chamcong32

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

/**
 * Widget chấm công hiển thị lên màn hình Home của Android.
 * Đọc dữ liệu từ SharedPreferences được Flutter ghi thông qua home_widget package.
 */
class AttendanceWidget : AppWidgetProvider() {

    companion object {
        private const val PREF_NAME = "HomeWidgetPreferences"
        private const val KEY_CHECK_IN = "checkIn"
        private const val KEY_CHECK_OUT = "checkOut"
        private const val KEY_STATUS = "status"
        private const val KEY_HOURS = "hours"
        private const val KEY_HAS_CHECKED_IN = "hasCheckedIn"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val prefs: SharedPreferences =
            context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

        val checkIn = prefs.getString(KEY_CHECK_IN, "--:--") ?: "--:--"
        val checkOut = prefs.getString(KEY_CHECK_OUT, "--:--") ?: "--:--"
        val status = prefs.getString(KEY_STATUS, "Chưa chấm công") ?: "Chưa chấm công"
        // hours có thể lưu dạng "8.0 hrs" – lấy phần số nếu có
        val hoursRaw = prefs.getString(KEY_HOURS, "0.0h") ?: "0.0h"
        val hours = hoursRaw.replace(" hrs", "h").replace(" hr", "h")

        val views = RemoteViews(context.packageName, R.layout.attendance_widget_layout)

        views.setTextViewText(R.id.tv_check_in, checkIn)
        views.setTextViewText(R.id.tv_check_out, checkOut)
        views.setTextViewText(R.id.tv_status, status)
        views.setTextViewText(R.id.tv_hours, hours)

        // Tap vào widget → mở app
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (intent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.attendance_widget_root, pendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
