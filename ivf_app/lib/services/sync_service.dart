import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/medication.dart' hide MedicationLog;
import '../models/hospital.dart';
import '../models/onboarding_checklist.dart';
import 'medication_storage_service.dart';
import 'cloud_storage_service.dart';
import 'hospital_service.dart';
import 'onboarding_service.dart';

/// 동기화 상태
enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
}

/// 동기화 결과
class SyncResult {
  final bool success;
  final int syncedItems;
  final int failedItems;
  final String? errorMessage;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.syncedItems = 0,
    this.failedItems = 0,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 동기화 서비스
/// 로컬 데이터와 클라우드(Supabase) 간 동기화 관리
class SyncService {
  static SyncStatus _status = SyncStatus.idle;
  static final _statusController = StreamController<SyncStatus>.broadcast();
  static Timer? _autoSyncTimer;
  static bool _isInitialized = false;

  static const int _maxRetries = 3;
  static const Duration _autoSyncInterval = Duration(minutes: 5);

  /// 현재 동기화 상태
  static SyncStatus get status => _status;

  /// 동기화 상태 스트림
  static Stream<SyncStatus> get statusStream => _statusController.stream;

  /// 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;

    // 네트워크 상태 변경 감지
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);

      if (isOnline && CloudStorageService.isLoggedIn) {
        // 온라인 상태가 되면 동기화 시도
        syncAll();
      } else if (!isOnline) {
        _updateStatus(SyncStatus.offline);
      }
    });

    // 자동 동기화 타이머 시작
    _startAutoSync();
  }

  /// 자동 동기화 시작
  static void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      if (CloudStorageService.isLoggedIn) {
        syncAll();
      }
    });
  }

  /// 자동 동기화 중지
  static void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// 상태 업데이트
  static void _updateStatus(SyncStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// 네트워크 연결 확인
  static Future<bool> _isOnline() async {
    final results = await Connectivity().checkConnectivity();
    return results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);
  }

  // ============================================
  // 전체 동기화
  // ============================================

  /// 전체 동기화 실행
  static Future<SyncResult> syncAll() async {
    if (!CloudStorageService.isLoggedIn) {
      return SyncResult(
        success: false,
        errorMessage: '로그인이 필요합니다',
      );
    }

    if (!await _isOnline()) {
      _updateStatus(SyncStatus.offline);
      return SyncResult(
        success: false,
        errorMessage: '네트워크에 연결되어 있지 않습니다',
      );
    }

    if (_status == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        errorMessage: '이미 동기화 중입니다',
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      int syncedItems = 0;
      int failedItems = 0;

      // 1. 오프라인 큐 처리
      debugPrint('🔄 [Sync] 1. 오프라인 큐 처리 시작...');
      final queueResult = await _processOfflineQueue();
      syncedItems += queueResult.syncedItems;
      failedItems += queueResult.failedItems;
      debugPrint('🔄 [Sync] 1. 완료 - synced: ${queueResult.syncedItems}, failed: ${queueResult.failedItems}');

      // 2. 약물 동기화 (양방향)
      debugPrint('🔄 [Sync] 2. 약물 동기화 시작...');
      final medicationResult = await _syncMedications();
      syncedItems += medicationResult.syncedItems;
      failedItems += medicationResult.failedItems;
      debugPrint('🔄 [Sync] 2. 완료 - synced: ${medicationResult.syncedItems}, failed: ${medicationResult.failedItems}');

      // 3. 복용 기록 동기화
      debugPrint('🔄 [Sync] 3. 복용 기록 동기화 시작...');
      final logsResult = await _syncMedicationLogs();
      syncedItems += logsResult.syncedItems;
      failedItems += logsResult.failedItems;
      debugPrint('🔄 [Sync] 3. 완료 - synced: ${logsResult.syncedItems}, failed: ${logsResult.failedItems}');

      // 4. 주사 부위 기록 동기화
      debugPrint('🔄 [Sync] 4. 주사 부위 기록 동기화 시작...');
      final sitesResult = await _syncInjectionSites();
      syncedItems += sitesResult.syncedItems;
      failedItems += sitesResult.failedItems;
      debugPrint('🔄 [Sync] 4. 완료 - synced: ${sitesResult.syncedItems}, failed: ${sitesResult.failedItems}');

      // 5. 프로필 동기화 (치료 단계, 병원 정보)
      debugPrint('🔄 [Sync] 5. 프로필 동기화 시작...');
      final profileResult = await _syncProfile();
      syncedItems += profileResult.syncedItems;
      // 프로필 동기화 실패는 전체 실패로 처리하지 않음
      debugPrint('🔄 [Sync] 5. 완료 - synced: ${profileResult.syncedItems}, failed: ${profileResult.failedItems}');

      // 마지막 동기화 시간 저장
      await MedicationStorageService.setLastSyncTime(DateTime.now());

      final success = failedItems == 0;
      debugPrint('🔄 [Sync] 최종 결과 - success: $success, total synced: $syncedItems, total failed: $failedItems');
      _updateStatus(success ? SyncStatus.success : SyncStatus.failed);

      return SyncResult(
        success: success,
        syncedItems: syncedItems,
        failedItems: failedItems,
        errorMessage: failedItems > 0 ? 'Supabase 테이블 확인 필요' : null,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [Sync] syncAll 오류: $e');
      debugPrint('❌ [Sync] stackTrace: $stackTrace');
      _updateStatus(SyncStatus.failed);
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ============================================
  // 오프라인 큐 처리
  // ============================================

  /// 오프라인 큐 처리
  static Future<SyncResult> _processOfflineQueue() async {
    final queue = await MedicationStorageService.getSyncQueue();
    int syncedItems = 0;
    int failedItems = 0;

    debugPrint('  📋 오프라인 큐 항목 수: ${queue.length}');

    for (final item in queue) {
      debugPrint('  📋 처리 중: table=${item.table}, action=${item.action}, retryCount=${item.retryCount}');

      if (item.retryCount >= _maxRetries) {
        // 최대 재시도 초과 - 큐에서 제거
        debugPrint('  ⚠️ 최대 재시도 초과, 큐에서 제거: ${item.id}');
        await MedicationStorageService.removeSyncQueueItem(item.id);
        failedItems++;
        continue;
      }

      try {
        bool success = false;

        switch (item.table) {
          case 'user_medications':
            success = await _processMedicationQueueItem(item);
            break;
          case 'medication_logs':
            success = await _processMedicationLogQueueItem(item);
            break;
          case 'injection_sites':
            success = await _processInjectionSiteQueueItem(item);
            break;
          default:
            debugPrint('  ⚠️ 알 수 없는 테이블: ${item.table}');
            // 알 수 없는 테이블은 제거
            await MedicationStorageService.removeSyncQueueItem(item.id);
            continue;
        }

        if (success) {
          await MedicationStorageService.removeSyncQueueItem(item.id);
          syncedItems++;
          debugPrint('  ✅ 큐 항목 처리 성공: ${item.id}');
        } else {
          await MedicationStorageService.incrementSyncQueueItemRetry(item.id);
          failedItems++;
          debugPrint('  ❌ 큐 항목 처리 실패 (재시도 예정): ${item.id}');
        }
      } catch (e) {
        debugPrint('❌ 큐 항목 처리 오류: $e');
        await MedicationStorageService.incrementSyncQueueItemRetry(item.id);
        failedItems++;
      }
    }

    return SyncResult(
      success: failedItems == 0,
      syncedItems: syncedItems,
      failedItems: failedItems,
    );
  }

  /// 약물 큐 항목 처리
  static Future<bool> _processMedicationQueueItem(SyncQueueItem item) async {
    switch (item.action) {
      case 'create':
        final medication = Medication.fromJson(item.data);
        final cloudId = await CloudStorageService.addMedication(medication);
        return cloudId != null;

      case 'update':
        final medication = Medication.fromJson(item.data);
        return await CloudStorageService.updateMedication(medication);

      case 'delete':
        final id = item.data['id'] as String;
        return await CloudStorageService.deleteMedication(id);

      default:
        return false;
    }
  }

  /// 복용 기록 큐 항목 처리
  static Future<bool> _processMedicationLogQueueItem(SyncQueueItem item) async {
    if (item.action != 'upsert') return false;

    return await CloudStorageService.saveMedicationLog(
      medicationId: item.data['medicationId'] as String,
      date: DateTime.parse(item.data['date'] as String),
      scheduledCount: item.data['scheduledCount'] as int,
      completedCount: item.data['completedCount'] as int,
      firstCompletedAt: item.data['firstCompletedAt'] as String?,
      lastCompletedAt: item.data['lastCompletedAt'] as String?,
    );
  }

  /// 주사 부위 기록 큐 항목 처리
  static Future<bool> _processInjectionSiteQueueItem(SyncQueueItem item) async {
    if (item.action != 'create') return false;

    return await CloudStorageService.saveInjectionSite(
      medicationId: item.data['medicationId'] as String?,
      dateTime: DateTime.parse(item.data['dateTime'] as String),
      site: item.data['site'] as String,
      location: item.data['location'] as String?,
      notes: item.data['notes'] as String?,
    );
  }

  // ============================================
  // 약물 동기화
  // ============================================

  /// 약물 동기화 (클라우드 → 로컬 단방향)
  /// 로컬 → 클라우드는 저장 시점에 직접 업로드하므로 여기서는 다운로드만 수행
  /// 중복 방지를 위해 ID + 이름+시간+시작일로 이중 체크
  static Future<SyncResult> _syncMedications() async {
    int syncedItems = 0;
    int failedItems = 0;

    try {
      // 클라우드에서 약물 조회 (테이블 없으면 빈 배열)
      debugPrint('  📦 클라우드에서 약물 조회 중...');
      List<Medication> cloudMedications = [];
      try {
        cloudMedications = await CloudStorageService.getAllMedications();
      } catch (e) {
        debugPrint('  ⚠️ user_medications 테이블 조회 실패: $e');
      }
      debugPrint('  📦 클라우드 약물: ${cloudMedications.length}개');

      final localMedications = await MedicationStorageService.getAllMedications();
      debugPrint('  📦 로컬 약물: ${localMedications.length}개');

      // 약물 고유 키 생성 함수 (이름+시간+시작일)
      // 시간 문자열을 정규화하여 비교 (공백, 대소문자 무시)
      String normalizeTime(String time) {
        return time.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      }

      String getMedicationKey(Medication med) {
        final startDateStr = med.startDate.toIso8601String().split('T')[0];
        final normalizedTime = normalizeTime(med.time);
        final normalizedName = med.name.trim().toLowerCase();
        return '${normalizedName}_${normalizedTime}_$startDateStr';
      }

      // 로컬 약물 ID Set과 키 맵 생성 (이중 체크용)
      final localMedicationIds = <String>{};
      final localMedicationKeys = <String>{};
      for (final localMed in localMedications) {
        localMedicationIds.add(localMed.id);
        localMedicationKeys.add(getMedicationKey(localMed));
        debugPrint('  📋 로컬 약물: ${localMed.name} | ID: ${localMed.id} | 키: ${getMedicationKey(localMed)}');
      }

      debugPrint('  📦 로컬 약물 ID: ${localMedicationIds.length}개, 키: ${localMedicationKeys.length}개');

      // 클라우드 -> 로컬 동기화 (클라우드에만 있는 약물)
      for (final cloudMed in cloudMedications) {
        final key = getMedicationKey(cloudMed);

        debugPrint('  🔎 클라우드 약물 체크: ${cloudMed.name} | ID: ${cloudMed.id} | 키: $key');

        // ID로 체크 + 키(이름+시간+시작일)로 체크 - 둘 중 하나라도 있으면 중복
        if (localMedicationIds.contains(cloudMed.id)) {
          debugPrint('  ⏭️ 이미 있음 (ID 일치): ${cloudMed.name} (${cloudMed.id})');
          continue;
        }

        if (localMedicationKeys.contains(key)) {
          debugPrint('  ⏭️ 이미 있음 (키 일치): ${cloudMed.name} ($key)');
          continue;
        }

        // 로컬에 없음 - 추가
        debugPrint('  📥 클라우드에서 로컬로 추가: ${cloudMed.name} (${cloudMed.id})');
        await MedicationStorageService.addMedication(cloudMed, addToSyncQueue: false);

        // 추가 후 Set에도 반영 (같은 동기화 세션 내 중복 방지)
        localMedicationIds.add(cloudMed.id);
        localMedicationKeys.add(key);
        syncedItems++;
      }

      debugPrint('  ✅ 약물 동기화 완료 (다운로드 $syncedItems개)');
    } catch (e, stackTrace) {
      debugPrint('❌ 약물 동기화 오류: $e');
      debugPrint('  stackTrace: $stackTrace');
      // 전체 동기화가 실패해도 failedItems 증가하지 않음
    }

    return SyncResult(
      success: failedItems == 0,
      syncedItems: syncedItems,
      failedItems: failedItems,
    );
  }

  // ============================================
  // 복용 기록 동기화
  // ============================================

  /// 복용 기록 동기화
  static Future<SyncResult> _syncMedicationLogs() async {
    int syncedItems = 0;
    int failedItems = 0;

    try {
      final lastSync = await MedicationStorageService.getLastSyncTime();
      final startDate = lastSync ?? DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();

      // 클라우드에서 기록 조회 (테이블 없으면 빈 배열 반환)
      List<Map<String, dynamic>> cloudLogs = [];
      try {
        cloudLogs = await CloudStorageService.getMedicationLogsByRange(
          startDate: startDate,
          endDate: endDate,
        );
      } catch (e) {
        debugPrint('  ⚠️ medication_logs 테이블 조회 실패 (테이블 없을 수 있음): $e');
        // 테이블 없으면 그냥 넘어감
      }

      // 로컬에서 기록 조회
      final localLogs = await MedicationStorageService.getMedicationLogsByRange(
        startDate: startDate,
        endDate: endDate,
      );

      // 병합 로직 (completedCount가 더 높은 값 우선)
      final mergedLogs = <String, MedicationLog>{};

      // 로컬 기록 먼저 추가
      for (final log in localLogs) {
        mergedLogs[log.id] = log;
      }

      // 클라우드 기록 병합
      for (final cloudLog in cloudLogs) {
        // local_medication_id 우선 사용, 없으면 medication_id 사용
        final medicationId = (cloudLog['local_medication_id'] as String?) ??
                             (cloudLog['medication_id']?.toString() ?? '');
        final logId = '${medicationId}_${cloudLog['date']}';
        final cloudCompleted = cloudLog['completed_count'] as int? ?? 0;
        final cloudUpdatedAt = DateTime.tryParse(cloudLog['updated_at']?.toString() ?? '');

        if (mergedLogs.containsKey(logId)) {
          final localLog = mergedLogs[logId]!;

          // 병합: completedCount가 더 높은 값 사용
          if (cloudCompleted > localLog.completedCount) {
            mergedLogs[logId] = MedicationLog(
              id: logId,
              medicationId: medicationId,
              date: DateTime.parse(cloudLog['date'] as String),
              scheduledCount: cloudLog['scheduled_count'] as int? ?? 1,
              completedCount: cloudCompleted,
              firstCompletedAt: cloudLog['first_completed_at'] as String?,
              lastCompletedAt: cloudLog['last_completed_at'] as String?,
              notes: cloudLog['notes'] as String?,
              updatedAt: cloudUpdatedAt,
            );
            syncedItems++;
          }
        } else {
          // 로컬에 없는 기록 추가
          mergedLogs[logId] = MedicationLog(
            id: logId,
            medicationId: medicationId,
            date: DateTime.parse(cloudLog['date'] as String),
            scheduledCount: cloudLog['scheduled_count'] as int? ?? 1,
            completedCount: cloudCompleted,
            firstCompletedAt: cloudLog['first_completed_at'] as String?,
            lastCompletedAt: cloudLog['last_completed_at'] as String?,
            notes: cloudLog['notes'] as String?,
            updatedAt: cloudUpdatedAt,
          );
          syncedItems++;
        }
      }

      // 로컬에 병합된 기록 저장
      await MedicationStorageService.saveMedicationLogs(mergedLogs.values.toList());
    } catch (e) {
      debugPrint('⚠️ 복용 기록 동기화 오류 (계속 진행): $e');
      // 실패해도 failedItems 증가 안함
    }

    return SyncResult(
      success: failedItems == 0,
      syncedItems: syncedItems,
      failedItems: failedItems,
    );
  }

  // ============================================
  // 주사 부위 기록 동기화
  // ============================================

  /// 주사 부위 기록 동기화
  static Future<SyncResult> _syncInjectionSites() async {
    int syncedItems = 0;
    int failedItems = 0;

    try {
      // 클라우드에서 최근 기록 조회 (테이블 없으면 빈 배열)
      List<Map<String, dynamic>> cloudSites = [];
      try {
        cloudSites = await CloudStorageService.getRecentInjectionSites(limit: 30);
      } catch (e) {
        debugPrint('  ⚠️ injection_sites 테이블 조회 실패 (테이블 없을 수 있음): $e');
        // 테이블 없으면 그냥 넘어감
      }

      // 로컬 기록 조회
      final localSites = await MedicationStorageService.getInjectionSites();

      // 클라우드 기록을 로컬 형식으로 변환하여 병합
      final mergedSites = <String, InjectionSiteRecord>{};

      // 로컬 기록 먼저 추가
      for (final site in localSites) {
        mergedSites[site.id] = site;
      }

      // 클라우드 기록 병합
      for (final cloudSite in cloudSites) {
        final id = cloudSite['id'] as String;
        if (!mergedSites.containsKey(id)) {
          final dateStr = cloudSite['date'] as String;
          final timeStr = cloudSite['time'] as String;
          final dateTime = DateTime.parse('${dateStr}T$timeStr:00');
          // local_medication_id 우선 사용
          final medicationId = (cloudSite['local_medication_id'] as String?) ??
                               (cloudSite['medication_id']?.toString());

          mergedSites[id] = InjectionSiteRecord(
            id: id,
            medicationId: medicationId,
            dateTime: dateTime,
            site: cloudSite['site'] as String,
            location: cloudSite['location'] as String?,
            notes: cloudSite['notes'] as String?,
          );
          syncedItems++;
        }
      }

      // 최신순 정렬 및 30개 제한
      final sortedSites = mergedSites.values.toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final limitedSites = sortedSites.take(30).toList();

      // 로컬에 저장
      await MedicationStorageService.saveInjectionSites(limitedSites);
    } catch (e) {
      debugPrint('⚠️ 주사 부위 기록 동기화 오류 (계속 진행): $e');
      // 실패해도 failedItems 증가 안함
    }

    return SyncResult(
      success: failedItems == 0,
      syncedItems: syncedItems,
      failedItems: failedItems,
    );
  }

  // ============================================
  // 프로필 동기화 (치료 단계, 병원 정보)
  // ============================================

  /// 프로필 동기화 (양방향)
  static Future<SyncResult> _syncProfile() async {
    int syncedItems = 0;
    int failedItems = 0;

    try {
      // 1. 치료 단계 동기화
      final localStage = await OnboardingService.getTreatmentStage();
      final cloudStage = await CloudStorageService.getTreatmentStage();

      if (localStage != null && cloudStage == null) {
        // 로컬에만 있으면 클라우드에 업로드
        await CloudStorageService.saveTreatmentStage(localStage.index);
        syncedItems++;
        debugPrint('  ☁️ 치료 단계 업로드: ${localStage.index}');
      } else if (localStage == null && cloudStage != null) {
        // 클라우드에만 있으면 로컬에 다운로드
        await OnboardingService.saveTreatmentStage(
          OnboardingTreatmentStage.values[cloudStage],
        );
        syncedItems++;
        debugPrint('  📥 치료 단계 다운로드: $cloudStage');
      }

      // 2. 병원 정보 동기화
      final localHospitalInfo = await HospitalService.loadUserHospitalInfo();
      final cloudHospitalInfo = await CloudStorageService.getHospitalInfo();

      if (localHospitalInfo?.hospital != null && cloudHospitalInfo == null) {
        // 로컬에만 있으면 클라우드에 업로드
        final hospitalData = _convertHospitalInfoToCloud(localHospitalInfo!);
        await CloudStorageService.saveHospitalInfo(hospitalData);
        syncedItems++;
        debugPrint('  ☁️ 병원 정보 업로드: ${localHospitalInfo.hospital?.name}');
      } else if ((localHospitalInfo?.hospital == null) && cloudHospitalInfo != null) {
        // 클라우드에만 있으면 로컬에 다운로드
        final hospitalInfo = _convertCloudToHospitalInfo(cloudHospitalInfo);
        await HospitalService.saveUserHospitalInfo(hospitalInfo);
        syncedItems++;
        debugPrint('  📥 병원 정보 다운로드: ${hospitalInfo.hospital?.name}');
      }

      debugPrint('  ✅ 프로필 동기화 완료');
    } catch (e) {
      debugPrint('⚠️ 프로필 동기화 오류 (계속 진행): $e');
      // 실패해도 failedItems 증가 안함 (중요 데이터 아님)
    }

    return SyncResult(
      success: failedItems == 0,
      syncedItems: syncedItems,
      failedItems: failedItems,
    );
  }

  /// 로컬 병원 정보를 클라우드 형식으로 변환
  static Map<String, dynamic> _convertHospitalInfoToCloud(UserHospitalInfo info) {
    return {
      'name': info.hospital?.name,
      'address': info.hospital?.address,
      'phone': info.hospital?.phone,
      'sidoName': info.hospital?.sidoName,
      'sgguName': info.hospital?.sgguName,
      'ykiho': info.hospital?.ykiho,
      'doctorName': info.doctorName,
      'memo': info.memo,
    };
  }

  /// 클라우드 병원 정보를 로컬 형식으로 변환
  static UserHospitalInfo _convertCloudToHospitalInfo(Map<String, dynamic> cloudData) {
    Hospital? hospital;
    if (cloudData['name'] != null) {
      hospital = Hospital(
        name: cloudData['name'] as String,
        address: cloudData['address'] as String? ?? '',
        phone: cloudData['phone'] as String?,
        sidoName: cloudData['sidoName'] as String?,
        sgguName: cloudData['sgguName'] as String?,
        ykiho: cloudData['ykiho'] as String?,
      );
    }

    return UserHospitalInfo(
      hospital: hospital,
      doctorName: cloudData['doctorName'] as String?,
      memo: cloudData['memo'] as String?,
    );
  }

  // ============================================
  // 수동 동기화 (사용자 요청)
  // ============================================

  /// 강제 전체 동기화
  static Future<SyncResult> forceSyncAll() async {
    // 큐 초기화 후 전체 동기화
    await MedicationStorageService.clearSyncQueue();
    return await syncAll();
  }

  /// 클라우드에서 전체 데이터 복원
  static Future<SyncResult> restoreFromCloud() async {
    if (!CloudStorageService.isLoggedIn) {
      return SyncResult(
        success: false,
        errorMessage: '로그인이 필요합니다',
      );
    }

    if (!await _isOnline()) {
      return SyncResult(
        success: false,
        errorMessage: '네트워크에 연결되어 있지 않습니다',
      );
    }

    _updateStatus(SyncStatus.syncing);

    try {
      int syncedItems = 0;

      // 1. 약물 복원 (중복 체크 포함)
      final cloudMedications = await CloudStorageService.getAllMedications();
      final localMedications = await MedicationStorageService.getAllMedications();

      // 로컬 약물 ID Set과 키 Set 생성
      String normalizeTime(String time) {
        return time.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      }

      String getMedicationKey(Medication med) {
        final startDateStr = med.startDate.toIso8601String().split('T')[0];
        final normalizedTime = normalizeTime(med.time);
        final normalizedName = med.name.trim().toLowerCase();
        return '${normalizedName}_${normalizedTime}_$startDateStr';
      }

      final localMedicationIds = <String>{};
      final localMedicationKeys = <String>{};
      for (final localMed in localMedications) {
        localMedicationIds.add(localMed.id);
        localMedicationKeys.add(getMedicationKey(localMed));
      }

      for (final med in cloudMedications) {
        final key = getMedicationKey(med);

        // 이미 있으면 건너뜀
        if (localMedicationIds.contains(med.id) || localMedicationKeys.contains(key)) {
          debugPrint('  ⏭️ 복원 건너뜀 (중복): ${med.name}');
          continue;
        }

        await MedicationStorageService.addMedication(med, addToSyncQueue: false);
        localMedicationIds.add(med.id);
        localMedicationKeys.add(key);
        syncedItems++;
      }

      // 2. 복용 기록 복원 (최근 30일)
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final cloudLogs = await CloudStorageService.getMedicationLogsByRange(
        startDate: startDate,
        endDate: now,
      );

      final localLogs = <MedicationLog>[];
      for (final log in cloudLogs) {
        // local_medication_id 우선 사용
        final medicationId = (log['local_medication_id'] as String?) ??
                             (log['medication_id']?.toString() ?? '');
        localLogs.add(MedicationLog(
          id: '${medicationId}_${log['date']}',
          medicationId: medicationId,
          date: DateTime.parse(log['date'] as String),
          scheduledCount: log['scheduled_count'] as int? ?? 1,
          completedCount: log['completed_count'] as int? ?? 0,
          firstCompletedAt: log['first_completed_at'] as String?,
          lastCompletedAt: log['last_completed_at'] as String?,
          notes: log['notes'] as String?,
        ));
        syncedItems++;
      }
      await MedicationStorageService.saveMedicationLogs(localLogs);

      // 3. 주사 부위 기록 복원
      final cloudSites = await CloudStorageService.getRecentInjectionSites(limit: 30);
      final localSites = <InjectionSiteRecord>[];
      for (final site in cloudSites) {
        final dateStr = site['date'] as String;
        final timeStr = site['time'] as String;
        final dateTime = DateTime.parse('${dateStr}T$timeStr:00');
        // local_medication_id 우선 사용
        final medicationId = (site['local_medication_id'] as String?) ??
                             (site['medication_id']?.toString());

        localSites.add(InjectionSiteRecord(
          id: site['id'] as String,
          medicationId: medicationId,
          dateTime: dateTime,
          site: site['site'] as String,
          location: site['location'] as String?,
          notes: site['notes'] as String?,
        ));
        syncedItems++;
      }
      await MedicationStorageService.saveInjectionSites(localSites);

      // 동기화 시간 저장
      await MedicationStorageService.setLastSyncTime(DateTime.now());

      _updateStatus(SyncStatus.success);

      return SyncResult(
        success: true,
        syncedItems: syncedItems,
      );
    } catch (e) {
      debugPrint('데이터 복원 오류: $e');
      _updateStatus(SyncStatus.failed);
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  // ============================================
  // 상태 조회
  // ============================================

  /// 동기화 대기 중인 항목 수
  static Future<int> getPendingSyncCount() async {
    return await MedicationStorageService.getPendingSyncCount();
  }

  /// 마지막 동기화 시간
  static Future<DateTime?> getLastSyncTime() async {
    return await MedicationStorageService.getLastSyncTime();
  }

  /// 로그인 상태
  static bool get isLoggedIn => CloudStorageService.isLoggedIn;

  /// 리소스 정리
  static void dispose() {
    stopAutoSync();
    if (!_statusController.isClosed) {
      _statusController.close();
    }
    _isInitialized = false;
  }
}
