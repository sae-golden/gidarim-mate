import 'package:flutter/material.dart';

/// 피드백 수집 바텀시트 (1-3점 선택 시)
/// 불편 사항 카테고리 선택 및 자유 텍스트 피드백 작성
class FeedbackSheet extends StatefulWidget {
  final int givenStars;
  final Function(String category, String content) onSubmit;
  final VoidCallback onSkip;

  const FeedbackSheet({
    super.key,
    required this.givenStars,
    required this.onSubmit,
    required this.onSkip,
  });

  /// 바텀시트 표시
  static Future<void> show(
    BuildContext context, {
    required int givenStars,
    required Function(String category, String content) onSubmit,
    required VoidCallback onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => FeedbackSheet(
        givenStars: givenStars,
        onSubmit: onSubmit,
        onSkip: onSkip,
      ),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  String? _selectedCategory;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  // 피드백 카테고리 목록
  static const List<Map<String, String>> _categories = [
    {'id': 'bug', 'label': '버그/오류', 'icon': '🐛'},
    {'id': 'ui', 'label': 'UI/디자인', 'icon': '🎨'},
    {'id': 'feature', 'label': '기능 부족', 'icon': '⚡'},
    {'id': 'notification', 'label': '알림 문제', 'icon': '🔔'},
    {'id': 'other', 'label': '기타', 'icon': '💬'},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedCategory != null && _feedbackController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 별점 표시
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < widget.givenStars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 24,
                          color: index < widget.givenStars
                              ? const Color(0xFFFFB300)
                              : Colors.grey[300],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 타이틀
                  const Center(
                    child: Text(
                      '더 나은 앱을 위해\n의견을 들려주세요',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 서브타이틀
                  Center(
                    child: Text(
                      '소중한 의견은 개선에 큰 도움이 됩니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 카테고리 선택
                  const Text(
                    '어떤 부분이 불편하셨나요?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 카테고리 칩들
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category['id'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8F5E9)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category['icon']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 피드백 입력
                  const Text(
                    '자세한 의견을 들려주세요',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 텍스트 입력 필드
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '개선이 필요한 부분이나 추가 의견을 작성해주세요',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 제출 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canSubmit && !_isSubmitting
                          ? () async {
                              setState(() => _isSubmitting = true);
                              Navigator.pop(context);
                              widget.onSubmit(
                                _selectedCategory!,
                                _feedbackController.text.trim(),
                              );
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
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '의견 보내기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 건너뛰기 버튼
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSkip();
                      },
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
