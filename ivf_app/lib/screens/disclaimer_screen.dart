import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';

/// 의료 면책 조항 열람 화면 (앱 정보에서 접근)
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

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
          '의료기기 아님 확인',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    '의료 면책 조항',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 면책 조항 내용
            _buildDisclaimerItem(
              '앱의 목적',
              '기다림메이트는 IVF(체외수정) 시술 중 약물 복용 시간을 알려주는 알림 앱입니다.',
            ),
            _buildDisclaimerItem(
              '의료 기기 아님',
              '이 앱은 의료 기기가 아니며, 의학적 진단, 치료, 예방을 목적으로 하지 않습니다.',
            ),
            _buildDisclaimerItem(
              '참고용 정보',
              '앱에서 제공하는 모든 정보는 참고용이며, 전문적인 의료 조언을 대체하지 않습니다.',
            ),
            _buildDisclaimerItem(
              '의료진 상담 필수',
              '모든 약물 복용, 용량 조절, 치료 관련 결정은 반드시 담당 의료진과 상담 후 진행해 주세요.',
            ),
            _buildDisclaimerItem(
              '응급 상황',
              '건강에 이상이 느껴지거나 응급 상황 발생 시 즉시 의료 기관에 연락하세요.',
            ),

            const SizedBox(height: AppSpacing.l),

            // 경고 박스
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      '사용자는 본인의 건강에 대한 최종 책임이 있으며, 앱 사용으로 인한 결과에 대해 개발사는 책임지지 않습니다.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 의료 면책 조항 동의 화면 (첫 실행 시 표시)
class DisclaimerConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const DisclaimerConsentScreen({
    super.key,
    required this.onAccepted,
  });

  @override
  State<DisclaimerConsentScreen> createState() => _DisclaimerConsentScreenState();

  /// 면책 조항 동의 여부 확인
  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('disclaimer_accepted') ?? false;
  }

  /// 면책 조항 동의 저장
  static Future<void> setAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disclaimer_accepted', true);
  }
}

class _DisclaimerConsentScreenState extends State<DisclaimerConsentScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    // 상단바 스타일 설정 (어두운 아이콘)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // 헤더
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('💊', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      '기다림메이트',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'IVF 약물 알림 앱',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 면책 조항 카드
              Expanded(
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.medical_information_outlined,
                              color: AppColors.primaryPurple,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Text(
                              '이용 전 확인사항',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),

                        _buildDisclaimerItem(
                          '앱의 목적',
                          '기다림메이트는 IVF(체외수정) 시술 중 약물 복용 시간을 알려주는 알림 앱입니다.',
                        ),

                        _buildDisclaimerItem(
                          '의료 기기 아님',
                          '이 앱은 의료 기기가 아니며, 의학적 진단, 치료, 예방을 목적으로 하지 않습니다.',
                        ),

                        _buildDisclaimerItem(
                          '참고용 정보',
                          '앱에서 제공하는 모든 정보는 참고용이며, 전문적인 의료 조언을 대체하지 않습니다.',
                        ),

                        _buildDisclaimerItem(
                          '의료진 상담 필수',
                          '모든 약물 복용, 용량 조절, 치료 관련 결정은 반드시 담당 의료진과 상담 후 진행해 주세요.',
                        ),

                        _buildDisclaimerItem(
                          '응급 상황',
                          '건강에 이상이 느껴지거나 응급 상황 발생 시 즉시 의료 기관에 연락하세요.',
                        ),

                        const SizedBox(height: AppSpacing.m),

                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.s),
                              Expanded(
                                child: Text(
                                  '사용자는 본인의 건강에 대한 최종 책임이 있으며, 앱 사용으로 인한 결과에 대해 개발사는 책임지지 않습니다.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.m),

              // 체크박스
              InkWell(
                onTap: () {
                  setState(() {
                    _isChecked = !_isChecked;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _isChecked,
                          onChanged: (value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          '위 내용을 모두 읽었으며, 이해하고 동의합니다.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.m),

              // 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecked
                      ? () async {
                          await DisclaimerConsentScreen.setAccepted();
                          widget.onAccepted();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    disabledBackgroundColor: AppColors.textDisabled,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '시작하기',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
