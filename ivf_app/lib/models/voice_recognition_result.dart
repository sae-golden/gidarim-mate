import 'package:flutter/material.dart';

/// 음성 인식 결과
class VoiceRecognitionResult {
  final String rawText; // 원본 인식 텍스트
  final List<ParsedMedication> medications; // 파싱된 약물 목록
  final double confidence; // 인식 신뢰도

  VoiceRecognitionResult({
    required this.rawText,
    required this.medications,
    this.confidence = 0.0,
  });
}

/// 파싱된 약물 정보
class ParsedMedication {
  String name; // 약 이름
  MedicationType type; // 알약/주사/질정/패치
  int quantity; // 개수
  String? timeText; // 시간 텍스트 ("아침 8시")
  TimeOfDay? time; // 파싱된 시간
  DateTime startDate; // 시작일
  DateTime endDate; // 종료일
  bool isSelected; // 추가 선택 여부 (기본 true)

  ParsedMedication({
    required this.name,
    this.type = MedicationType.oral,
    this.quantity = 1,
    this.timeText,
    this.time,
    DateTime? startDate,
    DateTime? endDate,
    this.isSelected = true,
  }) : startDate = startDate ?? DateTime.now(),
       endDate = endDate ?? DateTime.now(); // 기본값: 오늘 하루만

  /// 복용 기간 (일수)
  int get durationDays => endDate.difference(startDate).inDays + 1;

  /// 시간 표시 텍스트
  String get displayTime {
    if (timeText != null && timeText!.isNotEmpty) {
      return timeText!;
    }
    if (time != null) {
      final hour = time!.hour;
      final minute = time!.minute.toString().padLeft(2, '0');
      final period = hour < 12 ? '오전' : '오후';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$period $displayHour:$minute';
    }
    return '시간 미지정';
  }

  /// 종류 표시 텍스트
  String get displayType {
    switch (type) {
      case MedicationType.oral:
        return '알약';
      case MedicationType.injection:
        return '주사';
      case MedicationType.suppository:
        return '질정';
      case MedicationType.patch:
        return '한약';
    }
  }

  /// 아이콘
  String get emoji {
    switch (type) {
      case MedicationType.oral:
        return '💊';
      case MedicationType.injection:
        return '💉';
      case MedicationType.suppository:
        return '💊';
      case MedicationType.patch:
        return '🍵';
    }
  }
}

/// 약물 종류
enum MedicationType {
  oral, // 알약/경구
  injection, // 주사
  suppository, // 질정
  patch, // 한약 (기존 patch 유지 - DB 호환성)
}

/// 음성 텍스트 파서
class VoiceTextParser {
  // 구분자 패턴 (쉼표, 그리고/랑/하고/이랑 + 약 이름 앞 공백)
  static final RegExp _separatorPattern = RegExp(r'[,，]|\s+(그리고|랑|하고|이랑)\s+');

  // 알려진 약 이름들 (IVF 약물 + 음성인식 변형 + 일반 표현)
  static final List<String> _knownMedications = [
    // IVF 주사제 (+ 음성인식 변형)
    '고나도트로핀', '고나엘에프', '고날에프', '퓨레곤', '메노푸어', '폴리트롭',
    '오비드렐', '프레그닐', '데카펩틸', '루프론', '세트로타이드', '오르가루트란',
    '크녹산', '큰옥산', '큰 옥산', '프록산', '크록산',
    // IVF 경구약 (+ 음성인식 변형)
    '프로기노바', '푸르기노바', '프로기노', '푸르기노', '프로게노바',
    '에스트로페', '프레마린', '유트로게스탄', '듀파스톤',
    '클로미펜', '클로미드', '페마라', '레트로졸',
    '아스피린', '프레드니솔론', '덱사메타손',
    // IVF 질정
    '루테늄', '크리논', '프로게스테론',
    // 일반 표현
    '주사', '알약', '질정', '한약',
  ];

  // 시간 키워드 매핑
  static final Map<String, TimeOfDay> _timeKeywords = {
    '아침': const TimeOfDay(hour: 8, minute: 0),
    '점심': const TimeOfDay(hour: 12, minute: 0),
    '저녁': const TimeOfDay(hour: 18, minute: 0),
    '밤': const TimeOfDay(hour: 22, minute: 0),
    '새벽': const TimeOfDay(hour: 6, minute: 0),
  };

  // 식후 시간 추가 (30분)
  static final Map<String, int> _mealModifiers = {
    '식후': 30,
    '식전': -30,
  };

  // 약물 종류 키워드
  static final Map<String, MedicationType> _typeKeywords = {
    '알약': MedicationType.oral,
    '경구': MedicationType.oral,
    '주사': MedicationType.injection,
    '질정': MedicationType.suppository,
    '좌약': MedicationType.suppository,
    '한약': MedicationType.patch,
  };

