import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_button.dart';
import '../services/supabase_service.dart';
import 'main_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // OAuth 로그인 후 콜백 처리
    _authSubscription = SupabaseService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedIn && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    });
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
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

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

        if (mounted) {
          // 이메일 인증이 필요한 경우
          if (response.user?.emailConfirmedAt == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('회원가입 완료! 이메일에서 인증 링크를 확인해주세요.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            // 로그인 모드로 전환
            setState(() => _isLogin = true);
          } else {
            // 이메일 인증 없이 바로 로그인 가능
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
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

  Future<void> _signInWithKakao() async {
    setState(() => _isSocialLoading = true);
    try {
      final success = await SupabaseService.signInWithKakao();
      if (!success && mounted) {
        _showErrorSnackBar('카카오 로그인에 실패했습니다');
      }
      // 성공 시 authStateChanges listener에서 화면 전환 처리
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('카카오 로그인 중 오류가 발생했습니다');
      }
    } finally {
      if (mounted) {
        setState(() => _isSocialLoading = false);
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
              const SizedBox(height: AppSpacing.l),

              // 제출 버튼
              AppButton(
                text: _isLogin ? '로그인' : '회원가입',
                onPressed: _isLoading ? null : _submit,
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
    return Column(
      children: [
        // 카카오 로그인 버튼
        _buildSocialButton(
          onPressed: _isSocialLoading ? null : _signInWithKakao,
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF191919),
          text: '카카오로 시작하기',
          iconPath: null, // 아이콘 대신 텍스트 사용
          iconText: '💬',
        ),
        const SizedBox(height: AppSpacing.s),

        // 구글 로그인 버튼
        _buildSocialButton(
          onPressed: _isSocialLoading ? null : _signInWithGoogle,
          backgroundColor: Colors.white,
          textColor: const Color(0xFF191919),
          text: 'Google로 시작하기',
          iconText: 'G',
          iconTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
          hasBorder: true,
        ),
        const SizedBox(height: AppSpacing.s),

        // 애플 로그인 버튼 (iOS/macOS에서만 표시)
        if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
          _buildSocialButton(
            onPressed: _isSocialLoading ? null : _signInWithApple,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            text: 'Apple로 시작하기',
            iconText: '',
          ),
      ],
    );
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
        // 앱 아이콘
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '💉',
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        // 앱 제목
        Text(
          'IVF 약물 알림',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // 서브 타이틀
        Text(
          _isLogin ? '다시 만나서 반가워요!' : '함께 시작해요',
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
}
