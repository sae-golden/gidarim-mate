import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// 확인 바텀시트 (기존 AlertDialog 대체)
/// 위험한 액션(삭제, 로그아웃 등)과 취소 버튼을 바텀시트로 표시
class ConfirmBottomSheet extends StatelessWidget {
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmBottomSheet({
    super.key,
    required this.message,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.confirmColor = const Color(0xFFE74C3C), // 기본 경고색
    this.onConfirm,
    this.onCancel,
  });

  /// 바텀시트 표시 및 결과 반환
  /// 반환값: true (확인), false (취소)
  static Future<bool> show(
    BuildContext context, {
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmColor,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfirmBottomSheet(
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor ?? const Color(0xFFE74C3C),
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.l,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: AppSpacing.xl),

          // 메시지
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 확인 버튼 (위험한 액션)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                confirmText,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // 취소 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCancel ?? () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                foregroundColor: const Color(0xFF666666),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                cancelText,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
