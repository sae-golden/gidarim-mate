import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication.dart';
import 'supabase_service.dart';

/// 클라우드 저장소 서비스 (Supabase)
/// 로그인한 사용자의 데이터를 클라우드에 저장/조회
class CloudStorageService {
  static SupabaseClient get _client => SupabaseService.client;

  // ============================================
  // 사용자 프로필
  // ============================================

  /// 사용자 프로필 생성 (회원가입 시)
  static Future<void> createUserProfile({
    String? displayName,
    String? hospitalId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    await _client.from('user_profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'hospital_id': hospitalId,
    });
  }

  /// 사용자 프로필 조회
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  /// 사용자 프로필 업데이트
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    await _client.from('user_profiles').update(data).eq('id', userId);
  }

  /// 치료 단계 저장
  static Future<bool> saveTreatmentStage(int stageIndex) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('user_profiles').upsert({
        'id': userId,
        'treatment_stage': stageIndex,
      });
      debugPrint('☁️ 치료 단계 저장 완료: $stageIndex');
      return true;
    } catch (e) {
      debugPrint('☁️ 치료 단계 저장 실패: $e');
      return false;
    }
  }

  /// 치료 단계 조회
  static Future<int?> getTreatmentStage() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select('treatment_stage')
          .eq('id', userId)
          .maybeSingle();

      return response?['treatment_stage'] as int?;
    } catch (e) {
      debugPrint('☁️ 치료 단계 조회 실패: $e');
      return null;
    }
  }

  /// 병원 정보 저장
  static Future<bool> saveHospitalInfo(Map<String, dynamic> hospitalInfo) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('user_profiles').upsert({
        'id': userId,
        'hospital_info': hospitalInfo,
      });
      debugPrint('☁️ 병원 정보 저장 완료');
      return true;
    } catch (e) {
      debugPrint('☁️ 병원 정보 저장 실패: $e');
      return false;
    }
  }

  /// 병원 정보 조회
  static Future<Map<String, dynamic>?> getHospitalInfo() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select('hospital_info')
          .eq('id', userId)
          .maybeSingle();

      final hospitalInfo = response?['hospital_info'];
      if (hospitalInfo == null) return null;
      return Map<String, dynamic>.from(hospitalInfo);
    } catch (e) {
      debugPrint('☁️ 병원 정보 조회 실패: $e');
      return null;
    }
  }

  // ============================================
  // 약물 관리
  // ============================================

  /// 모든 약물 조회
  static Future<List<Medication>> getAllMedications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('user_medications')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _medicationFromSupabase(json))
          .toList();
    } catch (e) {
      debugPrint('CloudStorageService.getAllMedications 오류: $e');
      return [];
    }
  }

  /// 약물 추가 (중복 방지 - medication_id로 upsert)
  static Future<String?> addMedication(Medication medication) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    try {
      debugPrint('☁️ [Cloud] 약물 저장 시도: ${medication.name} (ID: ${medication.id})');

      // upsert로 변경 - 로컬 ID를 medication_id로 저장하고, 중복 시 업데이트
      // onConflict는 UNIQUE 제약조건이 있는 컬럼 조합이어야 함
      final response = await _client.from('user_medications').upsert({
        'user_id': userId,
        'medication_id': medication.id,  // 로컬 ID 저장 (중복 방지 키)
        'name': medication.name,
        'dosage': medication.dosage,
        'type': medication.type.name,
        'time': medication.time,
        'pattern': medication.pattern ?? '매일',
        'start_date': medication.startDate.toIso8601String().split('T')[0],
        'end_date': medication.endDate.toIso8601String().split('T')[0],
        'total_count': medication.totalCount,
        'is_active': true,
      }, onConflict: 'user_id,medication_id').select('id').single();

      debugPrint('☁️ [Cloud] 약물 저장 성공: ${medication.name} -> Supabase ID: ${response['id']}');
      return response['id'] as String;
    } catch (e) {
      debugPrint('☁️ [Cloud] addMedication 오류: $e');

      // UNIQUE 제약조건 위반 오류인 경우 이미 존재하는 것이므로 성공으로 처리
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('unique constraint')) {
        debugPrint('☁️ [Cloud] 이미 존재하는 약물 (정상): ${medication.name}');
        return medication.id; // 기존 ID 반환
      }
      return null;
    }
  }

  /// 여러 약물 추가
  static Future<List<String>> addMedications(List<Medication> medications) async {
    final ids = <String>[];
    for (final med in medications) {
      final id = await addMedication(med);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  /// 약물 업데이트
  static Future<bool> updateMedication(Medication medication) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('user_medications').update({
        'name': medication.name,
        'dosage': medication.dosage,
        'type': medication.type.name,
        'time': medication.time,
        'pattern': medication.pattern ?? '매일',
        'start_date': medication.startDate.toIso8601String().split('T')[0],
        'end_date': medication.endDate.toIso8601String().split('T')[0],
        'total_count': medication.totalCount,
      }).eq('id', medication.id).eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('CloudStorageService.updateMedication 오류: $e');
      return false;
    }
  }

  /// 약물 삭제 (소프트 삭제) - 로컬 ID 또는 Supabase ID로 삭제
  static Future<bool> deleteMedication(String medicationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // 먼저 medication_id (로컬 ID)로 시도
      await _client
          .from('user_medications')
          .update({'is_active': false})
          .eq('medication_id', medicationId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      // 실패하면 Supabase id로 시도
      try {
        await _client
            .from('user_medications')
            .update({'is_active': false})
            .eq('id', medicationId)
            .eq('user_id', userId);
        return true;
      } catch (e2) {
        debugPrint('CloudStorageService.deleteMedication 오류: $e2');
        return false;
      }
    }
  }

  // ============================================
  // 복용 기록 (일별 요약)
  // ============================================

  /// 복용 기록 저장/업데이트
  static Future<bool> saveMedicationLog({
    required String medicationId,
    required DateTime date,
    required int scheduledCount,
    required int completedCount,
    String? firstCompletedAt,
    String? lastCompletedAt,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // local_medication_id 사용 (TEXT 타입)
      await _client.from('medication_logs').upsert({
        'user_id': userId,
        'local_medication_id': medicationId,
        'medication_id': medicationId,
        'date': date.toIso8601String().split('T')[0],
        'scheduled_count': scheduledCount,
        'completed_count': completedCount,
        'first_completed_at': firstCompletedAt,
        'last_completed_at': lastCompletedAt,
        'notes': notes,
      }, onConflict: 'user_id,local_medication_id,date');

      return true;
    } catch (e) {
      debugPrint('CloudStorageService.saveMedicationLog 오류: $e');
      return false;
    }
  }

  /// 특정 날짜의 복용 기록 조회
  static Future<List<Map<String, dynamic>>> getMedicationLogs(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await _client
          .from('medication_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', dateStr);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('CloudStorageService.getMedicationLogs 오류: $e');
      return [];
    }
  }

  /// 기간별 복용 기록 조회 (통계용)
  static Future<List<Map<String, dynamic>>> getMedicationLogsByRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final startStr = startDate.toIso8601String().split('T')[0];
      final endStr = endDate.toIso8601String().split('T')[0];

      final response = await _client
          .from('medication_logs')
          .select()
          .eq('user_id', userId)
          .gte('date', startStr)
          .lte('date', endStr)
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('CloudStorageService.getMedicationLogsByRange 오류: $e');
      return [];
    }
  }

  // ============================================
  // 주사 부위 기록
  // ============================================

  /// 주사 부위 기록 저장
  static Future<bool> saveInjectionSite({
    String? medicationId,
    required DateTime dateTime,
    required String site, // 'left' or 'right'
    String? location,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('injection_sites').insert({
        'user_id': userId,
        'local_medication_id': medicationId,
        'medication_id': medicationId,
        'date': dateTime.toIso8601String().split('T')[0],
        'time': '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
        'site': site,
        'location': location,
        'notes': notes,
      });

      return true;
    } catch (e) {
      debugPrint('CloudStorageService.saveInjectionSite 오류: $e');
      return false;
    }
  }

  /// 최근 주사 부위 기록 조회 (N건)
  static Future<List<Map<String, dynamic>>> getRecentInjectionSites({
    int limit = 30,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('injection_sites')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .order('time', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('CloudStorageService.getRecentInjectionSites 오류: $e');
      return [];
    }
  }

  // ============================================
  // 치료 사이클
  // ============================================

  /// 현재 활성 사이클 조회
  static Future<Map<String, dynamic>?> getActiveCycle() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('treatment_cycles')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('CloudStorageService.getActiveCycle 오류: $e');
      return null;
    }
  }

  /// 새 치료 사이클 생성
  static Future<String?> createCycle({
    required int cycleNumber,
    required DateTime startDate,
    String? currentStage,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client.from('treatment_cycles').insert({
        'user_id': userId,
        'cycle_number': cycleNumber,
        'start_date': startDate.toIso8601String().split('T')[0],
        'current_stage': currentStage,
        'status': 'active',
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('CloudStorageService.createCycle 오류: $e');
      return null;
    }
  }

  /// 치료 사이클 업데이트
  static Future<bool> updateCycle(String cycleId, Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client
          .from('treatment_cycles')
          .update(data)
          .eq('id', cycleId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('CloudStorageService.updateCycle 오류: $e');
      return false;
    }
  }

  // ============================================
  // 공용 데이터 조회
  // ============================================

  /// 병원 목록 조회
  static Future<List<Map<String, dynamic>>> getHospitals({String? region}) async {
    try {
      var query = _client.from('hospitals').select();

      if (region != null) {
        query = query.eq('region', region);
      }

      final response = await query.order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('CloudStorageService.getHospitals 오류: $e');
      return [];
    }
  }

  /// 약물 마스터 DB 조회
  static Future<List<Map<String, dynamic>>> getMedicationsDb({String? category}) async {
    try {
      var query = _client.from('medications_db').select();

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('CloudStorageService.getMedicationsDb 오류: $e');
      return [];
    }
  }

  // ============================================
  // 헬퍼 메서드
  // ============================================

  /// Supabase 응답을 Medication 객체로 변환
  static Medication _medicationFromSupabase(Map<String, dynamic> json) {
    // medication_id (로컬 ID)가 있으면 우선 사용, 없으면 Supabase UUID 사용
    final medicationId = json['medication_id'] as String?;
    final supabaseId = json['id'] as String;
    final id = medicationId ?? supabaseId;

    debugPrint('  🔍 클라우드 약물 파싱: ${json['name']}');
    debugPrint('     - medication_id (로컬): $medicationId');
    debugPrint('     - supabase id: $supabaseId');
    debugPrint('     - 사용할 ID: $id');

    return Medication(
      id: id,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      time: json['time'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      type: _parseMedicationType(json['type'] as String),
      pattern: json['pattern'] as String?,
      totalCount: (json['total_count'] as int?) ?? 1,
    );
  }

  static MedicationType _parseMedicationType(String type) {
    switch (type) {
      case 'injection':
        return MedicationType.injection;
      case 'suppository':
        return MedicationType.suppository;
      case 'patch':
        return MedicationType.patch;
      default:
        return MedicationType.oral;
    }
  }

  /// 로그인 여부 확인
  static bool get isLoggedIn => _client.auth.currentUser != null;

  /// 현재 사용자 ID
  static String? get currentUserId => _client.auth.currentUser?.id;

  // ============================================
  // 중복 데이터 정리
  // ============================================

  /// 클라우드에서 중복 약물 정리 (이름+시간+시작일 기준)
  /// 첫 번째 항목만 남기고 나머지는 삭제 (soft delete)
  static Future<int> removeDuplicateMedications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      // 모든 활성 약물 조회
      final response = await _client
          .from('user_medications')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final medications = response as List;
      if (medications.isEmpty) return 0;

      // 중복 체크용 Map (키 -> 첫 번째 ID)
      final seen = <String, String>{};
      final toDelete = <String>[];

      for (final med in medications) {
        final name = (med['name'] as String).trim().toLowerCase();
        final time = (med['time'] as String).trim().toLowerCase();
        final startDate = med['start_date'] as String;
        final key = '${name}_${time}_$startDate';

        if (seen.containsKey(key)) {
          // 이미 있으면 중복 - 삭제 대상
          toDelete.add(med['id'] as String);
          debugPrint('☁️ 중복 약물 발견: ${med['name']} (삭제 예정)');
        } else {
          seen[key] = med['id'] as String;
        }
      }

      if (toDelete.isEmpty) {
        debugPrint('☁️ 클라우드 중복 약물 없음');
        return 0;
      }

      // 중복 약물 비활성화 (soft delete)
      for (final id in toDelete) {
        await _client
            .from('user_medications')
            .update({'is_active': false})
            .eq('id', id);
      }

      debugPrint('☁️ 클라우드 중복 약물 ${toDelete.length}개 정리 완료');
      return toDelete.length;
    } catch (e) {
      debugPrint('☁️ 중복 약물 정리 오류: $e');
      return 0;
    }
  }

  // ============================================
  // 피드백
  // ============================================

  /// 피드백 저장
  static Future<bool> saveFeedback({
    required int stars,
    required String category,
    required String content,
    String? appVersion,
    String? osType,
    String? osVersion,
    String? deviceModel,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      await _client.from('feedbacks').insert({
        'user_id': userId,
        'stars': stars,
        'category': category,
        'content': content,
        'app_version': appVersion,
        'os_type': osType,
        'os_version': osVersion,
        'device_model': deviceModel,
      });

      debugPrint('☁️ 피드백 저장 완료: $stars점 / $category');
      return true;
    } catch (e) {
      debugPrint('☁️ 피드백 저장 실패: $e');
      return false;
    }
  }
}
