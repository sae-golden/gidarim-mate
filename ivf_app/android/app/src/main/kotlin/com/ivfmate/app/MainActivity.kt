package com.ivfmate.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ivfmate.app/alarm"
    private var wakeLock: PowerManager.WakeLock? = null
    private val TAG = "IVFMate_MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "wakeUpScreen" -> {
                    Log.d(TAG, "wakeUpScreen 호출됨")
                    enableShowOnLockScreen()
                    result.success(null)
                }
                "showFullScreenNotification" -> {
                    val notificationId = call.argument<Int>("notificationId") ?: 0
                    val title = call.argument<String>("title") ?: "약물 알림"
                    val message = call.argument<String>("message") ?: ""
                    val medicationId = call.argument<String>("medicationId")
                    val medicationName = call.argument<String>("medicationName")
                    val medicationType = call.argument<String>("medicationType")

                    Log.d(TAG, "showFullScreenNotification 호출: id=$notificationId, title=$title")

                    FullScreenNotificationHelper.showFullScreenNotification(
                        context = this,
                        notificationId = notificationId,
                        title = title,
                        message = message,
                        medicationId = medicationId,
                        medicationName = medicationName,
                        medicationType = medicationType
                    )
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "onCreate 시작")

        // super.onCreate() 호출 전에 잠금화면 플래그 설정 (중요!)
        // 약물 알림 앱이므로 항상 잠금화면 위에 표시
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            Log.d(TAG, "Android 8.1+ API 사용: setShowWhenLocked, setTurnScreenOn")
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
            Log.d(TAG, "레거시 플래그 사용")
        }

        super.onCreate(savedInstanceState)

        // WakeLock으로 화면 켜기
        acquireWakeLock()

        Log.d(TAG, "onCreate 완료")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent 수신")

        // 새 intent가 오면 화면 켜기 (알람일 가능성)
        enableShowOnLockScreen()
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "onResume")

        // Activity가 resume될 때마다 잠금화면 위 표시 설정 유지
        enableShowOnLockScreen()
    }

    /**
     * 잠금화면 위에 표시 + 화면 켜기 설정
     */
    private fun enableShowOnLockScreen() {
        Log.d(TAG, "enableShowOnLockScreen 호출")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        // Window 플래그 설정 (Android 버전 관계없이 항상 적용)
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )

        // WakeLock으로 화면 켜기
        acquireWakeLock()
    }

    /**
     * WakeLock 획득 (화면 켜기)
     */
    private fun acquireWakeLock() {
        if (wakeLock != null && wakeLock!!.isHeld) {
            return
        }

        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

            @Suppress("DEPRECATION")
            wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "IVFMate:AlarmWakeLock"
            )

            wakeLock?.acquire(5 * 60 * 1000L) // 최대 5분
            Log.d(TAG, "WakeLock 획득 완료")
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock 획득 실패: ${e.message}")
        }
    }

    /**
     * WakeLock 해제
     */
    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock 해제 실패: ${e.message}")
        }
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }
}
