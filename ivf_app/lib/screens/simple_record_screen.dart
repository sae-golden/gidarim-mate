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
import '../widgets/hospital_visit_bottom_sheet.dart';
import '../services/blood_test_service.dart';

/// 타임라인 기반 기록 화면
class SimpleRecordScreen extends StatefulWidget {
  final VoidCallback? onRecordChanged;

  const SimpleRecordScreen({super.key, this.onRecordChanged});

  @override
  State<SimpleRecordScreen> createState() => _SimpleRecordScreenState();
}

class _SimpleRecordScreenState extends State<SimpleRecordScreen> {
  List<TreatmentCycle> _allCycles = []; // 모든 사이클 (현재 + 과거)
  Map<String, List<BloodTest>> _bloodTestsByCycle = {}; // 사이클별 피검사
  // 추가 기록 항목들
  Map<String, List<PeriodRecord>> _periodRecordsByCycle = {};
  Map<String, List<UltrasoundRecord>> _ultrasoundRecordsByCycle = {};
  Map<String, List<PregnancyTestRecord>> _pregnancyTestRecordsByCycle = {};
  Map<String, List<ConditionRecord>> _conditionRecordsByCycle = {};
  Map<String, List<HospitalVisitRecord>> _hospitalVisitRecordsByCycle = {};
  // 사이클 없는 추가 기록들
  List<PeriodRecord> _orphanPeriodRecords = [];
  List<UltrasoundRecord> _orphanUltrasoundRecords = [];
  List<PregnancyTestRecord> _orphanPregnancyTestRecords = [];
  List<ConditionRecord> _orphanConditionRecords = [];
  List<HospitalVisitRecord> _orphanHospitalVisitRecords = [];
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

    // 각 사이클별 추가 기록 항목 로드
    final periodRecordsByCycle = <String, List<PeriodRecord>>{};
    final ultrasoundRecordsByCycle = <String, List<UltrasoundRecord>>{};
    final pregnancyTestRecordsByCycle = <String, List<PregnancyTestRecord>>{};
    final conditionRecordsByCycle = <String, List<ConditionRecord>>{};
    final hospitalVisitRecordsByCycle = <String, List<HospitalVisitRecord>>{};

    for (final cycle in allCycles) {
      periodRecordsByCycle[cycle.id] = await AdditionalRecordService.getPeriodRecordsByCycle(cycle.id);
      ultrasoundRecordsByCycle[cycle.id] = await AdditionalRecordService.getUltrasoundRecordsByCycle(cycle.id);
      pregnancyTestRecordsByCycle[cycle.id] = await AdditionalRecordService.getPregnancyTestRecordsByCycle(cycle.id);
      conditionRecordsByCycle[cycle.id] = await AdditionalRecordService.getConditionRecordsByCycle(cycle.id);
      hospitalVisitRecordsByCycle[cycle.id] = await AdditionalRecordService.getHospitalVisitRecordsByCycle(cycle.id);
    }

    // 사이클 없는 추가 기록들 로드
    // 기존 orphan 조회 + 존재하지 않는 사이클 ID를 가진 기록도 포함
    final validCycleIds = allCycles.map((c) => c.id).toSet();

    final allPeriodRecords = await AdditionalRecordService.getAllPeriodRecords();
    final allUltrasoundRecords = await AdditionalRecordService.getAllUltrasoundRecords();
    final allPregnancyTestRecords = await AdditionalRecordService.getAllPregnancyTestRecords();
    final allConditionRecords = await AdditionalRecordService.getAllConditionRecords();
    final allHospitalVisitRecords = await AdditionalRecordService.getAllHospitalVisitRecords();

