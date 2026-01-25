import 'package:flutter/material.dart';

/// IVF 앱 디자인 시스템 - 색상 팔레트
/// 토스 스타일 + 파스텔 퍼플 단일 컬러
class AppColors {
  // Primary Colors (주색상)
  static const Color primaryPurple = Color(0xFFD8B3FF); // 파스텔 퍼플
  static const Color primaryPurpleDark = Color(0xFFB88FE8); // 진한 퍼플
  static const Color primaryPurpleLight = Color(0xFFF0E5FF); // 연한 퍼플
  
  // Neutral Colors (중립색상)
  static const Color background = Color(0xFFFAFAFA); // 앱 전체 배경
  static const Color cardBackground = Color(0xFFFFFFFF); // 카드, 모달 배경
  static const Color border = Color(0xFFE8E8E8); // 구분선, 테두리
  static const Color textPrimary = Color(0xFF333333); // 주요 텍스트
  static const Color textSecondary = Color(0xFF999999); // 보조 텍스트
  static const Color textDisabled = Color(0xFFCCCCCC); // 비활성 텍스트
  
  // Status Colors (상태색상) - 파스텔 톤 통일
  static const Color success = Color(0xFFA78BFA); // 완료, 성공 (선명한 보라)
  static const Color warning = Color(0xFFFFD9B3); // 주의, 알림
  static const Color warningLight = Color(0xFFFFF4E5); // 주의 배경
  static const Color error = Color(0xFFFF8A8A); // 오류, 미완료 (진한 핑크)
  static const Color info = Color(0xFFB3D9FF); // 정보
  
  // Gradient (그라데이션)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
