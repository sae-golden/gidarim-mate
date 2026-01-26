import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/encouragement_messages.dart';

/// 복용 완료 오버레이 위젯 (컨페티 애니메이션 포함)
/// 탭하면 닫히는 전체화면 오버레이
class CompletionOverlay {
  static OverlayEntry? _currentOverlay;
  static VoidCallback? _onDismissCallback;

  /// 복용 완료 오버레이 표시
  /// [onDismissed] 콜백은 오버레이가 닫힌 후 호출됨
  static void show(
    BuildContext context, {
    required String medicationName,
    bool isInjection = false,
    VoidCallback? onDismissed,
  }) {
    // 기존 오버레이가 있으면 제거
    hide();

    _onDismissCallback = onDismissed;

    final message = isInjection
        ? EncouragementMessages.getInjectionMessage()
        : EncouragementMessages.getMedicationMessage();

    _currentOverlay = OverlayEntry(
      builder: (context) => _CompletionOverlayWidget(
        medicationName: medicationName,
        message: message,
        isInjection: isInjection,
        onDismiss: _hideAndCallback,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// 오버레이 숨기기 및 콜백 호출
  static void _hideAndCallback() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _onDismissCallback?.call();
    _onDismissCallback = null;
  }

  /// 오버레이 숨기기
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _onDismissCallback = null;
  }
}

class _CompletionOverlayWidget extends StatefulWidget {
  final String medicationName;
  final String message;
  final bool isInjection;
  final VoidCallback onDismiss;

  const _CompletionOverlayWidget({
    required this.medicationName,
    required this.message,
    required this.isInjection,
    required this.onDismiss,
  });

  @override
  State<_CompletionOverlayWidget> createState() =>
      _CompletionOverlayWidgetState();
}

class _CompletionOverlayWidgetState extends State<_CompletionOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    _mainController.forward();
    _confettiController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _mainController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _mainController,
          builder: (context, child) {
            return Stack(
              children: [
                // 배경
                Container(
                  color: Colors.black.withValues(alpha: 0.6 * _fadeAnimation.value),
                ),

                // 컨페티 효과
                ..._buildConfetti(size),

                // 중앙 컨텐츠
                Center(
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: _buildContent(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildConfetti(Size screenSize) {
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

    return List.generate(40, (index) {
      final startX = random.nextDouble() * screenSize.width;
      final endX = startX + (random.nextDouble() - 0.5) * 150;
      final startY = -30.0;
      final endY = screenSize.height + 50;
      final size = 6.0 + random.nextDouble() * 10;
      final color = colors[random.nextInt(colors.length)];
      final delay = random.nextDouble() * 0.3;
      final isCircle = random.nextBool();

      return AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          final progress = ((_confettiController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
          final curve = Curves.easeOutQuad.transform(progress);

          final x = startX + (endX - startX) * curve;
          final y = startY + (endY - startY) * curve;
          final opacity = (1 - progress * 0.8).clamp(0.0, 1.0);
          final rotation = progress * 3.14 * 3;

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
                        : BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이모지 아이콘
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: widget.isInjection
                  ? const Text('💉', style: TextStyle(fontSize: 44))
                  : const Icon(Icons.check, color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: 24),

          // 메인 메시지
          Text(
            widget.isInjection ? '용감하게 잘 맞았어요!' : '복용 완료!',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 서브 메시지
          Text(
            '오늘도 수고했어요 💜',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // 약물 이름
          Text(
            widget.medicationName,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // 응원 메시지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // 안내 텍스트
          Text(
            '화면을 탭하면 닫힙니다',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
