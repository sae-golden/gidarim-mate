import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import '../models/additional_records.dart';

/// 타임라인 시작 노드
/// 기획서: "시작 2025.12.01" 형태
class TimelineStart extends StatelessWidget {
  final DateTime startDate;
  final int cycleNumber;
  final TreatmentType treatmentType;
  final VoidCallback? onTap;

  const TimelineStart({
    super.key,
    required this.startDate,
    required this.cycleNumber,
    this.treatmentType = TreatmentType.ivf,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시작 원형 노드
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // 연결 라인
                  Container(
                    width: 2,
                    height: 20,
                    color: const Color(0xFFE9D5FF),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 구분선
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 16,
                height: 2,
                color: const Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 텍스트
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '시작 ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      dateText,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 타임라인 이벤트 노드
/// 기획서:
/// - 💉 ── 과배란 중이에요
/// - │    12.01
/// - │
/// - 🥚 ── 채취했어요
/// - │    12.18 · 12개 → 성숙 10개 → 수정 8개
class TimelineEventWidget extends StatelessWidget {
  final TreatmentEvent event;
  final bool isLast;
  final VoidCallback? onTap;

  const TimelineEventWidget({
    super.key,
    required this.event,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타임라인 라인 + 이모지 노드
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  // 이모지 원
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF), // 연보라 배경
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9B7ED9),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        event.type.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  // 연결 라인
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        constraints: const BoxConstraints(minHeight: 40),
                        color: const Color(0xFFE9D5FF), // 연보라
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 구분선
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 16,
                height: 2,
                color: const Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타입 텍스트
                    Text(
                      event.type.displayText, // "과배란 중이에요" 등
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 상세 정보 (기획서 규칙 적용)
                    Text(
                      _getDetailText(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // 메모
                    if (event.memo != null && event.memo!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.memo!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상세 정보 텍스트 (기획서 규칙)
  String _getDetailText() {
    switch (event.type) {
      case EventType.stimulation:
        return event.dateText;
      case EventType.retrieval:
        // "12.18 · 12개 → 성숙 10개 → 수정 8개"
        final parts = <String>[event.dateText];
        if (event.count != null) {
          final retrievalParts = <String>['${event.count}개'];
          if (event.matureCount != null) {
            retrievalParts.add('성숙 ${event.matureCount}개');
          }
          if (event.fertilizedCount != null) {
            retrievalParts.add('수정 ${event.fertilizedCount}개');
          }
          parts.add(retrievalParts.join(' → '));
        }
        return parts.join(' · ');
      case EventType.transfer:
      case EventType.freezing:
        // "12.26 · 5일 배아 · 2개" 또는 "12.26 · 5일 2개, 3일 1개"
        final parts = <String>[event.dateText];
        if (event.embryos != null && event.embryos!.isNotEmpty) {
          parts.add(event.embryos!.map((e) => e.displayText).join(', '));
        } else if (event.embryoDays != null && event.count != null) {
          parts.add('${event.embryoDays}일 배아 · ${event.count}개');
        } else if (event.count != null) {
          parts.add('${event.count}개');
        }
        return parts.join(' · ');
      case EventType.insemination:
        return event.dateText;
    }
  }
}

/// 타임라인 추가 버튼
/// 기획서: ○ ── 다음 단계를 기록해주세요 [+]
class TimelineAddButton extends StatelessWidget {
  final String? hint;
  final VoidCallback onTap;
  final bool isFirst; // 첫 기록인지

  const TimelineAddButton({
    super.key,
    this.hint,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 라인 + 빈 원 노드
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // 빈 원 (점선)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                ),
                // 연결 라인
                Expanded(
                  child: Container(
                    width: 2,
                    constraints: const BoxConstraints(minHeight: 30),
                    color: const Color(0xFFE9D5FF).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          // 구분선
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              width: 16,
              height: 2,
              color: const Color(0xFFE9D5FF).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          // 블록 버튼 스타일 (진한 보라 배경 + 흰색 텍스트로 강조)
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s + 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFirst ? '첫 단계 기록하기' : '다음 단계 기록하기',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // [+] 아이콘
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 타임라인 종료 노드
/// 기획서:
/// - 🎉 ── 좋은 소식이 있어요!
/// -      01.05
/// - 종료 2025.01.05
class TimelineEnd extends StatelessWidget {
  final CycleResult result;
  final DateTime? endDate;
  final VoidCallback? onTap;

  const TimelineEnd({
    super.key,
    required this.result,
    this.endDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 결과 이벤트 노드
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 타임라인 라인 + 이모지 노드
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      // 이모지 원
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getResultColor(result).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getResultColor(result),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            result.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                // 구분선
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    width: 16,
                    height: 2,
                    color: _getResultColor(result).withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                // 내용
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.label,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getResultColor(result),
                          ),
                        ),
                        if (endDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 종료일 텍스트
          if (endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Row(
                children: [
                  Text(
                    '종료 ',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${endDate!.year}.${endDate!.month.toString().padLeft(2, '0')}.${endDate!.day.toString().padLeft(2, '0')}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getResultColor(CycleResult result) {
    switch (result) {
      case CycleResult.success:
        return Colors.green;
      case CycleResult.frozen:
        return Colors.blue;
      case CycleResult.rest:
      case CycleResult.nextTime:
        return AppColors.primaryPurple;
    }
  }
}

/// 빈 타임라인 안내 메시지
/// 기획서: "💜 차근차근 함께 기록해요"
class TimelineEmptyMessage extends StatelessWidget {
  const TimelineEmptyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            const Text('💜', style: TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.s),
            Text(
              '차근차근 함께 기록해요',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 새 채취/시도 시작 버튼
/// 기획서: "🥚 새로운 채취 시작하기 >" 또는 "💫 새로운 시도 시작하기 >"
class TimelineNewCycleButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const TimelineNewCycleButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(
            top: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 지난 기록 보기 버튼
/// 기획서: "🕐 지난 기록 보기"
class TimelinePastRecordsButton extends StatelessWidget {
  final VoidCallback onTap;

  const TimelinePastRecordsButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🕐', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '지난 기록 보기',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 타임라인 피검사 기록 노드
/// 다른 이벤트와 동일한 타임라인 스타일
class TimelineBloodTestWidget extends StatelessWidget {
  final BloodTest bloodTest;
  final VoidCallback? onTap;

  const TimelineBloodTestWidget({
    super.key,
    required this.bloodTest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타임라인 라인 + 이모지 노드
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  // 이모지 원 (빨간색 테마)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '📋',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  // 연결 라인
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 40),
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 구분선
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 16,
                height: 2,
                color: const Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타입 텍스트
                    Text(
                      '피검사',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 날짜 및 수치 요약
                    Text(
                      bloodTest.hasAnyValue
                          ? '${bloodTest.dateText} · ${bloodTest.summaryText}'
                          : bloodTest.dateText,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// @deprecated Use TimelineEmptyMessage instead
class TimelineEmpty extends StatelessWidget {
  final VoidCallback onAddFirst;

  const TimelineEmpty({
    super.key,
    required this.onAddFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.m),
          Text(
            '아직 기록이 없어요',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '첫 번째 기록을 추가해보세요',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ElevatedButton.icon(
            onPressed: onAddFirst,
            icon: const Icon(Icons.add),
            label: const Text('기록 추가하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.m,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 타임라인 추가 기록 항목 노드
/// 생리 시작일, 초음파, 임신 테스트, 몸 상태 등
class TimelineAdditionalRecordWidget extends StatelessWidget {
  final RecordType recordType;
  final DateTime date;
  final String summary;
  final VoidCallback? onTap;

  const TimelineAdditionalRecordWidget({
    super.key,
    required this.recordType,
    required this.date,
    required this.summary,
    this.onTap,
  });

  String get _dateText {
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타임라인 라인 + 이모지 노드
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  // 이모지 원 (타입별 색상)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: recordType.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: recordType.color.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        recordType.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  // 연결 라인
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 40),
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 구분선
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                width: 16,
                height: 2,
                color: const Color(0xFFE9D5FF),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            // 내용
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타입 텍스트
                    Text(
                      recordType.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 날짜 및 요약
                    Text(
                      '$_dateText · $summary',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
