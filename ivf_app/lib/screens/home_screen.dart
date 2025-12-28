import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../constants/encouragement_messages.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../widgets/injection_location_dialog.dart';
import '../widgets/start_guide_card.dart';
import '../models/medication.dart';
import '../models/treatment_stage.dart';
import '../models/treatment_cycle.dart';
import '../models/onboarding_checklist.dart';
import '../services/onboarding_service.dart';
import '../services/notification_service.dart';
import '../services/medication_storage_service.dart';
import 'hospital_info_screen.dart';
import 'add_medication_screen.dart';

/// 메인 대시보드 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 등록된 약물 목록
  List<Medication> _medications = [];

  // 오늘의 약물 상태 (medicationId -> isCompleted)
  Map<String, bool> _medicationStatus = {};

  // 마지막 주사 위치 (0-8)
  int? _lastInjectionLocation = 3;

  // 다가오는 일정 (임시 데이터)
  final List<UpcomingEvent> _upcomingEvents = [];

  // 온보딩 체크리스트
  OnboardingChecklist _checklist = OnboardingChecklist();

  @override
  void initState() {
    super.initState();
    _loadChecklist();
    _loadMedications();
  }

  Future<void> _loadChecklist() async {
    final checklist = await OnboardingService.getChecklist();
    setState(() {
      _checklist = checklist;
    });
  }

  Future<void> _loadMedications() async {
    final medications = await MedicationStorageService.getAllMedications();
    final status = await MedicationStorageService.getMedicationStatus(DateTime.now());
    setState(() {
      _medications = medications;
      _medicationStatus = status;
    });
  }

  /// 체크리스트 항목 탭 처리
  void _handleChecklistItemTap(ChecklistItem item) async {
    switch (item) {
      case ChecklistItem.hospital:
        // 병원 정보 화면으로 이동
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HospitalInfoScreen()),
        );
        _loadChecklist(); // 돌아오면 체크리스트 새로고침
        break;

      case ChecklistItem.notification:
        // 알림 권한 요청
        final granted = await NotificationService.requestPermission();
        if (granted) {
          await NotificationService.setNotificationEnabled(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('알림이 켜졌어요! 복용 시간을 알려드릴게요 🔔'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
        _loadChecklist();
        break;

      case ChecklistItem.medication:
        // 약물 추가 화면으로 이동
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
        );
        _loadChecklist();
        _loadMedications(); // 약물 목록 새로고침
        break;

      case ChecklistItem.treatmentStage:
        // 치료 단계 선택 바텀시트
        _showTreatmentStageSelector();
        break;
    }
  }

  /// 치료 단계 선택 바텀시트
  void _showTreatmentStageSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
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
            Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.s),
                Text(
                  '현재 어떤 단계에 계세요?',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // 단계 선택 옵션들
            ...OnboardingTreatmentStage.values.map((stage) => _buildStageOption(stage)),

            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  Widget _buildStageOption(OnboardingTreatmentStage stage) {
    return InkWell(
      onTap: () async {
        await OnboardingService.saveTreatmentStage(stage);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${stage.shortTitle} 단계로 설정되었어요!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        _loadChecklist();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(stage.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                stage.title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
            ),
          ],
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

              // 시작하기 가이드 (미완료 항목 있을 때만)
              if (!_checklist.isAllCompleted)
                StartGuideCard(
                  items: _checklist.incompleteItems,
                  onItemTap: _handleChecklistItemTap,
                ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreetingEmoji()} ${_getGreeting()}',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '오늘도 한 걸음 더 가까워지고 있어요',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryPurpleLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: AppColors.primaryPurple,
            size: 22,
          ),
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

  /// 오늘도 한 걸음 카드 (약물 리스트)
  Widget _buildTodayStepsCard() {
    final todayMedications = _getTodayMedications();
    final completedCount = todayMedications.where((m) => _medicationStatus[m.id] == true).length;
    final isAllCompleted = todayMedications.isNotEmpty && completedCount == todayMedications.length;

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
                        ? const Color(0xFFE8DEF8) // 연보라 배경
                        : AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAllCompleted
                        ? '오늘도 수고했어요 💜'
                        : '$completedCount/${todayMedications.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: isAllCompleted
                          ? const Color(0xFF7C4DFF) // 보라 텍스트
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
                        color: AppColors.primaryPurpleLight.withOpacity(0.5),
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
            ...todayMedications.asMap().entries.map((entry) {
              final index = entry.key;
              final med = entry.value;
              final isLast = index == todayMedications.length - 1;

              return Column(
                children: [
                  _buildMedicationItem(
                    medication: med,
                    isCompleted: _medicationStatus[med.id] ?? false,
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Divider(
                        color: AppColors.border.withOpacity(0.5),
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

  List<Medication> _getTodayMedications() {
    final now = DateTime.now();
    return _medications.where((med) {
      return !now.isBefore(med.startDate) && !now.isAfter(med.endDate);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// 약물 항목
  Widget _buildMedicationItem({
    required Medication medication,
    required bool isCompleted,
  }) {
    final isInjection = medication.type == MedicationType.injection;
    final timeParts = medication.time.split(':');
    final hour = int.parse(timeParts[0]);
    final timeLabel = hour < 12 ? '오전' : (hour < 18 ? '오후' : '저녁');

    return Row(
      children: [
        // 완료 표시 아이콘
        GestureDetector(
          onTap: isCompleted
              ? null
              : () => _handleMedicationComplete(medication),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? AppColors.success : AppColors.error,
                width: 2,
              ),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle_outlined,
              color: isCompleted ? Colors.white : AppColors.error,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),

        // 약물 아이콘
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isInjection
                ? AppColors.primaryPurpleLight
                : AppColors.info.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isInjection ? Icons.vaccines : Icons.medication,
            color: isInjection ? AppColors.primaryPurple : AppColors.info,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.s),

        // 시간 및 약물명
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$timeLabel ${medication.time}',
                    style: AppTextStyles.caption.copyWith(
                      color: isCompleted
                          ? AppColors.textDisabled
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (medication.dosage != null) ...[
                    Text(' • ', style: AppTextStyles.caption),
                    Text(
                      medication.dosage!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // 완료 버튼
        if (!isCompleted)
          AppButton(
            text: '완료',
            onPressed: () => _handleMedicationComplete(medication),
            width: 72,
            height: 36,
          ),
      ],
    );
  }

  void _handleMedicationComplete(Medication medication) async {
    if (medication.type == MedicationType.injection) {
      // 주사인 경우 위치 선택 다이얼로그 표시
      final selectedLocation = await InjectionLocationDialog.show(
        context,
        lastLocation: _lastInjectionLocation,
      );

      if (selectedLocation != null) {
        setState(() {
          _medicationStatus[medication.id] = true;
          _lastInjectionLocation = selectedLocation;
        });
        // 로컬 저장소에 상태 저장
        await MedicationStorageService.setMedicationStatus(
          DateTime.now(),
          medication.id,
          true,
        );

        // 완료 확인 다이얼로그 표시
        if (mounted) {
          await InjectionCompleteDialog.show(
            context,
            medicationName: medication.name,
            selectedLocation: selectedLocation,
            // 8개 위치 (좌측 0-3, 우측 4-7)에서 좌/우 번갈아 추천
            // nextRecommendedLocation은 InjectionCompleteDialog 내부에서 자동 계산됨
          );
        }
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
    }
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
