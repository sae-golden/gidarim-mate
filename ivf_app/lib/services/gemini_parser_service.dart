import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/voice_recognition_result.dart';

/// Gemini AI 기반 약물 텍스트 파싱 서비스
class GeminiParserService {
  static GenerativeModel? _model;
  static bool _initialized = false;

  /// 서비스 초기화
  static Future<bool> initialize() async {
    if (_initialized) return true;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('GEMINI_API_KEY가 설정되지 않았습니다.');
      return false;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite', // 무료 10회/분
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1, // 낮은 온도로 일관된 결과
          maxOutputTokens: 1024,
        ),
      );
      _initialized = true;
      debugPrint('Gemini 서비스 초기화 완료');
      return true;
    } catch (e) {
      debugPrint('Gemini 초기화 실패: $e');
      return false;
    }
  }

  /// 음성 텍스트를 파싱하여 약물 정보 추출
  static Future<VoiceRecognitionResult> parseVoiceText(String text) async {
    if (!_initialized || _model == null) {
      final success = await initialize();
      if (!success) {
        // 폴백: 기존 로컬 파서 사용
        return VoiceTextParser.parse(text);
      }
    }

    try {
      final prompt = '''
다음 한국어 텍스트에서 약물 복용 정보를 추출해서 JSON 배열로 반환해줘.

텍스트: "$text"

각 약물에 대해 다음 정보를 추출해:
- name: 약 이름 (필수)
- type: 약물 종류 - "oral"(알약/경구), "injection"(주사), "suppository"(질정/좌약), "patch"(패치) 중 하나
- quantity: 복용 개수 (숫자, 기본값 1)
- times: 복용 시간 배열 ["HH:mm" 형식] (예: ["08:00", "20:00"])

규칙:
1. "아침"은 08:00, "점심"은 12:00, "저녁"은 18:00, "밤"은 22:00으로 변환
2. "아침 저녁"처럼 여러 시간이면 times 배열에 모두 포함
3. 주사 관련 키워드(주사, 펜, 앰플 등)가 있으면 type은 "injection"
4. 질정, 좌약 키워드가 있으면 type은 "suppository"
5. 패치 키워드가 있으면 type은 "patch"
6. 명시되지 않으면 type은 "oral"
7. 시간이 명시되지 않으면 times는 ["08:00"]

JSON 배열만 반환하고 다른 텍스트는 포함하지 마.

예시 입력: "프로기노바 아침 저녁 하나씩, 고나엘에프 주사 밤 10시"
예시 출력: [{"name":"프로기노바","type":"oral","quantity":1,"times":["08:00","18:00"]},{"name":"고나엘에프","type":"injection","quantity":1,"times":["22:00"]}]
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final responseText = response.text?.trim() ?? '';

      debugPrint('Gemini 응답: $responseText');

      // JSON 파싱
      final medications = _parseGeminiResponse(responseText);

      return VoiceRecognitionResult(
        rawText: text,
        medications: medications,
        confidence: medications.isNotEmpty ? 0.95 : 0.0,
      );
    } catch (e) {
      debugPrint('Gemini 파싱 실패: $e');
      // 폴백: 기존 로컬 파서 사용
      return VoiceTextParser.parse(text);
    }
  }

  /// Gemini 응답 JSON 파싱
  static List<ParsedMedication> _parseGeminiResponse(String response) {
    try {
      // JSON 배열 추출 (앞뒤 마크다운 코드블록 제거)
      String jsonStr = response;
      if (jsonStr.contains('```json')) {
        jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
      } else if (jsonStr.contains('```')) {
        jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
      }

      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final medications = <ParsedMedication>[];

      for (final item in jsonList) {
        final name = item['name'] as String? ?? '';
        if (name.isEmpty) continue;

        final typeStr = item['type'] as String? ?? 'oral';
        final type = _parseType(typeStr);

        final quantity = item['quantity'] as int? ?? 1;

        final times = item['times'] as List<dynamic>? ?? ['08:00'];
        TimeOfDay? firstTime;
        String? timeText;

        if (times.isNotEmpty) {
          final timeStr = times[0] as String;
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]) ?? 8;
            final minute = int.tryParse(parts[1]) ?? 0;
            firstTime = TimeOfDay(hour: hour, minute: minute);
          }

          // 여러 시간이면 텍스트로 표시
          if (times.length > 1) {
            timeText = times.map((t) => _formatTimeText(t as String)).join(', ');
          }
        }

        medications.add(ParsedMedication(
          name: name,
          type: type,
          quantity: quantity,
          time: firstTime,
          timeText: timeText,
        ));
      }

      return medications;
    } catch (e) {
      debugPrint('JSON 파싱 오류: $e');
      return [];
    }
  }

  static MedicationType _parseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
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

  static String _formatTimeText(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return timeStr;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    if (minute == 0) {
      return '$period ${displayHour}시';
    }
    return '$period ${displayHour}시 ${minute}분';
  }

  /// API 키가 설정되어 있는지 확인
  static bool get isConfigured {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    // 플레이스홀더나 빈 값 체크
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) debugPrint('❌ Gemini API 키 없음');
      return false;
    }
    if (apiKey.contains('여기에') || apiKey.contains('API_키')) {
      if (kDebugMode) debugPrint('❌ Gemini 플레이스홀더 키');
      return false;
    }
    if (!apiKey.startsWith('AIza')) {
      if (kDebugMode) debugPrint('❌ Gemini 잘못된 키 형식');
      return false;
    }
    if (kDebugMode) debugPrint('✅ Gemini API 키 유효');
    return true;
  }
}
