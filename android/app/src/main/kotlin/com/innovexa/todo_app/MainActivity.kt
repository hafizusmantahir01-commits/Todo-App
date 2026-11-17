package com.innovexa.todo_app

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Phone calendar (read only) and home-screen widget refresh for the Flutter side. */
class MainActivity : FlutterActivity() {
    private var pendingCalendarResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "todo_app/native").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasCalendarPermission" -> result.success(hasCalendarPermission())
                "requestCalendarPermission" -> {
                    if (hasCalendarPermission()) {
                        result.success(true)
                    } else {
                        pendingCalendarResult?.success(false)
                        pendingCalendarResult = result
                        requestPermissions(arrayOf(Manifest.permission.READ_CALENDAR), REQUEST_CALENDAR)
                    }
                }
                "calendarEvents" -> {
                    val start = call.argument<Number>("start")?.toLong() ?: 0L
                    val end = call.argument<Number>("end")?.toLong() ?: 0L
                    if (!hasCalendarPermission()) {
                        result.success(emptyList<Map<String, Any?>>())
                    } else {
                        try {
                            result.success(readEvents(start, end))
                        } catch (e: Exception) {
                            result.success(emptyList<Map<String, Any?>>())
                        }
                    }
                }
                "updateWidget" -> {
                    TodoWidgetProvider.refreshAll(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasCalendarPermission(): Boolean =
        checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED

    private fun readEvents(start: Long, end: Long): List<Map<String, Any?>> {
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, start)
        ContentUris.appendId(builder, end)
        val projection = arrayOf(
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
            CalendarContract.Instances.DISPLAY_COLOR,
        )
        val events = mutableListOf<Map<String, Any?>>()
        contentResolver.query(builder.build(), projection, null, null, CalendarContract.Instances.BEGIN + " ASC")?.use { cursor ->
            while (cursor.moveToNext() && events.size < 300) {
                events.add(
                    mapOf(
                        "title" to cursor.getString(0),
                        "begin" to cursor.getLong(1),
                        "end" to cursor.getLong(2),
                        "allDay" to (cursor.getInt(3) == 1),
                        "color" to cursor.getInt(4),
                    )
                )
            }
        }
        return events
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CALENDAR) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingCalendarResult?.success(granted)
            pendingCalendarResult = null
        }
    }

    companion object {
        private const val REQUEST_CALENDAR = 4711
    }
}
