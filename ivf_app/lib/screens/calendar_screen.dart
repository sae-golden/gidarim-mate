import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../services/medication_storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../services/notification_scheduler_service.dart';
import '../services/additional_record_service.dart';
import '../services/simple_treatment_service.dart';
import '../models/medication.dart' as med_model;
import '../models/additional_records.dart';
import '../models/simple_treatment_cycle.dart';
import 'quick_add_medication_screen.dart';

/// 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // 날짜별 완료 상태
  Map<DateTime, List<MedicationStatus>> _medicationData = {};

  // 날짜별 추가 기록 타입 (신규 4개 항목)
  Map<DateTime, Set<RecordType>> _additionalRecordData = {};

  // 날짜별 시술 이벤트 (기록 탭 연동)
  Map<DateTime, List<TreatmentEvent>> _treatmentEventData = {};

  // 날짜별 사이클 결과 (판정일)
  Map<DateTime, CycleResult> _cycleResultData = {};

  // PageView 컨트롤러 (캘린더 스와이프용)
  late PageController _pageController;
  static const int _initialPage = 1200; // 100년치 (중간값)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _initialPage);
    _loadMedications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  /// 앱이 포그라운드로 돌아올 때 데이터 새로고침
  /// 알림에서 복용 처리 후 캘린더 화면 복귀 시 반영됨
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 캘린더 화면 새로고침 (앱 포그라운드 복귀)');
      _loadMedications();
    }
  }

  /// 페이지 인덱스에서 월 계산
  DateTime _getMonthFromPage(int page) {
    final now = DateTime.now();
    final diff = page - _initialPage;
    return DateTime(now.year, now.month + diff);
  }

  /// 월에서 페이지 인덱스 계산
  int _getPageFromMonth(DateTime month) {
    final now = DateTime.now();
    final diff = (month.year - now.year) * 12 + (month.month - now.month);
    return _initialPage + diff;
  }

  /// 저장된 약물 데이터 및 추가 기록 로드
  Future<void> _loadMedications() async {
    final medications = await MedicationStorageService.getAllMedications();

    // 날짜별 약물 데이터 구성
    final Map<DateTime, List<MedicationStatus>> data = {};

    for (final med in medications) {
      // 시작일부터 종료일까지 각 날짜에 약물 추가
      DateTime currentDate = DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      final endDate = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);

      while (!currentDate.isAfter(endDate)) {
        final dateKey = DateTime(currentDate.year, currentDate.month, currentDate.day);

        // 시간 파싱
        TimeOfDay scheduledTime = const TimeOfDay(hour: 8, minute: 0);
        if (med.time.contains(':')) {
          final parts = med.time.split(':');
          final hour = int.tryParse(parts[0]) ?? 8;
          final minute = int.tryParse(parts[1]) ?? 0;
          scheduledTime = TimeOfDay(hour: hour, minute: minute);
        }

        // 해당 날짜의 완료 상태 확인
        final status = await MedicationStorageService.getMedicationStatus(currentDate);
        final isCompleted = status[med.id] ?? false;

        final medStatus = MedicationStatus(
          id: '${med.id}_${dateKey.toIso8601String()}',
          medicationId: med.id,
          name: med.name,
          type: _getTypeString(med.type),
          scheduledTime: scheduledTime,
          isCompleted: isCompleted,
        );

        if (data[dateKey] == null) {
          data[dateKey] = [];
        }
        data[dateKey]!.add(medStatus);

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    // 추가 기록 데이터 로드 (현재 포커스 월 기준 전후 2개월)
    final startDate = DateTime(_focusedMonth.year, _focusedMonth.month - 2, 1);
    final endDate = DateTime(_focusedMonth.year, _focusedMonth.month + 3, 0);
    final additionalRecords = await AdditionalRecordService.getRecordDatesByRange(startDate, endDate);

    // 시술 이벤트 데이터 로드 (기록 탭 연동)
    final treatmentEvents = await SimpleTreatmentService.getEventsByDateRange(startDate, endDate);
    final cycleResults = await SimpleTreatmentService.getCycleResultsByDateRange(startDate, endDate);

    setState(() {
      _medicationData = data;
      _additionalRecordData = additionalRecords;
      _treatmentEventData = treatmentEvents;
      _cycleResultData = cycleResults;
    });
  }

  String _getTypeString(med_model.MedicationType type) {
    switch (type) {
      case med_model.MedicationType.injection:
        return 'injection';
      case med_model.MedicationType.oral:
        return 'pill';
      case med_model.MedicationType.suppository:
        return 'suppository';
      case med_model.MedicationType.patch:
        return 'patch';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '캘린더',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            // 월 선택 헤더
            _buildMonthHeader(),
            const SizedBox(height: AppSpacing.m),

            // 캘린더 (먼저 표시)
            _buildCalendar(),
            const SizedBox(height: AppSpacing.m),

            // 선택된 날짜의 상세 정보 (캘린더 아래)
            _buildSelectedDateDetail(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            setState(() {
              _focusedMonth = newMonth;
            });
            _pageController.animateToPage(
              _getPageFromMonth(newMonth),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textPrimary,
        ),
        GestureDetector(
          onTap: () {
            // 오늘로 이동
            final now = DateTime.now();
            setState(() {
              _focusedMonth = DateTime(now.year, now.month);
              _selectedDate = now;
            });
            _pageController.animateToPage(
              _initialPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Text(
            '${_focusedMonth.year}년 ${_focusedMonth.month}월',
            style: AppTextStyles.h3,
          ),
        ),
        IconButton(
          onPressed: () {
            final newMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            setState(() {
              _focusedMonth = newMonth;
            });
            _pageController.animateToPage(
              _getPageFromMonth(newMonth),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return AppCard(
      child: Column(
        children: [
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: day == '일'
                                ? AppColors.error
                                : day == '토'
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.s),

          // 스와이프 가능한 날짜 그리드
          SizedBox(
            height: 360, // 6주치 높이
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _focusedMonth = _getMonthFromPage(page);
                });
              },
              itemBuilder: (context, page) {
                final month = _getMonthFromPage(page);
                return _buildCalendarMonth(month);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 특정 월의 캘린더 빌드
  Widget _buildCalendarMonth(DateTime month) {
    return SingleChildScrollView(
      child: Column(
        children: _buildCalendarWeeksForMonth(month),
      ),
    );
  }

  List<Widget> _buildCalendarWeeksForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startingWeekday = firstDay.weekday % 7;

    List<Widget> weeks = [];
    List<Widget> currentWeek = [];

    // 이전 달의 빈 칸
    for (int i = 0; i < startingWeekday; i++) {
      currentWeek.add(const Expanded(child: SizedBox(height: 60)));
    }

    // 현재 달의 날짜들
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(month.year, month.month, day);
      currentWeek.add(_buildDayCell(date));

      if (currentWeek.length == 7) {
        weeks.add(Row(children: currentWeek));
        weeks.add(const SizedBox(height: AppSpacing.xs));
        currentWeek = [];
      }
    }

    // 마지막 주 빈 칸 채우기
    while (currentWeek.length < 7 && currentWeek.isNotEmpty) {
      currentWeek.add(const Expanded(child: SizedBox(height: 60)));
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(Row(children: currentWeek));
    }

    // 6주가 안되면 빈 주 추가 (레이아웃 일관성)
    while (weeks.length < 11) { // 6주 * 2 (Row + SizedBox) - 1
      weeks.add(const SizedBox(height: 60 + AppSpacing.xs));
    }

    return weeks;
  }


  Widget _buildDayCell(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, _selectedDate);
    final dateKey = DateTime(date.year, date.month, date.day);
    final medications = _medicationData[dateKey];
    final additionalRecords = _additionalRecordData[dateKey];
    final treatmentEvents = _treatmentEventData[dateKey];
    final cycleResult = _cycleResultData[dateKey];

    int completed = 0;
    int total = 0;
    if (medications != null) {
      total = medications.length;
      completed = medications.where((m) => m.isCompleted).length;
    }

    // 표시할 색상 점 구성 (약물 알림)
    List<Color> dotColors = [];

    // 약물 복용 점 (완료: 초록, 미완료: 빨강)
    if (total > 0) {
      final medDotCount = total > 2 ? 2 : total;
      for (int i = 0; i < medDotCount; i++) {
        dotColors.add(i < completed ? AppColors.success : AppColors.error);
      }
    }

    // 시술 이벤트에 따른 원형 배경 색상 결정
    // 우선순위: 판정(사이클결과) > 이식 > 채취 > 시작(과배란)
    Color? circleBackgroundColor;
    if (cycleResult != null) {
      // 판정: 진보라 20% 투명도
      circleBackgroundColor = const Color(0xFF7C3AED).withValues(alpha: 0.2);
    } else if (treatmentEvents != null && treatmentEvents.isNotEmpty) {
      // 이벤트 타입별 색상 결정 (우선순위 적용)
      final hasTransfer = treatmentEvents.any((e) => e.type == EventType.transfer);
      final hasRetrieval = treatmentEvents.any((e) => e.type == EventType.retrieval);
      final hasStimulation = treatmentEvents.any((e) => e.type == EventType.stimulation);
      final hasInsemination = treatmentEvents.any((e) => e.type == EventType.insemination);
      final hasFreezing = treatmentEvents.any((e) => e.type == EventType.freezing);

      if (hasTransfer) {
        // 이식: 핑크(초록) 20% 투명도
        circleBackgroundColor = const Color(0xFF10B981).withValues(alpha: 0.2);
      } else if (hasRetrieval) {
        // 채취: 노랑(주황) 20% 투명도
        circleBackgroundColor = const Color(0xFFF59E0B).withValues(alpha: 0.2);
      } else if (hasInsemination) {
        // 인공수정: 핑크 20% 투명도
        circleBackgroundColor = const Color(0xFFEC4899).withValues(alpha: 0.2);
      } else if (hasFreezing) {
        // 동결: 하늘색 20% 투명도
        circleBackgroundColor = const Color(0xFF06B6D4).withValues(alpha: 0.2);
      } else if (hasStimulation) {
        // 시작(과배란): 보라 20% 투명도
        circleBackgroundColor = AppColors.primaryPurple.withValues(alpha: 0.2);
      }
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryPurpleLight
                : isToday
                    ? AppColors.primaryPurple.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: AppColors.primaryPurple, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 숫자 (시술 기록 있으면 원형 배경 안에)
              if (circleBackgroundColor != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: circleBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryPurpleDark : AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '${date.day}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primaryPurpleDark : AppColors.textPrimary,
                  ),
                ),
              // 약물 알림 점 (숫자 아래)
              if (dotColors.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dotColors.map((color) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 시간대별로 약물 그룹화
  Map<String, List<MedicationStatus>> _groupMedicationsByTime(List<MedicationStatus> medications) {
    final grouped = <String, List<MedicationStatus>>{};

    for (final med in medications) {
      final timeKey = '${med.scheduledTime.hour.toString().padLeft(2, '0')}:${med.scheduledTime.minute.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(timeKey, () => []).add(med);
    }

    // 시간순 정렬
    final sortedKeys = grouped.keys.toList()..sort();
    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, grouped[k]!)));
  }

  Widget _buildSelectedDateDetail() {
    final dateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final medications = _medicationData[dateKey];
    final additionalRecords = _additionalRecordData[dateKey];
    final treatmentEvents = _treatmentEventData[dateKey];
    final cycleResult = _cycleResultData[dateKey];

    // 완료 카운트 계산
    final completedCount = medications?.where((m) => m.isCompleted).length ?? 0;
    final totalCount = medications?.length ?? 0;
    final isAllCompleted = totalCount > 0 && completedCount == totalCount;

    // 오늘인지 확인
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = dateKey.isAtSameMomentAs(today);

    // 제목 텍스트
    final titleText = isToday
        ? '오늘도 한 걸음'
        : '${_selectedDate.month}월 ${_selectedDate.day}일의 한 걸음';

    // 기록이 하나도 없는지 확인
    final hasNoRecords = (medications == null || medications.isEmpty) &&
        (additionalRecords == null || additionalRecords.isEmpty) &&
        (treatmentEvents == null || treatmentEvents.isEmpty) &&
        cycleResult == null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('👣', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    titleText,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isAllCompleted
                        ? const Color(0xFFE8DEF8)
                        : AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAllCompleted
                        ? '수고했어요 💜'
                        : '$completedCount/$totalCount',
                    style: AppTextStyles.caption.copyWith(
                      color: isAllCompleted
                          ? const Color(0xFF7C4DFF)
                          : AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 시술 기록 표시 (있는 경우)
          if ((treatmentEvents != null && treatmentEvents.isNotEmpty) || cycleResult != null) ...[
            _buildTreatmentEventsSummary(treatmentEvents, cycleResult),
            if ((additionalRecords != null && additionalRecords.isNotEmpty) ||
                (medications != null && medications.isNotEmpty))
              const SizedBox(height: AppSpacing.m),
          ],

          // 추가 기록 표시 (있는 경우)
          if (additionalRecords != null && additionalRecords.isNotEmpty) ...[
            _buildAdditionalRecordsSummary(additionalRecords),
            if (medications != null && medications.isNotEmpty)
              const SizedBox(height: AppSpacing.m),
          ],

          if (hasNoRecords)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurpleLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('💊', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      '이 날은 등록된 기록이 없어요',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (medications != null && medications.isNotEmpty)
            ..._buildTimeGroupedList(medications, dateKey),
        ],
      ),
    );
  }

  /// 시술 기록 요약 표시
  Widget _buildTreatmentEventsSummary(List<TreatmentEvent>? events, CycleResult? cycleResult) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시술 기록',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            children: [
              // 시술 이벤트 칩들
              if (events != null)
                ...events.map((event) => _buildTreatmentEventChip(event)),
              // 사이클 결과 칩
              if (cycleResult != null)
                _buildCycleResultChip(cycleResult),
            ],
          ),
        ],
      ),
    );
  }

  /// 시술 이벤트 칩
  Widget _buildTreatmentEventChip(TreatmentEvent event) {
    final color = _getEventTypeColor(event.type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            event.type.displayText,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 사이클 결과 칩
  Widget _buildCycleResultChip(CycleResult result) {
    const color = Color(0xFF7C3AED); // 딥퍼플
    final resultText = result == CycleResult.success
        ? '좋은 소식이 있어요!'
        : result == CycleResult.frozen
            ? '동결하고 기다려요'
            : result == CycleResult.rest
                ? '쉬어가기로 했어요'
                : '다음을 준비해요';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            resultText,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 이벤트 타입별 색상 반환
  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.stimulation:
        return AppColors.primaryPurple;
      case EventType.retrieval:
        return const Color(0xFFF59E0B); // 오렌지/노랑
      case EventType.transfer:
        return const Color(0xFF10B981); // 그린
      case EventType.freezing:
        return const Color(0xFF06B6D4); // 시안
      case EventType.insemination:
        return const Color(0xFFEC4899); // 핑크
    }
  }

  /// 추가 기록 요약 표시
  Widget _buildAdditionalRecordsSummary(Set<RecordType> records) {
    // 표시 우선순위
    final priorityOrder = [
      RecordType.period,
      RecordType.ultrasound,
      RecordType.pregnancyTest,
      RecordType.condition,
    ];

    final sortedRecords = priorityOrder.where((type) => records.contains(type)).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            children: sortedRecords.map((type) => _buildRecordChip(type)).toList(),
          ),
        ],
      ),
    );
  }

  /// 기록 타입 칩
  Widget _buildRecordChip(RecordType type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: type.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: type.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            type.name,
            style: AppTextStyles.caption.copyWith(
              color: type.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 시간대별 그룹화된 리스트 빌드
  List<Widget> _buildTimeGroupedList(List<MedicationStatus> medications, DateTime dateKey) {
    final grouped = _groupMedicationsByTime(medications);
    final widgets = <Widget>[];

    for (final entry in grouped.entries) {
      widgets.add(_buildTimeSlotGroup(entry.key, entry.value, dateKey));
    }

    return widgets;
  }

  /// 시간대 그룹 위젯 (홈 화면과 동일한 UI)
  Widget _buildTimeSlotGroup(String timeKey, List<MedicationStatus> medications, DateTime dateKey) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = dateKey.isAtSameMomentAs(today);

    // 시간 파싱
    final parts = timeKey.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // 시간 지남 여부 확인 (오늘인 경우에만)
    bool isPastTime = false;
    if (isToday) {
      final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      isPastTime = now.isAfter(scheduledDateTime);
    }

    // 과거 날짜인 경우도 시간 지남으로 표시
    final isPastDate = dateKey.isBefore(today);

    // 전체 완료 여부
    final allCompleted = medications.every((m) => m.isCompleted);

    // 시간 포맷 (홈 화면과 동일)
    final timeLabel = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeText = '$timeLabel $displayHour:${minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시간 헤더 + 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  timeText,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: allCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                if ((isPastTime || isPastDate) && !allCompleted) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '· 시간 지남',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (allCompleted) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                ],
              ],
            ),
            // 복용 버튼
            if (!allCompleted)
              GestureDetector(
                onTap: () => _handleTimeSlotComplete(medications, dateKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    medications.length > 1 ? '모두 복용' : '복용',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        // 약물 목록
        ...medications.map((med) => _buildMedicationInGroup(med, dateKey)),

        const SizedBox(height: AppSpacing.s),
      ],
    );
  }

  /// 시간대 그룹 내 복용 완료 처리
  Future<void> _handleTimeSlotComplete(List<MedicationStatus> medications, DateTime dateKey) async {
    for (final med in medications) {
      if (!med.isCompleted) {
        await _completeMedication(med, dateKey);
      }
    }
  }

  /// 개별 약물 복용 완료 처리
  Future<void> _completeMedication(MedicationStatus med, DateTime dateKey) async {
    // 저장소에 복용 상태 저장 (성공 후 UI 업데이트)
    try {
      await MedicationStorageService.setMedicationStatus(
        dateKey,
        med.medicationId,
        true,
      );
      if (mounted) {
        setState(() {
          med.isCompleted = true;
          med.completedAt = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('❌ 복용 완료 저장 실패: $e');
    }
  }

  /// 약물 복용 취소 처리
  Future<void> _uncompleteMedication(MedicationStatus med, DateTime dateKey) async {
    // 저장소에서 복용 상태 취소 (성공 후 UI 업데이트)
    try {
      await MedicationStorageService.setMedicationStatus(
        dateKey,
        med.medicationId,
        false,
      );
      if (mounted) {
        setState(() {
          med.isCompleted = false;
          med.completedAt = null;
        });
      }
    } catch (e) {
      debugPrint('❌ 복용 취소 저장 실패: $e');
    }
  }

  /// 그룹 내 개별 약물 아이템 (홈 화면 UI와 동일)
  Widget _buildMedicationInGroup(MedicationStatus med, DateTime dateKey) {
    final isInjection = med.type == 'injection';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          // 완료 체크
          GestureDetector(
            onTap: med.isCompleted ? null : () => _completeMedication(med, dateKey),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: med.isCompleted ? AppColors.success : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: med.isCompleted ? AppColors.success : AppColors.border,
                  width: 2,
                ),
              ),
              child: med.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.s),

          // 약물 정보 (클릭하면 액션 시트)
          Expanded(
            child: GestureDetector(
              onTap: () => _showMedicationActionSheet(med, dateKey),
              child: Row(
                children: [
                  // 약물 아이콘
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isInjection
                          ? AppColors.primaryPurpleLight
                          : AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isInjection ? Icons.vaccines : Icons.medication,
                      color: isInjection ? AppColors.primaryPurple : AppColors.info,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),

                  // 약물명
                  Expanded(
                    child: Text(
                      med.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: med.isCompleted ? TextDecoration.lineThrough : null,
                        color: med.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // 수정 힌트 아이콘
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textDisabled,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicationActionSheet(MedicationStatus med, DateTime dateKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        med.name,
                        style: AppTextStyles.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 수정 버튼
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await _editMedication(med.medicationId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurpleLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '수정',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // 삭제 버튼
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteConfirmDialog(med);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '삭제',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_selectedDate.month}월 ${_selectedDate.day}일',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                Text(
                  '이 약을 복용하셨나요?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // 완료 버튼
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _completeMedication(med, dateKey);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          '네, 복용했어요',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),

                // 건너뛰기 버튼
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    await _uncompleteMedication(med, dateKey);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          '아니요, 건너뛰었어요',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(MedicationStatus med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('약물 삭제'),
        content: Text('${med.name}을(를) 삭제하시겠어요?\n\n이 작업은 되돌릴 수 없습니다.'),
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
              Navigator.pop(context);
              await _deleteMedication(med.medicationId, med.name);
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
  Future<void> _deleteMedication(String medicationId, String name) async {
    try {
      // 1. 로컬에서 삭제
      await MedicationStorageService.deleteMedication(medicationId, addToSyncQueue: false);

      // 2. 클라우드에서 삭제 (로그인 상태일 때)
      if (CloudStorageService.isLoggedIn) {
        await CloudStorageService.deleteMedication(medicationId);
      }

      // 3. 알림 취소
      await NotificationSchedulerService.cancelMedicationNotification(medicationId);

      // 4. 데이터 새로고침
      await _loadMedications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name이(가) 삭제되었습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 약물 수정 화면으로 이동
  Future<void> _editMedication(String medicationId) async {
    // 약물 정보 조회
    final medication = await MedicationStorageService.getMedicationById(medicationId);

    if (medication == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('약물 정보를 찾을 수 없습니다')),
        );
      }
      return;
    }

    if (!mounted) return;

    // 수정 화면으로 이동
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddMedicationScreen(
          editingMedication: medication,
        ),
      ),
    );

    // 수정 완료 후 데이터 새로고침
    if (result == true) {
      await _loadMedications();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class MedicationStatus {
  final String id;
  final String medicationId; // 원본 약물 ID (저장소 연동용)
  final String name;
  final String type; // 'pill', 'injection', 'suppository', 'patch'
  final TimeOfDay scheduledTime;
  bool isCompleted;
  DateTime? completedAt;
  String? injectionSide; // 주사인 경우: 'left' / 'right'

  MedicationStatus({
    required this.id,
    required this.medicationId,
    required this.name,
    required this.type,
    required this.scheduledTime,
    required this.isCompleted,
    this.completedAt,
    this.injectionSide,
  });

  String get formattedTime {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    if (hour < 12) {
      return '오전 ${hour == 0 ? 12 : hour}:$minute';
    } else {
      return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
    }
  }

  String get formattedCompletedTime {
    if (completedAt == null) return '';
    final hour = completedAt!.hour;
    final minute = completedAt!.minute.toString().padLeft(2, '0');
    if (hour < 12) {
      return '오전 ${hour == 0 ? 12 : hour}:$minute';
    } else {
      return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
    }
  }
}
