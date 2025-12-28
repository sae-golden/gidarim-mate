import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/treatment_cycle.dart';
import '../models/treatment_stage.dart';
import '../widgets/app_card.dart';

/// 치료 기록 화면
class TreatmentRecordScreen extends StatefulWidget {
  const TreatmentRecordScreen({super.key});

  @override
  State<TreatmentRecordScreen> createState() => _TreatmentRecordScreenState();
}

class _TreatmentRecordScreenState extends State<TreatmentRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 새로운 멀티 사이클 구조
  late RetrievalCycle _currentRetrievalCycle;
  List<RetrievalCycle> _pastCycles = [];

  // 기존 TreatmentCycle (호환성 유지)
  late TreatmentCycle _currentCycle;

  // 편집 모드 상태
  Map<TreatmentStage, bool> _editingStages = {};

  // 편집 중인 데이터 (임시 저장)
  Map<TreatmentStage, Map<String, dynamic>> _editingData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initEmptyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 빈 데이터로 초기화 (Supabase에서 실제 데이터 로드)
  void _initEmptyData() {
    _currentRetrievalCycle = RetrievalCycle(
      id: '',
      cycleNumber: 0,
      startDate: DateTime.now(),
      isActive: false,
    );

    _currentCycle = TreatmentCycle(
      id: '',
      cycleNumber: 0,
      startDate: DateTime.now(),
      stages: [],
    );
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
              child: TabBarView(
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
              '${_currentCycle.cycleNumber}차 시도',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
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
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.assignment, size: 18), SizedBox(width: 6), Text('기록'),
          ])),
          Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bar_chart, size: 18), SizedBox(width: 6), Text('통계'),
          ])),
        ],
      ),
    );
  }

  // ==================== 기록 탭 ====================
  Widget _buildRecordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          // 새로운 멀티 사이클 요약 카드
          _buildMultiCycleSummaryCard(),
          const SizedBox(height: AppSpacing.m),
          // 이식 히스토리 (신선 ❌ → 동결1차 ❌ → 동결2차 ⏳)
          _buildTransferHistoryCard(),
          const SizedBox(height: AppSpacing.m),
          // 동결배아 현황
          if (_currentRetrievalCycle.totalFrozenEmbryos > 0)
            _buildFrozenEmbryoCard(),
          const SizedBox(height: AppSpacing.m),
          _buildResultPipeline(),
          const SizedBox(height: AppSpacing.l),
          ..._currentCycle.stages.map((stage) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: _buildStageCard(stage),
          )),
          const SizedBox(height: AppSpacing.m),
          // 새 채취/이식 시작 버튼
          _buildActionButtons(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  /// 멀티 사이클 요약 카드
  Widget _buildMultiCycleSummaryCard() {
    final currentTransfer = _currentRetrievalCycle.currentTransfer;
    final hasActiveTransfer = currentTransfer != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 채취 사이클 헤더
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
                        '${_currentRetrievalCycle.cycleNumber}차 채취',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      Text(
                        '${_currentRetrievalCycle.startDate.year}.${_currentRetrievalCycle.startDate.month.toString().padLeft(2, '0')}.${_currentRetrievalCycle.startDate.day.toString().padLeft(2, '0')} ~',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              _buildEditChip(onTap: _showEditCycleDialog),
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
                    hasActiveTransfer ? currentTransfer!.type.emoji : '📋',
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
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                      ),
                      Text(
                        hasActiveTransfer
                            ? '${currentTransfer!.displayName} - 판정 대기 중'
                            : '이식 대기 중',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasActiveTransfer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⏳', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          'D+${DateTime.now().difference(currentTransfer!.date).inDays}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                icon: Icons.egg_outlined,
                label: '채취',
                value: '${_currentRetrievalCycle.retrieval?.totalEggs ?? 0}개',
              ),
              const SizedBox(width: AppSpacing.l),
              _buildSummaryItem(
                icon: Icons.ac_unit,
                label: '동결 잔여',
                value: '${_currentRetrievalCycle.remainingEmbryos}개',
              ),
              const SizedBox(width: AppSpacing.l),
              _buildSummaryItem(
                icon: Icons.replay,
                label: '이식 시도',
                value: '${_currentRetrievalCycle.transfers.length}회',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 이식 히스토리 카드
  Widget _buildTransferHistoryCard() {
    if (_currentRetrievalCycle.transfers.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Text('이식 기록', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${_currentRetrievalCycle.transfers.length}회 시도',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 이식 히스토리 플로우
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _currentRetrievalCycle.transfers.asMap().entries.map((entry) {
                final index = entry.key;
                final transfer = entry.value;
                return Row(
                  children: [
                    _buildTransferHistoryItem(transfer),
                    if (index < _currentRetrievalCycle.transfers.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textDisabled),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // 이식 상세 목록
          ...(_currentRetrievalCycle.transfers.map((transfer) => _buildTransferDetailRow(transfer))),
        ],
      ),
    );
  }

  Widget _buildTransferHistoryItem(TransferAttempt transfer) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    switch (transfer.status) {
      case TransferResultStatus.success:
        bgColor = AppColors.success.withOpacity(0.1);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        break;
      case TransferResultStatus.fail:
        bgColor = AppColors.error.withOpacity(0.1);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        break;
      case TransferResultStatus.inProgress:
        bgColor = AppColors.primaryPurple.withOpacity(0.1);
        borderColor = AppColors.primaryPurple;
        textColor = AppColors.primaryPurple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(transfer.status.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            transfer.type == TransferType.fresh ? '신선' : '동결${transfer.frozenAttemptNumber ?? 1}차',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferDetailRow(TransferAttempt transfer) {
    final dateStr = '${transfer.date.year}.${transfer.date.month.toString().padLeft(2, '0')}.${transfer.date.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(transfer.type.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        transfer.displayName,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: transfer.status == TransferResultStatus.inProgress
                              ? AppColors.primaryPurple.withOpacity(0.1)
                              : transfer.status == TransferResultStatus.success
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          transfer.status.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: transfer.status == TransferResultStatus.inProgress
                                ? AppColors.primaryPurple
                                : transfer.status == TransferResultStatus.success
                                    ? AppColors.success
                                    : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (transfer.transferData != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transfer.transferData!.embryoCount != null)
                    Text(
                      '배아 ${transfer.transferData!.embryoCount}개',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  if (transfer.transferData!.embryoGrade != null)
                    Text(
                      '${transfer.transferData!.embryoGrade}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// 동결배아 현황 카드
  Widget _buildFrozenEmbryoCard() {
    final total = _currentRetrievalCycle.totalFrozenEmbryos;
    final used = _currentRetrievalCycle.usedFrozenEmbryos;
    final remaining = _currentRetrievalCycle.remainingEmbryos;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('❄️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Text('동결배아 현황', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Expanded(
                child: _buildFrozenStatItem(
                  label: '총 동결',
                  value: '$total개',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _buildFrozenStatItem(
                  label: '사용',
                  value: '$used개',
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _buildFrozenStatItem(
                  label: '남은 배아',
                  value: '$remaining개',
                  color: remaining > 0 ? AppColors.success : AppColors.error,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          if (remaining > 0) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '동결 배아가 ${remaining}개 남아있어요. 다음 이식에 사용할 수 있어요.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (remaining == 0) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '남은 동결 배아가 없어요. 새로운 채취를 시작하거나 현재 결과를 기다려주세요.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFrozenStatItem({
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? color.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼들 (새 채취/이식 시작)
  Widget _buildActionButtons() {
    final hasRemainingEmbryos = _currentRetrievalCycle.remainingEmbryos > 0;
    final currentTransfer = _currentRetrievalCycle.currentTransfer;
    final hasActiveTransfer = currentTransfer != null;

    return Column(
      children: [
        // 다음 동결이식 시작 버튼 (남은 배아가 있고, 진행 중인 이식이 없을 때)
        if (hasRemainingEmbryos && !hasActiveTransfer)
          _buildActionButton(
            icon: '❄️',
            label: '다음 동결이식 시작',
            description: '남은 동결배아 ${_currentRetrievalCycle.remainingEmbryos}개로 새 이식 시작',
            color: AppColors.info,
            onTap: _startNewFrozenTransfer,
          ),

        // 새로운 채취 시작 버튼 (남은 배아가 없을 때)
        if (!hasRemainingEmbryos && !hasActiveTransfer)
          _buildActionButton(
            icon: '🥚',
            label: '새로운 채취 시작하기',
            description: '새 채취 사이클을 시작합니다',
            color: AppColors.primaryPurple,
            onTap: _startNewRetrievalCycle,
          ),

        // 지난 기록 보기
        const SizedBox(height: AppSpacing.s),
        GestureDetector(
          onTap: _showPastCyclesHistory,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '지난 기록 보기',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // 새 동결이식 시작
  void _startNewFrozenTransfer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('❄️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('새 동결이식 시작'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '동결 ${_currentRetrievalCycle.frozenTransferCount + 1}차 이식을 시작합니다.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('❄️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '남은 동결배아: ${_currentRetrievalCycle.remainingEmbryos}개',
                    style: AppTextStyles.body.copyWith(color: AppColors.info),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // 새 동결이식 추가
              setState(() {
                final newTransfer = TransferAttempt(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: TransferType.frozen,
                  frozenAttemptNumber: _currentRetrievalCycle.frozenTransferCount + 1,
                  date: DateTime.now(),
                  status: TransferResultStatus.inProgress,
                );
                _currentRetrievalCycle = _currentRetrievalCycle.copyWith(
                  transfers: [..._currentRetrievalCycle.transfers, newTransfer],
                  usedFrozenEmbryos: _currentRetrievalCycle.usedFrozenEmbryos + 1,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('❄️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('동결 ${_currentRetrievalCycle.frozenTransferCount}차 이식이 시작되었습니다'),
                    ],
                  ),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
            child: const Text('시작하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 새 채취 사이클 시작
  void _startNewRetrievalCycle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🥚', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('새 채취 시작'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_currentRetrievalCycle.cycleNumber + 1}차 채취를 시작합니다.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '현재 ${_currentRetrievalCycle.cycleNumber}차 채취 기록은 지난 기록으로 이동합니다.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // 현재 사이클을 지난 기록으로 이동하고 새 사이클 시작
              setState(() {
                _pastCycles.add(_currentRetrievalCycle.copyWith(isActive: false));
                _currentRetrievalCycle = RetrievalCycle(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  cycleNumber: _currentRetrievalCycle.cycleNumber + 1,
                  startDate: DateTime.now(),
                  isActive: true,
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('🥚', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('${_currentRetrievalCycle.cycleNumber}차 채취가 시작되었습니다'),
                    ],
                  ),
                  backgroundColor: AppColors.primaryPurple,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
            ),
            child: const Text('시작하기', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 지난 기록 보기
  void _showPastCyclesHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들바
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
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('지난 기록', style: AppTextStyles.h3),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _pastCycles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📋', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            '지난 기록이 없습니다',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      itemCount: _pastCycles.length,
                      itemBuilder: (context, index) {
                        final cycle = _pastCycles[index];
                        return _buildPastCycleItem(cycle);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastCycleItem(RetrievalCycle cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥚', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '${cycle.cycleNumber}차 채취',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${cycle.startDate.year}.${cycle.startDate.month.toString().padLeft(2, '0')}.${cycle.startDate.day.toString().padLeft(2, '0')}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            cycle.resultSummary,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (cycle.transfers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              cycle.transferSummary,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final dDay = _currentCycle.dDay;
    final completedCount = _currentCycle.stages.where((s) => s.status == StageStatus.completed).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('${_currentCycle.cycleNumber}차 시도', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                ],
              ),
              _buildEditChip(onTap: _showEditCycleDialog),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              _buildSummaryItem(icon: Icons.check_circle_outline, label: '완료', value: '$completedCount/${_currentCycle.stages.length}'),
              const SizedBox(width: AppSpacing.l),
              _buildSummaryItem(icon: Icons.pending_outlined, label: '남은 단계', value: '${_currentCycle.stages.length - completedCount}개'),
              if (dDay != null) ...[
                const SizedBox(width: AppSpacing.l),
                _buildSummaryItem(icon: Icons.calendar_today, label: '이식까지', value: dDay >= 0 ? 'D-$dDay' : 'D+${-dDay}'),
              ],
            ],
          ),
        ],
      ),
    );
  }

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
            const Icon(Icons.edit, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('편집', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
            Text(value, style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildResultPipeline() {
    final retrieval = _currentCycle.getStageData<RetrievalData>(TreatmentStage.retrieval);
    final waiting = _currentCycle.getStageData<WaitingData>(TreatmentStage.waiting);

    final parts = <Map<String, dynamic>>[];
    if (retrieval != null) {
      parts.add({'label': '채취', 'value': retrieval.totalEggs, 'color': AppColors.info});
    }
    if (waiting != null) {
      final fert = waiting.getResult(LabResultType.fertilization);
      final day3 = waiting.getResult(LabResultType.day3);
      final day5 = waiting.getResult(LabResultType.day5);
      final frozen = waiting.getResult(LabResultType.frozen);

      if (fert != null) parts.add({'label': '수정', 'value': fert.count, 'color': const Color(0xFF6C63FF)});
      if (day3 != null) parts.add({'label': 'Day3', 'value': day3.count, 'color': AppColors.primaryPurple});
      if (day5 != null) parts.add({'label': '배반포', 'value': day5.count, 'color': AppColors.success});
      if (frozen != null) parts.add({'label': '동결', 'value': frozen.count, 'color': AppColors.info});
    }

    if (parts.isEmpty) return const SizedBox();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Text('결과 요약', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: parts.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (item['color'] as Color).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(item['label'], style: TextStyle(fontSize: 11, color: item['color'], fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${item['value']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    if (index < parts.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textDisabled),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(CycleStage stage) {
    final isEditing = _editingStages[stage.stage] ?? false;
    // 자동 계산된 상태 사용
    final calculatedStatus = stage.calculatedStatus;
    final isCurrent = calculatedStatus == StageStatus.inProgress;
    final isPending = calculatedStatus == StageStatus.pending;
    final isCompleted = calculatedStatus == StageStatus.completed;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              _buildStatusBadge(calculatedStatus, dDay: stage.dDay),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(stage.info.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${stage.info.title} (${stage.info.titleEn})',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isPending ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 이식 대기(waiting)는 진행중 뱃지 표시 안함
                        if (isCurrent && stage.stage != TreatmentStage.waiting) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('진행중', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('완료', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          stage.periodString,
                          style: AppTextStyles.caption.copyWith(
                            color: isCurrent ? AppColors.primaryPurple : AppColors.textSecondary,
                          ),
                        ),
                        // 상태 텍스트 표시
                        if (isPending && stage.dDay != null && stage.dDay! > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${stage.statusText})',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildEditButton(
                isEditing: isEditing,
                onTap: () => _toggleEditMode(stage),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 단계별 콘텐츠
          _buildStageContent(stage, isEditing),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(StageStatus status, {String? statusText, int? dDay}) {
    switch (status) {
      case StageStatus.completed:
        return Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      case StageStatus.inProgress:
        return Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(color: AppColors.primaryPurple, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
        );
      case StageStatus.pending:
        // D-Day가 있으면 표시
        if (dDay != null && dDay > 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Text(
              'D-$dDay',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          );
        }
        return Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildEditButton({required bool isEditing, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEditing ? AppColors.primaryPurple : AppColors.primaryPurpleLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          isEditing ? '완료' : '편집',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isEditing ? Colors.white : AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }

  // 편집 모드 토글
  void _toggleEditMode(CycleStage stage) {
    final isEditing = _editingStages[stage.stage] ?? false;

    if (!isEditing) {
      // 편집 모드 진입: 현재 데이터 복사
      _startEditing(stage);
    } else {
      // 편집 완료: 데이터 저장
      _saveEditing(stage);
    }
  }

  void _startEditing(CycleStage stage) {
    final Map<String, dynamic> editData = {};

    switch (stage.stage) {
      case TreatmentStage.stimulation:
        final data = stage.data as StimulationData?;
        editData['injectionCount'] = data?.injectionCount ?? 0;
        editData['durationDays'] = data?.durationDays ?? 0;
        editData['startDate'] = stage.startDate;
        editData['endDate'] = stage.endDate;
        editData['memo'] = stage.memo ?? '';
        break;
      case TreatmentStage.retrieval:
        final data = stage.data as RetrievalData?;
        editData['totalEggs'] = data?.totalEggs ?? 0;
        editData['matureEggs'] = data?.matureEggs ?? 0;
        editData['startDate'] = stage.startDate;
        editData['memo'] = stage.memo ?? '';
        break;
      case TreatmentStage.waiting:
        editData['startDate'] = stage.startDate;
        editData['memo'] = stage.memo ?? '';
        break;
      case TreatmentStage.transfer:
        final data = stage.data as TransferData?;
        editData['embryoCount'] = data?.embryoCount ?? 0;
        editData['endometriumThickness'] = data?.endometriumThickness ?? 0.0;
        editData['embryoGrade'] = data?.embryoGrade ?? '';
        editData['startDate'] = stage.startDate;
        editData['memo'] = stage.memo ?? '';
        break;
      case TreatmentStage.result:
        final data = stage.data as ResultData?;
        editData['hcgLevel'] = data?.hcgLevel ?? 0.0;
        editData['isPregnant'] = data?.isPregnant;
        editData['testDate'] = data?.testDate;
        editData['memo'] = stage.memo ?? '';
        break;
    }

    setState(() {
      _editingData[stage.stage] = editData;
      _editingStages[stage.stage] = true;
    });
  }

  void _saveEditing(CycleStage stage) {
    final editData = _editingData[stage.stage];
    if (editData == null) return;

    final stageIndex = _currentCycle.stages.indexWhere((s) => s.stage == stage.stage);
    if (stageIndex == -1) return;

    final currentStage = _currentCycle.stages[stageIndex];
    CycleStage newStage;

    switch (stage.stage) {
      case TreatmentStage.stimulation:
        newStage = currentStage.copyWith(
          data: StimulationData(
            injectionCount: editData['injectionCount'] ?? 0,
            durationDays: editData['durationDays'],
            memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
          ),
          startDate: editData['startDate'],
          endDate: editData['endDate'],
          memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
        );
        break;
      case TreatmentStage.retrieval:
        newStage = currentStage.copyWith(
          data: RetrievalData(
            totalEggs: editData['totalEggs'] ?? 0,
            matureEggs: editData['matureEggs'] ?? 0,
            memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
          ),
          startDate: editData['startDate'],
          memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
        );
        break;
      case TreatmentStage.waiting:
        newStage = currentStage.copyWith(
          startDate: editData['startDate'],
          memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
        );
        break;
      case TreatmentStage.transfer:
        newStage = currentStage.copyWith(
          data: TransferData(
            embryoCount: editData['embryoCount'] > 0 ? editData['embryoCount'] : null,
            endometriumThickness: editData['endometriumThickness'] > 0 ? editData['endometriumThickness'] : null,
            embryoGrade: editData['embryoGrade']?.isNotEmpty == true ? editData['embryoGrade'] : null,
            memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
          ),
          startDate: editData['startDate'],
          memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
        );
        break;
      case TreatmentStage.result:
        newStage = currentStage.copyWith(
          data: ResultData(
            hcgLevel: editData['hcgLevel'] > 0 ? editData['hcgLevel'] : null,
            isPregnant: editData['isPregnant'],
            testDate: editData['testDate'],
            memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
          ),
          memo: editData['memo']?.isNotEmpty == true ? editData['memo'] : null,
        );
        break;
    }

    final newStages = List<CycleStage>.from(_currentCycle.stages);
    newStages[stageIndex] = newStage;

    setState(() {
      _currentCycle = _currentCycle.copyWith(stages: newStages);
      _editingStages[stage.stage] = false;
      _editingData.remove(stage.stage);
    });
  }

  // 숫자 키패드 바텀시트 표시
  void _showNumberKeypad({
    required TreatmentStage stage,
    required String field,
    required int currentValue,
    String? suffix,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _NumberKeypadBottomSheet(
        initialValue: currentValue,
        suffix: suffix,
        onConfirm: (value) {
          setState(() {
            _editingData[stage]?[field] = value;
          });
        },
      ),
    );
  }

  // 소수점 숫자 키패드 바텀시트 표시
  void _showDecimalKeypad({
    required TreatmentStage stage,
    required String field,
    required double currentValue,
    String? suffix,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _DecimalKeypadBottomSheet(
        initialValue: currentValue,
        suffix: suffix,
        onConfirm: (value) {
          setState(() {
            _editingData[stage]?[field] = value;
          });
        },
      ),
    );
  }

  // 날짜 선택기 표시
  Future<void> _showDatePickerForField({
    required TreatmentStage stage,
    required String field,
    DateTime? currentValue,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _editingData[stage]?[field] = picked;
      });
    }
  }

  Widget _buildStageContent(CycleStage stage, bool isEditing) {
    switch (stage.stage) {
      case TreatmentStage.stimulation:
        return _buildStimulationContent(stage, isEditing);
      case TreatmentStage.retrieval:
        return _buildRetrievalContent(stage, isEditing);
      case TreatmentStage.waiting:
        return _buildWaitingContent(stage, isEditing);
      case TreatmentStage.transfer:
        return _buildTransferContent(stage, isEditing);
      case TreatmentStage.result:
        return _buildResultContent(stage, isEditing);
    }
  }

  Widget _buildStimulationContent(CycleStage stage, bool isEditing) {
    final data = stage.data as StimulationData?;
    final editData = _editingData[stage.stage];

    if (isEditing && editData != null) {
      return Column(
        children: [
          // 날짜 편집 (시작일 ~ 종료일)
          _buildEditableDateRangeRow(
            stage: stage.stage,
            startDate: editData['startDate'] as DateTime?,
            endDate: editData['endDate'] as DateTime?,
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableDataGrid(
            stage: stage.stage,
            items: [
              {
                'icon': '💉',
                'label': '주사 횟수',
                'field': 'injectionCount',
                'value': editData['injectionCount'] ?? 0,
                'suffix': '회',
                'type': 'int',
              },
              {
                'icon': '📅',
                'label': '기간',
                'field': 'durationDays',
                'value': editData['durationDays'] ?? 0,
                'suffix': '일',
                'type': 'int',
              },
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableMemoRow(stage.stage, editData['memo'] ?? ''),
        ],
      );
    }

    return Column(
      children: [
        _buildDataGrid([
          {'icon': '💉', 'label': '주사 횟수', 'value': data != null ? '${data.injectionCount}회' : '-'},
          {'icon': '📅', 'label': '기간', 'value': data?.durationDays != null ? '${data!.durationDays}일' : '-'},
        ], isEditing),
        if (stage.memo != null && stage.memo!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          _buildMemoRow(stage.memo!, isEditing),
        ],
      ],
    );
  }

  Widget _buildRetrievalContent(CycleStage stage, bool isEditing) {
    final data = stage.data as RetrievalData?;
    final editData = _editingData[stage.stage];

    if (isEditing && editData != null) {
      return Column(
        children: [
          // 날짜 편집 (채취일)
          _buildEditableDateRow(
            stage: stage.stage,
            label: '채취일',
            field: 'startDate',
            currentValue: editData['startDate'] as DateTime?,
            emoji: '🥚',
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableDataGrid(
            stage: stage.stage,
            items: [
              {
                'icon': '🥚',
                'label': '채취 난자',
                'field': 'totalEggs',
                'value': editData['totalEggs'] ?? 0,
                'suffix': '개',
                'type': 'int',
              },
              {
                'icon': '🧫',
                'label': '성숙란(M2)',
                'field': 'matureEggs',
                'value': editData['matureEggs'] ?? 0,
                'suffix': '개',
                'type': 'int',
              },
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableMemoRow(stage.stage, editData['memo'] ?? ''),
        ],
      );
    }

    return Column(
      children: [
        _buildDataGrid([
          {'icon': '🥚', 'label': '채취 난자', 'value': data != null ? '${data.totalEggs}개' : '-'},
          {'icon': '🧫', 'label': '성숙란(M2)', 'value': data != null ? '${data.matureEggs}개' : '-'},
        ], isEditing),
        if (stage.memo != null && stage.memo!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          _buildMemoRow(stage.memo!, isEditing),
        ],
      ],
    );
  }

  Widget _buildWaitingContent(CycleStage stage, bool isEditing) {
    final data = stage.data as WaitingData?;
    final editData = _editingData[stage.stage];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 편집 모드일 때 날짜 편집 표시
        if (isEditing && editData != null) ...[
          _buildEditableDateRow(
            stage: stage.stage,
            label: '대기 시작일',
            field: 'startDate',
            currentValue: editData['startDate'] as DateTime?,
            emoji: '⏳',
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        // 병원 결과 섹션
        Row(
          children: [
            const Text('📞', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('병원 결과', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.s),

        if (data != null && data.results.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: data.results.map((result) => _buildLabResultRow(result, isEditing)).toList(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Text('아직 결과가 없어요', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),

        const SizedBox(height: AppSpacing.m),

        // 결과 추가 버튼
        GestureDetector(
          onTap: () => _showAddResultDialog(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.primaryPurple, size: 20),
                const SizedBox(width: 8),
                Text('결과 추가하기', style: TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),

        if (stage.memo != null && stage.memo!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          _buildMemoRow(stage.memo!, isEditing),
        ],
      ],
    );
  }

  Widget _buildLabResultRow(LabResult result, bool isEditing) {
    String displayValue = result.count != null ? '${result.count}개' : '-';
    if (result.method != null) {
      displayValue += ' (${result.method})';
    }
    if (result.gradeNote != null) {
      displayValue += '\n${result.gradeNote}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.type.displayName, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                Flexible(
                  child: Text(
                    displayValue,
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          if (isEditing) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _deleteLabResult(result.id),
              child: Icon(Icons.close, size: 16, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransferContent(CycleStage stage, bool isEditing) {
    final data = stage.data as TransferData?;
    final editData = _editingData[stage.stage];

    if (isEditing && editData != null) {
      return Column(
        children: [
          // 날짜 편집 (이식일)
          _buildEditableDateRow(
            stage: stage.stage,
            label: '이식일',
            field: 'startDate',
            currentValue: editData['startDate'] as DateTime?,
            emoji: '🎯',
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableDataGrid(
            stage: stage.stage,
            items: [
              {
                'icon': '🎯',
                'label': '이식 배아',
                'field': 'embryoCount',
                'value': editData['embryoCount'] ?? 0,
                'suffix': '개',
                'type': 'int',
              },
              {
                'icon': '📏',
                'label': '내막 두께',
                'field': 'endometriumThickness',
                'value': editData['endometriumThickness'] ?? 0.0,
                'suffix': 'mm',
                'type': 'double',
              },
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableMemoRow(stage.stage, editData['memo'] ?? ''),
        ],
      );
    }

    return Column(
      children: [
        _buildDataGrid([
          {'icon': '🎯', 'label': '이식 배아', 'value': data?.embryoCount != null ? '${data!.embryoCount}개' : '-'},
          {'icon': '📏', 'label': '내막 두께', 'value': data?.endometriumThickness != null ? '${data!.endometriumThickness}mm' : '-'},
        ], isEditing),
        if (stage.memo != null && stage.memo!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          _buildMemoRow(stage.memo!, isEditing),
        ],
      ],
    );
  }

  Widget _buildResultContent(CycleStage stage, bool isEditing) {
    final data = stage.data as ResultData?;
    final editData = _editingData[stage.stage];

    if (isEditing && editData != null) {
      return Column(
        children: [
          // 날짜 편집 (검사일)
          _buildEditableDateRow(
            stage: stage.stage,
            label: '검사일',
            field: 'testDate',
            currentValue: editData['testDate'] as DateTime?,
            emoji: '🩸',
          ),
          const SizedBox(height: AppSpacing.s),
          _buildEditableDataGrid(
            stage: stage.stage,
            items: [
              {
                'icon': '🩸',
                'label': 'hCG 수치',
                'field': 'hcgLevel',
                'value': editData['hcgLevel'] ?? 0.0,
                'suffix': '',
                'type': 'double',
              },
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          // 임신 여부 선택
          _buildPregnancySelector(stage.stage, editData['isPregnant']),
          const SizedBox(height: AppSpacing.s),
          _buildEditableMemoRow(stage.stage, editData['memo'] ?? ''),
        ],
      );
    }

    return Column(
      children: [
        _buildDataGrid([
          {'icon': '🩸', 'label': 'hCG 수치', 'value': data?.hcgLevel != null ? '${data!.hcgLevel}' : '-'},
          {'icon': '🤰', 'label': '임신 여부', 'value': data?.isPregnant != null ? (data!.isPregnant! ? '양성' : '음성') : '-'},
        ], isEditing),
        if (stage.memo != null && stage.memo!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          _buildMemoRow(stage.memo!, isEditing),
        ],
      ],
    );
  }

  Widget _buildPregnancySelector(TreatmentStage stage, bool? currentValue) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _editingData[stage]?['isPregnant'] = true),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: currentValue == true ? AppColors.success.withOpacity(0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentValue == true ? AppColors.success : AppColors.border,
                  width: currentValue == true ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  const Text('🤰', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    '양성',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: currentValue == true ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _editingData[stage]?['isPregnant'] = false),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: currentValue == false ? AppColors.error.withOpacity(0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentValue == false ? AppColors.error : AppColors.border,
                  width: currentValue == false ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  const Text('😢', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(
                    '음성',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: currentValue == false ? AppColors.error : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDataGrid({
    required TreatmentStage stage,
    required List<Map<String, dynamic>> items,
  }) {
    return Row(
      children: items.map((item) {
        final value = item['value'];
        final displayValue = item['type'] == 'double'
            ? (value as double).toStringAsFixed(1)
            : value.toString();

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (item['type'] == 'int') {
                _showNumberKeypad(
                  stage: stage,
                  field: item['field'],
                  currentValue: value as int,
                  suffix: item['suffix'],
                );
              } else if (item['type'] == 'double') {
                _showDecimalKeypad(
                  stage: stage,
                  field: item['field'],
                  currentValue: value as double,
                  suffix: item['suffix'],
                );
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: item != items.last ? AppSpacing.s : 0),
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryPurple, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['icon']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(item['label']!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayValue,
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                      ),
                      if (item['suffix']?.isNotEmpty == true)
                        Text(
                          item['suffix']!,
                          style: AppTextStyles.body.copyWith(color: AppColors.primaryPurple),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditableMemoRow(TreatmentStage stage, String memo) {
    return GestureDetector(
      onTap: () => _showMemoEditor(stage, memo),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryPurple, width: 2),
        ),
        child: Row(
          children: [
            const Text('📝', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                memo.isNotEmpty ? memo : '메모를 입력하세요',
                style: AppTextStyles.body.copyWith(
                  color: memo.isNotEmpty ? AppColors.textPrimary : AppColors.textDisabled,
                ),
              ),
            ),
            Icon(Icons.edit, size: 16, color: AppColors.primaryPurple),
          ],
        ),
      ),
    );
  }

  /// 날짜 편집 행 (시작일, 종료일)
  Widget _buildEditableDateRow({
    required TreatmentStage stage,
    required String label,
    required String field,
    DateTime? currentValue,
    String emoji = '📅',
  }) {
    final dateString = currentValue != null
        ? '${currentValue.year}.${currentValue.month.toString().padLeft(2, '0')}.${currentValue.day.toString().padLeft(2, '0')}'
        : '날짜를 선택하세요';

    return GestureDetector(
      onTap: () => _showDatePickerForField(
        stage: stage,
        field: field,
        currentValue: currentValue,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryPurple, width: 2),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              dateString,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: currentValue != null ? AppColors.primaryPurple : AppColors.textDisabled,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_today, size: 16, color: AppColors.primaryPurple),
          ],
        ),
      ),
    );
  }

  /// 날짜 범위 편집 행 (시작일 ~ 종료일)
  Widget _buildEditableDateRangeRow({
    required TreatmentStage stage,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildEditableDateRow(
            stage: stage,
            label: '시작일',
            field: 'startDate',
            currentValue: startDate,
            emoji: '🗓️',
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: _buildEditableDateRow(
            stage: stage,
            label: '종료일',
            field: 'endDate',
            currentValue: endDate,
            emoji: '🏁',
          ),
        ),
      ],
    );
  }

  void _showMemoEditor(TreatmentStage stage, String currentMemo) {
    final controller = TextEditingController(text: currentMemo);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('메모 입력', style: AppTextStyles.h3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '메모를 입력하세요',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _editingData[stage]?['memo'] = controller.text;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataGrid(List<Map<String, String>> items, bool isEditing) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item != items.last ? AppSpacing.s : 0),
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['icon']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(item['label']!, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item['value']!, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemoRow(String memo, bool isEditing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('📝', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(memo, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // ==================== 통계 탭 ====================
  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _buildFunnelVisualization(),
          const SizedBox(height: AppSpacing.l),
          _buildDetailedStats(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildFunnelVisualization() {
    final retrieval = _currentCycle.getStageData<RetrievalData>(TreatmentStage.retrieval);
    final waiting = _currentCycle.getStageData<WaitingData>(TreatmentStage.waiting);

    final baseCount = retrieval?.totalEggs ?? 0;
    final matureCount = retrieval?.matureEggs ?? 0;

    int fertilizedCount = 0;
    int day3Count = 0;
    int blastocystCount = 0;
    int frozenCount = 0;

    if (waiting != null) {
      fertilizedCount = waiting.getResult(LabResultType.fertilization)?.count ?? 0;
      day3Count = waiting.getResult(LabResultType.day3)?.count ?? 0;
      blastocystCount = waiting.getResult(LabResultType.day5)?.count ?? 0;
      frozenCount = waiting.getResult(LabResultType.frozen)?.count ?? 0;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryPurpleLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list, color: AppColors.primaryPurple, size: 20),
              ),
              const SizedBox(width: AppSpacing.s),
              Text('Funnel 분석', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _buildFunnelBar(label: '채취 난자', count: baseCount, percentage: 100, color: AppColors.info, icon: '🥚'),
          _buildFunnelConnector(),
          _buildFunnelBar(label: '성숙란', count: matureCount, percentage: baseCount > 0 ? matureCount / baseCount * 100 : 0, color: const Color(0xFF6C63FF), icon: '✨'),
          _buildFunnelConnector(),
          _buildFunnelBar(label: '수정', count: fertilizedCount, percentage: baseCount > 0 ? fertilizedCount / baseCount * 100 : 0, color: AppColors.primaryPurple, icon: '🔬'),
          _buildFunnelConnector(),
          _buildFunnelBar(label: 'Day 3', count: day3Count, percentage: baseCount > 0 ? day3Count / baseCount * 100 : 0, color: const Color(0xFFFF9800), icon: '🧫'),
          _buildFunnelConnector(),
          _buildFunnelBar(label: '배반포', count: blastocystCount, percentage: baseCount > 0 ? blastocystCount / baseCount * 100 : 0, color: AppColors.success, icon: '🌟'),
          _buildFunnelConnector(),
          _buildFunnelBar(label: '동결', count: frozenCount, percentage: baseCount > 0 ? frozenCount / baseCount * 100 : 0, color: AppColors.info, icon: '❄️'),
        ],
      ),
    );
  }

  Widget _buildFunnelBar({required String label, required int count, required double percentage, required Color color, required String icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
            ]),
            Row(children: [
              Text('$count개', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 20, width: double.infinity, decoration: BoxDecoration(color: AppColors.border.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 20,
              width: (MediaQuery.of(context).size.width - 80) * (percentage / 100),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunnelConnector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 11),
          Container(width: 2, height: 16, color: AppColors.border),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_downward, size: 12, color: AppColors.textDisabled),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    final retrieval = _currentCycle.getStageData<RetrievalData>(TreatmentStage.retrieval);
    final waiting = _currentCycle.getStageData<WaitingData>(TreatmentStage.waiting);

    final baseCount = retrieval?.totalEggs ?? 0;
    final matureCount = retrieval?.matureEggs ?? 0;
    int fertilizedCount = 0;
    int blastocystCount = 0;
    int frozenCount = 0;

    if (waiting != null) {
      fertilizedCount = waiting.getResult(LabResultType.fertilization)?.count ?? 0;
      blastocystCount = waiting.getResult(LabResultType.day5)?.count ?? 0;
      frozenCount = waiting.getResult(LabResultType.frozen)?.count ?? 0;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryPurpleLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.analytics, color: AppColors.primaryPurple, size: 20),
              ),
              const SizedBox(width: AppSpacing.s),
              Text('상세 통계', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Expanded(child: _buildStatCard(label: '성숙률', value: baseCount > 0 ? '${(matureCount / baseCount * 100).toStringAsFixed(1)}%' : '-', subLabel: '성숙란/채취', color: const Color(0xFF6C63FF))),
              const SizedBox(width: AppSpacing.s),
              Expanded(child: _buildStatCard(label: '수정률', value: matureCount > 0 ? '${(fertilizedCount / matureCount * 100).toStringAsFixed(1)}%' : '-', subLabel: '수정/성숙란', color: AppColors.primaryPurple)),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(child: _buildStatCard(label: '배반포율', value: fertilizedCount > 0 ? '${(blastocystCount / fertilizedCount * 100).toStringAsFixed(1)}%' : '-', subLabel: '배반포/수정', color: AppColors.success)),
              const SizedBox(width: AppSpacing.s),
              Expanded(child: _buildStatCard(label: '전체 효율', value: baseCount > 0 ? '${(blastocystCount / baseCount * 100).toStringAsFixed(1)}%' : '-', subLabel: '배반포/채취', color: AppColors.warning)),
            ],
          ),
          if (frozenCount > 0) ...[
            const SizedBox(height: AppSpacing.l),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('❄️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('동결 배아', style: AppTextStyles.caption.copyWith(color: AppColors.info)),
                        Text('${frozenCount}개', style: AppTextStyles.h3.copyWith(color: AppColors.info)),
                      ],
                    ),
                  ),
                  Text('다음 시도를 위해\n보관 중이에요', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.right),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value, required String subLabel, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h2),
          const SizedBox(height: 2),
          Text(subLabel, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ==================== 다이얼로그들 ====================
  void _showEditCycleDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditCycleDialog(
        cycle: _currentCycle,
        onSave: (updated) => setState(() => _currentCycle = updated),
      ),
    );
  }

  void _showAddResultDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddResultBottomSheet(
        onAdd: (result) {
          setState(() {
            final waitingIndex = _currentCycle.stages.indexWhere((s) => s.stage == TreatmentStage.waiting);
            if (waitingIndex != -1) {
              final waitingStage = _currentCycle.stages[waitingIndex];
              final waitingData = (waitingStage.data as WaitingData?) ?? WaitingData(results: []);
              final newWaitingData = waitingData.addResult(result);

              final newStages = List<CycleStage>.from(_currentCycle.stages);
              newStages[waitingIndex] = waitingStage.copyWith(data: newWaitingData);
              _currentCycle = _currentCycle.copyWith(stages: newStages);
            }
          });
        },
      ),
    );
  }

  void _deleteLabResult(String id) {
    setState(() {
      final waitingIndex = _currentCycle.stages.indexWhere((s) => s.stage == TreatmentStage.waiting);
      if (waitingIndex != -1) {
        final waitingStage = _currentCycle.stages[waitingIndex];
        final waitingData = waitingStage.data as WaitingData?;
        if (waitingData != null) {
          final newWaitingData = waitingData.removeResult(id);
          final newStages = List<CycleStage>.from(_currentCycle.stages);
          newStages[waitingIndex] = waitingStage.copyWith(data: newWaitingData);
          _currentCycle = _currentCycle.copyWith(stages: newStages);
        }
      }
    });
  }
}

// ==================== 다이얼로그 위젯들 ====================

class _EditCycleDialog extends StatefulWidget {
  final TreatmentCycle cycle;
  final Function(TreatmentCycle) onSave;

  const _EditCycleDialog({required this.cycle, required this.onSave});

  @override
  State<_EditCycleDialog> createState() => _EditCycleDialogState();
}

class _EditCycleDialogState extends State<_EditCycleDialog> {
  late int _cycleNumber;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _cycleNumber = widget.cycle.cycleNumber;
    _startDate = widget.cycle.startDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('시도 정보 편집', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.l),
            Text('시도 회차', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _cycleNumber > 1 ? () => setState(() => _cycleNumber--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primaryPurple,
                ),
                Text('$_cycleNumber차', style: AppTextStyles.h3),
                IconButton(
                  onPressed: () => setState(() => _cycleNumber++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primaryPurple,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Text('시작일', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) setState(() => _startDate = date);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}'),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소'))),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(widget.cycle.copyWith(cycleNumber: _cycleNumber, startDate: _startDate));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                    child: const Text('저장', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddResultBottomSheet extends StatefulWidget {
  final Function(LabResult) onAdd;

  const _AddResultBottomSheet({required this.onAdd});

  @override
  State<_AddResultBottomSheet> createState() => _AddResultBottomSheetState();
}

class _AddResultBottomSheetState extends State<_AddResultBottomSheet> {
  LabResultType? _selectedType;
  final _countController = TextEditingController();
  String? _selectedMethod;
  final _gradeNoteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('결과 추가', style: AppTextStyles.h3),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppSpacing.m),

              if (_selectedType == null) ...[
                Text('어떤 결과인가요?', style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: LabResultType.values.map((type) => _buildTypeChip(type)).toList(),
                ),
              ] else ...[
                _buildResultForm(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(LabResultType type) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryPurpleLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(type.displayName, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedType = null),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
            const SizedBox(width: 8),
            Text(_selectedType!.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(_selectedType!.displayName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.l),

        // 개수 입력
        Text('개수', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _countController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: '개',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          ),
        ),

        // 수정 방법 (수정 결과인 경우)
        if (_selectedType == LabResultType.fertilization) ...[
          const SizedBox(height: AppSpacing.m),
          Text('수정 방법', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            children: ['IVF', 'ICSI', 'Split'].map((method) {
              final isSelected = _selectedMethod == method;
              return GestureDetector(
                onTap: () => setState(() => _selectedMethod = method),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPurple : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primaryPurple : AppColors.border),
                  ),
                  child: Text(method, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ],

        // 등급 메모 (배반포인 경우)
        if (_selectedType == LabResultType.day5) ...[
          const SizedBox(height: AppSpacing.m),
          Text('등급 메모', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _gradeNoteController,
            decoration: InputDecoration(
              hintText: '예: AA 1개, AB 2개',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.l),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final result = LabResult(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                type: _selectedType!,
                recordedAt: DateTime.now(),
                count: int.tryParse(_countController.text),
                method: _selectedMethod,
                gradeNote: _gradeNoteController.text.isNotEmpty ? _gradeNoteController.text : null,
              );
              widget.onAdd(result);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ==================== 숫자 키패드 바텀시트 ====================

class _NumberKeypadBottomSheet extends StatefulWidget {
  final int initialValue;
  final String? suffix;
  final Function(int) onConfirm;

  const _NumberKeypadBottomSheet({
    required this.initialValue,
    this.suffix,
    required this.onConfirm,
  });

  @override
  State<_NumberKeypadBottomSheet> createState() => _NumberKeypadBottomSheetState();
}

class _NumberKeypadBottomSheetState extends State<_NumberKeypadBottomSheet> {
  late String _valueString;

  @override
  void initState() {
    super.initState();
    _valueString = widget.initialValue > 0 ? widget.initialValue.toString() : '';
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_valueString.isNotEmpty) {
          _valueString = _valueString.substring(0, _valueString.length - 1);
        }
      } else if (key == 'confirm') {
        final value = int.tryParse(_valueString) ?? 0;
        widget.onConfirm(value);
        Navigator.pop(context);
      } else {
        if (_valueString.length < 5) {
          _valueString += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 바
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _valueString.isEmpty ? '0' : _valueString,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primaryPurple),
                  ),
                  if (widget.suffix != null)
                    Text(widget.suffix!, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            // 키패드
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  _buildKeyRow(['1', '2', '3']),
                  const SizedBox(height: AppSpacing.s),
                  _buildKeyRow(['4', '5', '6']),
                  const SizedBox(height: AppSpacing.s),
                  _buildKeyRow(['7', '8', '9']),
                  const SizedBox(height: AppSpacing.s),
                  _buildKeyRow(['backspace', '0', 'confirm']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    Widget child;
    Color bgColor = AppColors.background;
    Color textColor = AppColors.textPrimary;

    if (key == 'backspace') {
      child = const Icon(Icons.backspace_outlined, size: 24);
    } else if (key == 'confirm') {
      child = const Icon(Icons.check, size: 28, color: Colors.white);
      bgColor = AppColors.primaryPurple;
    } else {
      child = Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600));
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DecimalKeypadBottomSheet extends StatefulWidget {
  final double initialValue;
  final String? suffix;
  final Function(double) onConfirm;

  const _DecimalKeypadBottomSheet({
    required this.initialValue,
    this.suffix,
    required this.onConfirm,
  });

  @override
  State<_DecimalKeypadBottomSheet> createState() => _DecimalKeypadBottomSheetState();
}

class _DecimalKeypadBottomSheetState extends State<_DecimalKeypadBottomSheet> {
  late String _valueString;

  @override
  void initState() {
    super.initState();
    _valueString = widget.initialValue > 0 ? widget.initialValue.toString() : '';
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_valueString.isNotEmpty) {
          _valueString = _valueString.substring(0, _valueString.length - 1);
        }
      } else if (key == 'confirm') {
        final value = double.tryParse(_valueString) ?? 0.0;
        widget.onConfirm(value);
        Navigator.pop(context);
      } else if (key == '.') {
        if (!_valueString.contains('.')) {
          _valueString += _valueString.isEmpty ? '0.' : '.';
        }
      } else {
        if (_valueString.length < 7) {
          _valueString += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 바
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _valueString.isEmpty ? '0' : _valueString,
                    style: AppTextStyles.h2.copyWith(color: AppColors.primaryPurple),
                  ),
                  if (widget.suffix != null)
                    Text(widget.suffix!, style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            // 키패드
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                children: [
                  _buildKeyRow(['1', '2', '3']),
                  const SizedBox(height: AppSpacing.s),
                  _buildKeyRow(['4', '5', '6']),
                  const SizedBox(height: AppSpacing.s),
                  _buildKeyRow(['7', '8', '9']),
                  const SizedBox(height: AppSpacing.s),
                  _buildKeyRow(['.', '0', 'backspace']),
                  const SizedBox(height: AppSpacing.s),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKey(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(String key) {
    Widget child;

    if (key == 'backspace') {
      child = const Icon(Icons.backspace_outlined, size: 24);
    } else {
      child = Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600));
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: () => _onKeyPressed('confirm'),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }
}
