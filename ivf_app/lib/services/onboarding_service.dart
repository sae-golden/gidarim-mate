import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_checklist.dart';
import 'hospital_service.dart';
import 'notification_service.dart';

/// 온보딩 체크리스트 서비스
class OnboardingService {
  static const String _treatmentStageKey = 'treatment_stage';
  static const String _hasMedicationKey = 'has_medication';

  /// 체크리스트 상태 조회
  static Future<OnboardingChecklist> getChecklist() async {
    final prefs = await SharedPreferences.getInstance();

    // 병원 등록 여부
    final hospitalInfo = await HospitalService.loadUserHospitalInfo();
    final isHospitalRegistered = hospitalInfo?.hospital != null;

    // 알림 활성화 여부
    final isNotificationEnabled =
        await NotificationService.isNotificationEnabled();

    // 약 등록 여부 (SharedPreferences에서 확인)
    final hasMedication = prefs.getBool(_hasMedicationKey) ?? false;

    // 치료 단계 설정 여부
    final treatmentStageIndex = prefs.getInt(_treatmentStageKey);
    final hasTreatmentStage = treatmentStageIndex != null;

    return OnboardingChecklist(
      isHospitalRegistered: isHospitalRegistered,
      isNotificationEnabled: isNotificationEnabled,
      hasMedication: hasMedication,
      hasTreatmentStage: hasTreatmentStage,
    );
  }

  /// 치료 단계 저장
  static Future<void> saveTreatmentStage(OnboardingTreatmentStage stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_treatmentStageKey, stage.index);
  }

  /// 치료 단계 조회
  static Future<OnboardingTreatmentStage?> getTreatmentStage() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_treatmentStageKey);
    if (index == null) return null;
    return OnboardingTreatmentStage.values[index];
  }

  /// 약 등록 상태 저장
  static Future<void> setHasMedication(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasMedicationKey, value);
  }

  /// 약 등록 여부 조회
  static Future<bool> getHasMedication() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasMedicationKey) ?? false;
  }
}
