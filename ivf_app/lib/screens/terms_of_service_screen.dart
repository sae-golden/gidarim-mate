import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// 이용약관 화면
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          '이용약관',
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
                '기다림메이트 이용약관',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '시행일: 2025년 1월 1일',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              _buildSection(
                '제1조 (목적)',
                '본 약관은 기다림메이트(이하 "앱")가 제공하는 약물 알림 서비스의 이용조건 및 절차에 관한 사항을 규정함을 목적으로 합니다.',
              ),

              _buildSection(
                '제2조 (서비스의 내용)',
                '앱은 다음 서비스를 제공합니다.\n\n'
                '• 약물 복용 시간 알림\n'
                '• 복용 기록 관리\n'
                '• 치료 일정 관리\n'
                '• 클라우드 데이터 동기화 (로그인 시)',
              ),

              _buildSection(
                '제3조 (의료 면책)',
                '1. 앱은 의료 기기가 아니며, 의학적 진단, 치료, 예방을 목적으로 하지 않습니다.\n\n'
                '2. 앱에서 제공하는 모든 정보는 참고용이며, 전문적인 의료 조언을 대체하지 않습니다.\n\n'
                '3. 모든 약물 복용 및 치료 관련 결정은 반드시 담당 의료진과 상담 후 진행해야 합니다.\n\n'
                '4. 앱 사용으로 인한 건강상의 문제에 대해 개발사는 책임지지 않습니다.',
              ),

              _buildSection(
                '제4조 (이용자의 의무)',
                '이용자는 다음 사항을 준수해야 합니다.\n\n'
                '• 정확한 정보 입력\n'
                '• 타인의 개인정보 도용 금지\n'
                '• 서비스의 정상적인 운영 방해 금지\n'
                '• 관련 법령 준수',
              ),

              _buildSection(
                '제5조 (서비스 이용)',
                '1. 앱은 무료로 제공됩니다.\n\n'
                '2. 일부 기능은 회원가입 후 이용 가능합니다.\n\n'
                '3. 앱은 필요한 경우 서비스 내용을 변경할 수 있으며, 변경 시 사전 공지합니다.',
              ),

              _buildSection(
                '제6조 (서비스 중단)',
                '앱은 다음 경우 서비스를 일시적으로 중단할 수 있습니다.\n\n'
                '• 시스템 점검, 보수 또는 교체\n'
                '• 천재지변, 국가비상사태 등 불가항력적 사유\n'
                '• 기타 운영상 필요한 경우',
              ),

              _buildSection(
                '제7조 (책임의 한계)',
                '1. 앱은 무료 서비스로 제공되며, 특별한 사정이 없는 한 서비스 이용과 관련하여 발생하는 손해에 대해 책임지지 않습니다.\n\n'
                '2. 이용자의 귀책사유로 인한 서비스 이용 장애에 대해서는 책임지지 않습니다.\n\n'
                '3. 앱에 입력된 정보의 정확성은 이용자에게 책임이 있습니다.',
              ),

              _buildSection(
                '제8조 (분쟁 해결)',
                '본 약관과 관련한 분쟁은 대한민국 법령에 따라 해결하며, 관할 법원은 민사소송법에 따릅니다.',
              ),

              _buildSection(
                '제9조 (약관 변경)',
                '본 약관은 필요시 변경될 수 있으며, 변경된 약관은 앱 내 공지를 통해 안내합니다. 변경된 약관에 동의하지 않는 경우 서비스 이용을 중단할 수 있습니다.',
              ),

              const SizedBox(height: AppSpacing.l),

              // 부칙
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '부칙',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      '본 약관은 2025년 1월 1일부터 시행됩니다.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
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
