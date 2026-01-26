import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// 개인정보 처리방침 화면 (로컬 저장 전용 버전)
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '개인정보 처리방침',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '기다림메이트 개인정보 처리방침',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '시행일: 2025년 1월 19일',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              _buildSection(
                '1. 개인정보 수집',
                '기다림메이트는 개인정보를 수집하지 않습니다.\n\n'
                '• 회원가입/로그인이 없습니다\n'
                '• 모든 데이터는 사용자 기기에만 저장됩니다\n'
                '• 외부 서버로 데이터가 전송되지 않습니다',
              ),

              _buildSection(
                '2. 기기 내 저장 데이터',
                '앱 사용을 위해 다음 데이터가 기기에 저장됩니다.\n\n'
                '• 시술 일정 및 기록\n'
                '• 약물 복용 알림 설정\n'
                '• 병원 정보\n'
                '• 메모 및 기타 입력 정보\n\n'
                '※ 위 데이터는 사용자 기기에만 저장되며, 앱 삭제 시 함께 삭제됩니다.',
              ),

              _buildSection(
                '3. 제3자 제공',
                '수집하는 개인정보가 없으므로 제3자에게 제공하지 않습니다.',
              ),

              _buildSection(
                '4. 데이터 삭제',
                '앱을 삭제하면 모든 데이터가 기기에서 완전히 삭제됩니다.\n\n'
                '또는 앱 내 설정 > 데이터 초기화를 통해 데이터를 삭제할 수 있습니다.',
              ),

              _buildSection(
                '5. 개인정보 보호책임자',
                '개인정보 처리에 관한 문의사항은 아래로 연락해 주세요.\n\n'
                '이메일: support@ivfmate.app',
              ),

              _buildSection(
                '6. 정책 변경',
                '본 개인정보 처리방침이 변경되는 경우, 변경 사항을 앱 내 공지를 통해 안내해 드립니다.',
              ),

              const SizedBox(height: AppSpacing.l),
              Center(
                child: Text(
                  '© 2025 기다림메이트',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
