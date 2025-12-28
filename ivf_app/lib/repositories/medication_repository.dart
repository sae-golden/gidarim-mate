import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// 약물 Repository
class MedicationRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// 특정 주기의 모든 약물 조회
  Future<List<Map<String, dynamic>>> getMedicationsByCycle(String cycleId) async {
    final response = await _client
        .from('medications')
        .select()
        .eq('cycle_id', cycleId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// 활성화된 약물만 조회
  Future<List<Map<String, dynamic>>> getActiveMedicationsByCycle(String cycleId) async {
    final response = await _client
        .from('medications')
        .select()
        .eq('cycle_id', cycleId)
        .eq('is_active', true)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// 오늘 복용해야 할 약물 조회
  Future<List<Map<String, dynamic>>> getTodayMedications(String cycleId) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final response = await _client
        .from('medications')
        .select()
        .eq('cycle_id', cycleId)
        .eq('is_active', true)
        .lte('start_date', today)
        .or('end_date.is.null,end_date.gte.$today');

    return List<Map<String, dynamic>>.from(response);
  }

  /// 새 약물 추가
  Future<Map<String, dynamic>> createMedication({
    required String cycleId,
    required String name,
    required String type, // injection, oral, patch, other
    String? dosage,
    String? frequency,
    List<String>? scheduledTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? color,
    String? memo,
  }) async {
    final response = await _client.from('medications').insert({
      'cycle_id': cycleId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'frequency': frequency,
      'scheduled_times': scheduledTimes,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'color': color,
      'memo': memo,
    }).select().single();

    return response;
  }

  /// 약물 업데이트
  Future<void> updateMedication(String medicationId, Map<String, dynamic> data) async {
    await _client.from('medications').update(data).eq('id', medicationId);
  }

  /// 약물 비활성화
  Future<void> deactivateMedication(String medicationId) async {
    await _client.from('medications').update({
      'is_active': false,
    }).eq('id', medicationId);
  }

  /// 약물 삭제
  Future<void> deleteMedication(String medicationId) async {
    await _client.from('medications').delete().eq('id', medicationId);
  }
}

/// 투약 기록 Repository
class MedicationLogRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// 특정 약물의 모든 기록 조회
  Future<List<Map<String, dynamic>>> getLogsByMedication(String medicationId) async {
    final response = await _client
        .from('medication_logs')
        .select()
        .eq('medication_id', medicationId)
        .order('scheduled_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 오늘의 투약 기록 조회
  Future<List<Map<String, dynamic>>> getTodayLogs(String medicationId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('medication_logs')
        .select()
        .eq('medication_id', medicationId)
        .gte('scheduled_at', startOfDay.toIso8601String())
        .lt('scheduled_at', endOfDay.toIso8601String())
        .order('scheduled_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// 특정 날짜의 모든 투약 기록 조회 (모든 약물)
  Future<List<Map<String, dynamic>>> getLogsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('medication_logs')
        .select('''
          *,
          medications(name, type, color)
        ''')
        .gte('scheduled_at', startOfDay.toIso8601String())
        .lt('scheduled_at', endOfDay.toIso8601String())
        .order('scheduled_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// 투약 기록 생성
  Future<Map<String, dynamic>> createLog({
    required String medicationId,
    required DateTime scheduledAt,
    DateTime? takenAt,
    String? status,
    int? injectionLocation,
    String? memo,
  }) async {
    final response = await _client.from('medication_logs').insert({
      'medication_id': medicationId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'taken_at': takenAt?.toIso8601String(),
      'status': status ?? 'pending',
      'injection_location': injectionLocation,
      'memo': memo,
    }).select().single();

    return response;
  }

  /// 투약 완료 처리
  Future<void> markAsTaken(
    String logId, {
    int? injectionLocation,
    String? memo,
  }) async {
    await _client.from('medication_logs').update({
      'status': 'taken',
      'taken_at': DateTime.now().toIso8601String(),
      if (injectionLocation != null) 'injection_location': injectionLocation,
      if (memo != null) 'memo': memo,
    }).eq('id', logId);
  }

  /// 투약 건너뛰기 처리
  Future<void> markAsSkipped(String logId, {String? memo}) async {
    await _client.from('medication_logs').update({
      'status': 'skipped',
      if (memo != null) 'memo': memo,
    }).eq('id', logId);
  }

  /// 투약 기록 삭제
  Future<void> deleteLog(String logId) async {
    await _client.from('medication_logs').delete().eq('id', logId);
  }
}

/// 주사 부위 히스토리 Repository
class InjectionHistoryRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// 최근 주사 기록 조회
  Future<List<Map<String, dynamic>>> getRecentHistory({int limit = 10}) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('injection_history')
        .select()
        .eq('user_id', userId)
        .order('injected_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// 마지막 주사 위치 조회
  Future<int?> getLastLocation() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('injection_history')
        .select('location')
        .eq('user_id', userId)
        .order('injected_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response?['location'] as int?;
  }

  /// 주사 기록 추가
  Future<void> addHistory({
    required int location,
    String? medicationName,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    await _client.from('injection_history').insert({
      'user_id': userId,
      'location': location,
      'medication_name': medicationName,
    });
  }

  /// 특정 기간의 주사 기록 조회 (통계용)
  Future<List<Map<String, dynamic>>> getHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('injection_history')
        .select()
        .eq('user_id', userId)
        .gte('injected_at', startDate.toIso8601String())
        .lte('injected_at', endDate.toIso8601String())
        .order('injected_at');

    return List<Map<String, dynamic>>.from(response);
  }
}
