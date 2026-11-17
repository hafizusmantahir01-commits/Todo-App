package com.innovexa.todo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
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

            // Look chosen in the app: navy (default), light or gold.
            val style = read("widget_style")
            val background = when (style) {
                "light" -> R.drawable.widget_bg_light
                "gold" -> R.drawable.widget_bg_gold
                else -> R.drawable.widget_bg
            }
            val titleColor = when (style) {
                "light" -> Color.parseColor("#7A5C05")
                "gold" -> Color.parseColor("#14213D")
                else -> Color.parseColor("#E9C46A")
            }
            val textColor = when (style) {
                "light", "gold" -> Color.parseColor("#14213D")
                else -> Color.parseColor("#FFFFFF")
            }
            val subColor = when (style) {
                "light" -> Color.parseColor("#5D6475")
                "gold" -> Color.parseColor("#3B3420")
                else -> Color.parseColor("#AAB3C8")
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", background)
            views.setTextColor(R.id.widget_title, titleColor)
            views.setTextColor(R.id.widget_l1, textColor)
            views.setTextColor(R.id.widget_l2, textColor)
            views.setTextColor(R.id.widget_l3, textColor)
            views.setTextColor(R.id.widget_sub, subColor)
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
