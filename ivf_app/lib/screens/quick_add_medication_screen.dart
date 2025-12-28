import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_button.dart';
import '../models/medication.dart';
import '../services/ivf_medication_matcher.dart';

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

/// 단일 페이지 약물 추가 화면
class QuickAddMedicationScreen extends StatefulWidget {
  const QuickAddMedicationScreen({super.key});

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
  IvfMedicationData? _selectedMedication;

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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
    _nameFocusNode.addListener(_onFocusChanged);
    _initDefaultDates();
  }

  void _initDefaultDates() {
    // 기본값: 아무것도 선택 안 됨
    // _selectedDates는 이미 빈 Set으로 초기화됨
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
      _selectedMedication = medication;
      _formType = medication.type;
      _showSuggestions = false;
    });
    _nameFocusNode.unfocus();
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
            const Text('💊', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '약물 추가',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        centerTitle: true,
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
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // 시간대 아이콘 + 라벨
                        Text(slot.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          slot.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 시간 조정
                        IconButton(
                          onPressed: () {
                            setState(() {
                              final newHour = (doseTime.time.hour - 1) % 24;
                              doseTime.time = TimeOfDay(hour: newHour, minute: doseTime.time.minute);
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          color: AppColors.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              final newHour = (doseTime.time.hour + 1) % 24;
                              doseTime.time = TimeOfDay(hour: newHour, minute: doseTime.time.minute);
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          color: AppColors.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),

                        const Spacer(),

                        // 수량 조정
                        IconButton(
                          onPressed: doseTime.quantity > 1
                              ? () => setState(() => doseTime.quantity--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          color: doseTime.quantity > 1
                              ? AppColors.primaryPurple
                              : AppColors.textDisabled,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          child: Text(
                            '${doseTime.quantity}${_formType.unit}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => doseTime.quantity++),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          color: AppColors.primaryPurple,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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

  void _applyDatePattern(QuickDatePattern pattern) {
    _selectedDates.clear();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);

    switch (pattern) {
      case QuickDatePattern.daily:
        for (int i = 0; i < 14; i++) {
          _selectedDates.add(startDate.add(Duration(days: i)));
        }
        break;
      case QuickDatePattern.everyOther:
        for (int i = 0; i < 14; i += 2) {
          _selectedDates.add(startDate.add(Duration(days: i)));
        }
        break;
      case QuickDatePattern.monWedFri:
        for (int i = 0; i < 28; i++) {
          final date = startDate.add(Duration(days: i));
          if (date.weekday == DateTime.monday ||
              date.weekday == DateTime.wednesday ||
              date.weekday == DateTime.friday) {
            _selectedDates.add(date);
          }
        }
        break;
      case QuickDatePattern.tueThuSat:
        for (int i = 0; i < 28; i++) {
          final date = startDate.add(Duration(days: i));
          if (date.weekday == DateTime.tuesday ||
              date.weekday == DateTime.thursday ||
              date.weekday == DateTime.saturday) {
            _selectedDates.add(date);
          }
        }
        break;
      case QuickDatePattern.custom:
        // 직접 선택 - 기존 선택 유지
        break;
    }
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
    final isValid = _nameController.text.isNotEmpty &&
        _selectedTimes.isNotEmpty &&
        _selectedDates.isNotEmpty;

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
          text: '저장',
          onPressed: isValid ? _saveMedication : null,
        ),
      ),
    );
  }

  void _saveMedication() {
    // 첫 번째 선택된 시간 사용
    final sortedTimes = _selectedTimes.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    final firstTime = sortedTimes.first.value.time;
    final timeString = '${firstTime.hour.toString().padLeft(2, '0')}:${firstTime.minute.toString().padLeft(2, '0')}';

    // 하루 총 수량 계산
    int dailyTotal = 0;
    for (final entry in sortedTimes) {
      dailyTotal += entry.value.quantity;
    }

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

    final medication = Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      type: _formType == MedicationFormType.injection
          ? MedicationType.injection
          : MedicationType.oral,
      time: timeString,
      pattern: pattern,
      startDate: startDate,
      endDate: endDate,
      dosage: '$dailyTotal${_formType.unit}',
      totalCount: _selectedDates.length * dailyTotal,
    );

    Navigator.pop(context, medication);
  }
}
