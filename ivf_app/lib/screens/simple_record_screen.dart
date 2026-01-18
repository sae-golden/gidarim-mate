import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import '../models/additional_records.dart';
import '../services/simple_treatment_service.dart';
import '../services/additional_record_service.dart';
import '../widgets/timeline_widgets.dart';
import '../widgets/event_type_bottom_sheet.dart';
import '../widgets/event_edit_bottom_sheet.dart';
import '../widgets/cycle_result_bottom_sheet.dart';
import '../widgets/new_cycle_bottom_sheet.dart';
import '../widgets/blood_test_bottom_sheet.dart';
import '../widgets/period_bottom_sheet.dart';
import '../widgets/ultrasound_bottom_sheet.dart';
import '../widgets/pregnancy_test_bottom_sheet.dart';
import '../widgets/condition_bottom_sheet.dart';
import '../widgets/cycle_edit_bottom_sheet.dart';
import '../services/blood_test_service.dart';

/// 타임라인 기반 기록 화면
class SimpleRecordScreen extends StatefulWidget {
  const SimpleRecordScreen({super.key});

  @override
  State<SimpleRecordScreen> createState() => _SimpleRecordScreenState();
}

class _SimpleRecordScreenState extends State<SimpleRecordScreen> {
  List<TreatmentCycle> _allCycles = []; // 모든 사이클 (현재 + 과거)
  Map<String, List<BloodTest>> _bloodTestsByCycle = {}; // 사이클별 피검사
  bool _isLoading = true;
  bool _hasCycleStarted = false; // 사이클이 명시적으로 생성되었는지

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 사이클이 명시적으로 생성되었는지 확인
    final hasCycleStarted = await SimpleTreatmentService.hasCycleStarted();

    final currentCycle = await SimpleTreatmentService.getCurrentCycle();
    final pastCycles = await SimpleTreatmentService.getPastCycles();

    // 모든 사이클 합치기 (현재 + 과거)
    final allCycles = <TreatmentCycle>[];
    allCycles.add(currentCycle);
    allCycles.addAll(pastCycles);

    // 최신이 위로 정렬 (시작일 기준 내림차순)
    allCycles.sort((a, b) => b.startDate.compareTo(a.startDate));

    // 각 사이클별 피검사 로드
    final bloodTestsByCycle = <String, List<BloodTest>>{};
    for (final cycle in allCycles) {
      bloodTestsByCycle[cycle.id] = await BloodTestService.getBloodTests(cycle.id);
    }

