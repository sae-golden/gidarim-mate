import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_button.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../services/medication_storage_service.dart';
import '../services/cloud_storage_service.dart';
import 'main_screen.dart';

/// 약관 동의 항목 정의
class ConsentItem {
  final String key;
  final String title;
  final bool isRequired;
  final String url;

  const ConsentItem({
    required this.key,
    required this.title,
    required this.isRequired,
    required this.url,
  });
}

/// 약관 URL 상수
class ConsentUrls {
  static const terms = 'https://continuous-snow-251.notion.site/1-2ea3287faece801dba3eeddc8bec43bf';
  static const privacy = 'https://continuous-snow-251.notion.site/2-2ea3287faece80a8bf3bf9dec2683d42';
  static const disclaimer = 'https://continuous-snow-251.notion.site/3-2ea3287faece80d7bfa3fb41cd761fc2';
  static const marketing = 'https://continuous-snow-251.notion.site/4-2ea3287faece80159f9ef2d699f7e9a8';
  static const analytics = 'https://continuous-snow-251.notion.site/5-2ea3287faece80108bd0ce11db25049c';
}

/// 인증 화면 (로그인/회원가입)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true; // true: 로그인, false: 회원가입
  bool _isLoading = false;
  bool _isSocialLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  StreamSubscription? _authSubscription;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _scrollController = ScrollController();

  // 약관 동의 상태
  final Map<String, bool> _consents = {
    'terms': false,
    'privacy': false,
    'disclaimer': false,
    'marketing': false,
    'analytics': false,
  };

  // 약관 항목별 에러 상태 (미체크 필수항목)
  final Map<String, bool> _consentErrors = {
    'terms': false,
    'privacy': false,
    'disclaimer': false,
    'marketing': false,
    'analytics': false,
  };

  // 약관 항목별 GlobalKey (스크롤 이동용)
  final Map<String, GlobalKey> _consentKeys = {
    'terms': GlobalKey(),
    'privacy': GlobalKey(),
    'disclaimer': GlobalKey(),
    'marketing': GlobalKey(),
    'analytics': GlobalKey(),
  };

  // 약관 항목 정의
  static const List<ConsentItem> _consentItems = [
    ConsentItem(key: 'terms', title: '서비스 이용약관', isRequired: true, url: ConsentUrls.terms),
    ConsentItem(key: 'privacy', title: '개인정보 수집·이용', isRequired: true, url: ConsentUrls.privacy),
    ConsentItem(key: 'disclaimer', title: '의료기기 아님 확인', isRequired: true, url: ConsentUrls.disclaimer),
    ConsentItem(key: 'marketing', title: '마케팅 정보 수신', isRequired: false, url: ConsentUrls.marketing),
    ConsentItem(key: 'analytics', title: '앱 사용 데이터 수집', isRequired: false, url: ConsentUrls.analytics),
  ];

  // 전체 동의 여부
  bool get _isAllAgreed => _consents.values.every((v) => v);

  // 필수 항목 모두 동의 여부
  bool get _isRequiredAgreed {
    for (final item in _consentItems) {
      if (item.isRequired && !(_consents[item.key] ?? false)) {
        return false;
      }
    }
    return true;
  }

  // 전체 동의 토글
  void _toggleAllConsent(bool value) {
    setState(() {
      for (final key in _consents.keys) {
        _consents[key] = value;
        // 동의 시 에러 상태 초기화
        if (value) {
          _consentErrors[key] = false;
        }
      }
    });
  }

  // 개별 동의 토글
  void _toggleConsent(String key, bool value) {
    setState(() {
      _consents[key] = value;
      // 동의 시 에러 상태 초기화
      if (value) {
        _consentErrors[key] = false;
      }
    });
  }

  // 약관 보기
  Future<void> _openConsentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('링크를 열 수 없습니다'),
            backgroundColor: AppColors.success, // 모든 토스트 초록색으로 통일
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('URL 열기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('링크 열기 오류: $e'),
            backgroundColor: AppColors.success, // 모든 토스트 초록색으로 통일
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // OAuth 로그인 후 콜백 처리
    _authSubscription = SupabaseService.authStateChanges.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn && mounted) {
        // 소셜 로그인 성공 시 바로 홈 화면으로 이동 (동의 팝업 제거)
        // 신규 사용자의 경우 약관 동의 일시 저장
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final hasAgreed = await _checkUserConsent(user.id);
          if (!hasAgreed) {
            // 신규 사용자: 소셜 로그인은 약관 동의 후 진행된 것으로 간주
            await _saveSocialUserConsentTimestamps(user.id);
          }
        }

        // 로그인 후 로컬 데이터 마이그레이션
        await _migrateLocalDataToCloud();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    });
  }

  /// 사용자가 이미 약관에 동의했는지 확인 (users 테이블에서 확인)
  Future<bool> _checkUserConsent(String? userId) async {
    if (userId == null) return false;
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('terms_agreed_at')
          .eq('id', userId)
          .maybeSingle();
      // terms_agreed_at이 null이 아니면 동의한 것으로 간주
      return response != null && response['terms_agreed_at'] != null;
    } catch (e) {
      // 테이블이 없거나 에러 시 false 반환 (신규 사용자로 간주)
      debugPrint('약관 동의 확인 실패: $e');
      return false;
    }
  }

  /// 소셜 로그인 사용자의 약관 동의 일시 저장
  Future<void> _saveSocialUserConsentTimestamps(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await Supabase.instance.client
          .from('users')
          .update({
            'terms_agreed_at': now,
            'privacy_agreed_at': now,
            'medical_disclaimer_agreed_at': now,
          })
          .eq('id', userId);
      debugPrint('소셜 로그인 사용자 약관 동의 일시 저장 완료');
    } catch (e) {
      debugPrint('소셜 로그인 사용자 약관 동의 일시 저장 실패: $e');
    }
  }

  /// 이메일 회원가입 시 약관 동의 일시를 users 테이블에 저장
  Future<void> _saveUserConsentTimestamps(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updateData = <String, dynamic>{};

      // 필수 약관 동의 일시 저장
      if (_consents['terms'] == true) {
        updateData['terms_agreed_at'] = now;
      }
      if (_consents['privacy'] == true) {
        updateData['privacy_agreed_at'] = now;
      }
      if (_consents['disclaimer'] == true) {
        updateData['medical_disclaimer_agreed_at'] = now;
      }
      // 선택 약관 동의 일시 저장
      if (_consents['marketing'] == true) {
        updateData['marketing_agreed_at'] = now;
      }
      if (_consents['analytics'] == true) {
        updateData['analytics_agreed_at'] = now;
      }

      if (updateData.isNotEmpty) {
        await Supabase.instance.client
            .from('users')
            .update(updateData)
            .eq('id', userId);
        debugPrint('약관 동의 일시 저장 완료: $updateData');
      }
    } catch (e) {
      debugPrint('약관 동의 일시 저장 실패: $e');
      // 저장 실패해도 회원가입은 계속 진행
    }
  }

  /// 로그인 후 로컬에 저장된 데이터를 클라우드로 마이그레이션
  /// 중복 방지: 이름+시간+시작일 기준으로 체크
  Future<void> _migrateLocalDataToCloud() async {
    try {
      // 로컬에 저장된 약물 데이터 확인
      final localMedications = await MedicationStorageService.getAllMedications();

      if (localMedications.isEmpty) {
        // 로컬 데이터 없으면 클라우드에서 복원 시도
        await SyncService.restoreFromCloud();
        return;
      }

      // 클라우드에 이미 데이터가 있는지 확인
      final cloudMedications = await CloudStorageService.getAllMedications();

      if (cloudMedications.isEmpty) {
        // 클라우드에 데이터 없으면 로컬 데이터를 업로드
        for (final med in localMedications) {
          await CloudStorageService.addMedication(med);
        }
        debugPrint('로컬 데이터 ${localMedications.length}개를 클라우드에 업로드했습니다.');
      } else {
        // 양쪽에 데이터가 있으면 동기화 (중복 체크 포함)
        // 로컬 데이터 중 클라우드에 없는 것만 업로드
        String getMedicationKey(med) {
          final startDateStr = med.startDate.toIso8601String().split('T')[0];
          final normalizedTime = med.time.trim().toLowerCase();
          final normalizedName = med.name.trim().toLowerCase();
          return '${normalizedName}_${normalizedTime}_$startDateStr';
        }

        // 클라우드 약물 키 Set 생성
        final cloudKeys = <String>{};
        final cloudIds = <String>{};
        for (final cloudMed in cloudMedications) {
          cloudKeys.add(getMedicationKey(cloudMed));
          cloudIds.add(cloudMed.id);
        }

        // 로컬 약물 중 클라우드에 없는 것만 업로드
        int uploadedCount = 0;
        for (final localMed in localMedications) {
          final key = getMedicationKey(localMed);
          // ID와 키 둘 다 체크
          if (!cloudIds.contains(localMed.id) && !cloudKeys.contains(key)) {
            await CloudStorageService.addMedication(localMed);
            uploadedCount++;
            debugPrint('☁️ 신규 약물 업로드: ${localMed.name}');
          } else {
            debugPrint('⏭️ 이미 존재 (스킵): ${localMed.name}');
          }
        }
        debugPrint('로컬 → 클라우드 업로드 완료: $uploadedCount개 신규');

        // 클라우드 → 로컬 동기화
        await SyncService.syncAll();
      }
    } catch (e) {
      debugPrint('데이터 마이그레이션 오류: $e');
      // 마이그레이션 실패해도 로그인은 계속 진행
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      // 입력값은 유지하고 에러 메시지만 초기화
      _formKey.currentState?.validate();
      // 회원가입 → 로그인 전환 시 약관 동의 및 에러 상태 초기화
      if (_isLogin) {
        for (final key in _consents.keys) {
          _consents[key] = false;
          _consentErrors[key] = false;
        }
        // 비밀번호 확인 필드 초기화 (로그인에서는 불필요)
        _confirmPasswordController.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // 회원가입 시 필수 약관 동의 체크
    if (!_isLogin && !_isRequiredAgreed) {
      _validateAndShowConsentErrors();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 로그인 후 로컬 데이터 마이그레이션
        await _migrateLocalDataToCloud();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        final response = await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 회원가입 성공 시 약관 동의 일시 저장 (users 테이블)
        if (response.user != null) {
          await _saveUserConsentTimestamps(response.user!.id);
        }

        if (mounted) {
          // 회원가입 완료 후 바로 홈 화면으로 이동 (이메일 인증 모달 제거)
          await _migrateLocalDataToCloud();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('Auth Error: $e'); // 콘솔에 에러 출력
      if (mounted) {
        _showErrorSnackBar(_getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    debugPrint('Error detail: $error');
    if (error.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다';
    } else if (error.contains('User already registered')) {
      return '이미 가입된 이메일입니다';
    } else if (error.contains('Email not confirmed')) {
      return '이메일 인증이 필요합니다. 메일함을 확인해주세요';
    } else if (error.contains('network')) {
      return '네트워크 연결을 확인해주세요';
    } else if (error.contains('rate limit') || error.contains('too many')) {
      return '너무 많은 시도입니다. 잠시 후 다시 시도해주세요';
    } else if (error.contains('email')) {
      return '이메일 관련 오류입니다: $error';
    }
    return '오류: $error';
  }

  /// 필수 약관 미체크 항목에 에러 표시 및 첫 번째 미체크 항목으로 스크롤
  void _validateAndShowConsentErrors() {
    String? firstErrorKey;

    setState(() {
      for (final item in _consentItems) {
        if (item.isRequired && !(_consents[item.key] ?? false)) {
          _consentErrors[item.key] = true;
          firstErrorKey ??= item.key;
        } else {
          _consentErrors[item.key] = false;
        }
      }
    });

    // 첫 번째 에러 항목으로 스크롤
    if (firstErrorKey != null) {
      final key = _consentKeys[firstErrorKey];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.3, // 화면 상단 30% 위치에 표시
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success, // 모든 토스트 초록색으로 통일
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar('이메일을 입력해주세요');
      return;
    }

    try {
      await SupabaseService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('비밀번호 재설정 이메일을 발송했습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('이메일 발송에 실패했습니다');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSocialLoading = true);
    try {
      final success = await SupabaseService.signInWithGoogle();
      if (!success && mounted) {
        _showErrorSnackBar('구글 로그인에 실패했습니다');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('구글 로그인 중 오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isSocialLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isSocialLoading = true);
    try {
      final success = await SupabaseService.signInWithApple();
      if (!success && mounted) {
        _showErrorSnackBar('애플 로그인에 실패했습니다');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('애플 로그인 중 오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isSocialLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // 로고 영역
              _buildHeader(),
              const SizedBox(height: AppSpacing.xl),

              // 폼 영역
              _buildForm(),

              // 약관 동의 섹션 (회원가입 시에만)
              if (!_isLogin) ...[
                const SizedBox(height: AppSpacing.l),
                _buildConsentSection(),
              ],

              const SizedBox(height: AppSpacing.l),

              // 제출 버튼
              AppButton(
                text: _isLogin ? '로그인' : '회원가입',
                onPressed: _isLoading || (!_isLogin && !_isRequiredAgreed) ? null : _submit,
              ),

              if (_isLogin) ...[
                const SizedBox(height: AppSpacing.m),
                // 비밀번호 찾기
                TextButton(
                  onPressed: _resetPassword,
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.l),

              // 소셜 로그인 구분선
              _buildDivider(),
              const SizedBox(height: AppSpacing.l),

              // 소셜 로그인 버튼들
              _buildSocialLoginButtons(),

              const SizedBox(height: AppSpacing.l),

              // 모드 전환 (로그인 ↔ 회원가입)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? '아직 계정이 없으신가요?' : '이미 계정이 있으신가요?',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAuthMode,
                    child: Text(
                      _isLogin ? '회원가입' : '로그인',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.border,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Text(
            '또는',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.border,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    // iOS/macOS에서만 애플 로그인 버튼 표시
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      return _buildSocialButton(
        onPressed: _isSocialLoading ? null : _signInWithApple,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        text: 'Apple로 시작하기',
        iconText: '',
      );
    }
    // 다른 플랫폼에서는 소셜 로그인 버튼 없음
    return const SizedBox.shrink();
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
    required String text,
    String? iconPath,
    String? iconText,
    TextStyle? iconTextStyle,
    bool hasBorder = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasBorder
                ? BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: _isSocialLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconText != null)
                    Text(
                      iconText,
                      style: iconTextStyle ?? const TextStyle(fontSize: 20),
                    ),
                  if (iconText != null) const SizedBox(width: AppSpacing.s),
                  Text(
                    text,
                    style: AppTextStyles.body.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 앱 아이콘 - 새싹 🌱
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFE9D5FF), // 연보라 배경
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🌱',
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        // 앱 제목
        Text(
          '기다림메이트',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // 서브 타이틀 - 희망을 향한 오늘 하루
        Text(
          _isLogin ? '희망을 향한 오늘 하루' : '함께 시작해요',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // 이메일 입력
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: '이메일',
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return '올바른 이메일 형식을 입력해주세요';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
          ),
          const SizedBox(height: AppSpacing.m),

          // 비밀번호 입력
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: '비밀번호',
            hint: '8자 이상 입력해주세요',
            obscureText: _obscurePassword,
            textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요';
              }
              if (value.length < 8) {
                return '비밀번호는 8자 이상이어야 합니다';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              if (_isLogin) {
                _submit();
              } else {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              }
            },
          ),

          // 비밀번호 확인 (회원가입 시에만)
          if (!_isLogin) ...[
            const SizedBox(height: AppSpacing.m),
            _buildTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              label: '비밀번호 확인',
              hint: '비밀번호를 다시 입력해주세요',
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 다시 입력해주세요';
                }
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          style: AppTextStyles.body,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.textSecondary,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryPurple,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.m,
            ),
          ),
        ),
      ],
    );
  }

  /// 약관 동의 섹션
  Widget _buildConsentSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 전체 동의
          InkWell(
            onTap: () => _toggleAllConsent(!_isAllAgreed),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
              child: Row(
                children: [
                  _buildCheckbox(_isAllAgreed, (value) => _toggleAllConsent(value ?? false)),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    '전체 동의',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s),

          // 개별 약관 항목들
          ..._consentItems.map((item) => _buildConsentItem(item)),
        ],
      ),
    );
  }

  /// 개별 약관 항목
  Widget _buildConsentItem(ConsentItem item) {
    final isChecked = _consents[item.key] ?? false;
    final hasError = _consentErrors[item.key] ?? false;

    return Container(
      key: _consentKeys[item.key],
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 약관 항목 컨테이너
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: hasError
                  ? Border.all(color: AppColors.error, width: 1.5)
                  : null,
            ),
            child: Row(
              children: [
                _buildCheckbox(isChecked, (value) => _toggleConsent(item.key, value ?? false)),
                const SizedBox(width: AppSpacing.s),

                // [필수] 또는 [선택] 태그
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasError
                        ? AppColors.error.withValues(alpha: 0.1)
                        : item.isRequired
                            ? AppColors.primaryPurple.withValues(alpha: 0.1)
                            : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.isRequired ? '필수' : '선택',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: hasError
                          ? AppColors.error
                          : item.isRequired
                              ? AppColors.primaryPurple
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // 약관 제목 (탭하면 체크)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleConsent(item.key, !isChecked),
                    child: Text(
                      item.title,
                      style: AppTextStyles.caption.copyWith(
                        color: hasError ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // 약관 보기 버튼 (터치 영역 확대)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openConsentUrl(item.url),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '보기',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.primaryPurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 에러 메시지 (필수 항목 미체크 시)
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                '필수 항목이에요',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 체크박스 위젯
  Widget _buildCheckbox(bool isChecked, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isChecked ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? AppColors.primaryPurple : AppColors.border,
            width: 1.5,
          ),
        ),
        child: isChecked
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}
