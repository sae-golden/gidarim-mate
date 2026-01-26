import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import 'app_button.dart';
import 'completion_overlay.dart';

/// 주사 부위 위치 정의
enum InjectionSitePosition {
  leftTop1,
  leftTop2,
  leftMid1,
  leftMid2,
  leftBottom1,
  leftBottom2,
  rightTop1,
  rightTop2,
  rightMid1,
  rightMid2,
  rightBottom1,
  rightBottom2,
}

extension InjectionSitePositionExt on InjectionSitePosition {
  String get side => name.startsWith('left') ? 'left' : 'right';
  String get sideLabel => side == 'left' ? '왼쪽' : '오른쪽';

  int get row {
    if (name.contains('Top')) return 0;
    if (name.contains('Mid')) return 1;
    return 2;
  }

  int get col => name.endsWith('1') ? 0 : 1;
}

/// 주사 부위 선택 바텀시트 (새로운 디자인)
/// 왼쪽/오른쪽 각각 2열 x 3행 = 총 12개 부위
class InjectionSiteBottomSheet extends StatefulWidget {
  final String medicationName;
  final String? lastSide; // 'left' 또는 'right'
  final Function(String side) onSiteSelected;

  const InjectionSiteBottomSheet({
    super.key,
    required this.medicationName,
    this.lastSide,
    required this.onSiteSelected,
  });

  /// 바텀시트 표시 후 결과 반환
  static Future<String?> show(
    BuildContext context, {
    required String medicationName,
    String? lastSide,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => InjectionSiteBottomSheet(
        medicationName: medicationName,
        lastSide: lastSide,
        onSiteSelected: (side) {
          Navigator.pop(context, side);
        },
      ),
    );
  }

  @override
  State<InjectionSiteBottomSheet> createState() =>
      _InjectionSiteBottomSheetState();
}

class _InjectionSiteBottomSheetState extends State<InjectionSiteBottomSheet> {
  InjectionSitePosition? _selectedPosition;

  // 추천 부위 (마지막 부위의 반대편)
  String get _recommendedSide {
    if (widget.lastSide == null) return 'left';
    return widget.lastSide == 'left' ? 'right' : 'left';
  }

  void _onComplete() {
    if (_selectedPosition == null) return;

    final selectedSide = _selectedPosition!.side;

    // 바텀시트 먼저 닫기
    Navigator.pop(context, selectedSide);

    // 공통 CompletionOverlay로 축하 애니메이션 표시 (컨페티 포함)
    // Navigator.pop 후에 바텀시트 context 대신 새로운 context가 필요하므로
    // 호출하는 쪽에서 CompletionOverlay를 표시하도록 함
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _buildSelectionView(),
    );
  }

  Widget _buildSelectionView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // 약물 이름
          Text(
            widget.medicationName,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // 질문
          Text(
            '어디에 맞았나요?',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // 새로운 부위 선택 그리드
          _buildNewSiteSelector(),

          // 추천 안내 메시지
          const SizedBox(height: AppSpacing.s),
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.lastSide != null) ...[
                        Text(
                          '최근에 ${widget.lastSide == 'left' ? '왼쪽' : '오른쪽'}에 맞았어요',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '오늘은 ${_recommendedSide == 'left' ? '왼쪽' : '오른쪽'}을 추천해요! ⭐',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Text(
                          '처음이시네요! 편한 쪽을 선택해주세요 ⭐',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 저장 버튼
          AppButton(
            text: '저장',
            onPressed: _selectedPosition != null ? _onComplete : null,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  /// 새로운 부위 선택 그리드 (왼쪽 2x3 + 오른쪽 2x3)
  Widget _buildNewSiteSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 헤더 (왼쪽 / 오른쪽) - 배꼽 없이 라벨만
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '왼쪽',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _recommendedSide == 'left'
                              ? AppColors.primaryPurple
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_recommendedSide == 'left') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 14, color: AppColors.primaryPurple),
                      ],
                    ],
                  ),
                ),
              ),
              // 중앙 여백 (배꼽 위치용)
              const SizedBox(width: 24),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '오른쪽',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _recommendedSide == 'right'
                              ? AppColors.primaryPurple
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_recommendedSide == 'right') ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 14, color: AppColors.primaryPurple),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // 그리드: 3행
          for (int row = 0; row < 3; row++) ...[
            if (row > 0) const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                // 왼쪽 2열
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildSiteCell(_getPosition('left', row, 0))),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildSiteCell(_getPosition('left', row, 1))),
                    ],
                  ),
                ),
                // 중앙 세로선
                Container(
                  width: 1,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
                // 오른쪽 2열
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildSiteCell(_getPosition('right', row, 0))),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildSiteCell(_getPosition('right', row, 1))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InjectionSitePosition _getPosition(String side, int row, int col) {
    final positions = InjectionSitePosition.values.where((p) =>
      p.side == side && p.row == row && p.col == col
    ).toList();
    return positions.first;
  }

  Widget _buildSiteCell(InjectionSitePosition position) {
    final isSelected = _selectedPosition == position;
    final isRecommendedSide = position.side == _recommendedSide;
    final isLastUsedSide = widget.lastSide != null && position.side == widget.lastSide;

    return GestureDetector(
      onTap: () => setState(() => _selectedPosition = position),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple
              : isLastUsedSide
                  ? AppColors.textSecondary.withValues(alpha: 0.15) // 최근 사용 쪽: 음영 처리
                  : isRecommendedSide
                      ? AppColors.primaryPurpleLight.withValues(alpha: 0.5)
                      : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : isRecommendedSide
                    ? AppColors.primaryPurple.withValues(alpha: 0.5)
                    : isLastUsedSide
                        ? AppColors.textSecondary.withValues(alpha: 0.3)
                        : AppColors.border,
            width: isSelected || isRecommendedSide ? 2 : 1,
          ),
        ),
        child: Center(
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : isRecommendedSide
                  ? const Icon(Icons.star, color: AppColors.primaryPurple, size: 16) // ⭐ 아이콘 추가
                  : isLastUsedSide
                      ? Icon(Icons.history, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 14) // 최근 사용 표시
                      : Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
                          ),
                        ),
        ),
      ),
    );
  }
}

