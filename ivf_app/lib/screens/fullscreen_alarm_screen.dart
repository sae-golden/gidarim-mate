import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import '../models/medication.dart';
import '../services/notification_service.dart';
import '../services/injection_site_service.dart';
import '../services/medication_storage_service.dart';
import '../services/home_widget_service.dart';

/// 네이티브 알람 기능 (화면 켜기)
class AlarmPlatformChannel {
  static const _channel = MethodChannel('com.ivfmate.app/alarm');

  /// 화면 켜기 + 잠금화면 위에 표시
  static Future<void> wakeUpScreen() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('wakeUpScreen');
    } catch (e) {
      debugPrint('화면 켜기 실패: $e');
    }
  }
}

/// 알람에 표시될 약물 정보
class AlarmMedicationInfo {
  final String id;
  final String name;
  final String? dosage;
  final MedicationType type;

  const AlarmMedicationInfo({
    required this.id,
    required this.name,
    this.dosage,
    required this.type,
  });
}

/// 풀스크린 알람 화면
/// 정각 알림 및 리마인드 알림 시 표시되는 전체 화면 알람
class FullscreenAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final String medicationName;
  final String? dosage;
  final MedicationType medicationType;
  final String scheduledTime;
  final int reminderCount; // 0: 정각, 1-3: 리마인드 횟수
  final List<AlarmMedicationInfo>? medications; // 여러 약물인 경우
  final String? medicationId; // 약물 ID (복용 완료 저장용)

  const FullscreenAlarmScreen({
    super.key,
    required this.alarmSettings,
    required this.medicationName,
    this.dosage,
    required this.medicationType,
    required this.scheduledTime,
    this.reminderCount = 0,
    this.medications,
    this.medicationId,
  });

  @override
  State<FullscreenAlarmScreen> createState() => _FullscreenAlarmScreenState();
}

