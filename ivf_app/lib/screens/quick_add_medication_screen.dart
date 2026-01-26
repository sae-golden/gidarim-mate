import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_button.dart';
import '../models/medication.dart';
import '../services/ivf_medication_matcher.dart';
import '../services/medication_storage_service.dart';
import '../services/notification_scheduler_service.dart';

/// 시간대 슬롯
enum TimeSlot {
  morning, // 기상 (기본 07:00)
  noon, // 점심 (기본 12:00)
  evening, // 저녁 (기본 18:00)
  night, // 취침 (기본 22:00)
}

extension TimeSlotExtension on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.morning:
        return '기상';
      case TimeSlot.noon:
        return '점심';
      case TimeSlot.evening:
        return '저녁';
      case TimeSlot.night:
        return '취침';
    }
  }

  String get emoji {
    switch (this) {
      case TimeSlot.morning:
        return '🌅';
      case TimeSlot.noon:
        return '☀️';
      case TimeSlot.evening:
        return '🌆';
      case TimeSlot.night:
        return '🌙';
    }
  }

  TimeOfDay get defaultTime {
    switch (this) {
      case TimeSlot.morning:
        return const TimeOfDay(hour: 7, minute: 0);
      case TimeSlot.noon:
        return const TimeOfDay(hour: 12, minute: 0);
      case TimeSlot.evening:
        return const TimeOfDay(hour: 18, minute: 0);
      case TimeSlot.night:
        return const TimeOfDay(hour: 22, minute: 0);
    }
  }
}

/// 복용 시간 데이터
class DoseTime {
  final TimeSlot slot;
  TimeOfDay time;
  int quantity; // 시간대별 수량

  DoseTime({required this.slot, required this.time, this.quantity = 1});
}

/// 빠른 날짜 선택 패턴
enum QuickDatePattern {
  daily, // 매일
  everyOther, // 격일
  monWedFri, // 월수금
  tueThuSat, // 화목토
  custom, // 직접선택
}

extension QuickDatePatternExtension on QuickDatePattern {
  String get label {
    switch (this) {
      case QuickDatePattern.daily:
        return '매일';
      case QuickDatePattern.everyOther:
        return '격일';
      case QuickDatePattern.monWedFri:
        return '월수금';
      case QuickDatePattern.tueThuSat:
        return '화목토';
      case QuickDatePattern.custom:
        return '직접선택';
    }
  }
}

/// 단일 페이지 약물 추가/수정 화면
class QuickAddMedicationScreen extends StatefulWidget {
  final Medication? editingMedication; // 수정할 약물 (null이면 새로 추가)

  const QuickAddMedicationScreen({
    super.key,
    this.editingMedication,
  });

  @override
  State<QuickAddMedicationScreen> createState() =>
      _QuickAddMedicationScreenState();
}

class _QuickAddMedicationScreenState extends State<QuickAddMedicationScreen> {
  // 약 이름
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _scrollController = ScrollController(); // 키보드 가림 방지용
  final _nameFieldKey = GlobalKey(); // 입력 필드 위치 추적
  List<IvfMedicationData> _suggestions = [];
  bool _showSuggestions = false;

  // 종류
  MedicationFormType _formType = MedicationFormType.injection;

  // 복용 시간대
  final Map<TimeSlot, DoseTime> _selectedTimes = {};

  // 복용일
  QuickDatePattern _datePattern = QuickDatePattern.daily;
  Set<DateTime> _selectedDates = {};
  DateTime _displayMonth = DateTime.now();

  // 기본 수량 (새로 추가되는 시간대에 적용)
  int _quantity = 1;

  // 저장 중 상태 (중복 클릭 방지)
  bool _isSaving = false;

  // Validation 에러 상태
  String? _nameError;

  // 수정 모드 여부
  bool get _isEditMode => widget.editingMedication != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _nameFocusNode.addListener(_onFocusChanged);

