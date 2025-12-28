import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// 앱 기본 버튼 (토스 스타일)
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final double? width;
  final double height;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.width,
    this.height = 52,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: type == AppButtonType.primary
          ? _buildPrimaryButton()
          : type == AppButtonType.secondary
              ? _buildSecondaryButton()
              : _buildTextButton(),
    );
  }
  
  Widget _buildPrimaryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.button,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSecondaryButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border.all(
          color: AppColors.primaryPurple,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.button.copyWith(
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      ),
    );
  }
}

enum AppButtonType {
  primary,
  secondary,
  text,
}
