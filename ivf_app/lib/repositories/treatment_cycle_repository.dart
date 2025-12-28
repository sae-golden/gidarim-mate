import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// 치료 주기 Repository
class TreatmentCycleRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// 현재 사용자의 모든 치료 주기 조회
  Future<List<Map<String, dynamic>>> getAllCycles() async {
    final response = await _client
        .from('treatment_cycles')
        .select()
        .order('cycle_number', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// 활성화된 치료 주기 조회
  Future<Map<String, dynamic>?> getActiveCycle() async {
    final response = await _client
        .from('treatment_cycles')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }

  /// 특정 치료 주기 조회 (단계 포함)
  Future<Map<String, dynamic>?> getCycleWithStages(String cycleId) async {
    final response = await _client
        .from('treatment_cycles')
        .select('''
          *,
          cycle_stages(*),
          medications(*)
        ''')
        .eq('id', cycleId)
        .single();
    return response;
  }

  /// 새 치료 주기 생성
  Future<Map<String, dynamic>> createCycle({
    required int cycleNumber,
    DateTime? startDate,
    String? memo,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다.');

    final response = await _client.from('treatment_cycles').insert({
      'user_id': userId,
      'cycle_number': cycleNumber,
      'start_date': startDate?.toIso8601String().split('T').first,
      'memo': memo,
    }).select().single();

    return response;
  }

  /// 치료 주기 업데이트
  Future<void> updateCycle(String cycleId, Map<String, dynamic> data) async {
    await _client
        .from('treatment_cycles')
        .update(data)
        .eq('id', cycleId);
  }

  /// 치료 주기 삭제
  Future<void> deleteCycle(String cycleId) async {
    await _client.from('treatment_cycles').delete().eq('id', cycleId);
  }

  /// 치료 주기 완료 처리
  Future<void> completeCycle(String cycleId) async {
    await _client.from('treatment_cycles').update({
      'status': 'completed',
      'end_date': DateTime.now().toIso8601String().split('T').first,
    }).eq('id', cycleId);
  }
}

/// 치료 단계 Repository
class CycleStageRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// 특정 주기의 모든 단계 조회
  Future<List<Map<String, dynamic>>> getStagesByCycle(String cycleId) async {
    final response = await _client
        .from('cycle_stages')
        .select()
        .eq('cycle_id', cycleId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  /// 새 단계 생성
  Future<Map<String, dynamic>> createStage({
    required String cycleId,
    required String stageType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.from('cycle_stages').insert({
      'cycle_id': cycleId,
      'stage_type': stageType,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
    }).select().single();

    return response;
  }

  /// 단계 업데이트
  Future<void> updateStage(String stageId, Map<String, dynamic> data) async {
    await _client.from('cycle_stages').update(data).eq('id', stageId);
  }

  /// 단계 결과 데이터 업데이트
  Future<void> updateStageResult(
    String stageId,
    Map<String, dynamic> resultData,
  ) async {
    await _client.from('cycle_stages').update({
      'result_data': resultData,
      'status': 'completed',
    }).eq('id', stageId);
  }

  /// 단계 삭제
  Future<void> deleteStage(String stageId) async {
    await _client.from('cycle_stages').delete().eq('id', stageId);
  }
}
