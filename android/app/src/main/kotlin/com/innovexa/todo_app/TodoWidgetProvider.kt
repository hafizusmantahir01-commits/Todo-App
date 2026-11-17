package com.innovexa.todo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/** Home-screen widget that shows today's top 3. The app writes the text; tapping opens the app. */
class TodoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val views = buildViews(context)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TodoWidgetProvider::class.java))
            if (ids.isEmpty()) return
            val views = buildViews(context)
            for (id in ids) {
                manager.updateAppWidget(id, views)
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            // Same file the Flutter shared_preferences package writes to.
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            fun read(key: String): String = prefs.getString("flutter." + key, "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            val title = read("widget_title")
            views.setTextViewText(R.id.widget_title, if (title.isEmpty()) "Today's top 3" else title)
            views.setTextViewText(R.id.widget_sub, read("widget_sub"))

            val rows = listOf(
                Pair(R.id.widget_l1, "widget_l1"),
                Pair(R.id.widget_l2, "widget_l2"),
                Pair(R.id.widget_l3, "widget_l3"),
            )
            for (row in rows) {
                val text = read(row.second)
                views.setTextViewText(row.first, text)
                views.setViewVisibility(row.first, if (text.isEmpty()) View.GONE else View.VISIBLE)
            }
            if (read("widget_l1").isEmpty()) {
                views.setTextViewText(R.id.widget_l1, "Open the app to plan your day")
                views.setViewVisibility(R.id.widget_l1, View.VISIBLE)
            }

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            return views
        }
    }
}
