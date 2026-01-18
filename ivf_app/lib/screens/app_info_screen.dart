import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';

/// 앱 정보 URL 상수
class AppInfoUrls {
  static const help = 'https://continuous-snow-251.notion.site/2ea3287faece81c4a48dc98ba350aa8b';
  static const terms = 'https://continuous-snow-251.notion.site/1-2ea3287faece801dba3eeddc8bec43bf';
  static const privacy = 'https://continuous-snow-251.notion.site/2-2ea3287faece80a8bf3bf9dec2683d42';
  static const disclaimer = 'https://continuous-snow-251.notion.site/3-2ea3287faece80d7bfa3fb41cd761fc2';
}

/// 앱 정보 상세 화면
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

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
          '앱 정보',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            // 메뉴 항목들 (도움말 + 약관 + 앱 버전)
            AppCard(
              child: Column(
                children: [
                  // 도움말
                  _buildNavigationTile(
                    icon: Icons.help_outline,
                    title: '도움말',
                    onTap: () => _openUrl(context, AppInfoUrls.help),
                  ),
                  const Divider(height: 1),
                  // 서비스 이용약관
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: '서비스 이용약관',
                    onTap: () => _openUrl(context, AppInfoUrls.terms),
                  ),
                  const Divider(height: 1),
                  // 개인정보 처리방침
                  _buildNavigationTile(
                    icon: Icons.privacy_tip_outlined,
                    title: '개인정보 처리방침',
                    onTap: () => _openUrl(context, AppInfoUrls.privacy),
                  ),
                  const Divider(height: 1),
                  // 의료기기 아님 확인
                  _buildNavigationTile(
                    icon: Icons.medical_information_outlined,
                    title: '의료기기 아님 확인',
                    onTap: () => _openUrl(context, AppInfoUrls.disclaimer),
                  ),
                  const Divider(height: 1),
                  // 앱 버전
                  _buildVersionTile(),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 저작권 표시
            Text(
              '2025 기다림메이트. All rights reserved.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(title, style: AppTextStyles.body),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// URL 열기 (외부 브라우저)
  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('링크를 열 수 없습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('URL 열기 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크 열기 오류: $e'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 앱 버전 타일 (화살표 없음, 클릭 불가)
  Widget _buildVersionTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text('앱 버전', style: AppTextStyles.body),
          ),
          Text(
            '1.0.0',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