    // cycleId가 null, 빈 문자열, 또는 존재하지 않는 사이클 ID인 경우 orphan으로 분류
    final orphanPeriodRecords = allPeriodRecords.where((r) =>
        r.cycleId == null || r.cycleId!.isEmpty || !validCycleIds.contains(r.cycleId)).toList();
    final orphanUltrasoundRecords = allUltrasoundRecords.where((r) =>
        r.cycleId == null || r.cycleId!.isEmpty || !validCycleIds.contains(r.cycleId)).toList();
    final orphanPregnancyTestRecords = allPregnancyTestRecords.where((r) =>
        r.cycleId == null || r.cycleId!.isEmpty || !validCycleIds.contains(r.cycleId)).toList();
    final orphanConditionRecords = allConditionRecords.where((r) =>
        r.cycleId == null || r.cycleId!.isEmpty || !validCycleIds.contains(r.cycleId)).toList();
    final orphanHospitalVisitRecords = allHospitalVisitRecords.where((r) =>
        r.cycleId == null || r.cycleId!.isEmpty || !validCycleIds.contains(r.cycleId)).toList();

    if (!mounted) return;
    setState(() {
      _allCycles = allCycles;
      _bloodTestsByCycle = bloodTestsByCycle;
      _periodRecordsByCycle = periodRecordsByCycle;
      _ultrasoundRecordsByCycle = ultrasoundRecordsByCycle;
      _pregnancyTestRecordsByCycle = pregnancyTestRecordsByCycle;
      _conditionRecordsByCycle = conditionRecordsByCycle;
      _hospitalVisitRecordsByCycle = hospitalVisitRecordsByCycle;
      _orphanPeriodRecords = orphanPeriodRecords;
      _orphanUltrasoundRecords = orphanUltrasoundRecords;
      _orphanPregnancyTestRecords = orphanPregnancyTestRecords;
      _orphanConditionRecords = orphanConditionRecords;
      _orphanHospitalVisitRecords = orphanHospitalVisitRecords;
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

  /// 사이클 없는 추가 기록이 있는지 확인
  bool get _hasOrphanRecords {
    return _orphanPeriodRecords.isNotEmpty ||
        _orphanUltrasoundRecords.isNotEmpty ||
        _orphanPregnancyTestRecords.isNotEmpty ||
        _orphanConditionRecords.isNotEmpty ||
        _orphanHospitalVisitRecords.isNotEmpty;
  }

  Widget _buildContent() {
    // 사이클이 없으면 "첫 단계 기록하기" 화면 표시 (단, 사이클 없는 기록이 있으면 보여줌)
    if (!_hasCycleStarted && !_hasOrphanRecords) {
      return _buildEmptyFirstScreen();
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

  /// 첫 진입 시 빈 화면 (시술 정보 없을 때)
  Widget _buildEmptyFirstScreen() {
    return Column(
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Text('기록', style: AppTextStyles.h2),
            ],
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 안내 텍스트
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.m),
                  child: Text(
                    '💜 차근차근 함께 기록해요',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),

                // 첫 단계 기록하기 버튼 (타임라인 노드 스타일)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타임라인 노드 (빈 원)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE9D5FF),
                          width: 2,
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
                        color: const Color(0xFFE9D5FF),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // 첫 단계 기록하기 버튼
                    Expanded(
                      child: GestureDetector(
                        onTap: _showFirstCycleSetup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '첫 단계 기록하기',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 첫 시술 정보 설정 바텀시트 표시
  Future<void> _showFirstCycleSetup() async {
    final newCycle = await NewCycleBottomSheet.show(
      context,
      isFirstCycle: true,
    );

    if (newCycle != null) {
      widget.onRecordChanged?.call();
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
          content: Text('${newCycle.cycleNumber}차 $typeText$optionText 시작!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 모든 사이클 타임라인 (한 페이지 스크롤)
  Widget _buildAllCyclesTimeline() {
    // 사이클이 없고 사이클 없는 기록만 있는 경우
    if (_allCycles.isEmpty || (!_hasCycleStarted && _hasOrphanRecords)) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        children: [
          // 사이클 없는 기록들 표시
          if (_hasOrphanRecords) _buildOrphanRecordsTimeline(),
          // 첫 사이클 생성 버튼
          if (!_hasCycleStarted) ...[
            const SizedBox(height: AppSpacing.l),
            _buildStartCycleButton(),
          ],
        ],
      );
    }

    // 사이클 개수 + 사이클 없는 기록 섹션 (있는 경우)
    final totalItems = _allCycles.length + (_hasOrphanRecords ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      itemCount: totalItems,
      separatorBuilder: (context, index) => const Divider(height: 32, thickness: 1),
      itemBuilder: (context, index) {
        // 마지막 아이템이 사이클 없는 기록 섹션
        if (_hasOrphanRecords && index == totalItems - 1) {
          return _buildOrphanRecordsTimeline();
        }

        final cycle = _allCycles[index];
        // 진행중인 사이클은 _currentCycle과 동일한 경우에만 (가장 최신의 결과 없는 사이클)
        final isCurrentCycle = _currentCycle?.id == cycle.id;
        final bloodTests = _bloodTestsByCycle[cycle.id] ?? [];
        final periodRecords = _periodRecordsByCycle[cycle.id] ?? [];
        final ultrasoundRecords = _ultrasoundRecordsByCycle[cycle.id] ?? [];
        final pregnancyTestRecords = _pregnancyTestRecordsByCycle[cycle.id] ?? [];
        final conditionRecords = _conditionRecordsByCycle[cycle.id] ?? [];
        final hospitalVisitRecords = _hospitalVisitRecordsByCycle[cycle.id] ?? [];

        return _buildCycleTimeline(
          cycle: cycle,
          bloodTests: bloodTests,
          periodRecords: periodRecords,
          ultrasoundRecords: ultrasoundRecords,
          pregnancyTestRecords: pregnancyTestRecords,
          conditionRecords: conditionRecords,
          hospitalVisitRecords: hospitalVisitRecords,
          isCurrentCycle: isCurrentCycle,
        );
      },
    );
  }

  /// 첫 사이클 생성 버튼
  Widget _buildStartCycleButton() {
    return GestureDetector(
      onTap: _showFirstCycleSetup,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.primaryPurpleLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '시술 시작하기',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  Text(
                    '시술 정보를 입력하고 기록을 시작해요',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.primaryPurple),
          ],
        ),
      ),
    );
  }

  /// 사이클 없는 기록들 타임라인
  Widget _buildOrphanRecordsTimeline() {
    // 모든 사이클 없는 기록들을 날짜순으로 병합
    final allOrphanRecords = <dynamic>[
      ..._orphanPeriodRecords,
      ..._orphanUltrasoundRecords,
      ..._orphanPregnancyTestRecords,
      ..._orphanConditionRecords,
      ..._orphanHospitalVisitRecords,
    ];

    // 날짜순 정렬 (최신순)
    allOrphanRecords.sort((a, b) {
      final dateA = _getItemDate(a);
      final dateB = _getItemDate(b);
      return dateB.compareTo(dateA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '기타 기록',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '시술에 연결되지 않은 기록',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        // 기록들 표시
        ...allOrphanRecords.map((item) {
          if (item is PeriodRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.period,
              date: item.date,
              summary: item.memo ?? '생리 시작',
              onTap: () => _editPeriodRecord(item),
            );
          } else if (item is UltrasoundRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.ultrasound,
              date: item.date,
              summary: item.summaryText,
              onTap: () => _editUltrasoundRecord(item),
            );
          } else if (item is PregnancyTestRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.pregnancyTest,
              date: item.date,
              summary: item.summaryText,
              onTap: () => _editPregnancyTestRecord(item),
            );
          } else if (item is ConditionRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.condition,
              date: item.date,
              summary: item.summaryText,
              onTap: () => _editConditionRecord(item),
            );
          } else if (item is HospitalVisitRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.hospitalVisit,
              date: item.date,
              summary: item.summaryText,
              onTap: () => _editHospitalVisitRecord(item),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  /// 단일 사이클 타임라인
  Widget _buildCycleTimeline({
    required TreatmentCycle cycle,
    required List<BloodTest> bloodTests,
    required List<PeriodRecord> periodRecords,
    required List<UltrasoundRecord> ultrasoundRecords,
    required List<PregnancyTestRecord> pregnancyTestRecords,
    required List<ConditionRecord> conditionRecords,
    required List<HospitalVisitRecord> hospitalVisitRecords,
    required bool isCurrentCycle,
  }) {
    final sortedEvents = cycle.sortedEvents;
    final hasEvents = sortedEvents.isNotEmpty;
    final hasBloodTests = bloodTests.isNotEmpty;
    final hasAdditionalRecords = periodRecords.isNotEmpty ||
        ultrasoundRecords.isNotEmpty ||
        pregnancyTestRecords.isNotEmpty ||
        conditionRecords.isNotEmpty ||
        hospitalVisitRecords.isNotEmpty;
    final hasAnyRecords = hasEvents || hasBloodTests || hasAdditionalRecords;

    // 이벤트와 피검사, 추가 기록을 날짜순으로 병합
    final timelineItems = _buildMergedTimeline(
      sortedEvents,
      bloodTests,
      periodRecords: periodRecords,
      ultrasoundRecords: ultrasoundRecords,
      pregnancyTestRecords: pregnancyTestRecords,
      conditionRecords: conditionRecords,
      hospitalVisitRecords: hospitalVisitRecords,
    );

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
          } else if (item is PeriodRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.period,
              date: item.date,
              summary: item.memo ?? '생리 시작',
              onTap: isCurrentCycle ? () => _editPeriodRecord(item) : null,
            );
          } else if (item is UltrasoundRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.ultrasound,
              date: item.date,
              summary: item.summaryText,
              onTap: isCurrentCycle ? () => _editUltrasoundRecord(item) : null,
            );
          } else if (item is PregnancyTestRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.pregnancyTest,
              date: item.date,
              summary: item.summaryText,
              onTap: isCurrentCycle ? () => _editPregnancyTestRecord(item) : null,
            );
          } else if (item is ConditionRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.condition,
              date: item.date,
              summary: item.summaryText,
              onTap: isCurrentCycle ? () => _editConditionRecord(item) : null,
            );
          } else if (item is HospitalVisitRecord) {
            return TimelineAdditionalRecordWidget(
              recordType: RecordType.hospitalVisit,
              date: item.date,
              summary: item.summaryText,
              onTap: isCurrentCycle ? () => _editHospitalVisitRecord(item) : null,
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

  /// 이벤트와 피검사, 추가 기록을 날짜순으로 병합
  List<dynamic> _buildMergedTimeline(
    List<TreatmentEvent> events,
    List<BloodTest> bloodTests, {
    List<PeriodRecord> periodRecords = const [],
    List<UltrasoundRecord> ultrasoundRecords = const [],
    List<PregnancyTestRecord> pregnancyTestRecords = const [],
    List<ConditionRecord> conditionRecords = const [],
    List<HospitalVisitRecord> hospitalVisitRecords = const [],
  }) {
    final items = <dynamic>[
      ...events,
      ...bloodTests,
      ...periodRecords,
      ...ultrasoundRecords,
      ...pregnancyTestRecords,
      ...conditionRecords,
      ...hospitalVisitRecords,
    ];
    items.sort((a, b) {
      final dateA = _getItemDate(a);
      final dateB = _getItemDate(b);
      return dateA.compareTo(dateB);
    });
    return items;
  }

  /// 타임라인 아이템의 날짜 추출
  DateTime _getItemDate(dynamic item) {
    if (item is TreatmentEvent) return item.date;
    if (item is BloodTest) return item.date;
    if (item is PeriodRecord) return item.date;
    if (item is UltrasoundRecord) return item.date;
    if (item is PregnancyTestRecord) return item.date;
    if (item is ConditionRecord) return item.date;
    if (item is HospitalVisitRecord) return item.date;
    return DateTime.now();
  }

  /// 빈 상태 메시지 (안내 텍스트만, 블록 없음)
  Widget _buildEmptyMessage() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, top: AppSpacing.xs, bottom: AppSpacing.s),
      child: Row(
        children: [
          Text(
            '💜 차근차근 함께 기록해요',
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
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

    if (result == 'hospitalVisit') {
      await _addHospitalVisitRecord();
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
        widget.onRecordChanged?.call();
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
      widget.onRecordChanged?.call();
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

    widget.onRecordChanged?.call();
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
      widget.onRecordChanged?.call();
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
      widget.onRecordChanged?.call();
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
      widget.onRecordChanged?.call();
      await _loadData(); // 데이터 새로고침
    } else if (result is CycleResult) {
      await SimpleTreatmentService.setCycleResult(result);
      widget.onRecordChanged?.call();
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
      widget.onRecordChanged?.call();
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
      widget.onRecordChanged?.call();
      await _loadData(); // 화면 데이터 새로고침

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
      widget.onRecordChanged?.call();
      await _loadData(); // 화면 데이터 새로고침

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
      widget.onRecordChanged?.call();
      await _loadData(); // 화면 데이터 새로고침

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
      widget.onRecordChanged?.call();
      await _loadData(); // 화면 데이터 새로고침

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
      widget.onRecordChanged?.call();
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
    widget.onRecordChanged?.call();
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

  // ============================================================
  // 추가 기록 항목 편집
  // ============================================================

  /// 생리 시작일 기록 편집
  Future<void> _editPeriodRecord(PeriodRecord record) async {
    final result = await PeriodBottomSheet.showForEdit(
      context,
      record: record,
    );

    if (result == null) return;

    if (result == 'delete') {
      await AdditionalRecordService.deletePeriodRecord(record.id);
      widget.onRecordChanged?.call();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('생리 시작일 기록이 삭제되었습니다'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (result is PeriodRecord) {
      await AdditionalRecordService.updatePeriodRecord(result);
      widget.onRecordChanged?.call();
      await _loadData();
    }
  }

  /// 초음파 검사 기록 편집
  Future<void> _editUltrasoundRecord(UltrasoundRecord record) async {
    final result = await UltrasoundBottomSheet.showForEdit(
      context,
      record: record,
    );

    if (result == null) return;

    if (result == 'delete') {
      await AdditionalRecordService.deleteUltrasoundRecord(record.id);
      widget.onRecordChanged?.call();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('초음파 검사 기록이 삭제되었습니다'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (result is UltrasoundRecord) {
      await AdditionalRecordService.updateUltrasoundRecord(result);
      widget.onRecordChanged?.call();
      await _loadData();
    }
  }

  /// 임신 테스트 기록 편집
  Future<void> _editPregnancyTestRecord(PregnancyTestRecord record) async {
    final result = await PregnancyTestBottomSheet.showForEdit(
      context,
      record: record,
    );

    if (result == null) return;

    if (result == 'delete') {
      await AdditionalRecordService.deletePregnancyTestRecord(record.id);
      widget.onRecordChanged?.call();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('임신 테스트 기록이 삭제되었습니다'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (result is PregnancyTestRecord) {
      await AdditionalRecordService.updatePregnancyTestRecord(result);
      widget.onRecordChanged?.call();
      await _loadData();
    }
  }

  /// 몸 상태 기록 편집
  Future<void> _editConditionRecord(ConditionRecord record) async {
    final result = await ConditionBottomSheet.showForEdit(
      context,
      record: record,
    );

    if (result == null) return;

    if (result == 'delete') {
      await AdditionalRecordService.deleteConditionRecord(record.id);
      widget.onRecordChanged?.call();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('몸 상태 기록이 삭제되었습니다'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (result is ConditionRecord) {
      await AdditionalRecordService.updateConditionRecord(result);
      widget.onRecordChanged?.call();
      await _loadData();
    }
  }

  /// 병원 예약 기록 추가
  Future<void> _addHospitalVisitRecord() async {
    final currentCycle = _currentCycle;
    final newRecord = await HospitalVisitBottomSheet.showForNew(
      context,
      cycleId: currentCycle?.id,
    );

    if (newRecord != null) {
      await AdditionalRecordService.addHospitalVisitRecord(newRecord);
      widget.onRecordChanged?.call();
      await _loadData(); // 화면 데이터 새로고침

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('병원 예약이 기록되었습니다'),
          backgroundColor: RecordType.hospitalVisit.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// 병원 예약 기록 편집
  Future<void> _editHospitalVisitRecord(HospitalVisitRecord record) async {
    final result = await HospitalVisitBottomSheet.showForEdit(
      context,
      record: record,
    );

    if (result == null) return;

    if (result == 'delete') {
      await AdditionalRecordService.deleteHospitalVisitRecord(record.id);
      widget.onRecordChanged?.call();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('병원 예약 기록이 삭제되었습니다'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } else if (result is HospitalVisitRecord) {
      await AdditionalRecordService.updateHospitalVisitRecord(result);
      widget.onRecordChanged?.call();
      await _loadData();
    }
  }

}
