import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase 서비스 - 앱 전체에서 사용하는 Supabase 클라이언트
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Supabase 초기화
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Supabase 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// 현재 로그인한 사용자
  static User? get currentUser => client.auth.currentUser;

  /// 로그인 여부 확인
  static bool get isLoggedIn => currentUser != null;

  /// 이메일/비밀번호 회원가입
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// 이메일/비밀번호 로그인
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 카카오 로그인 (OAuth)
  /// Supabase Dashboard에서 Kakao Provider 설정 필요:
  /// 1. Authentication > Providers > Kakao 활성화
  /// 2. Kakao Developers에서 앱 생성 후 REST API Key 입력
  /// 3. Redirect URL 설정: https://<project-ref>.supabase.co/auth/v1/callback
  static Future<bool> signInWithKakao() async {
    try {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/auth/callback'
          : 'io.supabase.ivfapp://login-callback';

      final result = await client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      return result;
    } catch (e) {
      debugPrint('카카오 로그인 오류: $e');
      return false;
    }
  }

  /// 구글 로그인 (OAuth)
  static Future<bool> signInWithGoogle() async {
    try {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/auth/callback'
          : 'io.supabase.ivfapp://login-callback';

      final result = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      return result;
    } catch (e) {
      debugPrint('구글 로그인 오류: $e');
      return false;
    }
  }

  /// 애플 로그인 (OAuth)
  static Future<bool> signInWithApple() async {
    try {
      final redirectUrl = kIsWeb
          ? '${Uri.base.origin}/auth/callback'
          : 'io.supabase.ivfapp://login-callback';

      final result = await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: redirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      return result;
    } catch (e) {
      debugPrint('애플 로그인 오류: $e');
      return false;
    }
  }

  /// 로그아웃
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// 비밀번호 재설정 이메일 발송
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// 인증 상태 변경 스트림
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
