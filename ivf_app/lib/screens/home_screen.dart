import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../constants/encouragement_messages.dart';
import '../widgets/app_card.dart';
import '../widgets/injection_site_bottom_sheet.dart';
import '../widgets/rating_request_sheet.dart';
import '../widgets/store_review_sheet.dart';
import '../widgets/feedback_sheet.dart';
import '../models/medication.dart';
import '../models/treatment_stage.dart';
import '../models/treatment_cycle.dart';
import '../services/medication_storage_service.dart';
import '../services/home_widget_service.dart';
import '../services/rating_service.dart';
import '../services/cloud_storage_service.dart';
import 'quick_add_medication_screen.dart';
import 'add_medication_screen.dart';
import 'voice_input_screen.dart';

/// 메인 대시보드 화면
class HomeScreen extends StatefulWidget {
  final VoidCallback? onMedicationStatusChanged;

  const HomeScreen({super.key, this.onMedicationStatusChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // 등록된 약물 목록
  List<Medication> _medications = [];

  // 오늘의 약물 상태 (medicationId -> isCompleted)
  Map<String, bool> _medicationStatus = {};

  // 마지막 주사 부위 ('left' 또는 'right')
  String? _lastInjectionSide;

  // 다가오는 일정 (임시 데이터)
  final List<UpcomingEvent> _upcomingEvents = [];

  // 복용 완료 이벤트 구독
  StreamSubscription<String>? _medicationCompletedSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initRatingService();
    _loadMedications();
    _subscribeToMedicationEvents();
  }

  /// 복용 완료 이벤트 구독 (알람에서 완료 시 즉시 반영)
  void _subscribeToMedicationEvents() {
    _medicationCompletedSubscription = MedicationStorageService.onMedicationCompleted.listen((medicationId) {
      debugPrint('🔄 복용 완료 이벤트 수신: $medicationId - 화면 갱신');
      _loadMedications();
    });
  }

  /// 평가 서비스 초기화
  Future<void> _initRatingService() async {
    await RatingService().initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _medicationCompletedSubscription?.cancel();
    super.dispose();
  }

  /// 앱이 포그라운드로 돌아올 때 데이터 새로고침
  /// 알림에서 복용 처리 후 홈 화면 복귀 시 반영됨
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 홈 화면 새로고침 (앱 포그라운드 복귀)');
      _loadMedications();
    }
  }

  Future<void> _loadMedications() async {
    final medications = await MedicationStorageService.getAllMedications();
    final status = await MedicationStorageService.getMedicationStatus(DateTime.now());

    // 디버그: 저장된 약물 확인
    debugPrint('📦 저장된 약물 수: ${medications.length}');
    for (final med in medications) {
      debugPrint('  - ${med.name}: ${med.startDate.toIso8601String()} ~ ${med.endDate.toIso8601String()}');
    }

    // 오늘 복용해야 할 약물 필터링 확인
    final today = DateTime.now();
    final todayMeds = medications.where((med) {
      final inRange = !today.isBefore(med.startDate) && !today.isAfter(med.endDate);
      debugPrint('  - ${med.name} 오늘 범위: $inRange (오늘: ${today.toIso8601String()})');
      return inRange;
    }).toList();
    debugPrint('📅 오늘 복용할 약물 수: ${todayMeds.length}');

    setState(() {
      _medications = medications;
      _medicationStatus = status;
    });

    // 홈 위젯 업데이트
    HomeWidgetService.updateWidget();
  }

  /// 약물 추가 방법 선택 바텀시트 표시
  void _showAddMedicationMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // 제목
              Text(
                '약물 일정을 어떻게 추가할까요?',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.m),

              // 처방전 사진 찍기 (추후 지원)
              _buildAddMedicationOption(
                icon: '📷',
                title: '처방전 사진 찍기 (추후지원)',
                subtitle: '준비 중이에요',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('준비 중입니다'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                isDisabled: true,
              ),
              const SizedBox(height: AppSpacing.s),

              // 음성으로 말하기
              _buildAddMedicationOption(
                icon: '🎤',
                title: '음성으로 말하기',
                subtitle: '여러 약 한번에 입력 가능',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImprovedVoiceInputScreen()),
                  );
                  if (result != null) {
                    _loadMedications();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.s),

              // 직접 입력
              _buildAddMedicationOption(
                icon: '✏️',
                title: '직접 입력',
                subtitle: '간편한 한 페이지 입력',
                isRecommended: true,
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuickAddMedicationScreen()),
                  );
                  if (result != null) {
                    _loadMedications();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ),
    );
  }

  /// 약물 추가 옵션 카드
  Widget _buildAddMedicationOption({
    required String icon,
    required String title,
    required String subtitle,
    bool isRecommended = false,
    bool isDisabled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // 아이콘
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.m),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? AppColors.textSecondary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 추천 배지
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '추천',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 치료 주기 기반으로 다가오는 일정 업데이트
  void updateUpcomingEventsFromCycle(TreatmentCycle cycle) {
    _upcomingEvents.clear();

    for (final stage in cycle.stages) {
      // 예정(pending) 상태이고 시작일이 있는 단계만 표시
      if (stage.calculatedStatus == StageStatus.pending && stage.startDate != null) {
        final stageInfo = TreatmentStageInfo.stageInfo[stage.stage];
        if (stageInfo != null) {
          _upcomingEvents.add(UpcomingEvent(
            id: stage.stage.name,
            title: '${stageInfo.title} 예정',
            date: stage.startDate!,
            type: _getEventTypeFromStage(stage.stage),
            stage: stage.stage,
            memo: stageInfo.description,
          ));
        }
      }
    }

    // 날짜순 정렬
    _upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
    setState(() {});
  }

  EventType _getEventTypeFromStage(TreatmentStage stage) {
    switch (stage) {
      case TreatmentStage.stimulation:
        return EventType.hospital;
      case TreatmentStage.retrieval:
        return EventType.procedure;
      case TreatmentStage.waiting:
        return EventType.result;
      case TreatmentStage.transfer:
        return EventType.procedure;
      case TreatmentStage.result:
        return EventType.result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시간대별 인사말 헤더
              _buildHeader(),
              const SizedBox(height: AppSpacing.m),

              // 오늘의 한마디 (응원 문구)
              _buildEncouragementCard(),
              const SizedBox(height: AppSpacing.m),

              // 오늘도 한 걸음 (약물 리스트)
              _buildTodayStepsCard(),
              const SizedBox(height: AppSpacing.l),

              // 곧 만나요 (다가오는 일정)
              _buildUpcomingEventsCard(),

              // 하단 여백 (네비게이션 바 + FAB 가림 방지)
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// 시간대별 인사말 가져오기
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '좋은 아침이에요';
    } else if (hour >= 12 && hour < 18) {
      return '오늘 하루 어떠세요?';
    } else if (hour >= 18 && hour < 22) {
      return '수고한 하루, 잘 보내셨나요?';
    } else {
      return '편안한 밤 되세요';
    }
  }

  /// 시간대별 이모지 가져오기
  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '🌅';
    } else if (hour >= 12 && hour < 18) {
      return '☀️';
    } else if (hour >= 18 && hour < 22) {
      return '🌙';
    } else {
      return '✨';
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreetingEmoji()} ${_getGreeting()}',
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '오늘도 한 걸음 더 가까워지고 있어요',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 오늘의 응원 문구 카드
  Widget _buildEncouragementCard() {
    final message = EncouragementMessages.getMessageByTime();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '💜',
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 한마디',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 오늘도 한 걸음 카드 (시간대별 약물 리스트)
  Widget _buildTodayStepsCard() {
    final todayMedications = _getTodayMedications();
    final completedCount = todayMedications.where((m) => _medicationStatus[m.id] == true).length;
    final isAllCompleted = todayMedications.isNotEmpty && completedCount == todayMedications.length;

    // 시간대별로 그룹화
    final groupedByTime = _groupMedicationsByTime(todayMedications);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('👣', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '오늘도 한 걸음',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (todayMedications.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isAllCompleted
                        ? const Color(0xFFE8DEF8)
                        : AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAllCompleted
                        ? '오늘도 수고했어요 💜'
                        : '$completedCount/${todayMedications.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: isAllCompleted
                          ? const Color(0xFF7C4DFF)
                          : AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          if (todayMedications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurpleLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('💊', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      '아직 등록된 약이 없어요',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '아래 + 버튼으로 추가해 보세요',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...groupedByTime.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final timeSlot = entry.value.key;
              final meds = entry.value.value;
              final isLast = index == groupedByTime.length - 1;

              return Column(
                children: [
                  _buildTimeSlotGroup(timeSlot, meds),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                      child: Divider(
                        color: AppColors.border.withValues(alpha: 0.5),
                        height: 1,
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  /// 약물을 시간대별로 그룹화
  Map<String, List<Medication>> _groupMedicationsByTime(List<Medication> medications) {
    final grouped = <String, List<Medication>>{};

    for (final med in medications) {
      final timeKey = med.time; // "HH:mm" 형식
      grouped.putIfAbsent(timeKey, () => []).add(med);
    }

    // 시간순 정렬
    final sortedKeys = grouped.keys.toList()..sort();
    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, grouped[k]!)));
  }

  /// 시간대 그룹 위젯
  Widget _buildTimeSlotGroup(String timeKey, List<Medication> medications) {
    final now = DateTime.now();
    final timeParts = timeKey.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // 시간 지남 여부
    final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    final isPastTime = now.isAfter(scheduledTime);

    // 그룹 내 모든 약물 완료 여부
    final allCompleted = medications.every((m) => _medicationStatus[m.id] == true);

    // 시간 표시 형식
    final timeLabel = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeText = '$timeLabel $displayHour:${minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시간 헤더 + 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  timeText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: allCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if (isPastTime && !allCompleted) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '· 시간 지남',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (allCompleted) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                ],
              ],
            ),
            // 복용 버튼
            if (!allCompleted)
              GestureDetector(
                onTap: () => _handleTimeSlotComplete(medications),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    medications.length > 1 ? '모두 복용' : '복용',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // 약물 목록
        ...medications.map((med) => _buildMedicationInGroup(med)),
      ],
    );
  }

  /// 그룹 내 약물 항목
  Widget _buildMedicationInGroup(Medication medication) {
    final isCompleted = _medicationStatus[medication.id] ?? false;
    final isInjection = medication.type == MedicationType.injection;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          // 완료 체크 (탭하면 토글)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (isCompleted) {
                _handleMedicationUncomplete(medication);
              } else {
                _handleMedicationComplete(medication);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8), // 터치 영역 확대
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? AppColors.success : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),

          // 약물 정보 (클릭하면 수정 화면으로 이동)
          Expanded(
            child: GestureDetector(
              onTap: () => _openMedicationEdit(medication),
              child: Row(
                children: [
                  // 약물 아이콘
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isInjection
                          ? AppColors.primaryPurpleLight
                          : AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInjection ? Icons.vaccines : Icons.medication,
                      color: isInjection ? AppColors.primaryPurple : AppColors.info,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),

                  // 약물명 및 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                        if (medication.dosage != null)
                          Text(
                            medication.dosage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 수정 힌트 아이콘
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textDisabled,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 약물 수정 화면 열기
  Future<void> _openMedicationEdit(Medication medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddMedicationScreen(
          editingMedication: medication,
        ),
      ),
    );

    // 수정 또는 삭제 후 목록 새로고침
    if (result != null) {
      _loadMedications();
    }
  }

  /// 시간대 전체 복용 처리
  /// 주사 약물이 있으면 먼저 처리하고, 사용자가 취소하면 전체 취소
  void _handleTimeSlotComplete(List<Medication> medications) async {
    final incompleteMeds = medications.where((m) => _medicationStatus[m.id] != true).toList();
    if (incompleteMeds.isEmpty) return;

    // 주사 약물 먼저 분리
    final injections = incompleteMeds.where((m) => m.type == MedicationType.injection).toList();
    final others = incompleteMeds.where((m) => m.type != MedicationType.injection).toList();

    // 주사 약물이 있으면 먼저 처리 (하나라도 취소되면 전체 취소)
    for (final injection in injections) {
      // 새로운 주사 부위 선택 바텀시트 표시 (축하 애니메이션 포함)
      final selectedSide = await InjectionSiteBottomSheet.show(
        context,
        medicationName: injection.name,
        lastSide: _lastInjectionSide,
      );

      // 사용자가 취소하면 전체 중단
      if (selectedSide == null) {
        return;
      }

      // 주사 완료 처리
      setState(() {
        _medicationStatus[injection.id] = true;
        _lastInjectionSide = selectedSide;
      });

      await MedicationStorageService.setMedicationStatus(
        DateTime.now(),
        injection.id,
        true,
      );

      // 주사 부위 기록
      await MedicationStorageService.addInjectionSite(
        InjectionSiteRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          medicationId: injection.id,
          dateTime: DateTime.now(),
          site: selectedSide,
          location: selectedSide == 'left' ? '왼쪽' : '오른쪽',
        ),
      );

      // 평가 카운터 증가
      await _checkAndShowRatingPrompt();
    }

    // 일반 약물 모두 완료 처리
    for (final med in others) {
      setState(() {
        _medicationStatus[med.id] = true;
      });
      await MedicationStorageService.setMedicationStatus(
        DateTime.now(),
        med.id,
        true,
      );
      await _checkAndShowRatingPrompt();
    }

    // 완료 스낵바 표시
    if (mounted && others.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                others.length == 1
                    ? '${others.first.name} 복용 완료!'
                    : '${others.length}개 약물 복용 완료!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<Medication> _getTodayMedications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _medications.where((med) {
      final startDate = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final endDate = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
      return !today.isBefore(startDate) && !today.isAfter(endDate);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> _handleMedicationComplete(Medication medication) async {
    bool wasCompleted = false;

    if (medication.type == MedicationType.injection) {
      // 주사인 경우 새로운 부위 선택 바텀시트 표시 (축하 애니메이션 포함)
      final selectedSide = await InjectionSiteBottomSheet.show(
        context,
        medicationName: medication.name,
        lastSide: _lastInjectionSide,
      );

      if (selectedSide != null) {
        setState(() {
          _medicationStatus[medication.id] = true;
          _lastInjectionSide = selectedSide;
        });

        // 복용 상태 저장 (자동으로 동기화 큐에 추가됨)
        await MedicationStorageService.setMedicationStatus(
          DateTime.now(),
          medication.id,
          true,
        );

        // 주사 부위 기록 저장
        await MedicationStorageService.addInjectionSite(
          InjectionSiteRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            medicationId: medication.id,
            dateTime: DateTime.now(),
            site: selectedSide,
            location: selectedSide == 'left' ? '왼쪽' : '오른쪽',
          ),
        );

        // 축하 애니메이션이 바텀시트에 포함되어 있으므로 별도 다이얼로그 불필요

        wasCompleted = true;
      }
    } else {
      // 일반 약물인 경우 바로 완료 처리
      setState(() {
        _medicationStatus[medication.id] = true;
      });
      // 로컬 저장소에 상태 저장
      await MedicationStorageService.setMedicationStatus(
        DateTime.now(),
        medication.id,
        true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '${medication.name} 복용 완료!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  EncouragementMessages.getMedicationMessage(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      wasCompleted = true;
    }

    // 복용 완료 시 평가 카운터 증가 및 조건 체크
    if (wasCompleted) {
      // 캘린더 화면 동기화
      widget.onMedicationStatusChanged?.call();
      await _checkAndShowRatingPrompt();
    }
  }

  /// 약물 복용 완료 해제 처리
  Future<void> _handleMedicationUncomplete(Medication medication) async {
    setState(() {
      _medicationStatus[medication.id] = false;
    });

    // 로컬 저장소에서 상태 해제
    await MedicationStorageService.setMedicationStatus(
      DateTime.now(),
      medication.id,
      false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.undo, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                '${medication.name} 복용 취소됨',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // 캘린더 화면 동기화
    widget.onMedicationStatusChanged?.call();
  }

  /// 평가 프롬프트 조건 확인 및 표시
  Future<void> _checkAndShowRatingPrompt() async {
    final ratingService = RatingService();

    // 복용 완료 카운터 증가
    await ratingService.incrementCompletedDoses();

    // 디버그 정보 출력
    ratingService.printDebugInfo();

    // 조건 충족 시 평가 프롬프트 표시
    if (ratingService.shouldShowRatingPrompt() && mounted) {
      // 잠시 딜레이 후 표시 (복용 완료 애니메이션 후)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _showRatingFlow();
      }
    }
  }

  /// 평가 플로우 시작
  Future<void> _showRatingFlow() async {
    final ratingService = RatingService();

    // 프롬프트 표시 기록
    await ratingService.recordPromptShown();

    if (!mounted) return;

    // 1단계: 별점 선택 바텀시트
    await RatingRequestSheet.show(
      context,
      onRatingSelected: (stars) async {
        // 별점 저장
        await ratingService.saveRating(stars);

        if (!mounted) return;

        if (stars >= 4) {
          // 4-5점: 스토어 리뷰 유도
          await _showStoreReviewSheet(stars);
        } else {
          // 1-3점: 피드백 수집
          await _showFeedbackSheet(stars);
        }
      },
      onLater: () async {
        // 다음에 하기
        await ratingService.recordLater();
      },
    );
  }

  /// 스토어 리뷰 유도 바텀시트
  Future<void> _showStoreReviewSheet(int stars) async {
    if (!mounted) return;

    await StoreReviewSheet.show(
      context,
      givenStars: stars,
      onGoToStore: () async {
        // 인앱 리뷰 요청
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
        } else {
          // 인앱 리뷰 불가 시 스토어 페이지 열기
          await inAppReview.openStoreListing(
            appStoreId: 'YOUR_APP_STORE_ID', // TODO: 실제 앱스토어 ID로 변경
          );
        }
      },
      onClose: () {
        // 닫기
        debugPrint('📊 스토어 리뷰 건너뜀');
      },
    );
  }

  /// 피드백 수집 바텀시트
  Future<void> _showFeedbackSheet(int stars) async {
    if (!mounted) return;

    await FeedbackSheet.show(
      context,
      givenStars: stars,
      onSubmit: (category, content) async {
        // 디바이스/앱 정보 수집
        String? appVersion;
        String? osType;
        String? osVersion;
        String? deviceModel;

        try {
          final packageInfo = await PackageInfo.fromPlatform();
          appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

          if (!kIsWeb) {
            if (Platform.isIOS) {
              osType = 'ios';
              final deviceInfo = await DeviceInfoPlugin().iosInfo;
              osVersion = deviceInfo.systemVersion;
              deviceModel = deviceInfo.model;
            } else if (Platform.isAndroid) {
              osType = 'android';
              final deviceInfo = await DeviceInfoPlugin().androidInfo;
              osVersion = deviceInfo.version.release;
              deviceModel = deviceInfo.model;
            }
          } else {
            osType = 'web';
          }
        } catch (e) {
          debugPrint('📊 디바이스 정보 수집 실패: $e');
        }

        // Supabase에 피드백 저장
        final success = await CloudStorageService.saveFeedback(
          stars: stars,
          category: category,
          content: content,
          appVersion: appVersion,
          osType: osType,
          osVersion: osVersion,
          deviceModel: deviceModel,
        );

        if (success) {
          await RatingService().recordFeedbackSubmitted();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('소중한 의견 감사합니다! 더 나은 앱이 되도록 노력할게요 💚'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      },
      onSkip: () {
        // 건너뛰기
        debugPrint('📊 피드백 건너뜀');
      },
    );
  }

  /// 곧 만나요 카드 (다가오는 일정)
  Widget _buildUpcomingEventsCard() {
    // 오늘 이후의 일정만 필터링
    final upcomingEvents = _upcomingEvents
        .where((e) => e.date.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗓️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '곧 만나요',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          ...upcomingEvents.take(3).map((event) {
            final dDay = event.date.difference(DateTime.now()).inDays;
            final isToday = dDay == 0;
            final isTomorrow = dDay == 1;

            String dDayText;
            if (isToday) {
              dDayText = '오늘';
            } else if (isTomorrow) {
              dDayText = '내일';
            } else {
              dDayText = 'D-$dDay';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                children: [
                  // 이벤트 타입 아이콘 (치료 단계 이모지 우선 사용)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: event.type.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        event.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),

                  // 일정 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (event.memo != null)
                          Text(
                            event.memo!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // D-Day 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: isToday || isTomorrow
                          ? AppColors.primaryPurple.withOpacity(0.15)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday || isTomorrow
                            ? AppColors.primaryPurple.withOpacity(0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      dDayText,
                      style: AppTextStyles.caption.copyWith(
                        color: isToday || isTomorrow
                            ? AppColors.primaryPurple
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==================== 이벤트 관련 모델 ====================

/// 다가오는 일정 이벤트
class UpcomingEvent {
  final String id;
  final String title;
  final DateTime date;
  final EventType type;
  final TreatmentStage? stage;  // 연관된 치료 단계
  final String? memo;

  UpcomingEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    this.stage,
    this.memo,
  });

  /// 치료 단계의 이모지 (stage가 있으면 사용, 없으면 type의 이모지)
  String get emoji {
    if (stage != null) {
      return TreatmentStageInfo.stageInfo[stage]?.emoji ?? type.emoji;
    }
    return type.emoji;
  }
}

/// 이벤트 타입
enum EventType {
  hospital,   // 병원 방문
  procedure,  // 시술
  result,     // 결과 확인
  other,      // 기타
}

extension EventTypeExtension on EventType {
  String get emoji {
    switch (this) {
      case EventType.hospital:
        return '🏥';
      case EventType.procedure:
        return '💉';
      case EventType.result:
        return '📋';
      case EventType.other:
        return '📅';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case EventType.hospital:
        return AppColors.info.withOpacity(0.15);
      case EventType.procedure:
        return AppColors.primaryPurpleLight;
      case EventType.result:
        return AppColors.success.withOpacity(0.15);
      case EventType.other:
        return AppColors.background;
    }
  }
}
