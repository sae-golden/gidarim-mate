import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 토스트 유틸리티 - 상단에 표시되는 스낵바
class ToastUtils {
  /// 성공 토스트 (보라색)
  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, AppColors.success);
  }

  /// 에러 토스트 (핑크색)
  static void showError(BuildContext context, String message) {
    _showToast(context, message, AppColors.error);
  }

  /// 경고 토스트 (살구색)
  static void showWarning(BuildContext context, String message) {
    _showToast(context, message, AppColors.warning, textColor: AppColors.textPrimary);
  }

  /// 정보 토스트 (기본 보라색)
  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, AppColors.primaryPurple, textColor: AppColors.textPrimary);
  }

  /// 공통 토스트 표시
  static void _showToast(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Color textColor = Colors.white,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 100, // 탭바 위에 표시
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
