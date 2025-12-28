import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'constants/app_colors.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';

/// Supabase 초기화 성공 여부
bool _supabaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  try {
    await SupabaseService.initialize();
    _supabaseInitialized = true;
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
    // 초기화 실패해도 앱은 계속 실행 (오프라인 모드)
  }

  // 알림 서비스 초기화 (웹 제외)
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
      await NotificationService.requestPermission();
    } catch (e) {
      debugPrint('알림 서비스 초기화 실패: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: IVFApp(),
    ),
  );
}

class IVFApp extends StatelessWidget {
  const IVFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IVF 약물 알림',
      debugShowCheckedModeBanner: false,
      // 한국어 로컬라이제이션 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      home: _getInitialScreen(),
    );
  }

  /// 초기 화면 결정
  /// - Supabase 초기화 성공 + 로그인 안됨 → 인증 화면
  /// - Supabase 초기화 성공 + 로그인됨 → 메인 화면
  /// - Supabase 초기화 실패 → 메인 화면 (오프라인 모드)
  Widget _getInitialScreen() {
    if (_supabaseInitialized && !SupabaseService.isLoggedIn) {
      return const AuthScreen();
    }
    return const MainScreen();
  }
}
