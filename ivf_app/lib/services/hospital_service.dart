import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hospital.dart';

/// 병원 검색 서비스
class HospitalService {
  static const String _baseUrl =
      'http://apis.data.go.kr/B551182/hospInfoServicev2';
  static const String _serviceKey =
      '9452f9e3e312293e084b9a4b34ca590f2acf7f4342eae5fafc2b02920d470a15';

  static const String _userHospitalKey = 'user_hospital_info';

  /// 병원 검색 (키워드)
  static Future<List<Hospital>> searchHospitals({
    String? keyword,
    String? sidoCd,
    int pageNo = 1,
    int numOfRows = 20,
  }) async {
    try {
      final queryParams = {
        'serviceKey': _serviceKey,
        'pageNo': pageNo.toString(),
        'numOfRows': numOfRows.toString(),
        'dgsbjtCd': '11', // 산부인과
        '_type': 'json',
      };

      if (keyword != null && keyword.isNotEmpty) {
        queryParams['yadmNm'] = keyword;
      }

      if (sidoCd != null && sidoCd.isNotEmpty) {
        queryParams['sidoCd'] = sidoCd;
      }

      final uri = Uri.parse('$_baseUrl/getHospBasisList')
          .replace(queryParameters: queryParams);

      debugPrint('Hospital API Request: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다');
        },
      );

      if (response.statusCode == 200) {
        return _parseResponse(response.body);
      } else {
        debugPrint('Hospital API Error: ${response.statusCode}');
        throw Exception('서버 오류가 발생했습니다');
      }
    } catch (e) {
      debugPrint('Hospital Search Error: $e');
      rethrow;
    }
  }

  /// API 응답 파싱
  static List<Hospital> _parseResponse(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      final response = decoded['response'];

      if (response == null) {
        return [];
      }

      final body = response['body'];
      if (body == null) {
        return [];
      }

      final items = body['items'];
      if (items == null || items['item'] == null) {
        return [];
      }

      final itemList = items['item'];

      // 단일 항목인 경우 리스트로 변환
      if (itemList is Map) {
        return [Hospital.fromJson(itemList as Map<String, dynamic>)];
      }

      // 리스트인 경우
      if (itemList is List) {
        return itemList
            .map((item) => Hospital.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Parse Error: $e');
      return [];
    }
  }

  /// 사용자 병원 정보 저장 (로컬)
  static Future<void> saveUserHospitalInfo(UserHospitalInfo info, {bool syncToCloud = true}) async {
    try {
      // 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(info.toJson());
      await prefs.setString(_userHospitalKey, jsonStr);
      debugPrint('✅ 병원 정보 저장 완료');
    } catch (e) {
      debugPrint('Save Hospital Info Error: $e');
    }
  }

  /// 사용자 병원 정보 불러오기
  static Future<UserHospitalInfo?> loadUserHospitalInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userHospitalKey);

      if (jsonStr == null) return null;

      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return UserHospitalInfo.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Load Hospital Info Error: $e');
      return null;
    }
  }

  /// 사용자 병원 정보 삭제
  static Future<void> clearUserHospitalInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userHospitalKey);
    } catch (e) {
      debugPrint('Clear Hospital Info Error: $e');
    }
  }
}
