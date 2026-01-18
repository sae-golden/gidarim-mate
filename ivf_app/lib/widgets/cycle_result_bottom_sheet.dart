import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import 'app_button.dart';

/// 사이클 결과 선택 바텀시트 (4가지 옵션)
class CycleResultBottomSheet extends StatefulWidget {
  final CycleResult? currentResult;
  final Function(CycleResult?) onSave;
  final VoidCallback? onClear;

  const CycleResultBottomSheet({
    super.key,
    this.currentResult,
    required this.onSave,
    this.onClear,
  });

  /// 바텀시트 표시
  static Future<dynamic> show(
    BuildContext context, {
    CycleResult? currentResult,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CycleResultBottomSheet(
        currentResult: currentResult,
        onSave: (result) {
          Navigator.pop(context, result);
        },
        onClear: currentResult != null
            ? () {
                Navigator.pop(context, 'clear');
              }
            : null,
      ),
    );
  }

  @override
  State<CycleResultBottomSheet> createState() => _CycleResultBottomSheetState();
}

class _CycleResultBottomSheetState extends State<CycleResultBottomSheet> {
  late CycleResult? _selectedResult;

  @override
  void initState() {
    super.initState();
    _selectedResult = widget.currentResult;
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
              const Text('📋', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.s),
              Text(
                '이번 사이클 어떻게 되셨나요?',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 결과 옵션들 (4가지)
          ...CycleResult.values.map((result) => _buildResultOption(result)),

          const SizedBox(height: AppSpacing.l),

          // 버튼들
          Row(
            children: [
              // 결과 초기화 버튼 (이미 결과가 있는 경우)
              if (widget.onClear != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('결과 초기화'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
              ],
              // 완료 버튼
              Expanded(
                flex: widget.onClear != null ? 2 : 1,
                child: AppButton(
                  text: '완료',
                  onPressed: _selectedResult != null
                      ? () => widget.onSave(_selectedResult)
                      : null,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultOption(CycleResult result) {
    final isSelected = _selectedResult == result;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedResult = result;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: isSelected
                ? _getResultColor(result).withOpacity(0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _getResultColor(result) : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(result.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.shortLabel,
                      style: AppTextStyles.body.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? _getResultColor(result)
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: _getResultColor(result),
                  size: 20,
                ),
            ],
          ),
        ),
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
