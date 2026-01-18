import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import '../models/additional_records.dart';

/// 이벤트 타입 선택 바텀시트 (기획서 v2 - 컴팩트 리스트)
/// 기획서에 맞춘 UI: 카테고리별 분류, 컴팩트 리스트
class EventTypeBottomSheet extends StatelessWidget {
  final Function(EventType) onSelect;
  final VoidCallback? onFinish; // 이번 시도 마무리하기
  final VoidCallback? onBloodTest; // 피검사 기록
  final VoidCallback? onNewCycle; // 새로운 시도 시작하기
  final List<EventType> availableTypes; // 사용 가능한 이벤트 타입들
  final bool hasRecords; // 기록이 있는지 여부
  // 신규 항목 콜백
  final VoidCallback? onPeriod; // 생리 시작일
  final VoidCallback? onUltrasound; // 초음파 검사
  final VoidCallback? onPregnancyTest; // 임신 테스트
  final VoidCallback? onCondition; // 몸 상태

  const EventTypeBottomSheet({
    super.key,
    required this.onSelect,
    this.onFinish,
    this.onBloodTest,
    this.onNewCycle,
    required this.availableTypes,
    this.hasRecords = false,
    this.onPeriod,
    this.onUltrasound,
    this.onPregnancyTest,
    this.onCondition,
  });

  /// 바텀시트 표시
  /// [availableTypes]: 시술 종류에 따라 표시할 이벤트 타입 목록
  /// [hasRecords]: 기록이 있는지 여부 (첫 진입 vs 기록 있음)
  /// 반환값: EventType (선택) 또는 String 타입 (특수 액션) 또는 null (취소)
  static Future<dynamic> show(
    BuildContext context, {
    required List<EventType> availableTypes,
    bool showFinishOption = true,
    bool showBloodTestOption = true,
    bool showNewCycleOption = true,
    bool hasRecords = false,
    // 신규 항목 표시 여부
    bool showPeriodOption = true,
    bool showUltrasoundOption = true,
    bool showPregnancyTestOption = true,
    bool showConditionOption = true,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventTypeBottomSheet(
        availableTypes: availableTypes,
        hasRecords: hasRecords,
        onSelect: (type) {
          Navigator.pop(context, type);
        },
        onFinish: showFinishOption
            ? () {
                Navigator.pop(context, 'finish');
              }
            : null,
        onBloodTest: showBloodTestOption
            ? () {
                Navigator.pop(context, 'bloodTest');
              }
            : null,
        onNewCycle: showNewCycleOption
            ? () {
                Navigator.pop(context, 'newCycle');
              }
            : null,
        onPeriod: showPeriodOption
            ? () {
                Navigator.pop(context, 'period');
              }
            : null,
        onUltrasound: showUltrasoundOption
            ? () {
                Navigator.pop(context, 'ultrasound');
              }
            : null,
        onPregnancyTest: showPregnancyTestOption
            ? () {
                Navigator.pop(context, 'pregnancyTest');
              }
            : null,
        onCondition: showConditionOption
            ? () {
                Navigator.pop(context, 'condition');
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 (고정)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.l),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // 제목 (고정)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '어떤 단계를 기록할까요?',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // 스크롤 가능 영역
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주기 관리 섹션
                  _buildCategoryHeader('주기 관리'),
                  if (onPeriod != null) _buildCompactItem(
                    RecordType.period.displayText,  // 생리 시작했어요
                    RecordType.period.color,
                    onPeriod!,
                  ),
                  if (hasRecords && onFinish != null) _buildCompactItem(
                    RecordType.cycleResult.displayText,  // 사이클 결과
                    RecordType.cycleResult.color,
                    onFinish!,
                  ),
                  _buildDivider(),

                  // 시술 기록 섹션
                  _buildCategoryHeader('시술 기록'),
                  ...availableTypes.map((type) => _buildCompactEventItem(type)),
                  _buildDivider(),

                  // 검사 기록 섹션
                  _buildCategoryHeader('검사 기록'),
                  if (onBloodTest != null) _buildCompactItem(
                    RecordType.bloodTest.displayText,  // 피검사 했어요
                    RecordType.bloodTest.color,
                    onBloodTest!,
                  ),
                  if (onUltrasound != null) _buildCompactItem(
                    RecordType.ultrasound.displayText,  // 초음파 봤어요
                    RecordType.ultrasound.color,
                    onUltrasound!,
                  ),
                  if (onPregnancyTest != null) _buildCompactItem(
                    RecordType.pregnancyTest.displayText,  // 임신 테스트 했어요
                    RecordType.pregnancyTest.color,
                    onPregnancyTest!,
                  ),
                  _buildDivider(),

                  // 일상 기록 섹션
                  _buildCategoryHeader('일상 기록'),
                  if (onCondition != null) _buildCompactItem(
                    RecordType.condition.displayText,  // 오늘 몸 상태 기록하기
                    RecordType.condition.color,
                    onCondition!,
                  ),

                  // 새로운 시도 시작하기 (맨 아래)
                  if (onNewCycle != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    _buildNewCycleOption(context),
                  ],

                  const SizedBox(height: AppSpacing.m),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 카테고리 헤더
  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 구분선
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Container(
        height: 1,
        color: AppColors.border.withValues(alpha: 0.3),
      ),
    );
  }

  /// 컴팩트 아이템 (색상 점 + 이름 + 화살표)
  Widget _buildCompactItem(String name, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            // 색상 점
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            // 이름
            Expanded(
              child: Text(
                name,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // 화살표
            Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 컴팩트 이벤트 아이템 (EventType용)
  Widget _buildCompactEventItem(EventType type) {
    return _buildCompactItem(
      type.displayText,  // "과배란 중이에요", "채취했어요" 등
      _getTypeColor(type),
      () => onSelect(type),
    );
  }

  /// 새로운 시도 시작하기 버튼
  Widget _buildNewCycleOption(BuildContext context) {
    return InkWell(
      onTap: onNewCycle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.primaryPurpleLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🌱',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppSpacing.s),
            Text(
              '새로운 시도 시작하기',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(EventType type) {
    switch (type) {
      case EventType.stimulation:
        return RecordType.stimulation.color;
      case EventType.retrieval:
        return RecordType.retrieval.color;
      case EventType.transfer:
        return RecordType.transfer.color;
      case EventType.freezing:
        return RecordType.freezing.color;
      case EventType.insemination:
        return RecordType.insemination.color;
    }
  }
}