  /// 음성 텍스트를 파싱하여 여러 약물 정보 추출
  static VoiceRecognitionResult parse(String text) {
    if (text.trim().isEmpty) {
      return VoiceRecognitionResult(rawText: text, medications: []);
    }

    // 1차: 구분자로 분리
    var segments = text.split(_separatorPattern);

    // 2차: 약 이름 기반 분리 (구분자가 없는 경우)
    final expandedSegments = <String>[];
    for (final segment in segments) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;

      // 약 이름이 여러 개 있는지 확인
      final splitByMedName = _splitByMedicationNames(trimmed);
      expandedSegments.addAll(splitByMedName);
    }

    final medications = <ParsedMedication>[];
    for (final segment in expandedSegments) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) continue;

      final parsed = _parseSingleMedication(trimmed);
      if (parsed != null) {
        medications.add(parsed);
      }
    }

    return VoiceRecognitionResult(
      rawText: text,
      medications: medications,
      confidence: medications.isNotEmpty ? 0.8 : 0.0,
    );
  }

  /// 약 이름 기반으로 텍스트 분리
  static List<String> _splitByMedicationNames(String text) {
    // 텍스트에서 알려진 약 이름 위치 찾기
    final matches = <_MedMatch>[];

    for (final medName in _knownMedications) {
      final lowerText = text.toLowerCase();
      final lowerMed = medName.toLowerCase();
      int startIndex = 0;

      while (true) {
        final index = lowerText.indexOf(lowerMed, startIndex);
        if (index == -1) break;

        matches.add(_MedMatch(
          name: medName,
          start: index,
          end: index + medName.length,
        ));
        startIndex = index + 1;
      }
    }

    // 약 이름이 0~1개면 분리 불필요
    if (matches.length <= 1) {
      return [text];
    }

    // 위치순 정렬
    matches.sort((a, b) => a.start.compareTo(b.start));

    // 중복 제거 (긴 이름 우선: "큰 옥산" vs "옥산")
    final filteredMatches = <_MedMatch>[];
    for (final match in matches) {
      final overlaps = filteredMatches.any((m) =>
          (match.start >= m.start && match.start < m.end) ||
          (match.end > m.start && match.end <= m.end));
      if (!overlaps) {
        filteredMatches.add(match);
      }
    }

    // 1개 이하면 분리 불필요
    if (filteredMatches.length <= 1) {
      return [text];
    }

    // 약 이름 위치 기준으로 분리
    final result = <String>[];
    for (int i = 0; i < filteredMatches.length; i++) {
      final start = filteredMatches[i].start;
      final end = i < filteredMatches.length - 1
          ? filteredMatches[i + 1].start
          : text.length;
      final segment = text.substring(start, end).trim();
      if (segment.isNotEmpty) {
        result.add(segment);
      }
    }

    return result.isEmpty ? [text] : result;
  }

  /// 단일 약물 텍스트 파싱
  static ParsedMedication? _parseSingleMedication(String text) {
    if (text.isEmpty) return null;

    String name = '';
    MedicationType type = MedicationType.oral;
    int quantity = 1;
    String? timeText;
    TimeOfDay? time;
    DateTime? endDate;
    int durationDays = 1; // 기본값: 오늘 하루만

    // 약물 종류 감지 및 제거
    for (final entry in _typeKeywords.entries) {
      if (text.contains(entry.key)) {
        type = entry.value;
        text = text.replaceAll(entry.key, ' ').trim();
        break;
      }
    }

    // 개수 추출 (숫자 + 개/알/정)
    final quantityMatch = RegExp(r'(\d+)\s*(개|알|정|번)').firstMatch(text);
    if (quantityMatch != null) {
      quantity = int.tryParse(quantityMatch.group(1)!) ?? 1;
      text = text.replaceAll(quantityMatch.group(0)!, ' ').trim();
    }

    // 시간 추출
    final timeResult = _extractTime(text);
    if (timeResult != null) {
      time = timeResult.time;
      timeText = timeResult.text;
      text = text.replaceAll(timeResult.originalText, ' ').trim();
    }

    // 기간 추출 - 일주일/주/달/일 동안 패턴
    final durationResult = _extractDuration(text);
    if (durationResult != null) {
      durationDays = durationResult.days;
      text = text.replaceAll(durationResult.originalText, ' ').trim();
    }

    // 기간 추출 (예: "1월 4일까지")
    final dateMatch = RegExp(r'(\d+)월\s*(\d+)일\s*(까지)?').firstMatch(text);
    if (dateMatch != null) {
      final month = int.tryParse(dateMatch.group(1)!) ?? DateTime.now().month;
      final day = int.tryParse(dateMatch.group(2)!) ?? 1;
      var year = DateTime.now().year;

      // 파싱된 날짜가 현재보다 과거면 다음 해로 설정
      var parsedDate = DateTime(year, month, day);
      if (parsedDate.isBefore(DateTime.now())) {
        year += 1;
        parsedDate = DateTime(year, month, day);
      }
      endDate = parsedDate;
      text = text.replaceAll(dateMatch.group(0)!, ' ').trim();
    }

    // 남은 텍스트가 약 이름
    name = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (name.isEmpty) return null;

    // endDate가 설정되지 않았으면 durationDays로 계산
    final startDate = DateTime.now();
    endDate ??= startDate.add(Duration(days: durationDays - 1));

    return ParsedMedication(
      name: name,
      type: type,
      quantity: quantity,
      timeText: timeText,
      time: time,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 복용 기간 추출
  static _DurationResult? _extractDuration(String text) {
    // 일주일, 1주, 1주일
    final weekMatch = RegExp(r'(일주일|1주일?|한\s*주)\s*(동안)?').firstMatch(text);
    if (weekMatch != null) {
      return _DurationResult(days: 7, originalText: weekMatch.group(0)!);
    }

    // 2주, 2주일, 이주
    final twoWeekMatch = RegExp(r'(2주일?|이주|두\s*주)\s*(동안)?').firstMatch(text);
    if (twoWeekMatch != null) {
      return _DurationResult(days: 14, originalText: twoWeekMatch.group(0)!);
    }

    // 한달, 1달, 한 달
    final monthMatch = RegExp(r'(한\s*달|1달)\s*(동안)?').firstMatch(text);
    if (monthMatch != null) {
      return _DurationResult(days: 30, originalText: monthMatch.group(0)!);
    }

    // N일 동안 (숫자 + 일)
    final daysMatch = RegExp(r'(\d+)\s*일\s*(동안)?').firstMatch(text);
    if (daysMatch != null) {
      final days = int.tryParse(daysMatch.group(1)!) ?? 1;
      return _DurationResult(days: days, originalText: daysMatch.group(0)!);
    }

    return null;
  }

  /// 시간 추출
  static _TimeResult? _extractTime(String text) {
    // 구체적 시간 (아침 8시, 밤 10시 등)
    final specificTimeMatch =
        RegExp(r'(아침|점심|저녁|밤|새벽)?\s*(\d{1,2})\s*시\s*(\d{1,2})?\s*분?').firstMatch(text);
    if (specificTimeMatch != null) {
      int hour = int.tryParse(specificTimeMatch.group(2)!) ?? 8;
      int minute = int.tryParse(specificTimeMatch.group(3) ?? '0') ?? 0;

      // 문맥에 따라 오전/오후 결정
      final context = specificTimeMatch.group(1);
      if (context != null) {
        if ((context == '밤' || context == '저녁') && hour < 12) {
          hour += 12;
        }
      } else if (hour < 7 && hour != 0) {
        // 1~6시는 오후로 추정 (약 복용 시간 특성상)
        hour += 12;
      }

      final timeText = specificTimeMatch.group(0)!.trim();
      return _TimeResult(
        time: TimeOfDay(hour: hour, minute: minute),
        text: timeText,
        originalText: specificTimeMatch.group(0)!,
      );
    }

    // 키워드 시간 (아침, 점심 등) + 식후/식전
    for (final entry in _timeKeywords.entries) {
      if (text.contains(entry.key)) {
        var time = entry.value;
        String timeText = entry.key;

        // 식후/식전 처리
        for (final mealEntry in _mealModifiers.entries) {
          if (text.contains(mealEntry.key)) {
            final totalMinutes = time.hour * 60 + time.minute + mealEntry.value;
            time = TimeOfDay(
              hour: (totalMinutes ~/ 60) % 24,
              minute: totalMinutes % 60,
            );
            timeText += ' ${mealEntry.key}';
            break;
          }
        }

        return _TimeResult(
          time: time,
          text: timeText,
          originalText: timeText,
        );
      }
    }

    return null;
  }
}

class _TimeResult {
  final TimeOfDay time;
  final String text;
  final String originalText;

  _TimeResult({
    required this.time,
    required this.text,
    required this.originalText,
  });
}

class _DurationResult {
  final int days;
  final String originalText;

  _DurationResult({
    required this.days,
    required this.originalText,
  });
}

/// 약 이름 매치 정보
class _MedMatch {
  final String name;
  final int start;
  final int end;

  _MedMatch({
    required this.name,
    required this.start,
    required this.end,
  });
}
