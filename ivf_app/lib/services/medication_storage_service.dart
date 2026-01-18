import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medication.dart';

/// 오프라인 동기화 큐 항목
class SyncQueueItem {
  final String id;
  final String action; // 'create', 'update', 'delete'
  final String table;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.table,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({int? retryCount}) {
    return SyncQueueItem(
      id: id,
      action: action,
      table: table,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'table': table,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      action: json['action'] as String,
      table: json['table'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}

/// 복용 기록 (일별 요약)
class MedicationLog {
  final String id;
  final String medicationId;
  final DateTime date;
  final int scheduledCount;
  final int completedCount;
  final String? firstCompletedAt;
  final String? lastCompletedAt;
  final String? notes;
  final DateTime updatedAt;

  MedicationLog({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.scheduledCount,
    required this.completedCount,
    this.firstCompletedAt,
    this.lastCompletedAt,
    this.notes,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  double get completionRate =>
      scheduledCount > 0 ? (completedCount / scheduledCount) * 100 : 0;

  MedicationLog copyWith({
    int? completedCount,
    String? firstCompletedAt,
    String? lastCompletedAt,
    String? notes,
  }) {
    return MedicationLog(
      id: id,
      medicationId: medicationId,
      date: date,
      scheduledCount: scheduledCount,
      completedCount: completedCount ?? this.completedCount,
      firstCompletedAt: firstCompletedAt ?? this.firstCompletedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      notes: notes ?? this.notes,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'date': date.toIso8601String().split('T')[0],
        'scheduledCount': scheduledCount,
        'completedCount': completedCount,
        'firstCompletedAt': firstCompletedAt,
        'lastCompletedAt': lastCompletedAt,
        'notes': notes,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      date: DateTime.parse(json['date'] as String),
      scheduledCount: json['scheduledCount'] as int,
      completedCount: json['completedCount'] as int,
      firstCompletedAt: json['firstCompletedAt'] as String?,
      lastCompletedAt: json['lastCompletedAt'] as String?,
      notes: json['notes'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// 주사 부위 기록
class InjectionSiteRecord {
  final String id;
  final String? medicationId;
  final DateTime dateTime;
  final String site; // 'left' or 'right'
  final String? location; // 복부, 허벅지 등
  final String? notes;

  InjectionSiteRecord({
    required this.id,
    this.medicationId,
    required this.dateTime,
    required this.site,
    this.location,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'dateTime': dateTime.toIso8601String(),
        'site': site,
        'location': location,
        'notes': notes,
      };

  factory InjectionSiteRecord.fromJson(Map<String, dynamic> json) {
    return InjectionSiteRecord(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      site: json['site'] as String,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// 약물 로컬 저장 서비스
/// SharedPreferences를 사용한 로컬 저장 + 오프라인 큐 지원
class MedicationStorageService {
  static const String _medicationsKey = 'local_medications';
  static const String _medicationLogsKey = 'local_medication_logs';
  static const String _injectionSitesKey = 'local_injection_sites';
  static const String _syncQueueKey = 'offline_sync_queue';
  static const String _lastSyncKey = 'last_sync_timestamp';

  static const int _maxInjectionSites = 30; // 최대 보관 개수

  // ============================================
  // 데이터 변경 이벤트 스트림 (화면 갱신용)
  // ============================================

  /// 복용 완료/취소 이벤트 스트림
  static final _medicationCompletedController = StreamController<String>.broadcast();

  /// 복용 완료/취소 이벤트 스트림 (medicationId 전달)
  static Stream<String> get onMedicationCompleted => _medicationCompletedController.stream;

  /// 약물 목록 변경 이벤트 스트림
  static final _medicationsChangedController = StreamController<void>.broadcast();

  /// 약물 목록 변경 이벤트 스트림
  static Stream<void> get onMedicationsChanged => _medicationsChangedController.stream;

  /// 이벤트 발행 (내부용)
  static void _notifyMedicationCompleted(String medicationId) {
    if (!_medicationCompletedController.isClosed) {
      _medicationCompletedController.add(medicationId);
      debugPrint('📢 복용 완료 이벤트 발행: $medicationId');
    }
  }

  static void _notifyMedicationsChanged() {
    if (!_medicationsChangedController.isClosed) {
      _medicationsChangedController.add(null);
      debugPrint('📢 약물 목록 변경 이벤트 발행');
    }
  }

  // ============================================
  // 약물 관리 (기존 기능 유지)
  // ============================================

  /// 모든 약물 조회
  static Future<List<Medication>> getAllMedications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_medicationsKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => Medication.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MedicationStorageService.getAllMedications 오류: $e');
      return [];
    }
  }

  /// 오늘 복용해야 할 약물 조회
  static Future<List<Medication>> getTodayMedications() async {
    final allMedications = await getAllMedications();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return allMedications.where((med) {
      final startDate =
          DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final endDate =
          DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
      return !today.isBefore(startDate) && !today.isAfter(endDate);
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// 약물 추가 (오프라인 큐 지원)
  static Future<void> addMedication(Medication medication,
      {bool addToSyncQueue = true}) async {
    final medications = await getAllMedications();
    medications.add(medication);
    await _saveMedications(medications);

    if (addToSyncQueue) {
      await _addToSyncQueue(
        action: 'create',
        table: 'user_medications',
        data: medication.toJson(),
      );
    }
  }

  /// 여러 약물 추가
  static Future<void> addMedications(List<Medication> newMedications,
      {bool addToSyncQueue = true}) async {
    final medications = await getAllMedications();
    medications.addAll(newMedications);
    await _saveMedications(medications);

    if (addToSyncQueue) {
      for (final med in newMedications) {
        await _addToSyncQueue(
          action: 'create',
          table: 'user_medications',
          data: med.toJson(),
        );
      }
    }
  }

  /// 약물 업데이트
  static Future<void> updateMedication(Medication medication,
      {bool addToSyncQueue = true}) async {
    final medications = await getAllMedications();
    final index = medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      medications[index] = medication;
      await _saveMedications(medications);

      if (addToSyncQueue) {
        await _addToSyncQueue(
          action: 'update',
          table: 'user_medications',
          data: medication.toJson(),
        );
      }
    }
  }

  /// 약물 삭제
  static Future<void> deleteMedication(String medicationId,
      {bool addToSyncQueue = true}) async {
    final medications = await getAllMedications();
    medications.removeWhere((m) => m.id == medicationId);
    await _saveMedications(medications);

    if (addToSyncQueue) {
      await _addToSyncQueue(
        action: 'delete',
        table: 'user_medications',
        data: {'id': medicationId},
      );
    }
  }

  /// 약물 목록 저장
  static Future<void> _saveMedications(List<Medication> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = medications.map((m) => m.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_medicationsKey, jsonString);
  }

  // ============================================
  // 복용 기록 관리 (일별 요약)
  // ============================================

  /// 복용 기록 조회 (특정 날짜)
  static Future<List<MedicationLog>> getMedicationLogs(DateTime date) async {
    final allLogs = await _getAllMedicationLogs();
    final dateStr = _dateToString(date);

    return allLogs.where((log) => _dateToString(log.date) == dateStr).toList();
  }

  /// 복용 기록 조회 (기간)
  static Future<List<MedicationLog>> getMedicationLogsByRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allLogs = await _getAllMedicationLogs();
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    return allLogs.where((log) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      return !logDate.isBefore(start) && !logDate.isAfter(end);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 특정 약물의 특정 날짜 복용 기록 조회/생성
  static Future<MedicationLog> getOrCreateMedicationLog({
    required String medicationId,
    required DateTime date,
    int scheduledCount = 1,
  }) async {
    final logs = await getMedicationLogs(date);
    final existing = logs.where((l) => l.medicationId == medicationId).toList();

    if (existing.isNotEmpty) {
      return existing.first;
    }

    // 새 기록 생성
    final newLog = MedicationLog(
      id: '${medicationId}_${_dateToString(date)}',
      medicationId: medicationId,
      date: date,
      scheduledCount: scheduledCount,
      completedCount: 0,
    );

    await _saveMedicationLog(newLog);
    return newLog;
  }

  /// 복용 완료 처리
  static Future<void> markMedicationCompleted({
    required String medicationId,
    required DateTime date,
    int scheduledCount = 1,
  }) async {
    final log = await getOrCreateMedicationLog(
      medicationId: medicationId,
      date: date,
      scheduledCount: scheduledCount,
    );

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final updatedLog = log.copyWith(
      completedCount: log.completedCount + 1,
      firstCompletedAt: log.firstCompletedAt ?? timeStr,
      lastCompletedAt: timeStr,
    );

    await _saveMedicationLog(updatedLog);

    // 복용 완료 이벤트 발행 (화면 갱신용)
    _notifyMedicationCompleted(medicationId);

    // 동기화 큐에 추가
    await _addToSyncQueue(
      action: 'upsert',
      table: 'medication_logs',
      data: {
        'medicationId': medicationId,
        'date': _dateToString(date),
        'scheduledCount': scheduledCount,
        'completedCount': updatedLog.completedCount,
        'firstCompletedAt': updatedLog.firstCompletedAt,
        'lastCompletedAt': updatedLog.lastCompletedAt,
      },
    );
  }

  /// 복용 취소 처리
  static Future<void> markMedicationUncompleted({
    required String medicationId,
    required DateTime date,
  }) async {
    final logs = await getMedicationLogs(date);
    final existing = logs.where((l) => l.medicationId == medicationId).toList();

    if (existing.isEmpty) return;

    final log = existing.first;
    if (log.completedCount <= 0) return;

    final updatedLog = log.copyWith(
      completedCount: log.completedCount - 1,
    );

    await _saveMedicationLog(updatedLog);

    // 동기화 큐에 추가
    await _addToSyncQueue(
      action: 'upsert',
      table: 'medication_logs',
      data: {
        'medicationId': medicationId,
        'date': _dateToString(date),
        'scheduledCount': log.scheduledCount,
        'completedCount': updatedLog.completedCount,
        'firstCompletedAt': updatedLog.firstCompletedAt,
        'lastCompletedAt': updatedLog.lastCompletedAt,
      },
    );
  }

  /// 복용 상태 조회 (기존 호환성 유지)
  static Future<Map<String, bool>> getMedicationStatus(DateTime date) async {
    final logs = await getMedicationLogs(date);
    final result = <String, bool>{};

    for (final log in logs) {
      result[log.medicationId] = log.completedCount >= log.scheduledCount;
    }

    return result;
  }

  /// 복용 상태 저장 (기존 호환성 유지)
  static Future<void> setMedicationStatus(
    DateTime date,
    String medicationId,
    bool isCompleted,
  ) async {
    if (isCompleted) {
      await markMedicationCompleted(
        medicationId: medicationId,
        date: date,
      );
    } else {
      await markMedicationUncompleted(
        medicationId: medicationId,
        date: date,
      );
    }
  }

  /// 모든 복용 기록 조회 (내부용)
  static Future<List<MedicationLog>> _getAllMedicationLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_medicationLogsKey);

    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => MedicationLog.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MedicationStorageService._getAllMedicationLogs 오류: $e');
      return [];
    }
  }

  /// 복용 기록 저장
  static Future<void> _saveMedicationLog(MedicationLog log) async {
    final allLogs = await _getAllMedicationLogs();

    // 기존 기록 업데이트 또는 추가
    final index = allLogs.indexWhere((l) => l.id == log.id);
    if (index != -1) {
      allLogs[index] = log;
    } else {
      allLogs.add(log);
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonList = allLogs.map((l) => l.toJson()).toList();
    await prefs.setString(_medicationLogsKey, jsonEncode(jsonList));
  }

  /// 복용 기록 전체 저장 (동기화용)
  static Future<void> saveMedicationLogs(List<MedicationLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toJson()).toList();
    await prefs.setString(_medicationLogsKey, jsonEncode(jsonList));
  }

  // ============================================
  // 주사 부위 기록 관리
  // ============================================

  /// 주사 부위 기록 추가
  static Future<void> addInjectionSite(InjectionSiteRecord record) async {
    final sites = await getInjectionSites();

    // 새 기록 추가
    sites.insert(0, record);

    // 최대 개수 제한
    while (sites.length > _maxInjectionSites) {
      sites.removeLast();
    }

    await _saveInjectionSites(sites);

    // 동기화 큐에 추가
    await _addToSyncQueue(
      action: 'create',
      table: 'injection_sites',
      data: record.toJson(),
    );
  }

  /// 주사 부위 기록 조회
  static Future<List<InjectionSiteRecord>> getInjectionSites({
    int? limit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_injectionSitesKey);

    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      var sites = jsonList
          .map((j) => InjectionSiteRecord.fromJson(j as Map<String, dynamic>))
          .toList();

      // 최신순 정렬
      sites.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      if (limit != null && sites.length > limit) {
        sites = sites.take(limit).toList();
      }

      return sites;
    } catch (e) {
      debugPrint('MedicationStorageService.getInjectionSites 오류: $e');
      return [];
    }
  }

  /// 마지막 주사 부위 조회 (다음 부위 추천용)
  static Future<String?> getLastInjectionSite() async {
    final sites = await getInjectionSites(limit: 1);
    return sites.isNotEmpty ? sites.first.site : null;
  }

  /// 다음 추천 주사 부위
  static Future<String> getRecommendedInjectionSite() async {
    final lastSite = await getLastInjectionSite();
    // 좌우 번갈아 추천
    return lastSite == 'left' ? 'right' : 'left';
  }

  /// 주사 부위 기록 저장
  static Future<void> _saveInjectionSites(
      List<InjectionSiteRecord> sites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sites.map((s) => s.toJson()).toList();
    await prefs.setString(_injectionSitesKey, jsonEncode(jsonList));
  }

  /// 주사 부위 기록 전체 저장 (동기화용)
  static Future<void> saveInjectionSites(
      List<InjectionSiteRecord> sites) async {
    await _saveInjectionSites(sites);
  }

  // ============================================
  // 오프라인 동기화 큐
  // ============================================

  /// 동기화 큐에 항목 추가
  static Future<void> _addToSyncQueue({
    required String action,
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final queue = await getSyncQueue();
    final item = SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      table: table,
      data: data,
      createdAt: DateTime.now(),
    );
    queue.add(item);
    await _saveSyncQueue(queue);
  }

  /// 동기화 큐 조회
  static Future<List<SyncQueueItem>> getSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_syncQueueKey);

    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => SyncQueueItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('MedicationStorageService.getSyncQueue 오류: $e');
      return [];
    }
  }

  /// 동기화 큐 저장
  static Future<void> _saveSyncQueue(List<SyncQueueItem> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = queue.map((item) => item.toJson()).toList();
    await prefs.setString(_syncQueueKey, jsonEncode(jsonList));
  }

  /// 동기화 큐에서 항목 제거
  static Future<void> removeSyncQueueItem(String itemId) async {
    final queue = await getSyncQueue();
    queue.removeWhere((item) => item.id == itemId);
    await _saveSyncQueue(queue);
  }

  /// 동기화 큐 초기화
  static Future<void> clearSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_syncQueueKey);
  }

  /// 동기화 큐 항목 재시도 카운트 증가
  static Future<void> incrementSyncQueueItemRetry(String itemId) async {
    final queue = await getSyncQueue();
    final index = queue.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      queue[index] = queue[index].copyWith(retryCount: queue[index].retryCount + 1);
      await _saveSyncQueue(queue);
    }
  }

  /// 동기화 대기 중인 항목 수
  static Future<int> getPendingSyncCount() async {
    final queue = await getSyncQueue();
    return queue.length;
  }

  // ============================================
  // 마지막 동기화 시간
  // ============================================

  /// 마지막 동기화 시간 조회
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// 마지막 동기화 시간 저장
  static Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  // ============================================
  // 유틸리티
  // ============================================

  /// 날짜를 문자열로 변환
  static String _dateToString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 약물 데이터만 초기화
  static Future<void> clearAllMedications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_medicationsKey);
    await prefs.remove(_medicationLogsKey);
    await prefs.remove(_injectionSitesKey);
    await prefs.remove(_syncQueueKey);
    debugPrint('🗑️ 로컬 약물 데이터가 모두 삭제되었습니다');
  }

  /// 모든 데이터 초기화 (테스트용)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_medicationsKey);
    await prefs.remove(_medicationLogsKey);
    await prefs.remove(_injectionSitesKey);
    await prefs.remove(_syncQueueKey);
    await prefs.remove(_lastSyncKey);
  }

  /// 중복 약물 제거 (이름+시간+시작일 기준)
  /// 중복 그룹에서 가장 먼저 추가된 약물만 유지
  static Future<int> removeDuplicateMedications() async {
    final medications = await getAllMedications();
    final seen = <String, Medication>{};
    final toRemove = <String>[];

    // 정규화 함수 (대소문자, 공백 무시)
    String normalizeTime(String time) {
      return time.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    }

    for (final med in medications) {
      final startDateStr = med.startDate.toIso8601String().split('T')[0];
      final normalizedName = med.name.trim().toLowerCase();
      final normalizedTime = normalizeTime(med.time);
      final key = '${normalizedName}_${normalizedTime}_$startDateStr';

      if (seen.containsKey(key)) {
        // 이미 있으면 중복 - 제거 대상
        toRemove.add(med.id);
        debugPrint('🗑️ 중복 약물 발견: ${med.name} (${med.time}, $startDateStr) ID: ${med.id}');
      } else {
        seen[key] = med;
      }
    }

    if (toRemove.isEmpty) {
      debugPrint('✅ 중복 약물 없음');
      return 0;
    }

    // 중복 제거된 목록 저장
    final uniqueMedications = medications.where((m) => !toRemove.contains(m.id)).toList();
    await _saveMedications(uniqueMedications);

    debugPrint('🗑️ ${toRemove.length}개 중복 약물 제거됨');
    return toRemove.length;
  }

  /// 특정 ID로 약물 조회
  static Future<Medication?> getMedicationById(String id) async {
    final medications = await getAllMedications();
    final matches = medications.where((m) => m.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// 로컬 데이터 덤프 (디버깅용)
  static Future<Map<String, dynamic>> dumpLocalData() async {
    return {
      'medications': (await getAllMedications()).map((m) => m.toJson()).toList(),
      'medicationLogs': (await _getAllMedicationLogs()).map((l) => l.toJson()).toList(),
      'injectionSites': (await getInjectionSites()).map((s) => s.toJson()).toList(),
      'syncQueue': (await getSyncQueue()).map((q) => q.toJson()).toList(),
      'lastSyncTime': (await getLastSyncTime())?.toIso8601String(),
    };
  }
}