/// 전체화면 축하 애니메이션 위젯
class _FullScreenCelebration extends StatefulWidget {
  final VoidCallback onComplete;

  const _FullScreenCelebration({required this.onComplete});

  @override
  State<_FullScreenCelebration> createState() => _FullScreenCelebrationState();
}

class _FullScreenCelebrationState extends State<_FullScreenCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();
    _confettiController.forward();

    // 자동 닫힘 제거 - 탭할 때만 닫힘
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: widget.onComplete,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 컨페티 효과 (전체 화면)
            ..._buildFullScreenConfetti(size),

            // 중앙 컨텐츠
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 큰 주사기 아이콘
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('💉', style: TextStyle(fontSize: 70)),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 체크 마크 애니메이션
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _mainController.value > 0.5 ? 1.0 : 0.0,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),

                      // 축하 메시지
                      Text(
                        '용감하게 잘 맞았어요!',
                        style: AppTextStyles.h1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '오늘도 수고했어요 💜',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // 탭하여 닫기 힌트
                      Text(
                        '화면을 탭하면 닫힙니다',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFullScreenConfetti(Size screenSize) {
    final random = Random(42);
    final colors = [
      AppColors.primaryPurple,
      AppColors.primaryPurpleLight,
      Colors.pink.shade300,
      Colors.amber.shade400,
      Colors.teal.shade300,
      Colors.orange.shade300,
      Colors.white,
    ];

    return List.generate(50, (index) {
      final startX = random.nextDouble() * screenSize.width;
      final endX = startX + (random.nextDouble() - 0.5) * 200;
      final startY = -50.0;
      final endY = screenSize.height + 100;
      final size = 8.0 + random.nextDouble() * 12;
      final color = colors[random.nextInt(colors.length)];
      final delay = random.nextDouble() * 0.4;
      final isCircle = random.nextBool();

      return AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          final progress = ((_confettiController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
          final curve = Curves.easeOutQuad.transform(progress);

          final x = startX + (endX - startX) * curve;
          final y = startY + (endY - startY) * curve;
          final opacity = (1 - progress * 0.7).clamp(0.0, 1.0);
          final rotation = progress * 3.14 * 4;

          return Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: isCircle ? size : size * 0.4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: isCircle
                        ? BorderRadius.circular(size / 2)
                        : BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
