import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/completion_overlay.dart';
import '../widgets/injection_site_bottom_sheet.dart';
import '../services/medication_storage_service.dart';
import '../services/notification_scheduler_service.dart';
import '../services/additional_record_service.dart';
import '../services/simple_treatment_service.dart';
import '../models/medication.dart' as med_model;
import '../models/additional_records.dart';
import '../models/simple_treatment_cycle.dart';
import '../widgets/medication_action_bottom_sheet.dart';
import 'quick_add_medication_screen.dart';
import 'voice_input_screen.dart';

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

  // 날짜별 추가 기록 타입 (신규 4개 항목) - 캘린더 도트 표시용
  Map<DateTime, Set<RecordType>> _additionalRecordData = {};

  // 날짜별 추가 기록 상세 데이터 - 타임라인 표시용
  Map<DateTime, List<dynamic>> _additionalRecordDetails = {};

  // 날짜별 시술 이벤트 (기록 탭 연동)
  Map<DateTime, List<TreatmentEvent>> _treatmentEventData = {};

  // 날짜별 사이클 결과 (판정일)
  Map<DateTime, CycleResult> _cycleResultData = {};

  // 날짜별 사이클 시작일 (시작 표시용)
  Map<DateTime, List<Map<String, dynamic>>> _cycleStartData = {};

  // PageView 컨트롤러 (캘린더 스와이프용)
  late PageController _pageController;
  static const int _initialPage = 1200; // 100년치 (중간값)

  // 복용 완료 이벤트 구독 (알림에서 복용 시 즉시 UI 반영)
  StreamSubscription<String>? _medicationCompletedSubscription;

  // 주사 부위 추천을 위한 마지막 사용 부위 추적
  String? _lastInjectionSide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _initialPage);
    _subscribeToMedicationEvents();
    _loadMedications();
  }

  /// 약물 복용 완료 이벤트 구독
  void _subscribeToMedicationEvents() {
    _medicationCompletedSubscription = MedicationStorageService.onMedicationCompleted.listen((medicationId) {
      debugPrint('🔄 복용 완료 이벤트 수신: $medicationId - 캘린더 화면 갱신');
      _loadMedications();
    });
  }

  @override
  void dispose() {
    _medicationCompletedSubscription?.cancel();
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

  /// 기록 추가 바텀시트 표시
  void _showAddRecordSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // 제목
              Text(
                '어떤 기록을 추가할까요?',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: AppSpacing.s),

              // 선택된 날짜 표시
              Text(
                '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // 약물 직접 입력
              _buildAddRecordOption(
                icon: Icons.medication,
                iconColor: AppColors.primaryPurple,
                title: '약물 직접 입력',
                subtitle: '투약 일정 추가',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuickAddMedicationScreen(),
                    ),
                  );
                  if (result != null) {
                    _loadMedications();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.s),

              // 음성으로 약물 입력
              _buildAddRecordOption(
                icon: Icons.mic,
                iconColor: AppColors.success,
                title: '음성으로 약물 입력',
                subtitle: '여러 약 한번에 입력 가능',
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImprovedVoiceInputScreen(),
                    ),
                  );
                  if (result != null) {
                    _loadMedications();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ),
    );
  }

  /// 기록 추가 옵션 카드
  Widget _buildAddRecordOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 화살표
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
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

    // 추가 기록 상세 데이터 로드 (타임라인 표시용)
    final periodRecords = await AdditionalRecordService.getPeriodRecordsByDateRange(startDate, endDate);
    final ultrasoundRecords = await AdditionalRecordService.getUltrasoundRecordsByDateRange(startDate, endDate);
    final pregnancyTestRecords = await AdditionalRecordService.getPregnancyTestRecordsByDateRange(startDate, endDate);
    final conditionRecords = await AdditionalRecordService.getConditionRecordsByDateRange(startDate, endDate);
    final hospitalVisitRecords = await AdditionalRecordService.getHospitalVisitRecordsByDateRange(startDate, endDate);

    // 날짜별로 추가 기록 상세 데이터 그룹화
    final additionalDetails = <DateTime, List<dynamic>>{};
    for (final record in periodRecords) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      additionalDetails.putIfAbsent(dateKey, () => []).add(record);
    }
    for (final record in ultrasoundRecords) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      additionalDetails.putIfAbsent(dateKey, () => []).add(record);
    }
    for (final record in pregnancyTestRecords) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      additionalDetails.putIfAbsent(dateKey, () => []).add(record);
    }
    for (final record in conditionRecords) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      additionalDetails.putIfAbsent(dateKey, () => []).add(record);
    }
    for (final record in hospitalVisitRecords) {
      final dateKey = DateTime(record.date.year, record.date.month, record.date.day);
      additionalDetails.putIfAbsent(dateKey, () => []).add(record);
    }

    // 시술 이벤트 데이터 로드 (기록 탭 연동)
    final treatmentEvents = await SimpleTreatmentService.getEventsByDateRange(startDate, endDate);
    final cycleResults = await SimpleTreatmentService.getCycleResultsByDateRange(startDate, endDate);
    final cycleStarts = await SimpleTreatmentService.getCycleStartDatesByRange(startDate, endDate);

    // 디버그: 시술 이벤트 및 사이클 시작일 데이터 확인
    debugPrint('📅 캘린더 시술 이벤트 로드: ${treatmentEvents.length}개 날짜');
    for (final entry in treatmentEvents.entries) {
      debugPrint('  - ${entry.key}: ${entry.value.map((e) => e.type.name).join(", ")}');
    }
    debugPrint('📅 캘린더 사이클 시작일 로드: ${cycleStarts.length}개 날짜');
    for (final entry in cycleStarts.entries) {
      debugPrint('  - ${entry.key}: ${entry.value.map((e) => "${e['cycleNumber']}차").join(", ")}');
    }

    setState(() {
      _medicationData = data;
      _additionalRecordData = additionalRecords;
      _additionalRecordDetails = additionalDetails;
      _treatmentEventData = treatmentEvents;
      _cycleResultData = cycleResults;
      _cycleStartData = cycleStarts;
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
      body: Column(
        children: [
          // 상단 고정 영역: 월 선택 + 캘린더
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.m, AppSpacing.m, AppSpacing.m, 0),
            child: Column(
              children: [
                _buildMonthHeader(),
                const SizedBox(height: AppSpacing.m),
                _buildCalendar(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          // 하단 스크롤 영역: 선택된 날짜 상세 정보
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.m, 0, AppSpacing.m, AppSpacing.m),
              child: _buildSelectedDateDetail(),
            ),
          ),
        ],
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
            height: 240, // 6주치 높이 (34*6 + 간격 + 여유)
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
    // SingleChildScrollView 제거 - PageView 내부에 고정 높이로 스크롤 불필요
    return Column(
      children: _buildCalendarWeeksForMonth(month),
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
      currentWeek.add(const Expanded(child: SizedBox(height: 34)));
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
      currentWeek.add(const Expanded(child: SizedBox(height: 34)));
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(Row(children: currentWeek));
    }

    // 6주가 안되면 빈 주 추가 (레이아웃 일관성)
    while (weeks.length < 11) { // 6주 * 2 (Row + SizedBox) - 1
      weeks.add(const SizedBox(height: 34 + AppSpacing.xs));
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
    final cycleStarts = _cycleStartData[dateKey];

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
    // 우선순위: 판정(사이클결과) > 이식 > 채취 > 사이클시작 > 시작(과배란)
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
    } else if (cycleStarts != null && cycleStarts.isNotEmpty) {
      // 사이클 시작일: 보라 20% 투명도
      circleBackgroundColor = AppColors.primaryPurple.withValues(alpha: 0.2);
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: Container(
          height: 34,
          margin: const EdgeInsets.all(1),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: circleBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primaryPurpleDark : AppColors.textPrimary,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  '${date.day}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.primaryPurpleDark : AppColors.textPrimary,
                  ),
                ),
              // 약물 알림 점 (숫자 아래)
              if (dotColors.isNotEmpty) ...[
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dotColors.map((color) => Container(
                    width: 4,
                    height: 4,
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
    final additionalDetails = _additionalRecordDetails[dateKey];
    final treatmentEvents = _treatmentEventData[dateKey];
    final cycleResult = _cycleResultData[dateKey];
    final cycleStarts = _cycleStartData[dateKey];

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
        (additionalDetails == null || additionalDetails.isEmpty) &&
        (treatmentEvents == null || treatmentEvents.isEmpty) &&
        cycleResult == null &&
        (cycleStarts == null || cycleStarts.isEmpty);

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
          else
            // 통합 타임라인: 시술 기록 + 일상 기록 + 약물 복용을 하나로 표시
            _buildUnifiedTimeline(
              treatmentEvents: treatmentEvents,
              cycleResult: cycleResult,
              cycleStarts: cycleStarts,
              additionalDetails: additionalDetails,
              medications: medications,
              dateKey: dateKey,
            ),
        ],
      ),
    );
  }

  /// 통합 타임라인 빌드 (시술 + 일상 기록 + 약물 복용)
  Widget _buildUnifiedTimeline({
    List<TreatmentEvent>? treatmentEvents,
    CycleResult? cycleResult,
    List<Map<String, dynamic>>? cycleStarts,
    List<dynamic>? additionalDetails,
    List<MedicationStatus>? medications,
    required DateTime dateKey,
  }) {
    // 모든 기록을 통합 아이템 리스트로 변환
    final items = <_UnifiedTimelineItem>[];

    // 1. 사이클 시작일
    if (cycleStarts != null) {
      for (final start in cycleStarts) {
        items.add(_UnifiedTimelineItem(
          type: _TimelineItemType.cycleStart,
          data: start,
          sortOrder: 0, // 시작일은 맨 위
        ));
      }
    }

    // 2. 시술 이벤트들
    if (treatmentEvents != null && treatmentEvents.isNotEmpty) {
      for (final event in treatmentEvents) {
        items.add(_UnifiedTimelineItem(
          type: _TimelineItemType.treatmentEvent,
          data: event,
          sortOrder: 1,
          createdAt: event.createdAt,
        ));
      }
    }

    // 3. 사이클 결과
    if (cycleResult != null) {
      items.add(_UnifiedTimelineItem(
        type: _TimelineItemType.cycleResult,
        data: cycleResult,
        sortOrder: 2,
      ));
    }

    // 4. 일상 기록 (추가 기록)
    if (additionalDetails != null && additionalDetails.isNotEmpty) {
      for (final record in additionalDetails) {
        // 각 레코드 타입에서 createdAt 추출
        DateTime? recordCreatedAt;
        if (record is PeriodRecord) {
          recordCreatedAt = record.createdAt;
        } else if (record is UltrasoundRecord) {
          recordCreatedAt = record.createdAt;
        } else if (record is PregnancyTestRecord) {
          recordCreatedAt = record.createdAt;
        } else if (record is ConditionRecord) {
          recordCreatedAt = record.createdAt;
        } else if (record is HospitalVisitRecord) {
          recordCreatedAt = record.createdAt;
        }
        items.add(_UnifiedTimelineItem(
          type: _TimelineItemType.additionalRecord,
          data: record,
          sortOrder: 3,
          createdAt: recordCreatedAt,
        ));
      }
    }

    // 5. 약물 복용
    if (medications != null && medications.isNotEmpty) {
      // 시간대별 그룹화
      final grouped = _groupMedicationsByTime(medications);
      for (final entry in grouped.entries) {
        items.add(_UnifiedTimelineItem(
          type: _TimelineItemType.medication,
          data: {'time': entry.key, 'meds': entry.value},
          sortOrder: 4,
        ));
      }
    }

    // 정렬: sortOrder 기준, 동일 타입 내에서는 createdAt 기준 (최신순)
    items.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      // 동일 타입 내에서는 createdAt 최신순 정렬
      if (a.createdAt != null && b.createdAt != null) {
        return b.createdAt!.compareTo(a.createdAt!); // 최신이 위로
      }
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          _buildUnifiedTimelineItem(
            items[i],
            isLast: i == items.length - 1,
            dateKey: dateKey,
          ),
      ],
    );
  }

  /// 통합 타임라인 개별 아이템 빌드
  Widget _buildUnifiedTimelineItem(
    _UnifiedTimelineItem item, {
    required bool isLast,
    required DateTime dateKey,
  }) {
    switch (item.type) {
      case _TimelineItemType.cycleStart:
        return _buildTimelineStartItem(item.data as Map<String, dynamic>, isLast: isLast);
      case _TimelineItemType.treatmentEvent:
        return _buildTimelineEventItem(item.data as TreatmentEvent, isLast: isLast);
      case _TimelineItemType.cycleResult:
        return _buildTimelineResultItem(item.data as CycleResult);
      case _TimelineItemType.additionalRecord:
        return _buildAdditionalRecordTimelineItem(item.data, isLast: isLast);
      case _TimelineItemType.medication:
        final data = item.data as Map<String, dynamic>;
        return _buildMedicationTimelineItem(
          data['time'] as String,
          data['meds'] as List<MedicationStatus>,
          dateKey,
          isLast: isLast,
        );
    }
  }

  /// 약물 복용 타임라인 아이템 (통합 타임라인용)
  Widget _buildMedicationTimelineItem(
    String timeKey,
    List<MedicationStatus> medications,
    DateTime dateKey, {
    bool isLast = false,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = dateKey.isAtSameMomentAs(today);

    // 시간 파싱
    final parts = timeKey.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // 시간 지남 여부 확인
    bool isPastTime = false;
    if (isToday) {
      final scheduledDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      isPastTime = now.isAfter(scheduledDateTime);
    }
    final isPastDate = dateKey.isBefore(today);

    // 전체 완료 여부
    final allCompleted = medications.every((m) => m.isCompleted);

    // 시간 포맷
    final timeLabel = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeText = '$timeLabel $displayHour:${minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 노드
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: allCompleted
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.primaryPurpleLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: allCompleted ? AppColors.success : AppColors.primaryPurple,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      allCompleted ? Icons.check : Icons.medication,
                      size: 14,
                      color: allCompleted ? AppColors.success : AppColors.primaryPurple,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 20),
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 구분선
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 12,
              height: 2,
              color: const Color(0xFFE9D5FF),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 내용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Column(
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
                            style: AppTextStyles.body.copyWith(
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
                            Icon(Icons.check_circle, size: 14, color: AppColors.success),
                          ],
                        ],
                      ),
                      // 복용 버튼
                      if (!allCompleted)
                        GestureDetector(
                          onTap: () => _handleTimeSlotComplete(medications, dateKey),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurpleLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              medications.length > 1 ? '모두 복용' : '복용',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // 약물 목록
                  ...medications.map((med) => _buildMedicationInTimeline(med, dateKey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 타임라인 내 약물 아이템
  Widget _buildMedicationInTimeline(MedicationStatus med, DateTime dateKey) {
    final isInjection = med.type == 'injection';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: GestureDetector(
        onTap: () => _showMedicationActionSheet(med, dateKey),
        child: Row(
          children: [
            // 완료 체크
            GestureDetector(
              onTap: med.isCompleted ? null : () => _completeMedication(med, dateKey),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: med.isCompleted ? AppColors.success : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: med.isCompleted ? AppColors.success : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: med.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // 약물 아이콘
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isInjection
                    ? AppColors.primaryPurpleLight
                    : AppColors.info.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isInjection ? Icons.vaccines : Icons.medication,
                color: isInjection ? AppColors.primaryPurple : AppColors.info,
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // 약물명
            Expanded(
              child: Text(
                med.name,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: med.isCompleted ? TextDecoration.lineThrough : null,
                  color: med.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 시술 기록 타임라인 형식 표시 (기록 탭과 동일한 스타일)
  Widget _buildTreatmentEventsSummary(
    List<TreatmentEvent>? events,
    CycleResult? cycleResult,
    List<Map<String, dynamic>>? cycleStarts,
  ) {
    // 타임라인 아이템 구성 (시작일 -> 이벤트 -> 결과 순서)
    final items = <Widget>[];

    // 1. 사이클 시작일
    if (cycleStarts != null) {
      for (final start in cycleStarts) {
        items.add(_buildTimelineStartItem(start, isLast: items.isEmpty && (events == null || events.isEmpty) && cycleResult == null));
      }
    }

    // 2. 시술 이벤트들 (날짜순 정렬)
    if (events != null && events.isNotEmpty) {
      final sortedEvents = List<TreatmentEvent>.from(events)
        ..sort((a, b) => a.date.compareTo(b.date));

      for (int i = 0; i < sortedEvents.length; i++) {
        final isLast = i == sortedEvents.length - 1 && cycleResult == null;
        items.add(_buildTimelineEventItem(sortedEvents[i], isLast: isLast));
      }
    }

    // 3. 사이클 결과
    if (cycleResult != null) {
      items.add(_buildTimelineResultItem(cycleResult));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  /// 타임라인 시작 아이템 (사이클 시작일)
  Widget _buildTimelineStartItem(Map<String, dynamic> cycleInfo, {bool isLast = false}) {
    final cycleNumber = cycleInfo['cycleNumber'] as int;
    final type = cycleInfo['type'] as TreatmentType;
    final isFrozen = cycleInfo['isFrozenTransfer'] as bool? ?? false;
    final isNatural = cycleInfo['isNaturalCycle'] as bool? ?? false;
    final startDate = cycleInfo['startDate'] as DateTime;

    String typeText = type == TreatmentType.ivf ? '시험관' : '인공수정';
    if (isFrozen) typeText = '동결이식';
    if (isNatural) typeText = '자연주기';

    final dateText = '${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 노드
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 20),
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 구분선
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 12,
              height: 2,
              color: const Color(0xFFE9D5FF),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 내용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시작 $dateText',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$cycleNumber차 $typeText',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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

  /// 타임라인 이벤트 아이템
  Widget _buildTimelineEventItem(TreatmentEvent event, {bool isLast = false}) {
    final dateText = '${event.date.month.toString().padLeft(2, '0')}.${event.date.day.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 노드
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF9B7ED9),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      event.type.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 20),
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 구분선
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 12,
              height: 2,
              color: const Color(0xFFE9D5FF),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 내용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.type.displayText,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getEventDetailText(event, dateText),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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

  /// 이벤트 상세 텍스트
  String _getEventDetailText(TreatmentEvent event, String dateText) {
    switch (event.type) {
      case EventType.stimulation:
        return dateText;
      case EventType.retrieval:
        final parts = <String>[dateText];
        if (event.count != null) {
          final retrievalParts = <String>['${event.count}개'];
          if (event.matureCount != null) {
            retrievalParts.add('성숙 ${event.matureCount}개');
          }
          if (event.fertilizedCount != null) {
            retrievalParts.add('수정 ${event.fertilizedCount}개');
          }
          parts.add(retrievalParts.join(' → '));
        }
        return parts.join(' · ');
      case EventType.transfer:
      case EventType.freezing:
        final parts = <String>[dateText];
        if (event.embryos != null && event.embryos!.isNotEmpty) {
          parts.add(event.embryos!.map((e) => e.displayText).join(', '));
        } else if (event.embryoDays != null && event.count != null) {
          parts.add('${event.embryoDays}일 ${event.count}개');
        } else if (event.count != null) {
          parts.add('${event.count}개');
        }
        return parts.join(' · ');
      case EventType.insemination:
        return dateText;
    }
  }

  /// 타임라인 결과 아이템
  Widget _buildTimelineResultItem(CycleResult result) {
    final resultColor = _getResultColor(result);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 노드
          SizedBox(
            width: 40,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: resultColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  result.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 구분선
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 12,
              height: 2,
              color: resultColor.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 내용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Text(
                result.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: resultColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 사이클 결과 색상
  Color _getResultColor(CycleResult result) {
    switch (result) {
      case CycleResult.success:
        return Colors.green;
      case CycleResult.frozen:
        return Colors.blue;
      case CycleResult.rest:
      case CycleResult.nextTime:
        return AppColors.primaryPurple;
    }
  }


  /// 추가 기록 타임라인 표시 (기록 탭과 동일한 스타일)
  Widget _buildAdditionalRecordsTimeline(List<dynamic> records) {
    // 표시 우선순위에 따라 정렬
    final priorityOrder = {
      PeriodRecord: 0,
      UltrasoundRecord: 1,
      PregnancyTestRecord: 2,
      HospitalVisitRecord: 3,
      ConditionRecord: 4,
    };

    final sortedRecords = List.from(records)
      ..sort((a, b) {
        final priorityA = priorityOrder[a.runtimeType] ?? 99;
        final priorityB = priorityOrder[b.runtimeType] ?? 99;
        return priorityA.compareTo(priorityB);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sortedRecords.length; i++)
          _buildAdditionalRecordTimelineItem(
            sortedRecords[i],
            isLast: i == sortedRecords.length - 1,
          ),
      ],
    );
  }

  /// 추가 기록 타임라인 아이템
  Widget _buildAdditionalRecordTimelineItem(dynamic record, {bool isLast = false}) {
    RecordType recordType;
    String summary;

    if (record is PeriodRecord) {
      recordType = RecordType.period;
      summary = record.memo ?? '생리 시작';
    } else if (record is UltrasoundRecord) {
      recordType = RecordType.ultrasound;
      summary = record.summaryText;
    } else if (record is PregnancyTestRecord) {
      recordType = RecordType.pregnancyTest;
      summary = record.summaryText;
    } else if (record is ConditionRecord) {
      recordType = RecordType.condition;
      summary = record.summaryText;
    } else if (record is HospitalVisitRecord) {
      recordType = RecordType.hospitalVisit;
      summary = record.summaryText;
    } else {
      return const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타임라인 노드
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: recordType.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: recordType.color,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      recordType.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: const BoxConstraints(minHeight: 16),
                      color: recordType.color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 구분선
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 12,
              height: 2,
              color: recordType.color.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 내용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recordType.displayText,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 추가 기록 요약 표시 (칩 형식 - 폴백용)
  Widget _buildAdditionalRecordsSummary(Set<RecordType> records) {
    // 표시 우선순위
    final priorityOrder = [
      RecordType.period,
      RecordType.ultrasound,
      RecordType.pregnancyTest,
      RecordType.hospitalVisit,
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
    final incompleteMeds = medications.where((med) => !med.isCompleted).toList();
    if (incompleteMeds.isEmpty) return;

    // 여러 개를 한번에 완료할 때는 마지막 하나에만 애니메이션 표시
    for (int i = 0; i < incompleteMeds.length; i++) {
      final isLast = i == incompleteMeds.length - 1;
      await _completeMedication(incompleteMeds[i], dateKey, showAnimation: isLast);
    }
  }

  /// 개별 약물 복용 완료 처리
  Future<void> _completeMedication(MedicationStatus med, DateTime dateKey, {bool showAnimation = true}) async {
    final isInjection = med.type == 'injection';

    // 주사인 경우 먼저 부위 선택 모달 표시
    if (isInjection) {
      final selectedSide = await InjectionSiteBottomSheet.show(
        context,
        medicationName: med.name,
        lastSide: _lastInjectionSide,
      );

      // 사용자가 취소한 경우
      if (selectedSide == null) return;

      // 선택한 부위 저장
      _lastInjectionSide = selectedSide;
    }

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

        // 완료 애니메이션 표시 (주사인 경우 모달 닫힘 후 딜레이)
        if (showAnimation) {
          if (isInjection) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (mounted) {
            CompletionOverlay.show(
              context,
              medicationName: med.name,
              isInjection: isInjection,
            );
          }
        }
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

  /// 약물 클릭 시 액션 모달 표시
  Future<void> _showMedicationActionSheet(MedicationStatus med, DateTime dateKey) async {
    final result = await MedicationActionBottomSheet.show(
      context,
      medicationName: med.name,
      date: _selectedDate,
      isCompleted: med.isCompleted,
    );

    if (result == null) return;

    switch (result) {
      case MedicationActionResult.complete:
        await _completeMedication(med, dateKey);
        break;
      case MedicationActionResult.skip:
        await _uncompleteMedication(med, dateKey);
        break;
      case MedicationActionResult.edit:
        await _editMedication(med.medicationId);
        break;
      case MedicationActionResult.delete:
        await _showDeleteConfirmDialog(med);
        break;
    }
  }

  /// 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog(MedicationStatus med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('약물 삭제'),
        content: Text('${med.name}을(를) 삭제하시겠어요?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMedication(med.medicationId, med.name);
    }
  }

  /// 약물 삭제
  Future<void> _deleteMedication(String medicationId, String name) async {
    try {
      // 1. 로컬에서 삭제
      await MedicationStorageService.deleteMedication(medicationId, addToSyncQueue: false);

      // 2. 알림 취소
      await NotificationSchedulerService.cancelMedicationNotification(medicationId);

      // 3. 데이터 새로고침
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
            backgroundColor: AppColors.error,
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

/// 통합 타임라인 아이템 타입
enum _TimelineItemType {
  cycleStart,      // 사이클 시작
  treatmentEvent,  // 시술 이벤트 (채취, 이식, 동결 등)
  cycleResult,     // 사이클 결과 (판정)
  additionalRecord, // 일상 기록 (생리, 초음파, 임신테스트, 몸상태)
  medication,      // 약물 복용
}

/// 통합 타임라인 아이템
class _UnifiedTimelineItem {
  final _TimelineItemType type;
  final dynamic data;
  final int sortOrder;
  final DateTime? createdAt; // 생성 시간 (동일 타입 내 정렬용)

  _UnifiedTimelineItem({
    required this.type,
    required this.data,
    required this.sortOrder,
    this.createdAt,
  });
}
