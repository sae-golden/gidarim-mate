import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// 약물 액션 결과
enum MedicationActionResult {
  complete,   // 복용 완료
  skip,       // 건너뛰기
  edit,       // 수정
  delete,     // 삭제
}

/// 약물 액션 바텀시트 (홈, 캘린더에서 공통 사용)
class MedicationActionBottomSheet extends StatelessWidget {
  final String medicationName;
  final DateTime date;
  final bool isCompleted;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MedicationActionBottomSheet({
    super.key,
    required this.medicationName,
    required this.date,
    this.isCompleted = false,
    this.onComplete,
    this.onSkip,
    this.onEdit,
    this.onDelete,
  });

  /// 바텀시트 표시
  static Future<MedicationActionResult?> show(
    BuildContext context, {
    required String medicationName,
    required DateTime date,
    bool isCompleted = false,
  }) async {
    return showModalBottomSheet<MedicationActionResult>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MedicationActionBottomSheet(
        medicationName: medicationName,
        date: date,
        isCompleted: isCompleted,
        onComplete: () => Navigator.pop(context, MedicationActionResult.complete),
        onSkip: () => Navigator.pop(context, MedicationActionResult.skip),
        onEdit: () => Navigator.pop(context, MedicationActionResult.edit),
        onDelete: () => Navigator.pop(context, MedicationActionResult.delete),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Expanded(
                  child: Text(
                    medicationName,
                    style: AppTextStyles.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 수정 버튼
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurpleLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: AppColors.primaryPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '수정',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
                // 삭제 버튼
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '삭제',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${date.month}월 ${date.day}일',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            Text(
              '이 약을 복용하셨나요?',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // 완료 버튼
            if (onComplete != null)
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        '네, 복용했어요',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.s),

            // 건너뛰기 버튼
            if (onSkip != null)
              GestureDetector(
                onTap: onSkip,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        '아니요, 건너뛰었어요',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}
