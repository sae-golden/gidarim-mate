package com.ivfmate.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ivfmate.app/alarm"
    private var wakeLock: PowerManager.WakeLock? = null
    private val TAG = "IVFMate_MainActivity"

    // 진동 관련
    private var vibrator: Vibrator? = null
    private var isVibrating = false

    // 볼륨 버튼 콜백
    private var volumeButtonCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Vibrator 초기화
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

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
                "startVibration" -> {
                    Log.d(TAG, "startVibration 호출됨")
                    startContinuousVibration()
                    result.success(null)
                }
                "stopVibration" -> {
                    Log.d(TAG, "stopVibration 호출됨")
                    stopVibration()
                    result.success(null)
                }
                "listenVolumeButton" -> {
                    Log.d(TAG, "listenVolumeButton 호출됨")
                    volumeButtonCallback = result
                    // result는 나중에 볼륨 버튼 눌릴 때 반환
                }
                "cancelVolumeButtonListener" -> {
                    Log.d(TAG, "cancelVolumeButtonListener 호출됨")
                    volumeButtonCallback = null
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 연속 진동 시작 (오디오 포커스 없이)
     * 패턴: 500ms 진동, 500ms 대기, 반복
     */
    private fun startContinuousVibration() {
        if (isVibrating) return
        isVibrating = true

        val pattern = longArrayOf(0, 500, 500) // 대기, 진동, 대기
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val effect = VibrationEffect.createWaveform(pattern, 1) // 인덱스 1부터 반복
            vibrator?.vibrate(effect)
        } else {
            @Suppress("DEPRECATION")
            vibrator?.vibrate(pattern, 1)
        }
        Log.d(TAG, "연속 진동 시작됨")
    }

    /**
     * 진동 중지
     */
    private fun stopVibration() {
        vibrator?.cancel()
        isVibrating = false
        Log.d(TAG, "진동 중지됨")
    }

    /**
     * 볼륨 버튼 이벤트 감지
     * 볼륨 버튼이 눌리면 즉시 진동을 중지하고 Flutter에 알림
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val wasVibrating = isVibrating
            Log.d(TAG, "볼륨 버튼 감지: $keyCode, wasVibrating=$wasVibrating")

            // 진동 중이면 즉시 중지 (콜백 여부와 관계없이)
            if (wasVibrating) {
                stopVibration()
                Log.d(TAG, "볼륨 버튼으로 진동 중지됨")
            }

            // Flutter 콜백이 있으면 호출
            volumeButtonCallback?.let { callback ->
                callback.success(if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down")
                volumeButtonCallback = null
                return true // 볼륨 변경 방지
            }

            // 콜백이 없어도 진동 중이었으면 볼륨 변경 방지
            if (wasVibrating) {
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
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
