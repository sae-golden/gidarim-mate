package com.ivfmate.app

import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 잠금화면 위에 표시되는 알람 전용 Activity
 *
 * 일반 MainActivity와 달리 잠금화면 위에 바로 표시됨
 * 패턴/PIN 해제 없이 알람 UI를 보여줌
 */
class AlarmActivity : FlutterActivity() {
    private val CHANNEL = "com.ivfmate.app/alarm"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 잠금화면 위에 표시 + 화면 켜기
        enableShowOnLockScreen()

        // WakeLock으로 화면 유지
        acquireWakeLock()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "wakeUpScreen" -> {
                    enableShowOnLockScreen()
                    result.success(null)
                }
                "dismissKeyguard" -> {
                    dismissKeyguard()
                    result.success(null)
                }
                "closeAlarmActivity" -> {
                    finish()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 잠금화면 위에 표시 + 화면 켜기 설정
     */
    private fun enableShowOnLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            // Android 8.1 이상
            setShowWhenLocked(true)
            setTurnScreenOn(true)

            // 키가드(잠금화면) 해제 요청
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            // Android 8.0 이하 (deprecated but necessary)
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
            )
        }

        // 추가: 화면 켜진 상태 유지
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    /**
     * 키가드(잠금화면) 해제
     */
    private fun dismissKeyguard() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() {
                    // 잠금화면 해제 성공
                }
                override fun onDismissCancelled() {
                    // 사용자가 취소
                }
                override fun onDismissError() {
                    // 오류 발생
                }
            })
        }
    }

    /**
     * WakeLock 획득 (화면 켜기)
     */
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        @Suppress("DEPRECATION")
        wakeLock = powerManager.newWakeLock(
            PowerManager.SCREEN_BRIGHT_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "IVFMate:AlarmWakeLock"
        )

        wakeLock?.acquire(10 * 60 * 1000L) // 최대 10분
    }

    /**
     * WakeLock 해제
     */
    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }
}