    if (_isEditMode) {
      _loadEditingMedication();
    } else {
      _initDefaultDates();
    }
  }

  void _initDefaultDates() {
    // 기본값: 오늘 날짜 선택
    final today = DateTime.now();
    _selectedDates.add(DateTime(today.year, today.month, today.day));
  }

  /// 수정 모드: 기존 약물 데이터 로드
  void _loadEditingMedication() {
    final med = widget.editingMedication!;

    // 약물명
    _nameController.text = med.name;

    // 타입 변환
    switch (med.type) {
      case MedicationType.injection:
        _formType = MedicationFormType.injection;
        break;
      case MedicationType.oral:
        _formType = MedicationFormType.oral;
        break;
      case MedicationType.suppository:
        _formType = MedicationFormType.vaginal;
        break;
      case MedicationType.patch:
        _formType = MedicationFormType.patch;
        break;
    }

    // dosage에서 수량 파싱 (예: "2대", "1정", "3매")
    int dosageQuantity = 1;
    if (med.dosage != null && med.dosage!.isNotEmpty) {
      // 숫자만 추출
      final numericMatch = RegExp(r'(\d+)').firstMatch(med.dosage!);
      if (numericMatch != null) {
        dosageQuantity = int.tryParse(numericMatch.group(1)!) ?? 1;
      }
    }

    // 시간 파싱
    final timeParts = med.time.split(':');
    if (timeParts.length == 2) {
      final hour = int.tryParse(timeParts[0]) ?? 8;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final time = TimeOfDay(hour: hour, minute: minute);

      // 시간대 결정
      TimeSlot slot;
      if (hour < 10) {
        slot = TimeSlot.morning;
      } else if (hour < 14) {
        slot = TimeSlot.noon;
      } else if (hour < 20) {
        slot = TimeSlot.evening;
      } else {
        slot = TimeSlot.night;
      }

      _selectedTimes[slot] = DoseTime(slot: slot, time: time, quantity: dosageQuantity);
    }

    // 패턴
    switch (med.pattern) {
      case '매일':
        _datePattern = QuickDatePattern.daily;
        break;
      case '격일':
        _datePattern = QuickDatePattern.everyOther;
        break;
      case '월수금':
        _datePattern = QuickDatePattern.monWedFri;
        break;
      case '화목토':
        _datePattern = QuickDatePattern.tueThuSat;
        break;
      default:
        _datePattern = QuickDatePattern.custom;
    }

    // 날짜 범위 설정
    _displayMonth = med.startDate;
    _selectedDates = {};

    // 시작일부터 종료일까지 패턴에 맞게 날짜 추가
    DateTime current = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
    final end = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);

    while (!current.isAfter(end)) {
      bool shouldAdd = false;
      switch (_datePattern) {
        case QuickDatePattern.daily:
          shouldAdd = true;
          break;
        case QuickDatePattern.everyOther:
          final diff = current.difference(DateTime(med.startDate.year, med.startDate.month, med.startDate.day)).inDays;
          shouldAdd = diff % 2 == 0;
          break;
        case QuickDatePattern.monWedFri:
          shouldAdd = current.weekday == 1 || current.weekday == 3 || current.weekday == 5;
          break;
        case QuickDatePattern.tueThuSat:
          shouldAdd = current.weekday == 2 || current.weekday == 4 || current.weekday == 6;
          break;
        case QuickDatePattern.custom:
          shouldAdd = true;
          break;
      }
      if (shouldAdd) {
        _selectedDates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
  }

  void _onNameChanged() {
    final query = _nameController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final matches = IvfMedicationMatcher.getSuggestions(query, limit: 5);
    setState(() {
      _suggestions = matches.map((m) => m.medication).toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  void _onFocusChanged() {
    if (_nameFocusNode.hasFocus) {
      // 키보드가 올라올 때 입력 필드가 보이도록 스크롤
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _nameFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _nameFieldKey.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_nameFocusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  void _selectMedication(IvfMedicationData medication) {
    setState(() {
      _nameController.text = medication.name;
      _formType = medication.type;
      _showSuggestions = false;
      _nameError = null; // 선택 시 에러 제거
    });
    _nameFocusNode.unfocus();
  }

  /// 약물명 필드로 스크롤 (validation 실패 시)
  void _scrollToNameField() {
    // 맨 위로 스크롤
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // 포커스 설정
    _nameFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _nameFocusNode.removeListener(_onFocusChanged);
    _nameFocusNode.dispose();
    _scrollController.dispose();
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
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isEditMode ? '✏️' : '💊', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              _isEditMode ? '약물 수정' : '약물 추가',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        centerTitle: true,
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: _showDeleteConfirmDialog,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 약 이름 입력
                  _buildNameSection(),
                  const SizedBox(height: AppSpacing.l),

                  // 2. 종류 선택
                  _buildTypeSection(),
                  const SizedBox(height: AppSpacing.l),

                  // 3. 복용 시간대 선택
                  _buildTimeSection(),
                  const SizedBox(height: AppSpacing.l),

                  // 4. 시간 & 수량 설정 (캘린더 위)
                  if (_selectedTimes.isNotEmpty) ...[
                    _buildTimeQuantitySection(),
                    const SizedBox(height: AppSpacing.l),
                  ],

                  // 5. 복용일 선택
                  _buildDateSection(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // 저장 버튼
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ==================== 1. 약 이름 입력 ====================
  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '약 이름',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          key: _nameFieldKey, // 키보드 가림 방지용 key
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _nameError != null ? AppColors.error : AppColors.border,
              width: _nameError != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            onChanged: (_) {
              // 입력 시 에러 메시지 제거
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
            decoration: InputDecoration(
              hintText: '검색 또는 직접 입력',
              hintStyle: TextStyle(color: AppColors.textDisabled),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.m,
              ),
            ),
          ),
        ),
        // 에러 메시지
        if (_nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _nameError!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),

        // 자동완성 목록
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((med) {
                return InkWell(
                  onTap: () => _selectMedication(med),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurpleLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            med.type.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                med.category,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ==================== 2. 종류 선택 ====================
  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '종류',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
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
                    color: isSelected
                        ? AppColors.primaryPurple
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        type.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== 3. 복용 시간대 선택 ====================
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '언제 복용하나요?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),

        // 4개 타임슬롯
        Row(
          children: TimeSlot.values.map((slot) {
            final isSelected = _selectedTimes.containsKey(slot);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTimes.remove(slot);
                    } else {
                      _selectedTimes[slot] = DoseTime(
                        slot: slot,
                        time: slot.defaultTime,
                        quantity: _quantity,
                      );
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: slot != TimeSlot.night ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurpleLight
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryPurple
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        slot.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slot.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primaryPurple
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryPurple,
                          size: 16,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== 4. 시간 & 수량 설정 (통합) ====================
  Widget _buildTimeQuantitySection() {
    // 하루 총 수량 계산
    int dailyTotal = 0;
    final sortedTimes = _selectedTimes.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    for (final entry in sortedTimes) {
      dailyTotal += entry.value.quantity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '시간 & 수량 설정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            // 하루 총량
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '하루 총 $dailyTotal${_formType.unit}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // 통합 카드: 각 시간대별 시간 + 수량 조절
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: sortedTimes.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final slot = entry.key;
              final doseTime = entry.value;
              final isLast = index == sortedTimes.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // 1줄: 시간대 + 시간/수량 조정 (한 줄에 통합)
                        Row(
                          children: [
                            // 시간대 아이콘 + 라벨
                            Text(slot.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              slot.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // 시간 조정 (컴팩트)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  final newHour = (doseTime.time.hour - 1) % 24;
                                  doseTime.time = TimeOfDay(hour: newHour, minute: doseTime.time.minute);
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.remove_circle_outline, size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: doseTime.time,
                                );
                                if (picked != null) {
                                  setState(() => doseTime.time = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPurpleLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${doseTime.time.hour.toString().padLeft(2, '0')}:${doseTime.time.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  final newHour = (doseTime.time.hour + 1) % 24;
                                  doseTime.time = TimeOfDay(hour: newHour, minute: doseTime.time.minute);
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.add_circle_outline, size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                            // 구분선
                            Container(
                              width: 1,
                              height: 20,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              color: AppColors.border,
                            ),
                            // 수량 조정 (컴팩트)
                            GestureDetector(
                              onTap: doseTime.quantity > 1
                                  ? () => setState(() => doseTime.quantity--)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                  color: doseTime.quantity > 1 ? AppColors.primaryPurple : AppColors.textDisabled,
                                ),
                              ),
                            ),
                            Container(
                              width: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '${doseTime.quantity}${_formType.unit}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => doseTime.quantity++),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryPurple),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(color: AppColors.border.withOpacity(0.5), height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==================== 4. 복용일 선택 ====================
  Widget _buildDateSection() {
    // 선택된 날짜 기간 계산
    String periodText = '';
    int totalDoses = 0;
    if (_selectedDates.isNotEmpty) {
      final sortedDates = _selectedDates.toList()..sort();
      final firstDate = sortedDates.first;
      final lastDate = sortedDates.last;
      final days = _selectedDates.length;
      totalDoses = days * _selectedTimes.length;
      periodText = '기간: ${firstDate.month}/${firstDate.day} ~ ${lastDate.month}/${lastDate.day} (${days}일간, 총 ${totalDoses}회)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '복용일 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // 미니 캘린더
        _buildMiniCalendar(),

        // 선택된 기간 표시
        if (_selectedDates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: Text(
              periodText,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMiniCalendar() {
    final year = _displayMonth.year;
    final month = _displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startWeekday = firstDay.weekday % 7; // 일요일=0

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 월 네비게이션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayMonth = DateTime(year, month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
              ),
              Text(
                '$year년 $month월',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayMonth = DateTime(year, month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
              ),
            ],
          ),

          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      color: day == '일'
                          ? Colors.red
                          : day == '토'
                              ? Colors.blue
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 날짜 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday + lastDay.day,
            itemBuilder: (context, index) {
              if (index < startWeekday) {
                return const SizedBox();
              }

              final day = index - startWeekday + 1;
              final date = DateTime(year, month, day);
              final isSelected = _selectedDates.any(
                (d) => d.year == date.year && d.month == date.month && d.day == date.day,
              );
              final isToday = DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;
              final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

              return GestureDetector(
                onTap: isPast
                    ? null
                    : () {
                        setState(() {
                          _datePattern = QuickDatePattern.custom;
                          if (isSelected) {
                            _selectedDates.removeWhere(
                              (d) => d.year == date.year && d.month == date.month && d.day == date.day,
                            );
                          } else {
                            _selectedDates.add(date);
                          }
                        });
                      },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    // 선택됨: 채워진 원, 미선택: 테두리만 있는 원
                    color: isSelected
                        ? AppColors.primaryPurple
                        : null,
                    shape: BoxShape.circle,
                    border: !isSelected && !isPast
                        ? Border.all(
                            color: isToday
                                ? AppColors.primaryPurple
                                : AppColors.border,
                            width: isToday ? 2 : 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday ? FontWeight.w600 : null,
                        color: isPast
                            ? AppColors.textDisabled
                            : isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== 저장 버튼 ====================
  Widget _buildSaveButton() {
    // 저장 버튼은 항상 활성화 (validation은 _saveMedication에서 수행)
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          text: _isSaving ? '저장 중...' : '저장',
          onPressed: _isSaving ? null : _saveMedication,
        ),
      ),
    );
  }

  Future<void> _saveMedication() async {
    // 중복 클릭 방지
    if (_isSaving) return;

    // Validation: 약물명 필수
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = '약 이름을 알려주세요');
      // 약물명 필드로 스크롤
      _scrollToNameField();
      return;
    }

    // Validation: 복용일 필수
    if (_selectedDates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('복용일을 선택해 주세요'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    // 패턴 문자열 생성
    String pattern;
    switch (_datePattern) {
      case QuickDatePattern.daily:
        pattern = '매일';
        break;
      case QuickDatePattern.everyOther:
        pattern = '격일';
        break;
      case QuickDatePattern.monWedFri:
        pattern = '월수금';
        break;
      case QuickDatePattern.tueThuSat:
        pattern = '화목토';
        break;
      case QuickDatePattern.custom:
        pattern = '${_selectedDates.length}일';
        break;
    }

    // 시작일/종료일 계산
    final sortedDates = _selectedDates.toList()..sort();
    final startDate = sortedDates.first;
    final endDate = sortedDates.last;

    // MedicationType 변환
    MedicationType medicationType;
    switch (_formType) {
      case MedicationFormType.injection:
        medicationType = MedicationType.injection;
        break;
      case MedicationFormType.oral:
        medicationType = MedicationType.oral;
        break;
      case MedicationFormType.vaginal:
        medicationType = MedicationType.suppository;
        break;
      case MedicationFormType.patch:
        medicationType = MedicationType.patch;
        break;
    }

    // 로컬 저장소에 저장
    try {
      if (_isEditMode) {
        // 수정 모드: 단일 약물 업데이트 (시간 변경 불가, 기존 로직 유지)
        String timeString;
        int dailyTotal;

        if (_selectedTimes.isNotEmpty) {
          final sortedTimes = _selectedTimes.entries.toList()
            ..sort((a, b) => a.key.index.compareTo(b.key.index));
          final firstTime = sortedTimes.first.value.time;
          timeString = '${firstTime.hour.toString().padLeft(2, '0')}:${firstTime.minute.toString().padLeft(2, '0')}';
          dailyTotal = sortedTimes.first.value.quantity;
        } else {
          timeString = '09:00';
          dailyTotal = _quantity;
        }

        final medication = Medication(
          id: widget.editingMedication!.id,
          name: _nameController.text,
          type: medicationType,
          time: timeString,
          pattern: pattern,
          startDate: startDate,
          endDate: endDate,
          dosage: '$dailyTotal${_formType.unit}',
          totalCount: _selectedDates.length * dailyTotal,
        );

        await MedicationStorageService.updateMedication(medication, addToSyncQueue: false);
        await NotificationSchedulerService.cancelMedicationNotification(medication.id);
        await NotificationSchedulerService.scheduleMedication(medication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${medication.name}이(가) 수정되었습니다'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // 새로 추가 모드: 각 시간대별로 별도의 Medication 객체 생성
        final medications = <Medication>[];
        final baseId = DateTime.now().millisecondsSinceEpoch.toString();

        if (_selectedTimes.isNotEmpty) {
          // 선택된 시간대가 있는 경우 - 각 시간대별로 별도 Medication 생성
          final sortedTimes = _selectedTimes.entries.toList()
            ..sort((a, b) => a.key.index.compareTo(b.key.index));

          for (var i = 0; i < sortedTimes.length; i++) {
            final entry = sortedTimes[i];
            final time = entry.value.time;
            final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            final quantity = entry.value.quantity;

            medications.add(Medication(
              id: '${baseId}_$i', // 고유 ID 부여
              name: _nameController.text,
              type: medicationType,
              time: timeString,
              pattern: pattern,
              startDate: startDate,
              endDate: endDate,
              dosage: '$quantity${_formType.unit}',
              totalCount: _selectedDates.length * quantity,
            ));
          }
        } else {
          // 시간대 미선택 시 기본값으로 단일 Medication 생성
          medications.add(Medication(
            id: baseId,
            name: _nameController.text,
            type: medicationType,
            time: '09:00',
            pattern: pattern,
            startDate: startDate,
            endDate: endDate,
            dosage: '$_quantity${_formType.unit}',
            totalCount: _selectedDates.length * _quantity,
          ));
        }

        // 모든 약물 저장 및 알림 스케줄링
        for (final medication in medications) {
          await MedicationStorageService.addMedication(medication, addToSyncQueue: false);
          await NotificationSchedulerService.scheduleMedication(medication);
        }

        if (mounted) {
          final message = medications.length > 1
              ? '${_nameController.text}이(가) ${medications.length}개 시간대로 추가되었습니다'
              : '${_nameController.text}이(가) 추가되었습니다';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    } finally {
      // 저장 상태 리셋 (에러 발생 시 다시 시도 가능하도록)
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('약물 삭제'),
        content: Text('${widget.editingMedication!.name}을(를) 삭제하시겠어요?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기
              await _deleteMedication(); // 삭제 완료까지 대기
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 약물 삭제
  Future<void> _deleteMedication() async {
    try {
      final medicationId = widget.editingMedication!.id;

      // 1. 로컬에서 삭제
      await MedicationStorageService.deleteMedication(medicationId, addToSyncQueue: false);

      // 2. 알림 취소
      await NotificationSchedulerService.cancelMedicationNotification(medicationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.editingMedication!.name}이(가) 삭제되었습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    }
  }
}
