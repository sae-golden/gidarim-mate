import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../models/medication.dart';
import '../services/medication_api_service.dart';
import '../models/medication_info.dart';
import '../services/ivf_medication_matcher.dart';
import 'medication_detail_screen.dart';
import 'quick_add_medication_screen.dart';
import 'voice_input_screen.dart';

/// 약물 추가 화면
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '약 추가',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _buildInputMethodSelection(),
    );
  }

  Widget _buildInputMethodSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '약물 일정을 어떻게\n추가할까요?',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: AppSpacing.l),

          _buildInputMethodCard(
            icon: Icons.camera_alt_outlined,
            title: '처방전 사진 찍기',
            subtitle: '가장 빠른 방법',
            color: AppColors.primaryPurple,
            onTap: () async {
              final result = await Navigator.push<Medication>(
                context,
                MaterialPageRoute(
                  builder: (context) => const OcrInputScreen(),
                ),
              );
              if (result != null && mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s),

          _buildInputMethodCard(
            icon: Icons.mic_outlined,
            title: '음성으로 말하기',
            subtitle: '여러 약 한번에 입력 가능',
            color: AppColors.info,
            onTap: () async {
              final result = await Navigator.push<dynamic>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImprovedVoiceInputScreen(),
                ),
              );
              if (result != null && mounted) {
                // 단일 약물 또는 리스트 모두 처리
                if (result is List<Medication>) {
                  Navigator.pop(context, result.isNotEmpty ? result.first : null);
                } else if (result is Medication) {
                  Navigator.pop(context, result);
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.s),

          _buildInputMethodCard(
            icon: Icons.text_fields,
            title: '텍스트로 입력',
            subtitle: '복붙도 가능',
            color: AppColors.success,
            onTap: () async {
              final result = await Navigator.push<Medication>(
                context,
                MaterialPageRoute(
                  builder: (context) => const TextInputScreen(),
                ),
              );
              if (result != null && mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s),

          _buildInputMethodCard(
            icon: Icons.edit_outlined,
            title: '직접 입력',
            subtitle: '간편한 한 페이지 입력',
            color: AppColors.warning,
            isRecommended: true,
            onTap: () async {
              final result = await Navigator.push<Medication>(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuickAddMedicationScreen(),
                ),
              );
              if (result != null && mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isRecommended = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Color.fromRGBO(color.red, color.green, color.blue, 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      if (isRecommended) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '추천',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 텍스트 입력 화면
// =============================================================================
class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final _textController = TextEditingController();
  final _textFieldKey = GlobalKey(); // 키보드 가림 방지용
  final _focusNode = FocusNode();
  List<ParsedMedication> _parsedMedications = [];
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      // 키보드가 올라올 때 입력 필드가 보이도록 스크롤
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _textFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _textFieldKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true, // 키보드 출력 시 화면 자동 조절
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '텍스트로 입력',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('처방 내용을 입력하세요', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '복사 붙여넣기도 가능해요',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 입력 필드
                  Container(
                    key: _textFieldKey, // 키보드 가림 방지용
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: '예시:\n• FSH 225IU 매일 아침 8시\n• 아스피린 100mg 매일 저녁 식후\n• HCG 주사 1월 15일 밤 10시',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: AppColors.textDisabled,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(AppSpacing.m),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // 분석 버튼
                  AppButton(
                    text: _isParsing ? '분석 중...' : '텍스트 분석하기',
                    onPressed: _textController.text.trim().isNotEmpty && !_isParsing
                        ? _parseText
                        : null,
                  ),

                  // 분석 결과
                  if (_parsedMedications.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      '인식된 약물 (${_parsedMedications.length}개)',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    ..._parsedMedications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value;
                      return _buildParsedMedicationCard(med, index);
                    }),
                  ],
                ],
              ),
            ),
          ),

          // 하단 버튼
          if (_parsedMedications.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: AppButton(
                  text: '${_parsedMedications.length}개 약물 추가하기',
                  onPressed: _saveMedications,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _parseText() {
    setState(() {
      _isParsing = true;
      _parsedMedications = [];
    });

    // 텍스트 파싱 로직
    Future.delayed(const Duration(milliseconds: 500), () {
      final text = _textController.text;
      final parsed = _parseMedicationText(text);

      setState(() {
        _parsedMedications = parsed;
        _isParsing = false;
      });

      if (parsed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('약물 정보를 인식하지 못했습니다. 다시 입력해주세요.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  List<ParsedMedication> _parseMedicationText(String text) {
    final List<ParsedMedication> results = [];

    // 줄 단위로 분리
    final lines = text.split(RegExp(r'[\n•·\-]+')).where((l) => l.trim().isNotEmpty);

    // 약물명 패턴 (한글/영문)
    final medicationNames = [
      'FSH', 'HCG', 'GnRH', 'LH',
      '아스피린', '메트포르민', '엽산', '프로게스테론', '에스트라디올',
      '클로미펜', '레트로졸', '고나도트로핀', '세트로타이드',
    ];

    // 시간 패턴
    final timePattern = RegExp(r'(\d{1,2})\s*[시:]?\s*(\d{0,2})?');
    final periodPattern = RegExp(r'(아침|점심|저녁|밤|오전|오후)');
    final dosagePattern = RegExp(r'(\d+\.?\d*)\s*(mg|IU|iu|정|알|캡슐|ml|ML)?', caseSensitive: false);

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      String? foundName;
      MedicationType type = MedicationType.oral;
      String? dosage;
      String time = '08:00';

      // 약물명 찾기
      for (final name in medicationNames) {
        if (trimmedLine.toUpperCase().contains(name.toUpperCase())) {
          foundName = name;
          // 주사 여부 판단
          if (['FSH', 'HCG', 'GnRH', 'LH', '프로게스테론', '고나도트로핀', '세트로타이드'].contains(name) ||
              trimmedLine.contains('주사')) {
            type = MedicationType.injection;
          }
          break;
        }
      }

      // 약물명이 없으면 첫 단어를 약물명으로 사용
      if (foundName == null) {
        final words = trimmedLine.split(RegExp(r'\s+'));
        if (words.isNotEmpty) {
          foundName = words.first;
          if (trimmedLine.contains('주사')) {
            type = MedicationType.injection;
          }
        }
      }

      if (foundName == null) continue;

      // 용량 찾기
      final dosageMatch = dosagePattern.firstMatch(trimmedLine);
      if (dosageMatch != null) {
        dosage = '${dosageMatch.group(1)}${dosageMatch.group(2) ?? 'mg'}';
      }

      // 시간 찾기
      final periodMatch = periodPattern.firstMatch(trimmedLine);
      final timeMatch = timePattern.firstMatch(trimmedLine);

      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        int minute = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;

        // 오후/저녁/밤이면 12시간 추가
        if (periodMatch != null) {
          final period = periodMatch.group(1)!;
          if (['오후', '저녁', '밤'].contains(period) && hour < 12) {
            hour += 12;
          }
          if (period == '아침' && hour > 12) {
            hour -= 12;
          }
        }

        time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      } else if (periodMatch != null) {
        // 시간 숫자가 없으면 기본 시간 설정
        final period = periodMatch.group(1)!;
        time = switch (period) {
          '아침' || '오전' => '08:00',
          '점심' => '12:00',
          '저녁' => '18:00',
          '밤' => '21:00',
          '오후' => '14:00',
          _ => '08:00',
        };
      }

      results.add(ParsedMedication(
        name: foundName,
        type: type,
        dosage: dosage,
        time: time,
        pattern: '매일',
      ));
    }

    return results;
  }

  Widget _buildParsedMedicationCard(ParsedMedication med, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: med.type == MedicationType.injection
                  ? AppColors.primaryPurpleLight
                  : const Color.fromRGBO(76, 175, 80, 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              med.type == MedicationType.injection ? Icons.vaccines : Icons.medication,
              color: med.type == MedicationType.injection
                  ? AppColors.primaryPurple
                  : Colors.green[700],
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                Text(
                  '${med.dosage ?? ''} ${med.pattern} ${med.time}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
            onPressed: () {
              setState(() {
                _parsedMedications.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  void _saveMedications() {
    if (_parsedMedications.isEmpty) return;

    // 첫 번째 약물만 반환 (여러 개일 경우 나중에 처리)
    final first = _parsedMedications.first;
    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: first.name,
      dosage: first.dosage,
      time: first.time,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 14)),
      type: first.type,
      pattern: first.pattern,
      totalCount: 14,
    );

    Navigator.pop(context, medication);
  }
}

class ParsedMedication {
  final String name;
  final MedicationType type;
  final String? dosage;
  final String time;
  final String pattern;

  ParsedMedication({
    required this.name,
    required this.type,
    this.dosage,
    required this.time,
    required this.pattern,
  });
}

// =============================================================================
// 음성 입력 화면
// =============================================================================
class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String _recognizedText = '';

  // IVF 약물 매칭 결과
  MatchResult? _matchedMedication;
  List<MatchResult> _suggestions = [];

  // 파싱된 정보
  String? _parsedDosage;
  DateTime _parsedDate = DateTime.now();
  TimeOfDay _parsedTime = const TimeOfDay(hour: 8, minute: 0);
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    if (_isInitializing) return;

    if (mounted) {
      setState(() {
        _isInitializing = true;
      });
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            if (_recognizedText.isNotEmpty) {
              _parseVoiceInput();
            }
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('음성 인식 오류: ${error.errorMsg}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );

      if (!mounted) return;
      setState(() {
        _isInitialized = available;
        _isInitializing = false;
      });

      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  void _startListening() async {
    if (!_isInitialized) {
      await _initSpeech();
      if (!_isInitialized) return;
    }

    if (!mounted) return;
    setState(() {
      _recognizedText = '';
      _matchedMedication = null;
      _suggestions = [];
      _quantity = 1;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      localeId: 'ko_KR',
      listenMode: stt.ListenMode.dictation,
    );

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
    });

    if (_recognizedText.isNotEmpty) {
      _parseVoiceInput();
    }
  }

  void _parseVoiceInput() {
    final text = _recognizedText;

    // 1. IVF 약물 사전에서 매칭 (음성인식 오류 자동 보정)
    final bestMatch = IvfMedicationMatcher.matchMedication(text);
    final suggestions = IvfMedicationMatcher.getSuggestions(text, limit: 3);

    // 2. 날짜 파싱 (내일, 모레, 다음주 등)
    final parsedDate = _parseDateFromText(text);

    // 3. 시간 파싱
    final parsedTime = _parseTimeFromText(text);

    // 4. 수량 파싱
    final quantity = _parseQuantityFromText(text);

    // 5. 용량 파싱 (mg, IU 등)
    final dosage = _parseDosageFromText(text);

    setState(() {
      _matchedMedication = bestMatch;
      _suggestions = suggestions;
      _parsedDate = parsedDate;
      _parsedTime = parsedTime;
      _quantity = quantity;
      _parsedDosage = dosage;
    });
  }

  /// 날짜 파싱 (오늘, 내일, 모레, 다음주, 특정 날짜)
  DateTime _parseDateFromText(String text) {
    final now = DateTime.now();

    // "내일" 패턴
    if (text.contains('내일')) {
      return now.add(const Duration(days: 1));
    }

    // "모레" 패턴
    if (text.contains('모레') || text.contains('모래')) {
      return now.add(const Duration(days: 2));
    }

    // "글피" 패턴
    if (text.contains('글피')) {
      return now.add(const Duration(days: 3));
    }

    // "다음주" 패턴
    if (text.contains('다음주') || text.contains('다음 주')) {
      return now.add(const Duration(days: 7));
    }

    // "n월 n일" 패턴
    final dateMatch = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일').firstMatch(text);
    if (dateMatch != null) {
      final month = int.parse(dateMatch.group(1)!);
      final day = int.parse(dateMatch.group(2)!);
      var year = now.year;
      // 이미 지난 날짜면 다음 해로
      if (month < now.month || (month == now.month && day < now.day)) {
        year++;
      }
      return DateTime(year, month, day);
    }

    // "n일" 패턴 (이번 달)
    final dayMatch = RegExp(r'(\d{1,2})\s*일').firstMatch(text);
    if (dayMatch != null) {
      final day = int.parse(dayMatch.group(1)!);
      if (day >= 1 && day <= 31) {
        var month = now.month;
        var year = now.year;
        if (day < now.day) {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return DateTime(year, month, day);
      }
    }

    // 기본: 오늘
    return now;
  }

  /// 시간 파싱
  TimeOfDay _parseTimeFromText(String text) {
    // "n시 n분" 또는 "n시 반" 패턴
    final timeMatch = RegExp(r'(\d{1,2})\s*시\s*(반|(\d{1,2})\s*분)?').firstMatch(text);
    final periodMatch = RegExp(r'(아침|점심|저녁|밤|오전|오후)').firstMatch(text);

    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = 0;

      // "반" = 30분
      if (timeMatch.group(2) == '반') {
        minute = 30;
      } else if (timeMatch.group(3) != null) {
        minute = int.parse(timeMatch.group(3)!);
      }

      // 오후/저녁/밤이면 12시간 추가
      if (periodMatch != null) {
        final period = periodMatch.group(1)!;
        if (['오후', '저녁', '밤'].contains(period) && hour < 12) {
          hour += 12;
        }
        if (['아침', '오전'].contains(period) && hour == 12) {
          hour = 0;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    }

    // 시간대만 있는 경우
    if (periodMatch != null) {
      final period = periodMatch.group(1)!;
      return switch (period) {
        '아침' || '오전' => const TimeOfDay(hour: 8, minute: 0),
        '점심' => const TimeOfDay(hour: 12, minute: 0),
        '저녁' => const TimeOfDay(hour: 18, minute: 0),
        '밤' => const TimeOfDay(hour: 21, minute: 0),
        '오후' => const TimeOfDay(hour: 14, minute: 0),
        _ => const TimeOfDay(hour: 8, minute: 0),
      };
    }

    return const TimeOfDay(hour: 8, minute: 0);
  }

  /// 수량 파싱
  int _parseQuantityFromText(String text) {
    // "n대", "n알", "n개", "n장" 패턴
    final quantityMatch = RegExp(r'(\d+)\s*(대|알|개|장)').firstMatch(text);
    if (quantityMatch != null) {
      return int.parse(quantityMatch.group(1)!);
    }

    // 한글 숫자
    final koreanNumbers = {
      '한': 1, '두': 2, '세': 3, '네': 4, '다섯': 5,
      '여섯': 6, '일곱': 7, '여덟': 8, '아홉': 9, '열': 10,
    };

    for (final entry in koreanNumbers.entries) {
      if (text.contains('${entry.key} 대') ||
          text.contains('${entry.key} 알') ||
          text.contains('${entry.key} 개') ||
          text.contains('${entry.key} 장') ||
          text.contains('${entry.key}대') ||
          text.contains('${entry.key}알') ||
          text.contains('${entry.key}개') ||
          text.contains('${entry.key}장')) {
        return entry.value;
      }
    }

    return 1;
  }

  /// 용량 파싱 (mg, IU 등)
  String? _parseDosageFromText(String text) {
    final dosageMatch = RegExp(r'(\d+)\s*(밀리그램|mg|MG|IU|iu|아이유|단위)').firstMatch(text);
    if (dosageMatch != null) {
      final num = dosageMatch.group(1)!;
      var unit = dosageMatch.group(2)!;
      unit = unit.replaceAll('밀리그램', 'mg')
                 .replaceAll('아이유', 'IU')
                 .replaceAll('단위', 'IU')
                 .toUpperCase();
      return '$num$unit';
    }
    return null;
  }

  /// 파싱된 결과를 수정 가능한 폼으로 표시
  Widget _buildParsedResultForm() {
    final medication = _matchedMedication?.medication;
    final formType = medication?.type ?? MedicationFormType.injection;

    // 날짜 표시 형식
    final now = DateTime.now();
    String dateDisplay;
    if (_parsedDate.year == now.year &&
        _parsedDate.month == now.month &&
        _parsedDate.day == now.day) {
      dateDisplay = '오늘 ${_parsedDate.month}/${_parsedDate.day}';
    } else if (_parsedDate.difference(now).inDays == 1 ||
        (_parsedDate.day == now.day + 1 && _parsedDate.month == now.month)) {
      dateDisplay = '내일 ${_parsedDate.month}/${_parsedDate.day}';
    } else {
      dateDisplay = '${_parsedDate.month}/${_parsedDate.day}';
    }

    // 시간 표시 형식
    final hour = _parsedTime.hour;
    final minute = _parsedTime.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeDisplay = '$period $displayHour:${minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '인식 완료!',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              if (_matchedMedication != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _matchedMedication!.confidencePercent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 약 이름 (드롭다운)
          _buildFormRow(
            icon: '💊',
            label: '약 이름',
            child: _buildMedicationDropdown(),
          ),
          const SizedBox(height: AppSpacing.s),

          // 종류
          _buildFormRow(
            icon: formType.icon,
            label: '종류',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formType.displayName,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // 수량
          _buildFormRow(
            icon: '🔢',
            label: '수량',
            child: _buildQuantityStepper(formType),
          ),
          const SizedBox(height: AppSpacing.s),

          // 날짜
          _buildFormRow(
            icon: '📅',
            label: '날짜',
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dateDisplay,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // 시간
          _buildFormRow(
            icon: '⏰',
            label: '시간',
            child: GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeDisplay,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.body),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildMedicationDropdown() {
    final selectedName = _matchedMedication?.medication.name ?? '약물 선택';

    return GestureDetector(
      onTap: () => _showMedicationPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryPurple),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedName,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _matchedMedication != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.primaryPurple),
            const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          ],
        ),
      ),
    );
  }

  void _showMedicationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('약물 선택', style: AppTextStyles.h3),
            ),

            // 추천 약물 목록
            if (_suggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                child: Row(
                  children: [
                    Text(
                      '🎯 추천 약물',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                children: [
                  // 추천 약물
                  ..._suggestions.map((match) => _buildMedicationTile(
                    match.medication,
                    isRecommended: true,
                    confidence: match.confidencePercent,
                  )),

                  if (_suggestions.isNotEmpty)
                    const Divider(height: 24),

                  // 전체 IVF 약물 목록
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: Text(
                      '📋 전체 IVF 약물',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...IvfMedicationMatcher.getAllMedications()
                      .where((m) => !_suggestions.any((s) => s.medication.name == m.name))
                      .map((med) => _buildMedicationTile(med)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationTile(IvfMedicationData medication, {
    bool isRecommended = false,
    String? confidence,
  }) {
    final isSelected = _matchedMedication?.medication.name == medication.name;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple
              : AppColors.primaryPurpleLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            medication.type.icon,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            medication.name,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primaryPurple : AppColors.textPrimary,
            ),
          ),
          if (isRecommended && confidence != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                confidence,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${medication.category} · ${medication.type.displayName}',
        style: AppTextStyles.caption,
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryPurple)
          : null,
      onTap: () {
        setState(() {
          _matchedMedication = MatchResult(
            medication: medication,
            confidence: 1.0,
            matchedAlias: medication.name,
          );
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildQuantityStepper(MedicationFormType formType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            color: _quantity > 1 ? AppColors.primaryPurple : AppColors.textDisabled,
            onPressed: _quantity > 1
                ? () => setState(() => _quantity--)
                : null,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 50),
            child: Text(
              '$_quantity ${formType.unit}',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.primaryPurple,
            onPressed: () => setState(() => _quantity++),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _parsedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _parsedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _parsedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _parsedTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '음성으로 입력',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // 마이크 버튼
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isListening ? 140 : 120,
                      height: _isListening ? 140 : 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? AppColors.error
                            : AppColors.primaryPurple,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? AppColors.error : AppColors.primaryPurple)
                                .withAlpha(77),
                            blurRadius: _isListening ? 30 : 20,
                            spreadRadius: _isListening ? 10 : 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  Text(
                    _isListening
                        ? '듣고 있어요...\n탭하여 중지'
                        : '탭하여 음성 입력 시작',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // 예시
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: AppColors.primaryPurple, size: 20),
                            SizedBox(width: AppSpacing.xs),
                            Text('이렇게 말해보세요',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPurple,
                                )),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          '"매일 아침 8시 FSH 주사 225IU"\n'
                          '"아스피린 100mg 저녁 식후"\n'
                          '"밤 10시 HCG 주사"',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 인식된 텍스트
                  if (_recognizedText.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mic, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('인식된 내용', style: AppTextStyles.caption),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _recognizedText,
                            style: AppTextStyles.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 파싱 결과 - 수정 가능한 폼
                  if (_matchedMedication != null || _suggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.m),
                    _buildParsedResultForm(),
                  ],
                ],
              ),
            ),
          ),

          // 하단 버튼
          if (_matchedMedication != null || _suggestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: '다시 녹음',
                        type: AppButtonType.secondary,
                        onPressed: () {
                          setState(() {
                            _recognizedText = '';
                            _matchedMedication = null;
                            _suggestions = [];
                            _quantity = 1;
                          });
                          _startListening();
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: AppButton(
                        text: '추가하기',
                        onPressed: _matchedMedication != null ? _saveMedication : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _saveMedication() {
    if (_matchedMedication == null) return;

    final med = _matchedMedication!.medication;

    // MedicationFormType을 MedicationType으로 변환
    final medicationType = med.type == MedicationFormType.injection
        ? MedicationType.injection
        : MedicationType.oral;

    // 용량 텍스트 생성
    final dosageText = _parsedDosage ?? '$_quantity ${med.type.unit}';

    // 시간 문자열
    final timeString = '${_parsedTime.hour.toString().padLeft(2, '0')}:${_parsedTime.minute.toString().padLeft(2, '0')}';

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: med.name,
      dosage: dosageText,
      time: timeString,
      startDate: _parsedDate,
      endDate: _parsedDate.add(const Duration(days: 14)),
      type: medicationType,
      pattern: '매일',
      totalCount: 14,
    );

    Navigator.pop(context, medication);
  }
}

// =============================================================================
// OCR 입력 화면
// =============================================================================
class OcrInputScreen extends StatefulWidget {
  const OcrInputScreen({super.key});

  @override
  State<OcrInputScreen> createState() => _OcrInputScreenState();
}

class _OcrInputScreenState extends State<OcrInputScreen> {
  File? _imageFile;
  String? _webImagePath;
  bool _isProcessing = false;
  String _recognizedText = '';
  List<ParsedMedication> _parsedMedications = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isProcessing = true;
          if (kIsWeb) {
            _webImagePath = image.path;
          } else {
            _imageFile = File(image.path);
          }
        });

        await _processImage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 실패: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _processImage(XFile image) async {
    try {
      // 웹에서는 ML Kit이 작동하지 않으므로 시뮬레이션
      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 2));

        // 시뮬레이션된 OCR 결과
        setState(() {
          _recognizedText = '처방전 시뮬레이션:\nFSH 225IU 매일 아침 8시\n아스피린 100mg 저녁 식후';
          _parsedMedications = [
            ParsedMedication(
              name: 'FSH',
              type: MedicationType.injection,
              dosage: '225IU',
              time: '08:00',
              pattern: '매일',
            ),
            ParsedMedication(
              name: '아스피린',
              type: MedicationType.oral,
              dosage: '100mg',
              time: '18:00',
              pattern: '매일',
            ),
          ];
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('웹에서는 OCR 시뮬레이션이 표시됩니다.'),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // 모바일에서 ML Kit 사용
      // Note: google_mlkit_text_recognition 패키지가 필요합니다
      // 실제 구현은 패키지 import 후 진행

      // 시뮬레이션 (실제 앱에서는 아래 주석 해제)
      /*
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      */

      // 시뮬레이션
      await Future.delayed(const Duration(seconds: 2));
      const fullText = 'FSH 225IU 매일 아침 8시\n아스피린 100mg 저녁';

      setState(() {
        _recognizedText = fullText;
        _parsedMedications = _parseOcrText(fullText);
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('텍스트 인식 실패: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<ParsedMedication> _parseOcrText(String text) {
    final List<ParsedMedication> results = [];
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);

    final medicationNames = [
      'FSH', 'HCG', 'GnRH', 'LH',
      '아스피린', '메트포르민', '엽산', '프로게스테론', '에스트라디올',
    ];

    for (final line in lines) {
      String? foundName;
      MedicationType type = MedicationType.oral;
      String? dosage;
      String time = '08:00';

      for (final name in medicationNames) {
        if (line.toUpperCase().contains(name.toUpperCase())) {
          foundName = name;
          if (['FSH', 'HCG', 'GnRH', 'LH', '프로게스테론'].contains(name) ||
              line.contains('주사')) {
            type = MedicationType.injection;
          }
          break;
        }
      }

      if (foundName == null) continue;

      final dosageMatch = RegExp(r'(\d+\.?\d*)\s*(mg|IU|정)?', caseSensitive: false).firstMatch(line);
      if (dosageMatch != null) {
        dosage = '${dosageMatch.group(1)}${dosageMatch.group(2) ?? 'mg'}';
      }

      final timeMatch = RegExp(r'(\d{1,2})\s*[시:]').firstMatch(line);
      final periodMatch = RegExp(r'(아침|점심|저녁|밤|오전|오후)').firstMatch(line);

      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        if (periodMatch != null && ['오후', '저녁', '밤'].contains(periodMatch.group(1)) && hour < 12) {
          hour += 12;
        }
        time = '${hour.toString().padLeft(2, '0')}:00';
      } else if (periodMatch != null) {
        time = switch (periodMatch.group(1)!) {
          '아침' || '오전' => '08:00',
          '점심' => '12:00',
          '저녁' => '18:00',
          '밤' => '21:00',
          '오후' => '14:00',
          _ => '08:00',
        };
      }

      results.add(ParsedMedication(
        name: foundName,
        type: type,
        dosage: dosage,
        time: time,
        pattern: '매일',
      ));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '처방전 촬영',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('처방전을 촬영해주세요', style: AppTextStyles.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '약물 정보를 자동으로 인식합니다',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 이미지 미리보기 또는 카메라 버튼
                  if (_imageFile != null || _webImagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (kIsWeb && _webImagePath != null)
                            Image.network(
                              _webImagePath!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 250,
                                  color: AppColors.border,
                                  child: const Center(
                                    child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
                                  ),
                                );
                              },
                            )
                          else if (_imageFile != null)
                            Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          if (_isProcessing)
                            Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                    SizedBox(height: AppSpacing.m),
                                    Text(
                                      '텍스트 인식 중...',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppButton(
                      text: '다시 촬영',
                      type: AppButtonType.secondary,
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                          _webImagePath = null;
                          _recognizedText = '';
                          _parsedMedications = [];
                        });
                      },
                    ),
                  ] else ...[
                    // 카메라/갤러리 버튼
                    Row(
                      children: [
                        Expanded(
                          child: _buildImageSourceButton(
                            icon: Icons.camera_alt,
                            label: '카메라',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: _buildImageSourceButton(
                            icon: Icons.photo_library,
                            label: '갤러리',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // 팁
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurpleLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tips_and_updates,
                                  color: AppColors.primaryPurple, size: 20),
                              SizedBox(width: AppSpacing.xs),
                              Text('촬영 팁',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryPurple,
                                  )),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            '• 처방전을 평평한 곳에 놓아주세요\n'
                            '• 글씨가 잘 보이도록 밝은 곳에서 촬영해주세요\n'
                            '• 약물명과 용량이 포함되도록 촬영해주세요',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryPurple,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 인식 결과
                  if (_recognizedText.isNotEmpty && !_isProcessing) ...[
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      '인식된 텍스트',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(_recognizedText, style: AppTextStyles.body),
                    ),
                  ],

                  // 파싱 결과
                  if (_parsedMedications.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      '인식된 약물 (${_parsedMedications.length}개)',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    ..._parsedMedications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s),
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: med.type == MedicationType.injection
                                    ? AppColors.primaryPurpleLight
                                    : const Color.fromRGBO(76, 175, 80, 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                med.type == MedicationType.injection
                                    ? Icons.vaccines
                                    : Icons.medication,
                                color: med.type == MedicationType.injection
                                    ? AppColors.primaryPurple
                                    : Colors.green[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(med.name, style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                                  Text(
                                    '${med.dosage ?? ''} ${med.pattern} ${med.time}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              color: AppColors.textSecondary,
                              onPressed: () {
                                setState(() {
                                  _parsedMedications.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // 하단 버튼
          if (_parsedMedications.isNotEmpty && !_isProcessing)
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: AppButton(
                  text: '${_parsedMedications.length}개 약물 추가하기',
                  onPressed: _saveMedications,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryPurpleLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 32),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMedications() {
    if (_parsedMedications.isEmpty) return;

    final first = _parsedMedications.first;
    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: first.name,
      dosage: first.dosage,
      time: first.time,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 14)),
      type: first.type,
      pattern: first.pattern,
      totalCount: 14,
    );

    Navigator.pop(context, medication);
  }
}

// =============================================================================
// 직접 입력 화면
// =============================================================================
class ManualMedicationInputScreen extends StatefulWidget {
  const ManualMedicationInputScreen({super.key});

  @override
  State<ManualMedicationInputScreen> createState() =>
      _ManualMedicationInputScreenState();
}

class _ManualMedicationInputScreenState
    extends State<ManualMedicationInputScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  // 약물 형태 (주사, 알약, 질정, 패치)
  MedicationFormType _formType = MedicationFormType.injection;
  int _quantity = 1; // 수량 (대, 알, 개, 장)

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _pattern = '매일';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));

  int _currentStep = 0;

  // IVF 약물 사전 기반 자동완성
  List<IvfMedicationData> _ivfSuggestions = [];
  List<MedicationSearchResult> _apiResults = [];
  bool _showSuggestions = false;
  IvfMedicationData? _selectedIvfMedication;
  MedicationSearchResult? _selectedApiMedication;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _nameFocusNode.addListener(_onFocusChanged);
  }

  void _onNameChanged() {
    final query = _nameController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _ivfSuggestions = [];
        _apiResults = [];
        _showSuggestions = false;
      });
      return;
    }

    // IVF 사전 + API 검색 실행
    _searchMedications(query);
  }

  void _onFocusChanged() {
    if (!_nameFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_nameFocusNode.hasFocus) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  Future<void> _searchMedications(String query) async {
    // 1. IVF 사전에서 먼저 검색 (음성인식 오류 보정 포함)
    final ivfMatches = IvfMedicationMatcher.getSuggestions(query, limit: 3);

    // 2. 공공데이터 API에서도 검색
    final apiResults = await MedicationApiService.searchMedications(
      itemName: query,
      numOfRows: 3,
    );

    if (mounted) {
      setState(() {
        _ivfSuggestions = ivfMatches.map((m) => m.medication).toList();
        _apiResults = apiResults;
        _showSuggestions = _ivfSuggestions.isNotEmpty || apiResults.isNotEmpty;
      });
    }
  }

  void _selectIvfMedication(IvfMedicationData medication) {
    setState(() {
      _nameController.text = medication.name;
      _selectedIvfMedication = medication;
      _selectedApiMedication = null;
      _showSuggestions = false;
      _formType = medication.type;
    });
    _nameFocusNode.unfocus();
  }

  void _selectApiMedication(MedicationSearchResult medication) {
    setState(() {
      _nameController.text = medication.itemName;
      _selectedApiMedication = medication;
      _selectedIvfMedication = null;
      _showSuggestions = false;

      // API 약물 타입 추정
      final name = medication.itemName.toLowerCase();
      if (name.contains('주') || name.contains('펜')) {
        _formType = MedicationFormType.injection;
      } else if (name.contains('질정') || name.contains('크리논') || name.contains('루티너스')) {
        _formType = MedicationFormType.vaginal;
      } else if (name.contains('패치')) {
        _formType = MedicationFormType.patch;
      } else {
        _formType = MedicationFormType.oral;
      }
    });
    _nameFocusNode.unfocus();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _nameFocusNode.removeListener(_onFocusChanged);
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _getStepTitle(),
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '약물 정보';
      case 1:
        return '복용 시간';
      case 2:
        return '복용 기간';
      case 3:
        return '확인';
      default:
        return '약물 추가';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryPurple : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_currentStep + 1}/4 단계',
            style: AppTextStyles.caption.copyWith(color: AppColors.primaryPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1MedicationInfo();
      case 1:
        return _buildStep2TimePattern();
      case 2:
        return _buildStep3Period();
      case 3:
        return _buildStep4Confirmation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1MedicationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('어떤 약물인가요?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.l),

        // 약물명 입력
        Row(
          children: [
            Text('💊 약 이름', style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const Spacer(),
            if (_selectedApiMedication != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicationDetailScreen(
                        itemSeq: _selectedApiMedication!.itemSeq,
                        itemName: _selectedApiMedication!.itemName,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.primaryPurple),
                    const SizedBox(width: 4),
                    Text(
                      '약물 정보',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // 자동완성 입력 필드
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(
                hintText: '"크녹산", "듀파스톤" 등 입력',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
                filled: true,
                fillColor: AppColors.cardBackground,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          _nameController.clear();
                          setState(() {
                            _selectedIvfMedication = null;
                            _selectedApiMedication = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.m),
              ),
            ),

            // 자동완성 추천 목록
            if (_showSuggestions)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    // IVF 사전 결과 (우선 표시)
                    if (_ivfSuggestions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(
                          '🏥 IVF 자주 사용 약물',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                      ..._ivfSuggestions.map((med) => ListTile(
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurpleLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(med.type.icon, style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        title: Text(
                          med.name,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${med.category} · ${med.type.displayName}',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '추천',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () => _selectIvfMedication(med),
                      )),
                    ],

                    // API 결과
                    if (_apiResults.isNotEmpty) ...[
                      if (_ivfSuggestions.isNotEmpty)
                        const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(
                          '📋 식약처 의약품 DB',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ..._apiResults.map((med) => ListTile(
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          med.itemName,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          med.entpName,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectApiMedication(med),
                      )),
                    ],
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),

        // 약물 종류 선택
        Text('💉 종류', style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: MedicationFormType.values.map((type) {
            final isSelected = _formType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _formType = type),
                child: Container(
                  margin: EdgeInsets.only(
                    right: type != MedicationFormType.patch ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurpleLight : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryPurple : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(type.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        type.displayName,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.l),

        // 수량 입력 (스테퍼)
        Row(
          children: [
            Text('🔢 수량', style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    color: _quantity > 1 ? AppColors.primaryPurple : AppColors.textDisabled,
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '$_quantity ${_formType.unit}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: AppColors.primaryPurple,
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),

        // 자주 사용하는 약물 (카테고리별)
        Text('자주 사용하는 약물', style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: AppSpacing.s),
        _buildQuickSelectCategory(),
      ],
    );
  }

  Widget _buildQuickSelectCategory() {
    final categories = IvfMedicationMatcher.getMedicationsByCategory();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.entries.take(3).map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: entry.value.take(4).map((med) {
              return GestureDetector(
                onTap: () => _selectIvfMedication(med),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(med.type.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        med.name,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildStep2TimePattern() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('언제 복용하나요?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.l),

        Text('복용 시간', style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: AppSpacing.s),
        GestureDetector(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryPurple,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (time != null) {
              setState(() => _selectedTime = time);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time, color: AppColors.primaryPurple),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('선택된 시간', style: AppTextStyles.caption),
                      Text(
                        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        style: AppTextStyles.h3,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),

        Text('복용 패턴', style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: AppSpacing.s),
        ..._buildPatternOptions(),
      ],
    );
  }

  List<Widget> _buildPatternOptions() {
    final patterns = ['매일', '격일 (하루 걸러)', '월수금', '화목토'];
    return patterns.map((pattern) {
      final patternKey = pattern.split(' ')[0];
      final isSelected = _pattern == patternKey;
      return GestureDetector(
        onTap: () => setState(() => _pattern = patternKey),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurpleLight : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryPurple : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: AppSpacing.m),
              Text(
                pattern,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStep3Period() {
    final duration = _endDate.difference(_startDate).inDays + 1;
    final totalCount = _calculateTotalCount(duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('언제까지 복용하나요?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.l),

        Text('시작일', style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: AppSpacing.s),
        _buildDateSelector(
          date: _startDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryPurple,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _startDate = date;
                if (_endDate.isBefore(_startDate)) {
                  _endDate = _startDate.add(const Duration(days: 14));
                }
              });
            }
          },
        ),
        const SizedBox(height: AppSpacing.m),

        Text('종료일', style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: AppSpacing.s),
        _buildDateSelector(
          date: _endDate,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _endDate,
              firstDate: _startDate,
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primaryPurple,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _endDate = date);
            }
          },
        ),
        const SizedBox(height: AppSpacing.l),

        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.primaryPurpleLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSummaryRow('기간', '$duration일'),
              const SizedBox(height: AppSpacing.xs),
              _buildSummaryRow('패턴', _pattern),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('총 횟수', style: AppTextStyles.body),
                  Text(
                    '$totalCount회',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDateSelector({
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today, color: AppColors.primaryPurple),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                '${date.year}년 ${date.month}월 ${date.day}일',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Confirmation() {
    final duration = _endDate.difference(_startDate).inDays + 1;
    final totalCount = _calculateTotalCount(duration);
    final dosageText = '$_quantity ${_formType.unit}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('입력 정보를 확인해주세요', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.l),

        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(_formType.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text,
                          style: AppTextStyles.h3,
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formType.displayName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dosageText,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.l),
              _buildConfirmationRow(
                '📅',
                '기간',
                '${_startDate.month}/${_startDate.day} ~ ${_endDate.month}/${_endDate.day}',
              ),
              const SizedBox(height: AppSpacing.s),
              _buildConfirmationRow(
                '🕐',
                '시간',
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              ),
              const SizedBox(height: AppSpacing.s),
              _buildConfirmationRow('🔄', '패턴', _pattern),
              const SizedBox(height: AppSpacing.s),
              _buildConfirmationRow('📊', '총 횟수', '$totalCount회'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: AppSpacing.s),
        Text(label, style: AppTextStyles.body),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: AppButton(
                  text: '이전',
                  type: AppButtonType.secondary,
                  onPressed: () => setState(() => _currentStep--),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: AppSpacing.s),
            Expanded(
              child: AppButton(
                text: _currentStep == 3 ? '저장하기' : '다음',
                onPressed: _canProceed() ? _handleNext : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _nameController.text.isNotEmpty;
    }
    return true;
  }

  void _handleNext() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _saveMedication();
    }
  }

  int _calculateTotalCount(int duration) {
    if (_pattern == '격일') {
      return (duration / 2).ceil();
    } else if (_pattern == '월수금' || _pattern == '화목토') {
      return (duration / 7 * 3).ceil();
    }
    return duration;
  }

  void _saveMedication() {
    final duration = _endDate.difference(_startDate).inDays + 1;
    final totalCount = _calculateTotalCount(duration);

    // MedicationFormType을 MedicationType으로 변환
    final medicationType = _formType == MedicationFormType.injection
        ? MedicationType.injection
        : MedicationType.oral;

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      dosage: '$_quantity ${_formType.unit}',
      time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      startDate: _startDate,
      endDate: _endDate,
      type: medicationType,
      pattern: _pattern,
      totalCount: totalCount,
    );

    Navigator.pop(context, medication);
  }
}
