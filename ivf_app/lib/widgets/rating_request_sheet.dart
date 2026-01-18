import 'package:flutter/material.dart';

/// 별점 선택 바텀시트
/// 사용자에게 앱 만족도를 묻고 1-5점 별점을 선택하게 함
class RatingRequestSheet extends StatefulWidget {
  final Function(int stars) onRatingSelected;
  final VoidCallback onLater;

  const RatingRequestSheet({
    super.key,
    required this.onRatingSelected,
    required this.onLater,
  });

  /// 바텀시트 표시
  static Future<void> show(
    BuildContext context, {
    required Function(int stars) onRatingSelected,
    required VoidCallback onLater,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RatingRequestSheet(
        onRatingSelected: onRatingSelected,
        onLater: onLater,
      ),
    );
  }

  @override
  State<RatingRequestSheet> createState() => _RatingRequestSheetState();
}

class _RatingRequestSheetState extends State<RatingRequestSheet> {
  int _selectedStars = 0;
  int _hoverStars = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 아이콘
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 20),

              // 타이틀
              const Text(
                '기다림메이트가 도움이 되셨나요?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 서브타이틀
              Text(
                '별점으로 의견을 들려주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // 별점 선택 영역
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  final isSelected = starNumber <= _selectedStars;
                  final isHovered = starNumber <= _hoverStars;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStars = starNumber;
                      });
                    },
                    onTapDown: (_) {
                      setState(() {
                        _hoverStars = starNumber;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _hoverStars = 0;
                      });
                    },
                    onTapCancel: () {
                      setState(() {
                        _hoverStars = 0;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: isHovered ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Icon(
                          isSelected || isHovered ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 48,
                          color: isSelected || isHovered
                              ? const Color(0xFFFFB300)
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),

              // 선택된 별점 텍스트
              SizedBox(
                height: 24,
                child: _selectedStars > 0
                    ? Text(
                        _getStarLabel(_selectedStars),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedStars > 0
                      ? () {
                          Navigator.pop(context);
                          widget.onRatingSelected(_selectedStars);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '평가하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 다음에 하기 버튼
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onLater();
                },
                child: Text(
                  '다음에 하기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1:
        return '별로예요 😢';
      case 2:
        return '아쉬워요 😕';
      case 3:
        return '보통이에요 😐';
      case 4:
        return '좋아요 😊';
      case 5:
        return '최고예요! 🥰';
      default:
        return '';
    }
  }
}
