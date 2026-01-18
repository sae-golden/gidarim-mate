package com.ivfmate.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.view.View
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class MedicationWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 첫 번째 위젯이 생성될 때
    }

    override fun onDisabled(context: Context) {
        // 마지막 위젯이 제거될 때
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.medication_widget)

            // SharedPreferences에서 데이터 가져오기
            val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
            val medicationsJson = prefs.getString("medications", "[]") ?: "[]"
            val statusJson = prefs.getString("medication_status", "{}") ?: "{}"

            // 오늘 날짜 표시
            val dateFormat = SimpleDateFormat("M/d", Locale.getDefault())
            views.setTextViewText(R.id.widget_date, dateFormat.format(Date()))

            // 약물 데이터 파싱
            try {
                val medications = JSONArray(medicationsJson)
                val status = JSONObject(statusJson)

                var totalCount = 0
                var completedCount = 0

                // 약물 아이템 IDs
                val itemIds = arrayOf(
                    R.id.med_item_1, R.id.med_item_2, R.id.med_item_3, R.id.med_item_4
                )
                val timeIds = arrayOf(
                    R.id.med_time_1, R.id.med_time_2, R.id.med_time_3, R.id.med_time_4
                )
                val nameIds = arrayOf(
                    R.id.med_name_1, R.id.med_name_2, R.id.med_name_3, R.id.med_name_4
                )
                val checkIds = arrayOf(
                    R.id.med_check_1, R.id.med_check_2, R.id.med_check_3, R.id.med_check_4
                )

                // 모든 아이템 숨기기
                for (itemId in itemIds) {
                    views.setViewVisibility(itemId, View.GONE)
                }

                if (medications.length() == 0) {
                    views.setViewVisibility(R.id.empty_message, View.VISIBLE)
                    views.setInt(R.id.progress_bar, "setProgress", 0)
                    views.setTextViewText(R.id.progress_text, "0/0")
                } else {
                    views.setViewVisibility(R.id.empty_message, View.GONE)

                    val count = minOf(medications.length(), 4)
                    for (i in 0 until count) {
                        val med = medications.getJSONObject(i)
                        val id = med.optString("id", "")
                        val name = med.optString("name", "약물")
                        val time = med.optString("time", "00:00")
                        val isCompleted = status.optBoolean(id, false)

                        views.setViewVisibility(itemIds[i], View.VISIBLE)
                        views.setTextViewText(timeIds[i], time)
                        views.setTextViewText(nameIds[i], name)

                        // 체크 아이콘
                        if (isCompleted) {
                            views.setImageViewResource(checkIds[i], android.R.drawable.checkbox_on_background)
                            completedCount++
                        } else {
                            views.setImageViewResource(checkIds[i], android.R.drawable.checkbox_off_background)
                        }

                        totalCount++
                    }

                    // 진행률 업데이트
                    val progress = if (totalCount > 0) (completedCount * 100 / totalCount) else 0
                    views.setInt(R.id.progress_bar, "setProgress", progress)
                    views.setTextViewText(R.id.progress_text, "$completedCount/$totalCount")
                }

            } catch (e: Exception) {
                views.setViewVisibility(R.id.empty_message, View.VISIBLE)
                views.setTextViewText(R.id.empty_message, "데이터 로드 오류")
            }

            // 위젯 클릭시 앱 열기
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
