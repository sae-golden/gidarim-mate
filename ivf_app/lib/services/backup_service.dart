import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'medication_storage_service.dart';
import 'simple_treatment_service.dart';
import 'additional_record_service.dart';
import 'notification_settings_service.dart';
import 'hospital_service.dart';
import 'blood_test_service.dart';
import '../models/medication.dart' show Medication;
import '../models/simple_treatment_cycle.dart';
import '../models/additional_records.dart';
import '../models/notification_settings.dart';
import '../models/hospital.dart';

/// 백업 데이터 모델
class BackupData {
  final String version;
  final DateTime createdAt;
  final String appName;

  // 약물 관련
  final List<Map<String, dynamic>> medications;
  final List<Map<String, dynamic>> medicationLogs;
  final List<Map<String, dynamic>> injectionSites;

  // 치료 사이클
  final Map<String, dynamic>? currentCycle;
  final List<Map<String, dynamic>> pastCycles;

  // 추가 기록
  final List<Map<String, dynamic>> periodRecords;
  final List<Map<String, dynamic>> ultrasoundRecords;
  final List<Map<String, dynamic>> bloodTestRecords;
  final List<Map<String, dynamic>> pregnancyTestRecords;
  final List<Map<String, dynamic>> conditionRecords;

  // 설정
  final Map<String, dynamic>? notificationSettings;
  final Map<String, dynamic>? hospitalInfo;
  final String? lastInjectionSide;

