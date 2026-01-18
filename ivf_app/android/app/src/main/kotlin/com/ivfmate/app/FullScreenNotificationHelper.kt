package com.ivfmate.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * 풀스크린 알림 헬퍼
 *
 * flutter_local_notifications가 제대로 fullScreenIntent를 생성하지 못하므로
 * 네이티브에서 직접 생성
 */
object FullScreenNotificationHelper {
    private const val CHANNEL_ID = "medication_alarm_fullscreen"
    private const val CHANNEL_NAME = "약물 알람 (풀스크린)"

    /**
     * 풀스크린 알림 표시
     * 잠금화면 위에 AlarmActivity를 띄움
     */
    fun showFullScreenNotification(
        context: Context,
        notificationId: Int,
        title: String,
        message: String,
        medicationId: String?,
        medicationName: String?,
        medicationType: String?
    ) {
        createNotificationChannel(context)

        // AlarmActivity를 띄우는 Intent
        val fullScreenIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("notificationId", notificationId)
            putExtra("medicationId", medicationId)
            putExtra("medicationName", medicationName)
            putExtra("medicationType", medicationType)
            putExtra("title", title)
            putExtra("message", message)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 일반 탭 Intent (앱 열기)
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val contentPendingIntent = PendingIntent.getActivity(
            context,
            notificationId + 10000,
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 알림 빌드
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm) // 기본 알람 아이콘
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setOngoing(false)
            .setContentIntent(contentPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true) // 🔥 핵심!

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
    }

    /**
     * 알림 채널 생성 (Android 8.0+)
     */
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = "약물 복용 시간 풀스크린 알람"
                enableVibration(true)
                enableLights(true)
                setBypassDnd(true) // 방해금지 무시
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
