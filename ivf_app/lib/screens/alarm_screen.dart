import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../services/alarm_service.dart';
import '../services/notification_settings_service.dart';
import '../widgets/app_button.dart';

/// 알람 화면 (끌 때까지 울리는 풀스크린)
class AlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmScreen({
    super.key,
    required this.alarmSettings,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  String? _medicationId;
  String? _medicationName;
  bool? _isInjection;
  String? _dosage;

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 알람 정보에서 약물 정보 파싱
    _parseAlarmInfo();
  }

  void _parseAlarmInfo() {
    // 알람 제목에서 약물 정보 추출
    final title = widget.alarmSettings.notificationSettings.title;
    _isInjection = title.contains('💉');

    // 실제로는 payload에서 파싱하거나 DB에서 조회
    _medicationName = title
        .replaceAll('💉 ', '')
        .replaceAll('💊 ', '')
        .replaceAll(' 주사 시간', '')
        .replaceAll(' 약 시간', '');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInjection = _isInjection ?? false;
    final emoji = isInjection ? '💉' : '💊';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // 약물 아이콘 (펄스 애니메이션)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: isInjection
                            ? AppColors.primaryPurpleLight
                            : AppColors.info.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isInjection
                                    ? AppColors.primaryPurple
                                    : AppColors.info)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 56)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // 약물 이름
              Text(
                _medicationName ?? '약물',
                style: AppTextStyles.h1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s),

              // 시간
              Text(
                _formatTime(widget.alarmSettings.dateTime),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // 알림 상태
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '알림음 울리는 중...',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 버튼들
              Row(
                children: [
                  // 다시 알림 버튼
                  Expanded(
                    child: AppButton(
                      text: '다시 알림',
                      onPressed: _handleSnooze,
                      type: AppButtonType.secondary,
                      height: 56,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  // 완료 버튼
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: '완료',
                      onPressed: _handleComplete,
                      height: 56,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:$minute';
  }

  /// 다시 알림
  Future<void> _handleSnooze() async {
    await AlarmService.stopAlarm(widget.alarmSettings.id);

    await AlarmService.setSnoozeAlarm(
      id: widget.alarmSettings.id,
      medicationId: _medicationId ?? widget.alarmSettings.id.toString(),
      medicationName: _medicationName ?? '약물',
      isInjection: _isInjection ?? false,
      dosage: _dosage,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 완료 처리
  Future<void> _handleComplete() async {
    await AlarmService.stopAlarm(widget.alarmSettings.id);

    if (_isInjection == true) {
      // 주사인 경우 부위 선택 팝업
      if (mounted) {
        await _showInjectionSiteDialog();
      }
    } else {
      // 알약/질정/패치는 바로 완료
      _completeMedication();
    }
  }

  /// 주사 부위 선택 다이얼로그
  Future<void> _showInjectionSiteDialog() async {
    final lastSide = await NotificationSettingsService.getLastInjectionSide();
    final recommendedSide =
        await NotificationSettingsService.getRecommendedInjectionSide();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InjectionSiteDialog(
        lastSide: lastSide,
        recommendedSide: recommendedSide,
        onSelect: (side) async {
          await NotificationSettingsService.saveInjectionRecord(
            medicationId: _medicationId ?? widget.alarmSettings.id.toString(),
            side: side,
            time: DateTime.now(),
          );
          _completeMedication(injectionSide: side);
        },
      ),
    );
  }

  void _completeMedication({String? injectionSide}) {
    // TODO: 복용 기록 저장

    if (mounted) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                injectionSide != null
                    ? '${_medicationName} 완료! (${NotificationSettingsService.getInjectionSideText(injectionSide)})'
                    : '${_medicationName} 복용 완료!',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

/// 주사 부위 선택 다이얼로그
class _InjectionSiteDialog extends StatelessWidget {
  final String? lastSide;
  final String recommendedSide;
  final Function(String) onSelect;

  const _InjectionSiteDialog({
    required this.lastSide,
    required this.recommendedSide,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💉', style: TextStyle(fontSize: 40)),
            const SizedBox(height: AppSpacing.m),
            Text(
              '어디에 맞았나요?',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.m),

            // 힌트
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (lastSide != null)
                    Text(
                      '💡 어제: ${NotificationSettingsService.getInjectionSideText(lastSide!)}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    '추천: ${NotificationSettingsService.getInjectionSideText(recommendedSide)} ⭐',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // 선택 버튼들
            Row(
              children: [
                Expanded(
                  child: _buildSideButton(
                    context,
                    side: 'left',
                    label: '왼쪽',
                    isRecommended: recommendedSide == 'left',
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _buildSideButton(
                    context,
                    side: 'right',
                    label: '오른쪽',
                    isRecommended: recommendedSide == 'right',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideButton(
    BuildContext context, {
    required String side,
    required String label,
    required bool isRecommended,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onSelect(side);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
        decoration: BoxDecoration(
          color: isRecommended ? AppColors.primaryPurple : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? AppColors.primaryPurple : AppColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              side == 'left' ? '👈' : '👉',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              isRecommended ? '$label ⭐' : label,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isRecommended ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
