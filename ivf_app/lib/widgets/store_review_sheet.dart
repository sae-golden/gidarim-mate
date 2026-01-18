import 'package:flutter/material.dart';

/// 스토어 리뷰 유도 바텀시트 (4-5점 선택 시)
/// 앱스토어/플레이스토어 리뷰 작성을 유도함
class StoreReviewSheet extends StatelessWidget {
  final int givenStars;
  final VoidCallback onGoToStore;
  final VoidCallback onClose;

  const StoreReviewSheet({
    super.key,
    required this.givenStars,
    required this.onGoToStore,
    required this.onClose,
  });

  /// 바텀시트 표시
  static Future<void> show(
    BuildContext context, {
    required int givenStars,
    required VoidCallback onGoToStore,
    required VoidCallback onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => StoreReviewSheet(
        givenStars: givenStars,
        onGoToStore: onGoToStore,
        onClose: onClose,
      ),
    );
  }

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

              // 별점 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < givenStars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: index < givenStars ? const Color(0xFFFFB300) : Colors.grey[300],
                  );
                }),
              ),
              const SizedBox(height: 20),

              // 감사 메시지
              const Text(
                '소중한 평가 감사합니다! 💚',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // 설명
              Text(
                '스토어에 리뷰를 남겨주시면\n다른 분들께 큰 도움이 됩니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // 일러스트 영역 (하트 아이콘)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Center(
                  child: Text('❤️', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 28),

              // 스토어 리뷰 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onGoToStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '스토어에 리뷰 남기기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 닫기 버튼
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onClose();
                },
                child: Text(
                  '다음에 할게요',
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
}
