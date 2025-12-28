import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import '../services/simple_treatment_service.dart';
import '../widgets/stage_edit_bottom_sheet.dart';

/// 심플 기록 화면 (개선 버전)
class SimpleRecordScreen extends StatefulWidget {
  const SimpleRecordScreen({super.key});

  @override
  State<SimpleRecordScreen> createState() => _SimpleRecordScreenState();
}

class _SimpleRecordScreenState extends State<SimpleRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SimpleTreatmentCycle? _currentCycle;
  List<SimpleTreatmentCycle> _pastCycles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final currentCycle = await SimpleTreatmentService.getCurrentCycle();
    final pastCycles = await SimpleTreatmentService.getPastCycles();

    setState(() {
      _currentCycle = currentCycle;
      _pastCycles = pastCycles;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.m),
                  _buildTabBar(),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRecordTab(),
                        _buildStatisticsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 헤더
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기록', style: AppTextStyles.h2),
            const SizedBox(height: 2),
            Text(
              '${_currentCycle?.cycleNumber ?? 1}차 시도',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: _showPastRecords,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: AppColors.primaryPurple, size: 20),
          ),
        ),
      ],
    );
  }

  /// 탭 바
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryPurple,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📊', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('기록'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📈', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('통계'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 기록 탭
  Widget _buildRecordTab() {
    if (_currentCycle == null) {
      return const Center(child: Text('데이터를 불러오는 중...'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          // 요약 카드
          _buildSummaryCard(),
          const SizedBox(height: AppSpacing.l),

          // 전체 단계 구분선
          _buildSectionDivider('전체 단계'),
          const SizedBox(height: AppSpacing.m),

          // 단계 리스트
          ...SimpleStageType.values.map((type) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                child: _buildStageRow(type),
              )),

          const SizedBox(height: AppSpacing.l),

          // 새로운 채취 시작 버튼
          _buildNewRetrievalButton(),

          const SizedBox(height: AppSpacing.m),

          // 지난 기록 보기
          _buildPastRecordsButton(),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// 요약 카드
  Widget _buildSummaryCard() {
    final cycle = _currentCycle!;
    final currentType = cycle.currentStageType;
    final startDateStr =
        '${cycle.startDate.year}.${cycle.startDate.month.toString().padLeft(2, '0')}.${cycle.startDate.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🥚', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cycle.cycleNumber}차 채취',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      Text(
                        '$startDateStr ~',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildEditChip(onTap: _showCycleEditDialog),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 현재 진행 상태
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentType?.emoji ?? '✅',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 진행',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        currentType != null
                            ? '${currentType.name} 중'
                            : '모든 단계 완료',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // 요약 통계
          Row(
            children: [
              _buildSummaryItem(
                label: '채취',
                value: cycle.retrievalCount != null
                    ? '${cycle.retrievalCount}개'
                    : '-',
              ),
              const SizedBox(width: AppSpacing.l),
              _buildSummaryItem(
                label: '동결 잔여',
                value:
                    cycle.frozenCount != null ? '${cycle.frozenCount}개' : '-',
              ),
              const SizedBox(width: AppSpacing.l),
              _buildSummaryItem(
                label: '이식 시도',
                value: '${cycle.transferAttemptCount}회',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요약 아이템
  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 편집 칩
  Widget _buildEditChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 14, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(
              '편집',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 섹션 구분선
  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ],
    );
  }

  /// 단계 행
  Widget _buildStageRow(SimpleStageType type) {
    final cycle = _currentCycle!;
    final stage = cycle.getStage(type);
    final status = cycle.getStageStatus(type);

    return InkWell(
      onTap: () => _editStage(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == SimpleStageStatus.inProgress
                ? AppColors.primaryPurple.withOpacity(0.5)
                : AppColors.border,
            width: status == SimpleStageStatus.inProgress ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 상태 아이콘
            Text(
              status.icon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: AppSpacing.m),

            // 단계 이모지
            Text(
              type.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: AppSpacing.s),

            // 단계 이름
            Expanded(
              child: Text(
                type.name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: status == SimpleStageStatus.pending
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // 날짜
            Text(
              stage.dateText,
              style: AppTextStyles.body.copyWith(
                color: stage.hasDate
                    ? AppColors.textPrimary
                    : AppColors.textDisabled,
              ),
            ),

            // 개수 (있으면)
            if (stage.countText != null) ...[
              const SizedBox(width: AppSpacing.s),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stage.countText!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(width: AppSpacing.s),

            // 편집 아이콘
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// 새로운 채취 시작 버튼
  Widget _buildNewRetrievalButton() {
    return InkWell(
      onTap: _startNewRetrievalCycle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🥚', style: TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.s),
            Text(
              '새로운 채취 시작하기',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right,
              color: AppColors.primaryPurple,
            ),
          ],
        ),
      ),
    );
  }

  /// 지난 기록 보기 버튼
  Widget _buildPastRecordsButton() {
    return TextButton(
      onPressed: _showPastRecords,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '지난 기록 보기',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 탭
  Widget _buildStatisticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📈', style: TextStyle(fontSize: 48)),
          SizedBox(height: AppSpacing.m),
          Text(
            '통계 기능 준비 중',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 단계 편집
  Future<void> _editStage(SimpleStageType type) async {
    final stage = _currentCycle!.getStage(type);

    final updatedStage = await StageEditBottomSheet.show(
      context,
      stage: stage,
    );

    if (updatedStage != null) {
      final updatedCycle = await SimpleTreatmentService.updateStage(updatedStage);
      setState(() {
        _currentCycle = updatedCycle;
      });
    }
  }

  /// 사이클 편집 다이얼로그
  void _showCycleEditDialog() {
    // TODO: 사이클 편집 다이얼로그 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('사이클 편집 기능 준비 중'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// 새 채취 시작
  Future<void> _startNewRetrievalCycle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Text('🥚', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('새로운 채취 시작'),
          ],
        ),
        content: const Text(
          '현재 기록이 지난 기록으로 이동합니다.\n새로운 채취 사이클을 시작하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newCycle = await SimpleTreatmentService.startNewRetrievalCycle();
      final pastCycles = await SimpleTreatmentService.getPastCycles();
      setState(() {
        _currentCycle = newCycle;
        _pastCycles = pastCycles;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newCycle.cycleNumber}차 채취를 시작합니다!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// 지난 기록 보기
  void _showPastRecords() {
    if (_pastCycles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('지난 기록이 없습니다'),
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
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
            Row(
              children: [
                const Text('🕐', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.s),
                Text(
                  '지난 기록',
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // 목록
            Expanded(
              child: ListView.builder(
                itemCount: _pastCycles.length,
                itemBuilder: (context, index) {
                  final cycle = _pastCycles[index];
                  final startDateStr =
                      '${cycle.startDate.year}.${cycle.startDate.month.toString().padLeft(2, '0')}.${cycle.startDate.day.toString().padLeft(2, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Text('🥚', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${cycle.cycleNumber}차 채취',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                startDateStr,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (cycle.retrievalCount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurpleLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${cycle.retrievalCount}개',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