    if (!mounted) return;
    setState(() {
      _allCycles = allCycles;
      _bloodTestsByCycle = bloodTestsByCycle;
      _hasCycleStarted = hasCycleStarted;
      _isLoading = false;
    });
  }

  /// 현재 진행 중인 사이클 (첫 번째 미완료 사이클)
  TreatmentCycle? get _currentCycle {
    for (final cycle in _allCycles) {
      if (cycle.result == null) return cycle;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // 사이클이 없으면 단계 선택 화면 바로 표시
    if (!_hasCycleStarted) {
      return _buildStageSelectionScreen();
    }

    // 모든 사이클을 한 페이지에서 보여주기
    return Column(
      children: [
        // 간단한 헤더 (지난 기록 버튼 없이)
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Text('기록', style: AppTextStyles.h2),
            ],
          ),
        ),
        Expanded(child: _buildAllCyclesTimeline()),
      ],
    );
  }

  /// 단계 선택 화면 (시술 선택 화면 제거됨)
  Widget _buildStageSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Text('기록', style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // 중앙 콘텐츠 (스크롤 가능)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.l),
                  Text(
                    '어떤 단계를 기록할까요?',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    '시작하는 단계를 선택해주세요',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 이벤트 타입 버튼들 (자주 사용하는 것들)
                  _buildStageButton(
                    emoji: '💉',
                    title: '과배란 주사',
                    subtitle: '난포 자극 호르몬 주사 시작',
                    onTap: () => _startWithStage(EventType.stimulation),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildStageButton(
                    emoji: '🥚',
                    title: '난자 채취',
                    subtitle: '채취 일정 기록',
                    onTap: () => _startWithStage(EventType.retrieval),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildStageButton(
                    emoji: '🌱',
                    title: '배아 이식',
                    subtitle: '이식 일정 기록',
                    onTap: () => _startWithStage(EventType.transfer),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  _buildStageButton(
                    emoji: '📊',
                    title: '피검사',
                    subtitle: 'E2, P4, FSH, LH 등 기록',
                    onTap: () => _startWithBloodTest(),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 새 사이클 시작 버튼
                  TextButton.icon(
                    onPressed: _startNewCycleFromEmpty,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('새로운 시술 사이클 시작'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 단계 선택 버튼
  Widget _buildStageButton({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.m),
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
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 단계 선택 시 사이클 자동 생성 후 이벤트 추가
  Future<void> _startWithStage(EventType eventType) async {
    // 기본 IVF 사이클 자동 생성
    await SimpleTreatmentService.createDefaultCycle();

    if (!mounted) return;

    // 이벤트 편집 바텀시트 표시
    final newEvent = await EventEditBottomSheet.showForNew(
      context,
      eventType: eventType,
    );

    if (newEvent != null) {
      await SimpleTreatmentService.addEvent(newEvent);
    }

    await _loadData();
  }

  /// 피검사로 시작
  Future<void> _startWithBloodTest() async {
    // 기본 IVF 사이클 자동 생성
    await SimpleTreatmentService.createDefaultCycle();
    await _loadData();

    final currentCycle = _currentCycle;
    if (currentCycle == null || !mounted) return;

    final newTest = await BloodTestBottomSheet.showForNew(
      context,
      cycleId: currentCycle.id,
    );

    if (newTest != null) {
      await _loadData();
    }
  }

  /// 빈 상태에서 새 사이클 시작
  Future<void> _startNewCycleFromEmpty() async {
    final newCycle = await NewCycleBottomSheet.show(context);

    if (newCycle != null) {
      await _loadData();

      if (!mounted) return;

      final typeText = newCycle.type == TreatmentType.ivf ? '시험관' : '인공수정';
      String optionText = '';
      if (newCycle.isFrozenTransfer) {
        optionText = ' (동결배아 이식)';
      } else if (newCycle.isNaturalCycle) {
        optionText = ' (자연주기)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newCycle.cycleNumber}차 $typeText$optionText 시도를 시작합니다!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 모든 사이클 타임라인 (한 페이지 스크롤)
  Widget _buildAllCyclesTimeline() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      itemCount: _allCycles.length,
      separatorBuilder: (context, index) => const Divider(height: 32, thickness: 1),
      itemBuilder: (context, index) {
        final cycle = _allCycles[index];
        // 진행중인 사이클은 _currentCycle과 동일한 경우에만 (가장 최신의 결과 없는 사이클)
        final isCurrentCycle = _currentCycle?.id == cycle.id;
        final bloodTests = _bloodTestsByCycle[cycle.id] ?? [];

        return _buildCycleTimeline(
          cycle: cycle,
          bloodTests: bloodTests,
          isCurrentCycle: isCurrentCycle,
        );
      },
    );
  }

  /// 단일 사이클 타임라인
  Widget _buildCycleTimeline({
    required TreatmentCycle cycle,
    required List<BloodTest> bloodTests,
    required bool isCurrentCycle,
  }) {
    final sortedEvents = cycle.sortedEvents;
    final hasEvents = sortedEvents.isNotEmpty;
    final hasBloodTests = bloodTests.isNotEmpty;
    final hasAnyRecords = hasEvents || hasBloodTests;

    // 이벤트와 피검사를 날짜순으로 병합
    final timelineItems = _buildMergedTimeline(sortedEvents, bloodTests);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 사이클 헤더: "2차 시험관 (진행중)"
        _buildCycleHeader(cycle, isCurrentCycle),
        const SizedBox(height: AppSpacing.m),

        // 1. 시작 노드
        TimelineStart(
          startDate: cycle.startDate,
          cycleNumber: cycle.cycleNumber,
          treatmentType: cycle.type,
          onTap: isCurrentCycle ? () => _editStartDate(cycle) : null,
        ),

        // 2. 빈 상태 메시지 (이벤트가 없을 때, 진행 중인 사이클만)
        if (!hasAnyRecords && cycle.result == null && isCurrentCycle)
          _buildEmptyMessage(),

        // 3. 병합된 타임라인 아이템들
        ...timelineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == timelineItems.length - 1 && cycle.result == null;

          if (item is TreatmentEvent) {
            return TimelineEventWidget(
              event: item,
              isLast: isLast,
              onTap: isCurrentCycle ? () => _editEvent(item) : null,
            );
          } else if (item is BloodTest) {
            return TimelineBloodTestWidget(
              bloodTest: item,
              onTap: isCurrentCycle ? () => _editBloodTest(item) : null,
            );
          }
          return const SizedBox.shrink();
        }),

        // 4. 추가 버튼 (진행 중인 사이클만)
        if (isCurrentCycle && cycle.result == null) ...[
          TimelineAddButton(
            hint: cycle.nextStepHint,
            onTap: _addEvent,
            isFirst: !hasAnyRecords,
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        // 5. 결과 노드 (결과가 있는 경우만 표시)
        if (cycle.result != null)
          TimelineEnd(
            result: cycle.result!,
            endDate: cycle.endDate,
            onTap: isCurrentCycle ? _editCycleResult : null,
          ),

        const SizedBox(height: AppSpacing.m),
      ],
    );
  }

  /// 사이클 헤더 (예: "2차 시험관 (진행중)")
  Widget _buildCycleHeader(TreatmentCycle cycle, bool isCurrentCycle) {
    final typeText = cycle.type == TreatmentType.ivf ? '시험관' : '인공수정';
    String optionText = '';
    if (cycle.isFrozenTransfer) {
      optionText = ' (동결배아 이식)';
    } else if (cycle.isNaturalCycle) {
      optionText = ' (자연주기)';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '${cycle.cycleNumber}차 $typeText$optionText',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 수정 버튼 (진행 중인 사이클만)
        if (isCurrentCycle) ...[
          InkWell(
            onTap: () => _editCycleInfo(cycle),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE9D5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '진행중',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF9B7ED9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        if (!isCurrentCycle && cycle.result != null) ...[
          const SizedBox(width: AppSpacing.s),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cycle.result == CycleResult.success
                  ? Colors.green.withValues(alpha: 0.1)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cycle.result == CycleResult.success
                    ? Colors.green
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cycle.result!.emoji,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 2),
                Text(
                  cycle.result!.shortLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 이벤트와 피검사를 날짜순으로 병합
  List<dynamic> _buildMergedTimeline(
    List<TreatmentEvent> events,
    List<BloodTest> bloodTests,
  ) {
    final items = <dynamic>[...events, ...bloodTests];
    items.sort((a, b) {
      final dateA = a is TreatmentEvent ? a.date : (a as BloodTest).date;
      final dateB = b is TreatmentEvent ? b.date : (b as BloodTest).date;
      return dateA.compareTo(dateB);
    });
    return items;
  }

  /// 빈 상태 메시지 (안내 텍스트만, 블록 없음)
  Widget _buildEmptyMessage() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: AppSpacing.xs, bottom: AppSpacing.s),
      child: Text(
        '차근차근 함께 기록해요',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textDisabled,
        ),
      ),
    );
  }

  /// 시작일 편집 (특정 사이클)
  Future<void> _editStartDate(TreatmentCycle cycle) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cycle.startDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final updatedCycle = cycle.copyWith(startDate: picked);
      await SimpleTreatmentService.saveCycle(updatedCycle);
      await _loadData(); // 데이터 새로고침
    }
  }

  /// 이벤트 추가
  Future<void> _addEvent() async {
    final currentCycle = _currentCycle;
    if (currentCycle == null) return;

    // 기록이 있는지 확인
    final hasEvents = currentCycle.events.isNotEmpty;
    final bloodTests = _bloodTestsByCycle[currentCycle.id] ?? [];
    final hasBloodTests = bloodTests.isNotEmpty;
    final hasRecords = hasEvents || hasBloodTests;

    // 시술 종류별 기록 항목 분기 처리
    // IVF: 모든 항목 표시
    // IUI: 과배란(선택적), 인공수정 표시 / 채취, 이식, 동결 숨김
    // 자연주기 (IUI + isNaturalCycle): 과배란 숨김
    final isIVF = currentCycle.type == TreatmentType.ivf;
    final isNaturalCycle = currentCycle.isNaturalCycle;

    final result = await EventTypeBottomSheet.show(
      context,
      availableTypes: currentCycle.availableEventTypes,
      showFinishOption: hasRecords, // 기록 있을 때만 마무리 옵션 표시
      showBloodTestOption: true, // 피검사: 모든 시술에서 표시
      showNewCycleOption: true,
      hasRecords: hasRecords,
      // 신규 항목 표시 여부 (시술 종류별 분기)
      showPeriodOption: true, // 생리 시작일: 모든 시술에서 표시
      showUltrasoundOption: true, // 초음파 검사: 모든 시술에서 표시
      showPregnancyTestOption: true, // 임신 테스트: 모든 시술에서 표시
      showConditionOption: true, // 몸 상태: 모든 시술에서 표시
    );

    if (result == null) return;

    if (result == 'finish') {
      await _selectCycleResult();
      return;
    }

    if (result == 'bloodTest') {
      await _addBloodTest();
      return;
    }

    if (result == 'newCycle') {
      await _startNewCycle();
      return;
    }

    // 신규 항목 처리
    if (result == 'period') {
      await _addPeriodRecord();
      return;
    }

    if (result == 'ultrasound') {
      await _addUltrasoundRecord();
      return;
    }

    if (result == 'pregnancyTest') {
      await _addPregnancyTestRecord();
      return;
    }

    if (result == 'condition') {
      await _addConditionRecord();
      return;
    }

    if (result is EventType) {
      if (!mounted) return;
      final newEvent = await EventEditBottomSheet.showForNew(
        context,
        eventType: result,
      );

      if (newEvent != null) {
        await SimpleTreatmentService.addEvent(newEvent);
        await _loadData(); // 데이터 새로고침
      }
    }
  }

  /// 피검사 기록 추가
  Future<void> _addBloodTest() async {
    final currentCycle = _currentCycle;
    if (currentCycle == null) return;

    final newTest = await BloodTestBottomSheet.showForNew(
      context,
      cycleId: currentCycle.id,
    );

    if (newTest != null) {
      await _loadData(); // 데이터 새로고침

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('피검사 기록이 추가되었습니다'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 피검사 기록 편집
  Future<void> _editBloodTest(BloodTest test) async {
    final result = await BloodTestBottomSheet.showForEdit(
      context,
      test: test,
    );

    if (result == null) return;

    await _loadData(); // 데이터 새로고침

    if (result == 'delete' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('피검사 기록이 삭제되었습니다'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 이벤트 편집
  Future<void> _editEvent(TreatmentEvent event) async {
    final result = await EventEditBottomSheet.showForEdit(
      context,
      event: event,
    );

    if (result == null) return;

    if (result == 'delete') {
      await SimpleTreatmentService.removeEvent(event.id);
      await _loadData(); // 데이터 새로고침

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.type.name} 기록이 삭제되었습니다'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (result is TreatmentEvent) {
      await SimpleTreatmentService.updateEvent(result);
      await _loadData(); // 데이터 새로고침
    }
  }

  /// 사이클 결과 선택
  Future<void> _selectCycleResult() async {
    final result = await CycleResultBottomSheet.show(
      context,
      currentResult: _currentCycle?.result,
    );

    if (result == null) return;

    if (result == 'clear') {
      await SimpleTreatmentService.clearCycleResult();
      await _loadData(); // 데이터 새로고침
    } else if (result is CycleResult) {
      await SimpleTreatmentService.setCycleResult(result);
      await _loadData(); // 데이터 새로고침
    }
  }

  /// 사이클 결과 편집
  Future<void> _editCycleResult() async {
    await _selectCycleResult();
  }

  /// 새 사이클 시작
  Future<void> _startNewCycle() async {
    final newCycle = await NewCycleBottomSheet.show(context);

    if (newCycle != null) {
      await _loadData(); // 데이터 새로고침

      if (!mounted) return;

      final typeText =
          newCycle.type == TreatmentType.ivf ? '시험관' : '인공수정';
      String optionText = '';
      if (newCycle.isFrozenTransfer) {
        optionText = ' (동결배아 이식)';
      } else if (newCycle.isNaturalCycle) {
        optionText = ' (자연주기)';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${newCycle.cycleNumber}차 $typeText$optionText 시도를 시작합니다!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ============================================================
  // 신규 기록 항목 메서드들
  // ============================================================

  /// 생리 시작일 기록 추가
  Future<void> _addPeriodRecord() async {
    final currentCycle = _currentCycle;
    final newRecord = await PeriodBottomSheet.showForNew(
      context,
      cycleId: currentCycle?.id,
    );

    if (newRecord != null) {
      await AdditionalRecordService.addPeriodRecord(newRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('생리 시작일이 기록되었습니다'),
          backgroundColor: RecordType.period.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 초음파 검사 기록 추가
  Future<void> _addUltrasoundRecord() async {
    final currentCycle = _currentCycle;
    final newRecord = await UltrasoundBottomSheet.showForNew(
      context,
      cycleId: currentCycle?.id,
    );

    if (newRecord != null) {
      await AdditionalRecordService.addUltrasoundRecord(newRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('초음파 검사 기록이 추가되었습니다'),
          backgroundColor: RecordType.ultrasound.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 임신 테스트 기록 추가
  Future<void> _addPregnancyTestRecord() async {
    final currentCycle = _currentCycle;
    final newRecord = await PregnancyTestBottomSheet.showForNew(
      context,
      cycleId: currentCycle?.id,
    );

    if (newRecord != null) {
      await AdditionalRecordService.addPregnancyTestRecord(newRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('임신 테스트 기록이 추가되었습니다'),
          backgroundColor: RecordType.pregnancyTest.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 몸 상태 기록 추가
  Future<void> _addConditionRecord() async {
    final currentCycle = _currentCycle;
    final newRecord = await ConditionBottomSheet.showForNew(
      context,
      cycleId: currentCycle?.id,
    );

    if (newRecord != null) {
      await AdditionalRecordService.addConditionRecord(newRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('몸 상태가 기록되었습니다'),
          backgroundColor: RecordType.condition.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ============================================================
  // 시술 정보 수정/삭제
  // ============================================================

  /// 시술 정보 수정 바텀시트 열기
  Future<void> _editCycleInfo(TreatmentCycle cycle) async {
    final result = await CycleEditBottomSheet.show(
      context,
      cycle: cycle,
    );

    if (result == null) return;

    // 삭제 요청
    if (result == 'delete') {
      await _deleteCycle(cycle);
      return;
    }

    // 수정된 사이클
    if (result is TreatmentCycle) {
      await SimpleTreatmentService.updateCycle(result);
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('시술 정보가 수정되었습니다'),
          backgroundColor: AppColors.primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 시술 주기 삭제
  Future<void> _deleteCycle(TreatmentCycle cycle) async {
    // 연관된 피검사 기록도 함께 삭제
    await BloodTestService.removeBloodTestsForCycle(cycle.id);

    // 사이클 삭제
    await SimpleTreatmentService.deleteCycle(cycle.id);
    await _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${cycle.cycleNumber}차 시술 기록이 삭제되었습니다'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

}
