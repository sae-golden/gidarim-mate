import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// 개인정보 처리방침 화면
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
                '시행일: 2025년 1월 1일',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              _buildSection(
                '1. 수집하는 개인정보',
                '기다림메이트는 서비스 제공을 위해 다음 정보를 수집합니다.\n\n'
                '• 필수 정보: 이메일 주소 (회원가입 시)\n'
                '• 선택 정보: 약물 복용 일정, 병원 정보, 주사 부위 기록\n'
                '• 자동 수집 정보: 앱 사용 기록, 기기 정보, 오류 로그',
              ),

              _buildSection(
                '2. 개인정보 수집 목적',
                '수집된 개인정보는 다음 목적으로 사용됩니다.\n\n'
                '• 약물 복용 알림 서비스 제공\n'
                '• 복용 기록 저장 및 동기화\n'
                '• 서비스 개선 및 오류 분석\n'
                '• 고객 문의 응대',
              ),

              _buildSection(
                '3. 개인정보 보유 기간',
                '• 회원 탈퇴 시: 즉시 삭제\n'
                '• 서비스 이용 기록: 회원 탈퇴 시까지\n'
                '• 관련 법령에 따라 보존이 필요한 경우 해당 기간 동안 보관',
              ),

              _buildSection(
                '4. 개인정보 제3자 제공',
                '기다림메이트는 원칙적으로 개인정보를 외부에 제공하지 않습니다.\n\n'
                '단, 다음의 경우는 예외로 합니다.\n'
                '• 이용자가 사전에 동의한 경우\n'
                '• 법령에 따라 요청이 있는 경우',
              ),

              _buildSection(
                '5. 개인정보 처리 위탁',
                '기다림메이트는 서비스 제공을 위해 다음 업체에 개인정보 처리를 위탁합니다.\n\n'
                '• Supabase (데이터베이스 및 인증 서비스)\n'
                '• Google Firebase (푸시 알림 서비스)',
              ),

              _buildSection(
                '6. 이용자의 권리',
                '이용자는 언제든지 다음 권리를 행사할 수 있습니다.\n\n'
                '• 개인정보 열람 요청\n'
                '• 개인정보 정정 요청\n'
                '• 개인정보 삭제 요청\n'
                '• 처리 정지 요청\n\n'
                '권리 행사는 앱 내 설정 > 데이터 초기화 또는 이메일로 요청하실 수 있습니다.',
              ),

              _buildSection(
                '7. 개인정보 보호책임자',
                '개인정보 처리에 관한 문의사항은 아래로 연락해 주세요.\n\n'
                '이메일: support@ivfmate.app',
              ),

              _buildSection(
                '8. 개인정보의 안전성 확보',
                '기다림메이트는 개인정보 보호를 위해 다음 조치를 취합니다.\n\n'
                '• 개인정보 암호화 전송 (SSL/TLS)\n'
                '• 접근 권한 관리\n'
                '• 정기적인 보안 점검',
              ),

              _buildSection(
                '9. 정책 변경',
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