  BackupData({
    required this.version,
    required this.createdAt,
    required this.appName,
    required this.medications,
    required this.medicationLogs,
    required this.injectionSites,
    this.currentCycle,
    required this.pastCycles,
    required this.periodRecords,
    required this.ultrasoundRecords,
    required this.bloodTestRecords,
    required this.pregnancyTestRecords,
    required this.conditionRecords,
    this.notificationSettings,
    this.hospitalInfo,
    this.lastInjectionSide,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'appName': appName,
    'medications': medications,
    'medicationLogs': medicationLogs,
    'injectionSites': injectionSites,
    'currentCycle': currentCycle,
    'pastCycles': pastCycles,
    'periodRecords': periodRecords,
    'ultrasoundRecords': ultrasoundRecords,
    'bloodTestRecords': bloodTestRecords,
    'pregnancyTestRecords': pregnancyTestRecords,
    'conditionRecords': conditionRecords,
    'notificationSettings': notificationSettings,
    'hospitalInfo': hospitalInfo,
    'lastInjectionSide': lastInjectionSide,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['version'] as String? ?? '1.0.0',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      appName: json['appName'] as String? ?? '기다림메이트',
      medications: (json['medications'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      medicationLogs: (json['medicationLogs'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      injectionSites: (json['injectionSites'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      currentCycle: json['currentCycle'] as Map<String, dynamic>?,
      pastCycles: (json['pastCycles'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      periodRecords: (json['periodRecords'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      ultrasoundRecords: (json['ultrasoundRecords'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      bloodTestRecords: (json['bloodTestRecords'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      pregnancyTestRecords: (json['pregnancyTestRecords'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      conditionRecords: (json['conditionRecords'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
      notificationSettings: json['notificationSettings'] as Map<String, dynamic>?,
      hospitalInfo: json['hospitalInfo'] as Map<String, dynamic>?,
      lastInjectionSide: json['lastInjectionSide'] as String?,
    );
  }
}

/// 백업/복원 서비스
class BackupService {
  static const String _backupVersion = '1.0.0';
  static const String _appName = '기다림메이트';

  // SharedPreferences 키 (직접 접근용)
  static const String _periodRecordsKey = 'period_records';
  static const String _ultrasoundRecordsKey = 'ultrasound_records';
  static const String _bloodTestsKey = 'blood_tests';
  static const String _pregnancyTestRecordsKey = 'pregnancy_test_records';
  static const String _conditionRecordsKey = 'condition_records';
  static const String _currentCycleKey = 'timeline_current_cycle';
  static const String _pastCyclesKey = 'timeline_past_cycles';
  static const String _medicationsKey = 'local_medications';
  static const String _medicationLogsKey = 'local_medication_logs';
  static const String _injectionSitesKey = 'local_injection_sites';

  /// 백업 파일명 생성
  static String generateBackupFileName() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    return 'gidarim_backup_${formatter.format(now)}.json';
  }

  /// 모든 데이터를 JSON으로 내보내기
  static Future<String> exportAllData() async {
    try {
      debugPrint('📦 백업 데이터 수집 시작...');

      final prefs = await SharedPreferences.getInstance();

      // 약물 데이터
      final medications = await MedicationStorageService.getAllMedications();
      final medicationLogs = await _getAllMedicationLogs(prefs);
      final injectionSites = await MedicationStorageService.getInjectionSites();

      // 치료 사이클
      Map<String, dynamic>? currentCycle;
      List<Map<String, dynamic>> pastCycles = [];

      if (await SimpleTreatmentService.hasCycleStarted()) {
        final cycle = await SimpleTreatmentService.getCurrentCycle();
        currentCycle = cycle.toJson();

        final past = await SimpleTreatmentService.getPastCycles();
        pastCycles = past.map((c) => c.toJson()).toList();
      }

      // 추가 기록
      final periodRecords = await AdditionalRecordService.getAllPeriodRecords();
      final ultrasoundRecords = await AdditionalRecordService.getAllUltrasoundRecords();
      final bloodTestRecords = await BloodTestService.getAllBloodTests();
      final pregnancyTestRecords = await AdditionalRecordService.getAllPregnancyTestRecords();
      final conditionRecords = await AdditionalRecordService.getAllConditionRecords();

      // 설정
      final notificationSettings = await NotificationSettingsService.getSettings();
      final hospitalInfo = await HospitalService.loadUserHospitalInfo();
      final lastInjectionSide = await NotificationSettingsService.getLastInjectionSide();

      // 백업 데이터 생성
      final backupData = BackupData(
        version: _backupVersion,
        createdAt: DateTime.now(),
        appName: _appName,
        medications: medications.map((m) => m.toJson()).toList(),
        medicationLogs: medicationLogs,
        injectionSites: injectionSites.map((s) => s.toJson()).toList(),
        currentCycle: currentCycle,
        pastCycles: pastCycles,
        periodRecords: periodRecords.map((r) => r.toJson()).toList(),
        ultrasoundRecords: ultrasoundRecords.map((r) => r.toJson()).toList(),
        bloodTestRecords: bloodTestRecords.map((r) => r.toJson()).toList(),
        pregnancyTestRecords: pregnancyTestRecords.map((r) => r.toJson()).toList(),
        conditionRecords: conditionRecords.map((r) => r.toJson()).toList(),
        notificationSettings: notificationSettings.toJson(),
        hospitalInfo: hospitalInfo?.toJson(),
        lastInjectionSide: lastInjectionSide,
      );

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData.toJson());

      debugPrint('✅ 백업 데이터 생성 완료');
      debugPrint('   - 약물: ${medications.length}개');
      debugPrint('   - 복용 기록: ${medicationLogs.length}개');
      debugPrint('   - 주사 부위: ${injectionSites.length}개');
      debugPrint('   - 생리 기록: ${periodRecords.length}개');
      debugPrint('   - 초음파 기록: ${ultrasoundRecords.length}개');
      debugPrint('   - 피검사 기록: ${bloodTestRecords.length}개');
      debugPrint('   - 임신 테스트: ${pregnancyTestRecords.length}개');
      debugPrint('   - 몸 상태: ${conditionRecords.length}개');

      return jsonString;
    } catch (e, stack) {
      debugPrint('❌ 백업 데이터 생성 실패: $e');
      debugPrint('   스택: $stack');
      rethrow;
    }
  }

  /// JSON에서 모든 데이터 복원
  static Future<void> importAllData(String jsonString) async {
    try {
      debugPrint('📥 백업 데이터 복원 시작...');

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final backupData = BackupData.fromJson(json);

      // 버전 확인
      debugPrint('   - 백업 버전: ${backupData.version}');
      debugPrint('   - 생성일: ${backupData.createdAt}');

      final prefs = await SharedPreferences.getInstance();

      // 1. 기존 데이터 모두 삭제
      await _clearAllData(prefs);

      // 2. 약물 데이터 복원
      if (backupData.medications.isNotEmpty) {
        final medications = backupData.medications
            .map((j) => Medication.fromJson(j))
            .toList();
        for (final med in medications) {
          await MedicationStorageService.addMedication(med, addToSyncQueue: false);
        }
        debugPrint('   ✅ 약물 ${medications.length}개 복원');
      }

      // 복용 기록 복원
      if (backupData.medicationLogs.isNotEmpty) {
        final logs = backupData.medicationLogs
            .map((j) => MedicationLog.fromJson(j))
            .toList();
        await MedicationStorageService.saveMedicationLogs(logs);
        debugPrint('   ✅ 복용 기록 ${logs.length}개 복원');
      }

      // 주사 부위 기록 복원
      if (backupData.injectionSites.isNotEmpty) {
        final sites = backupData.injectionSites
            .map((j) => InjectionSiteRecord.fromJson(j))
            .toList();
        await MedicationStorageService.saveInjectionSites(sites);
        debugPrint('   ✅ 주사 부위 ${sites.length}개 복원');
      }

      // 3. 치료 사이클 복원
      if (backupData.currentCycle != null) {
        final cycle = TreatmentCycle.fromJson(backupData.currentCycle!);
        await SimpleTreatmentService.saveCurrentCycle(cycle);
        debugPrint('   ✅ 현재 사이클 복원');
      }

      if (backupData.pastCycles.isNotEmpty) {
        final cycles = backupData.pastCycles
            .map((j) => TreatmentCycle.fromJson(j))
            .toList();
        await SimpleTreatmentService.savePastCycles(cycles);
        debugPrint('   ✅ 지난 사이클 ${cycles.length}개 복원');
      }

      // 4. 추가 기록 복원
      if (backupData.periodRecords.isNotEmpty) {
        for (final json in backupData.periodRecords) {
          final record = PeriodRecord.fromJson(json);
          await AdditionalRecordService.addPeriodRecord(record);
        }
        debugPrint('   ✅ 생리 기록 ${backupData.periodRecords.length}개 복원');
      }

      if (backupData.ultrasoundRecords.isNotEmpty) {
        for (final json in backupData.ultrasoundRecords) {
          final record = UltrasoundRecord.fromJson(json);
          await AdditionalRecordService.addUltrasoundRecord(record);
        }
        debugPrint('   ✅ 초음파 기록 ${backupData.ultrasoundRecords.length}개 복원');
      }

      if (backupData.bloodTestRecords.isNotEmpty) {
        for (final json in backupData.bloodTestRecords) {
          final record = BloodTest.fromJson(json);
          await BloodTestService.addBloodTest(record);
        }
        debugPrint('   ✅ 피검사 기록 ${backupData.bloodTestRecords.length}개 복원');
      }

      if (backupData.pregnancyTestRecords.isNotEmpty) {
        for (final json in backupData.pregnancyTestRecords) {
          final record = PregnancyTestRecord.fromJson(json);
          await AdditionalRecordService.addPregnancyTestRecord(record);
        }
        debugPrint('   ✅ 임신 테스트 ${backupData.pregnancyTestRecords.length}개 복원');
      }

      if (backupData.conditionRecords.isNotEmpty) {
        for (final json in backupData.conditionRecords) {
          final record = ConditionRecord.fromJson(json);
          await AdditionalRecordService.addConditionRecord(record);
        }
        debugPrint('   ✅ 몸 상태 ${backupData.conditionRecords.length}개 복원');
      }

      // 5. 설정 복원
      if (backupData.notificationSettings != null) {
        final settings = NotificationSettings.fromJson(backupData.notificationSettings!);
        await NotificationSettingsService.saveSettings(settings);
        debugPrint('   ✅ 알림 설정 복원');
      }

      if (backupData.hospitalInfo != null) {
        final info = UserHospitalInfo.fromJson(backupData.hospitalInfo!);
        await HospitalService.saveUserHospitalInfo(info, syncToCloud: false);
        debugPrint('   ✅ 병원 정보 복원');
      }

      if (backupData.lastInjectionSide != null) {
        await NotificationSettingsService.saveLastInjectionSide(backupData.lastInjectionSide!);
        debugPrint('   ✅ 마지막 주사 부위 복원');
      }

      debugPrint('✅ 백업 데이터 복원 완료!');
    } catch (e, stack) {
      debugPrint('❌ 백업 데이터 복원 실패: $e');
      debugPrint('   스택: $stack');
      rethrow;
    }
  }

  /// 백업 파일 유효성 검사
  static Future<BackupValidationResult> validateBackupFile(String jsonString) async {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final backupData = BackupData.fromJson(json);

      // 필수 필드 검사
      if (backupData.appName != _appName) {
        return BackupValidationResult(
          isValid: false,
          errorMessage: '다른 앱의 백업 파일입니다.',
        );
      }

      // 데이터 요약 생성
      final summary = BackupSummary(
        version: backupData.version,
        createdAt: backupData.createdAt,
        medicationCount: backupData.medications.length,
        medicationLogCount: backupData.medicationLogs.length,
        cycleCount: (backupData.currentCycle != null ? 1 : 0) + backupData.pastCycles.length,
        periodRecordCount: backupData.periodRecords.length,
        ultrasoundRecordCount: backupData.ultrasoundRecords.length,
        bloodTestRecordCount: backupData.bloodTestRecords.length,
        pregnancyTestRecordCount: backupData.pregnancyTestRecords.length,
        conditionRecordCount: backupData.conditionRecords.length,
        hasNotificationSettings: backupData.notificationSettings != null,
        hasHospitalInfo: backupData.hospitalInfo != null,
      );

      return BackupValidationResult(
        isValid: true,
        summary: summary,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: '유효하지 않은 백업 파일입니다: $e',
      );
    }
  }

  /// 복용 기록 조회 (내부용)
  static Future<List<Map<String, dynamic>>> _getAllMedicationLogs(SharedPreferences prefs) async {
    final jsonString = prefs.getString(_medicationLogsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((j) => j as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// 모든 데이터 삭제 (복원 전 호출)
  static Future<void> _clearAllData(SharedPreferences prefs) async {
    debugPrint('🗑️ 기존 데이터 삭제 중...');

    // 약물 관련
    await prefs.remove(_medicationsKey);
    await prefs.remove(_medicationLogsKey);
    await prefs.remove(_injectionSitesKey);

    // 치료 사이클
    await prefs.remove(_currentCycleKey);
    await prefs.remove(_pastCyclesKey);

    // 추가 기록
    await prefs.remove(_periodRecordsKey);
    await prefs.remove(_ultrasoundRecordsKey);
    await prefs.remove(_bloodTestsKey);
    await prefs.remove(_pregnancyTestRecordsKey);
    await prefs.remove(_conditionRecordsKey);

    // 설정은 유지 (알림 설정, 병원 정보)
    // 사용자가 원하면 복원 데이터로 덮어씌워짐

    debugPrint('   ✅ 기존 데이터 삭제 완료');
  }
}

/// 백업 파일 유효성 검사 결과
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final BackupSummary? summary;

  BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.summary,
  });
}

/// 백업 데이터 요약
class BackupSummary {
  final String version;
  final DateTime createdAt;
  final int medicationCount;
  final int medicationLogCount;
  final int cycleCount;
  final int periodRecordCount;
  final int ultrasoundRecordCount;
  final int bloodTestRecordCount;
  final int pregnancyTestRecordCount;
  final int conditionRecordCount;
  final bool hasNotificationSettings;
  final bool hasHospitalInfo;

  BackupSummary({
    required this.version,
    required this.createdAt,
    required this.medicationCount,
    required this.medicationLogCount,
    required this.cycleCount,
    required this.periodRecordCount,
    required this.ultrasoundRecordCount,
    required this.bloodTestRecordCount,
    required this.pregnancyTestRecordCount,
    required this.conditionRecordCount,
    required this.hasNotificationSettings,
    required this.hasHospitalInfo,
  });

  /// 총 기록 수
  int get totalRecordCount =>
      medicationCount +
      medicationLogCount +
      cycleCount +
      periodRecordCount +
      ultrasoundRecordCount +
      bloodTestRecordCount +
      pregnancyTestRecordCount +
      conditionRecordCount;
}