class _FullscreenAlarmScreenState extends State<FullscreenAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  // 주사 부위 선택
  String? _selectedInjectionSite;
  String? _lastInjectionSite; // 최근 주사 부위 (추후 저장소에서 로드)

  @override
  void initState() {
    super.initState();
    debugPrint('🔔 [ALARM_SCREEN] initState 시작 - medicationId=${widget.medicationId}, name=${widget.medicationName}');

    // 상태바 스타일 설정 (밝은 배경에 어두운 글씨)
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // 어두운 아이콘 (Android)
        statusBarBrightness: Brightness.light, // 밝은 배경 (iOS)
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 화면 켜기 + 잠금화면 위에 표시 (네이티브)
    // 네이티브 코드에서 이미 showWhenLocked 처리하므로 FlutterShowWhenLocked 불필요
    _wakeUpScreen();

    // 애니메이션 컨트롤러
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // 펄스 애니메이션 (일반 알람용)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 쉐이크 애니메이션 (리마인드용)
    _shakeAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 주사인 경우 기본값 설정
    if (_isInjection) {
      _loadLastInjectionSite();
    }
  }

  bool get _isInjection => widget.medicationType == MedicationType.injection;
  bool get _isReminder => widget.reminderCount > 0;
  bool get _isMultipleMedications =>
      widget.medications != null && widget.medications!.length > 1;

  /// 화면 켜기 + 잠금화면 위에 표시
  Future<void> _wakeUpScreen() async {
    await AlarmPlatformChannel.wakeUpScreen();
  }


  Future<void> _loadLastInjectionSite() async {
    // InjectionSiteService에서 최근 주사 부위 로드
    final lastSite = await InjectionSiteService.getLastSite();
    final recommendedSite = await InjectionSiteService.getRecommendedSite();

    setState(() {
      // 'left'/'right' -> '왼쪽'/'오른쪽' 변환
      _lastInjectionSite = lastSite == 'left' ? '왼쪽' : lastSite == 'right' ? '오른쪽' : null;
      // 추천 부위를 기본 선택 (마지막의 반대편)
      _selectedInjectionSite = recommendedSite == 'left' ? '왼쪽' : '오른쪽';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    // 상태바 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// 알람 중지
  Future<void> _stopAlarm() async {
    debugPrint('🔔 [ALARM_SCREEN] _stopAlarm() 시작 - alarmId=${widget.alarmSettings.id}');
    try {
      final result = await Alarm.stop(widget.alarmSettings.id);
      debugPrint('🔔 [ALARM_SCREEN] Alarm.stop() 결과: $result');
    } catch (e) {
      debugPrint('❌ [ALARM_SCREEN] Alarm.stop() 실패: $e');
    }
  }

  /// 완료 버튼 처리
  Future<void> _onComplete() async {
    debugPrint('🔔 [ALARM] _onComplete() 호출됨');
    debugPrint('🔔 [ALARM] alarmSettings.id: ${widget.alarmSettings.id}');

    // 1. 알람/진동 즉시 중지
    final stopResult = await Alarm.stop(widget.alarmSettings.id);
    debugPrint('🔔 [ALARM] Alarm.stop(${widget.alarmSettings.id}) 결과: $stopResult');

    // 2. 리마인드 알람들도 모두 취소
    await NotificationService.instance.cancelReminderAlarms(
      widget.alarmSettings.id,
    );

    // 3. 주사인 경우 선택한 부위 저장
    if (_isInjection && _selectedInjectionSite != null) {
      final siteToSave = _selectedInjectionSite == '왼쪽' ? 'left' : 'right';
      await InjectionSiteService.saveSite(siteToSave);
      debugPrint('🔔 [ALARM] 주사 부위 저장: $siteToSave');
    }

    // 4. 복용 완료 DB 저장
    if (widget.medicationId != null && widget.medicationId!.isNotEmpty) {
      try {
        await MedicationStorageService.markMedicationCompleted(
          medicationId: widget.medicationId!,
          date: DateTime.now(),
          scheduledCount: 1,
        );
        debugPrint('✅ [ALARM] 복용 완료 저장: ${widget.medicationName} (id=${widget.medicationId})');

        // 홈 위젯 업데이트
        await HomeWidgetService.updateWidget();
      } catch (e) {
        debugPrint('❌ [ALARM] 복용 완료 저장 실패: $e');
      }
    } else {
      debugPrint('⚠️ [ALARM] medicationId가 없어서 복용 완료 저장 스킵');
    }

    if (mounted) {
      Navigator.of(context).pop({
        'action': 'complete',
        'injectionSite': _selectedInjectionSite,
        'medicationId': widget.medicationId,
      });
    }
  }

  /// 스누즈 버튼 처리 (조금 이따 알려줘)
  Future<void> _onSnooze() async {
    await _stopAlarm();

    // 리마인드 횟수가 3회 미만이면 다음 리마인드 예약
    if (widget.reminderCount < 3) {
      await NotificationService.instance.scheduleNextReminder(
        medicationId: widget.alarmSettings.id.toString(),
        medicationName: widget.medicationName,
        dosage: widget.dosage,
        medicationType: widget.medicationType,
        reminderCount: widget.reminderCount + 1,
      );
    }

    if (mounted) {
      Navigator.of(context).pop({'action': 'snooze'});
    }
  }

  /// 테마 색상 가져오기
  _AlarmTheme get _theme {
    if (_isReminder) {
      return _AlarmTheme.reminder;
    }
    if (_isInjection) {
      return _AlarmTheme.injection;
    }
    return _AlarmTheme.medication;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeFormat = DateFormat('a h:mm', 'ko_KR');
    final dateFormat = DateFormat('M월 d일 EEEE', 'ko_KR');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 스크롤 가능한 상단 콘텐츠
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    children: [
                      // 리마인드 배지
                      if (_isReminder) ...[
                        _buildReminderBadge(),
                        const SizedBox(height: 24),
                      ],

                      // 시간 표시
                      Text(
                        timeFormat.format(now),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(now),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF888888),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 메인 컨텐츠
                      _isMultipleMedications
                          ? _buildMultipleMedicationsView()
                          : _buildSingleMedicationView(),
                    ],
                  ),
                ),
              ),

              // 하단 고정 버튼 영역
              Container(
                padding: const EdgeInsets.all(24),
                child: _buildButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 리마인드 배지
  Widget _buildReminderBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '⚠️ 아직 복용 전이에요',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB45309),
        ),
      ),
    );
  }

  /// 단일 약물 뷰
  Widget _buildSingleMedicationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 아이콘
        _buildAnimatedIcon(),

        const SizedBox(height: 24),

        // 리마인드 메시지
        if (_isReminder) ...[
          Text(
            '잊지 않으셨죠?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _isReminder ? const Color(0xFF333333) : const Color(0xFF9B7ED9),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // 약물명
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.medicationName,
            style: TextStyle(
              fontSize: _isReminder ? 24 : 28,
              fontWeight: FontWeight.w600,
              color: _isReminder ? const Color(0xFF9B7ED9) : const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),

        // 용량
        if (widget.dosage != null && widget.dosage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.dosage!,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF666666),
            ),
          ),
        ],

        // 약물 타입 배지 (리마인드가 아닌 경우)
        if (!_isReminder) ...[
          const SizedBox(height: 16),
          _buildTypeBadge(widget.medicationType),
        ],

        // 주사 부위 선택
        if (_isInjection && !_isReminder) ...[
          const SizedBox(height: 32),
          _buildInjectionSiteSelector(),
        ],
      ],
    );
  }

  /// 여러 약물 뷰
  Widget _buildMultipleMedicationsView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '지금 복용할 약이에요',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 20),
          ...widget.medications!.asMap().entries.map((entry) {
            final index = entry.key;
            final med = entry.value;
            final isLast = index == widget.medications!.length - 1;
            return _buildMedicationItem(med, isLast);
          }),
        ],
      ),
    );
  }

  /// 약물 아이템 (여러 약물용)
  Widget _buildMedicationItem(AlarmMedicationInfo med, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(med.type),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                med.type.icon,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (med.dosage != null && med.dosage!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    med.dosage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 애니메이션 아이콘
  Widget _buildAnimatedIcon() {
    final iconWidget = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _theme.iconGradient,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.medicationType.icon,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );

    if (_isReminder) {
      // 쉐이크 애니메이션
      return AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _shakeAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    } else {
      // 펄스 애니메이션
      return ScaleTransition(
        scale: _pulseAnimation,
        child: iconWidget,
      );
    }
  }

  /// 타입 배지
  Widget _buildTypeBadge(MedicationType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _getTypeBadgeColor(type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.typeName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _getTypeBadgeTextColor(type),
        ),
      ),
    );
  }

  /// 주사 부위 선택기
  Widget _buildInjectionSiteSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '어디에 맞았나요?',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSiteOption(
                  '왼쪽',
                  '👈',
                  isRecent: _lastInjectionSite == '왼쪽',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSiteOption(
                  '오른쪽',
                  '👉',
                  isRecent: _lastInjectionSite == '오른쪽',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 부위 선택 옵션
  Widget _buildSiteOption(String label, String emoji, {bool isRecent = false}) {
    final isSelected = _selectedInjectionSite == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInjectionSite = label;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF9B7ED9)
                : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // 메인 콘텐츠 (중앙 정렬)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF9B7ED9)
                          : const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            // 최근 배지 (카드 안쪽 우측 상단)
            if (isRecent)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '최근',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 버튼들
  Widget _buildButtons() {
    final buttonText = _isMultipleMedications
        ? '모두 완료했어요'
        : widget.medicationType.completeButtonText;

    final isCompleteEnabled = !_isInjection || _selectedInjectionSite != null;

    return Column(
      children: [
        // 완료 버튼
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isCompleteEnabled ? _onComplete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _theme.buttonColor,
              disabledBackgroundColor: const Color(0xFFD1D5DB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 스누즈 버튼
        if (widget.reminderCount < 3)
          TextButton(
            onPressed: _onSnooze,
            child: const Text(
              '조금 이따 알려줘',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF888888),
              ),
            ),
          ),
      ],
    );
  }

  Color _getIconBackgroundColor(MedicationType type) {
    switch (type) {
      case MedicationType.injection:
        return const Color(0xFFDBEAFE);
      case MedicationType.suppository:
        return const Color(0xFFFCE7F3);
      case MedicationType.oral:
      default:
        return const Color(0xFFF3E8FF);
    }
  }

  Color _getTypeBadgeColor(MedicationType type) {
    switch (type) {
      case MedicationType.injection:
        return const Color(0xFFDBEAFE);
      case MedicationType.suppository:
        return const Color(0xFFFCE7F3);
      case MedicationType.oral:
      default:
        return const Color(0xFFF3E8FF);
    }
  }

  Color _getTypeBadgeTextColor(MedicationType type) {
    switch (type) {
      case MedicationType.injection:
        return const Color(0xFF2563EB);
      case MedicationType.suppository:
        return const Color(0xFFDB2777);
      case MedicationType.oral:
      default:
        return const Color(0xFF9B7ED9);
    }
  }
}

/// 알람 테마 설정
class _AlarmTheme {
  final List<Color> backgroundGradient;
  final List<Color> iconGradient;
  final Color buttonColor;

  const _AlarmTheme({
    required this.backgroundGradient,
    required this.iconGradient,
    required this.buttonColor,
  });

  /// 일반 약물 (보라색)
  static const medication = _AlarmTheme(
    backgroundGradient: [Color(0xFFF5F0FF), Color(0xFFFFFFFF)],
    iconGradient: [Color(0xFFE9D5FF), Color(0xFFD8B4FE)],
    buttonColor: Color(0xFF9B7ED9),
  );

  /// 주사 (파란색)
  static const injection = _AlarmTheme(
    backgroundGradient: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
    iconGradient: [Color(0xFFBFDBFE), Color(0xFF93C5FD)],
    buttonColor: Color(0xFF3B82F6),
  );

  /// 리마인드 (오렌지)
  static const reminder = _AlarmTheme(
    backgroundGradient: [Color(0xFFFFF7ED), Color(0xFFFFFFFF)],
    iconGradient: [Color(0xFFFED7AA), Color(0xFFFDBA74)],
    buttonColor: Color(0xFFF97316),
  );
}
