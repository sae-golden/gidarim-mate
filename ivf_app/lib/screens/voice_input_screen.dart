import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../models/medication.dart' as medication_model;
import '../models/voice_recognition_result.dart';
import '../services/gemini_parser_service.dart';
import '../services/ivf_medication_matcher.dart';
import '../services/medication_storage_service.dart';
import 'quick_add_medication_screen.dart';

/// 개선된 음성 입력 화면
class ImprovedVoiceInputScreen extends StatefulWidget {
  const ImprovedVoiceInputScreen({super.key});

  @override
  State<ImprovedVoiceInputScreen> createState() =>
      _ImprovedVoiceInputScreenState();
}

class _ImprovedVoiceInputScreenState extends State<ImprovedVoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String _recognizedText = '';

  // 파싱 결과
  VoiceRecognitionResult? _result;

  // 애니메이션
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAnimation();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _pulseController.forward();
        }
      }
    });
  }

  Future<void> _initSpeech() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            _pulseController.stop();
            if (_recognizedText.isNotEmpty) {
              _parseVoiceInput();
            }
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          _pulseController.stop();
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

      if (!available && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('음성 인식을 사용할 수 없습니다. 마이크 권한을 확인해주세요.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() async {
    if (!_isInitialized) {
      await _initSpeech();
      if (!_isInitialized) return;
    }

    setState(() {
      _recognizedText = '';
      _result = null;
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

    setState(() => _isListening = true);
    _pulseController.forward();
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    _pulseController.stop();

    if (_recognizedText.isNotEmpty) {
      _parseVoiceInput();
    }
  }

  void _parseVoiceInput() async {
    // Gemini AI가 설정되어 있으면 AI 파싱 사용, 아니면 로컬 파싱
    debugPrint('🔍 Gemini isConfigured: ${GeminiParserService.isConfigured}');
    if (GeminiParserService.isConfigured) {
      debugPrint('✅ Gemini API 사용 시도');
      setState(() {
        // 파싱 중 표시 (임시 결과)
        _result = VoiceRecognitionResult(
          rawText: _recognizedText,
          medications: [],
          confidence: 0.0,
        );
      });

      try {
        final result = await GeminiParserService.parseVoiceText(_recognizedText);
        if (mounted) {
          // 약 이름 자동 보정 적용
          final correctedResult = _autoCorrectMedicationNames(result);
          setState(() => _result = correctedResult);
        }
      } catch (e) {
        // AI 파싱 실패 시 로컬 파싱으로 폴백
        if (mounted) {
          final result = VoiceTextParser.parse(_recognizedText);
          final correctedResult = _autoCorrectMedicationNames(result);
          setState(() => _result = correctedResult);
        }
      }
    } else {
      // Gemini API 미설정 시 로컬 파싱
      debugPrint('❌ Gemini API 미설정 - 로컬 파싱 사용');
      final result = VoiceTextParser.parse(_recognizedText);
      final correctedResult = _autoCorrectMedicationNames(result);
      setState(() => _result = correctedResult);
    }
  }

  /// 파싱된 약물 이름을 IVF 약물 사전과 매칭하여 자동 보정
  VoiceRecognitionResult _autoCorrectMedicationNames(VoiceRecognitionResult result) {
    for (final med in result.medications) {
      final match = IvfMedicationMatcher.matchMedication(med.name);
      if (match != null && match.confidence > 0.5) {
        // 약 이름 보정
        med.name = match.medication.name;
        // 약 종류도 자동 설정
        med.type = _convertFormTypeToMedicationType(match.medication.type);
        debugPrint('🔄 약 이름 보정: ${match.matchedAlias} → ${match.medication.name} (${match.confidencePercent})');
      }
    }

    // 같은 약 이름 + 같은 종류는 시간대를 합쳐서 하나로 만듦
    final mergedMedications = _mergeSameMedications(result.medications);

    return VoiceRecognitionResult(
      rawText: result.rawText,
      medications: mergedMedications,
      confidence: result.confidence,
    );
  }

  /// 같은 약물 이름과 종류를 가진 항목들을 하나로 합침 (시간대 병합)
  List<ParsedMedication> _mergeSameMedications(List<ParsedMedication> medications) {
    // 약 이름(소문자) + 종류를 키로 그룹화
    final grouped = <String, List<ParsedMedication>>{};

    for (final med in medications) {
      final key = '${med.name.toLowerCase()}_${med.type.name}';
      grouped.putIfAbsent(key, () => []).add(med);
    }

    final result = <ParsedMedication>[];

    for (final group in grouped.values) {
      if (group.length == 1) {
        // 단일 항목은 그대로
        result.add(group.first);
      } else {
        // 여러 항목 병합
        final first = group.first;

        // 모든 시간 텍스트 수집
        final allTimeTimes = <String>[];
        for (final med in group) {
          if (med.timeText != null && med.timeText!.isNotEmpty) {
            allTimeTimes.add(med.timeText!);
          } else if (med.time != null) {
            allTimeTimes.add(med.displayTime);
          }
        }

        // 중복 제거 후 합침
        final uniqueTimes = allTimeTimes.toSet().toList();
        final mergedTimeText = uniqueTimes.join(', ');

        // 총 수량 합산
        final totalQuantity = group.fold<int>(0, (sum, med) => sum + med.quantity);

        // 날짜는 가장 넓은 범위로
        DateTime? earliestStart;
        DateTime? latestEnd;
        for (final med in group) {
          if (earliestStart == null || med.startDate.isBefore(earliestStart)) {
            earliestStart = med.startDate;
          }
          if (latestEnd == null || med.endDate.isAfter(latestEnd)) {
            latestEnd = med.endDate;
          }
        }

        result.add(ParsedMedication(
          name: first.name,
          type: first.type,
          quantity: totalQuantity,
          timeText: mergedTimeText,
          time: first.time,
          startDate: earliestStart,
          endDate: latestEnd,
          isSelected: first.isSelected,
        ));

        debugPrint('🔗 약물 병합: ${first.name} x${group.length} → 시간: $mergedTimeText');
      }
    }

    return result;
  }

  MedicationType _convertFormTypeToMedicationType(MedicationFormType formType) {
    switch (formType) {
      case MedicationFormType.injection:
        return MedicationType.injection;
      case MedicationFormType.oral:
        return MedicationType.oral;
      case MedicationFormType.vaginal:
        return MedicationType.suppository;
      case MedicationFormType.patch:
        return MedicationType.patch;
    }
  }

  void _addAllMedications() async {
    if (_result == null) return;

    final selectedMeds =
        _result!.medications.where((m) => m.isSelected).toList();
    if (selectedMeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('추가할 약물을 선택해주세요'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 여러 약물을 리스트로 생성 (다중 시간대는 각각 별도 저장)
    final medications = <medication_model.Medication>[];
    var idCounter = 0;

    for (final m in selectedMeds) {
      // timeText에 여러 시간이 있는 경우 분리
      final times = _parseMultipleTimes(m);

      for (final timeInfo in times) {
        // 고유 ID 생성 (밀리초 + 카운터)
        final id = '${DateTime.now().millisecondsSinceEpoch}_$idCounter';
        idCounter++;

        medications.add(medication_model.Medication(
          id: id,
          name: m.name,
          dosage: '${m.quantity}${_getUnit(m.type)}',
          time: timeInfo.timeString,
          startDate: m.startDate,
          endDate: m.endDate,
          type: _convertType(m.type),
          pattern: '매일',
          totalCount: m.durationDays * m.quantity,
        ));
      }
    }

    // 로컬 저장소에 저장
    try {
      await MedicationStorageService.addMedications(medications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medications.length}개 약물이 추가되었습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, medications);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 약물의 시간 정보를 파싱 (다중 시간 지원)
  List<_TimeInfo> _parseMultipleTimes(ParsedMedication med) {
    final times = <_TimeInfo>[];

    // timeText에 여러 시간이 있는 경우 (예: "오전 8시, 오후 12시, 오후 6시")
    if (med.timeText != null && med.timeText!.contains(',')) {
      final timeTexts = med.timeText!.split(',').map((t) => t.trim()).toList();

      for (final timeText in timeTexts) {
        final parsed = _parseTimeText(timeText);
        if (parsed != null) {
          times.add(_TimeInfo(
            timeString: '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}',
            label: timeText,
          ));
        }
      }
    }

    // 시간이 없거나 단일 시간인 경우
    if (times.isEmpty) {
      final time = med.time ?? const TimeOfDay(hour: 8, minute: 0);
      times.add(_TimeInfo(
        timeString: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        label: med.timeText,
      ));
    }

    return times;
  }

  /// 시간 텍스트 파싱 (예: "오전 8시", "오후 6시")
  TimeOfDay? _parseTimeText(String text) {
    // "오전/오후 N시" 형태
    final match = RegExp(r'(오전|오후)\s*(\d{1,2})').firstMatch(text);
    if (match != null) {
      final period = match.group(1);
      var hour = int.tryParse(match.group(2)!) ?? 8;
      if (period == '오후' && hour < 12) hour += 12;
      if (period == '오전' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: 0);
    }
    return null;
  }

  String _getUnit(MedicationType type) {
    switch (type) {
      case MedicationType.injection:
        return '대';
      case MedicationType.oral:
        return '알';
      case MedicationType.suppository:
        return '개';
      case MedicationType.patch:
        return '장';
    }
  }

  medication_model.MedicationType _convertType(MedicationType voiceType) {
    switch (voiceType) {
      case MedicationType.oral:
        return medication_model.MedicationType.oral;
      case MedicationType.injection:
        return medication_model.MedicationType.injection;
      case MedicationType.suppository:
        return medication_model.MedicationType.suppository;
      case MedicationType.patch:
        return medication_model.MedicationType.patch;
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
      body: _result != null
          ? (_result!.medications.isEmpty && _result!.confidence == 0.0
              ? _buildParsingView()  // AI 파싱 중
              : _buildResultView())
          : _buildInputView(),
    );
  }

  /// AI 파싱 중 화면
  Widget _buildParsingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryPurple,
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            '🤖 AI가 분석 중이에요...',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '"${_result!.rawText}"',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 음성 입력 화면
  Widget _buildInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // 마이크 버튼
          _buildMicButton(),
          const SizedBox(height: AppSpacing.m),

          // 인식 중 텍스트
          if (_isListening || _recognizedText.isNotEmpty)
            _buildRecognizingText(),

          const SizedBox(height: AppSpacing.xl),

          // 가이드
          _buildGuide(),
        ],
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isListening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: _isListening
                    ? LinearGradient(
                        colors: [
                          AppColors.error,
                          AppColors.error.withOpacity(0.7),
                        ],
                      )
                    : AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening
                            ? AppColors.error
                            : AppColors.primaryPurple)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 48,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecognizingText() {
    return AppCard(
      child: Column(
        children: [
          if (_isListening)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '듣고 있어요...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              _recognizedText,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuide() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '이렇게 말해보세요',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 포맷 설명
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 16)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '[약 이름] + [종류] + [개수] + [시간]',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // 예시들
          _buildExample('"퓨레곤 주사 1개 밤 9시"'),
          _buildExample('"크녹산 알약 1개 아침 8시"'),
          _buildExample('"아스피린 알약 1개 저녁 식후"'),

          const SizedBox(height: AppSpacing.m),
          const Divider(),
          const SizedBox(height: AppSpacing.m),

          // 여러 개 안내
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '여러 개 한번에 말해도 돼요!',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"퓨레곤 밤 9시, 크녹산 아침, 아스피린 저녁"',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.m),
          Icon(
            Icons.format_quote,
            size: 16,
            color: AppColors.textDisabled,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 인식 결과 화면
  Widget _buildResultView() {
    final selectedCount =
        _result!.medications.where((m) => m.isSelected).length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 원본 텍스트
                Row(
                  children: [
                    const Text('🎙️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '인식된 내용',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                AppCard(
                  child: Text(
                    _result!.rawText,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // 인식 완료
                Row(
                  children: [
                    Icon(
                      _result!.medications.isNotEmpty
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: _result!.medications.isNotEmpty
                          ? AppColors.success
                          : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _result!.medications.isNotEmpty
                          ? '${_result!.confidence > 0.9 ? '🤖 AI' : ''} 인식 완료! (${_result!.medications.length}개)'
                          : '약물을 인식하지 못했어요',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _result!.medications.isNotEmpty
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),

                // 약물 목록
                ..._result!.medications.asMap().entries.map((entry) {
                  return _buildMedicationItem(entry.key, entry.value);
                }),
              ],
            ),
          ),
        ),

        // 하단 버튼
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: '다시 녹음',
                    onPressed: () {
                      setState(() {
                        _result = null;
                        _recognizedText = '';
                      });
                    },
                    type: AppButtonType.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: selectedCount > 0
                        ? '${selectedCount}개 추가하기'
                        : '추가하기',
                    onPressed: selectedCount > 0 ? _addAllMedications : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationItem(int index, ParsedMedication med) {
    return GestureDetector(
      onTap: () {
        setState(() {
          med.isSelected = !med.isSelected;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: med.isSelected ? AppColors.primaryPurple : AppColors.border,
            width: med.isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: med.isSelected
                    ? AppColors.primaryPurple
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: med.isSelected
                      ? AppColors.primaryPurple
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: med.isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.m),

            // 아이콘
            Text(med.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.s),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.displayType} · ${med.quantity}개 · ${med.displayTime}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 복용 기간 표시
                  Text(
                    '📅 편집에서 복용일 선택',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 수정 버튼
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.textSecondary,
              onPressed: () => _showEditScreen(index, med),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),

            // 삭제 버튼
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              onPressed: () => _deleteMedication(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }

  /// 약물 삭제
  void _deleteMedication(int index) {
    setState(() {
      _result!.medications.removeAt(index);
    });
  }

  void _showEditScreen(int index, ParsedMedication med) async {
    // ParsedMedication을 Medication으로 변환
    final medication = _convertToMedication(med);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddMedicationScreen(
          editingMedication: medication,
        ),
      ),
    );

    // 수정 완료 후 약물 정보 새로고침
    if (result == true && mounted) {
      // 저장소에서 업데이트된 약물 조회
      final updatedMed = await MedicationStorageService.getMedicationById(medication.id);
      if (updatedMed != null) {
        setState(() {
          _result!.medications[index] = _convertToParsedMedication(updatedMed);
        });
      }
    }
  }

  /// ParsedMedication을 Medication으로 변환
  medication_model.Medication _convertToMedication(ParsedMedication med) {
    final time = med.time ?? const TimeOfDay(hour: 8, minute: 0);
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return medication_model.Medication(
      id: '${DateTime.now().millisecondsSinceEpoch}_voice',
      name: med.name,
      dosage: '${med.quantity}${_getUnit(med.type)}',
      time: timeString,
      startDate: med.startDate,
      endDate: med.endDate,
      type: _convertType(med.type),
      pattern: '매일',
      totalCount: med.durationDays * med.quantity,
    );
  }

  /// Medication을 ParsedMedication으로 변환
  ParsedMedication _convertToParsedMedication(medication_model.Medication med) {
    // 시간 파싱
    TimeOfDay? time;
    if (med.time.contains(':')) {
      final parts = med.time.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      time = TimeOfDay(hour: hour, minute: minute);
    }

    // 수량 파싱
    int quantity = 1;
    if (med.dosage != null) {
      final numericMatch = RegExp(r'(\d+)').firstMatch(med.dosage!);
      if (numericMatch != null) {
        quantity = int.tryParse(numericMatch.group(1)!) ?? 1;
      }
    }

    // 타입 변환
    MedicationType type;
    switch (med.type) {
      case medication_model.MedicationType.injection:
        type = MedicationType.injection;
        break;
      case medication_model.MedicationType.oral:
        type = MedicationType.oral;
        break;
      case medication_model.MedicationType.suppository:
        type = MedicationType.suppository;
        break;
      case medication_model.MedicationType.patch:
        type = MedicationType.patch;
        break;
    }

    return ParsedMedication(
      name: med.name,
      type: type,
      quantity: quantity,
      time: time,
      startDate: med.startDate,
      endDate: med.endDate,
      isSelected: true,
    );
  }

  String _getTypeName(MedicationType type) {
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
}

/// 시간 정보 헬퍼 클래스
class _TimeInfo {
  final String timeString; // "HH:mm" 형식
  final String? label; // "오전 8시" 등

  _TimeInfo({required this.timeString, this.label});
}
