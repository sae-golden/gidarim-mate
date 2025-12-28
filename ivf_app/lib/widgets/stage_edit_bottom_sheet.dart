import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import 'app_button.dart';

/// 단계 편집 바텀시트
class StageEditBottomSheet extends StatefulWidget {
  final SimpleTreatmentStage stage;
  final Function(SimpleTreatmentStage) onSave;

  const StageEditBottomSheet({
    super.key,
    required this.stage,
    required this.onSave,
  });

  /// 바텀시트 표시
  static Future<SimpleTreatmentStage?> show(
    BuildContext context, {
    required SimpleTreatmentStage stage,
  }) {
    return showModalBottomSheet<SimpleTreatmentStage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StageEditBottomSheet(
        stage: stage,
        onSave: (updatedStage) {
          Navigator.pop(context, updatedStage);
        },
      ),
    );
  }

  @override
  State<StageEditBottomSheet> createState() => _StageEditBottomSheetState();
}

class _StageEditBottomSheetState extends State<StageEditBottomSheet> {
  late DateTime? _selectedDate;
  late int? _count;
  late ResultType? _result;

  @override
  void initState() {
    super.initState();
    // 시작일 또는 당일 날짜 선택
    _selectedDate = widget.stage.type.usesStartDateOnly
        ? widget.stage.startDate
        : widget.stage.date;
    _count = widget.stage.count;
    _result = widget.stage.result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
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
              Text(widget.stage.type.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.s),
              Text(
                widget.stage.type.name,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // 날짜 선택
          _buildDateSelector(),
          const SizedBox(height: AppSpacing.m),

          // 개수 입력 (채취, 이식대기만)
          if (widget.stage.type.hasCountInput) ...[
            _buildCountSelector(),
            const SizedBox(height: AppSpacing.m),
          ],

          // 결과 선택 (판정만)
          if (widget.stage.type == SimpleStageType.result) ...[
            _buildResultSelector(),
            const SizedBox(height: AppSpacing.m),
          ],

          const SizedBox(height: AppSpacing.m),

          // 완료 버튼
          AppButton(
            text: '완료',
            onPressed: _handleSave,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  /// 날짜 선택 위젯
  Widget _buildDateSelector() {
    final isStartDate = widget.stage.type.usesStartDateOnly;
    final label = isStartDate ? '📅 시작일' : '📅 날짜';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? '${_selectedDate!.year}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.day.toString().padLeft(2, '0')}'
                      : '날짜를 선택하세요',
                  style: AppTextStyles.body.copyWith(
                    color: _selectedDate != null
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 개수 선택 위젯
  Widget _buildCountSelector() {
    final label = widget.stage.type == SimpleStageType.retrieval
        ? '🥚 채취 개수 (선택)'
        : '❄️ 동결 개수 (선택)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 감소 버튼
              IconButton(
                onPressed: _count != null && _count! > 0
                    ? () => setState(() => _count = _count! - 1)
                    : null,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, color: AppColors.primaryPurple),
                ),
              ),
              const SizedBox(width: AppSpacing.l),
              // 개수 표시
              Text(
                _count != null ? '${_count}개' : '-',
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _count != null
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                ),
              ),
              const SizedBox(width: AppSpacing.l),
              // 증가 버튼
              IconButton(
                onPressed: () {
                  setState(() {
                    _count = (_count ?? 0) + 1;
                  });
                },
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 결과 선택 위젯 (판정)
  Widget _buildResultSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎉 결과 (선택)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: ResultType.values.map((type) {
            final isSelected = _result == type;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _result = isSelected ? null : type;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: type != ResultType.unknown ? AppSpacing.s : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primaryPurple : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        type.label,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : AppColors.background,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDisabled,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: AppColors.primaryPurple)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSave() {
    SimpleTreatmentStage updatedStage;

    if (widget.stage.type.usesStartDateOnly) {
      // 과배란, 이식대기: startDate 사용
      updatedStage = widget.stage.copyWith(
        startDate: _selectedDate,
        count: _count,
        result: _result,
      );
    } else {
      // 채취, 이식, 판정: date 사용
      updatedStage = widget.stage.copyWith(
        date: _selectedDate,
        count: _count,
        result: _result,
      );
    }

    widget.onSave(updatedStage);
  }
}
