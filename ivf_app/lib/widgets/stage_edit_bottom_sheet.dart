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
  late int? _cultureDay;
  late String? _memo;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    // 시작일 또는 당일 날짜 선택
    _selectedDate = widget.stage.type.usesStartDateOnly
        ? widget.stage.startDate
        : widget.stage.date;
    _count = widget.stage.count;
    _cultureDay = widget.stage.cultureDay;
    _memo = widget.stage.memo;
    _memoController = TextEditingController(text: _memo ?? '');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
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

          // 배양일수 입력 (이식, 동결만)
          if (widget.stage.type.hasCultureDayInput) ...[
            _buildCultureDaySelector(),
            const SizedBox(height: AppSpacing.m),
          ],

          // 메모 입력
          _buildMemoInput(),
          const SizedBox(height: AppSpacing.m),

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

  /// 배양일수 선택 위젯
  Widget _buildCultureDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧫 배양일수 (선택)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [3, 5, 6].map((day) {
            final isSelected = _cultureDay == day;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _cultureDay = isSelected ? null : day;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: day != 6 ? AppSpacing.s : 0,
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
                  child: Center(
                    child: Text(
                      'D$day',
                      style: AppTextStyles.body.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 메모 입력 위젯
  Widget _buildMemoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 메모 (선택)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _memoController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '메모를 입력하세요',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryPurple),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.m),
          ),
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
    final memoText = _memoController.text.trim();
    SimpleTreatmentStage updatedStage;

    if (widget.stage.type.usesStartDateOnly) {
      // 배란유도: startDate 사용
      updatedStage = widget.stage.copyWith(
        startDate: _selectedDate,
        count: _count,
        cultureDay: _cultureDay,
        memo: memoText.isNotEmpty ? memoText : null,
        clearMemo: memoText.isEmpty,
      );
    } else {
      // 배란주사, 채취, 이식, 동결: date 사용
      updatedStage = widget.stage.copyWith(
        date: _selectedDate,
        count: _count,
        cultureDay: _cultureDay,
        memo: memoText.isNotEmpty ? memoText : null,
        clearMemo: memoText.isEmpty,
      );
    }

    widget.onSave(updatedStage);
  }
}
