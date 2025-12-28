import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../constants/encouragement_messages.dart';
import 'app_button.dart';

/// 주사 부위 상수 (8개 위치)
class InjectionLocation {
  static const List<int> leftLocations = [0, 1, 2, 3];
  static const List<int> rightLocations = [4, 5, 6, 7];

  static const List<String> names = [
    '왼쪽 위',      // 0
    '왼쪽 중상',    // 1
    '왼쪽 중하',    // 2
    '왼쪽 아래',    // 3
    '오른쪽 위',    // 4
    '오른쪽 중상',  // 5
    '오른쪽 중하',  // 6
    '오른쪽 아래',  // 7
  ];

  static String getName(int index) {
    if (index >= 0 && index < names.length) {
      return names[index];
    }
    return '';
  }

  static bool isLeft(int index) => leftLocations.contains(index);
  static bool isRight(int index) => rightLocations.contains(index);

  /// 다음 추천 위치 계산 (좌/우 번갈아, 대칭 위치)
  static int getNextRecommended(int current) {
    if (isLeft(current)) {
      final leftIndex = leftLocations.indexOf(current);
      return rightLocations[leftIndex];
    } else {
      final rightIndex = rightLocations.indexOf(current);
      return leftLocations[rightIndex];
    }
  }
}

/// 주사 부위 선택 다이얼로그
/// 좌/우 번갈아 로테이션: 왼쪽 → 오른쪽 → 왼쪽 → 오른쪽
class InjectionLocationDialog extends StatefulWidget {
  final int? lastLocation; // 마지막 주사 위치 (0-7)
  final Function(int) onLocationSelected;

  const InjectionLocationDialog({
    super.key,
    this.lastLocation,
    required this.onLocationSelected,
  });

  @override
  State<InjectionLocationDialog> createState() =>
      _InjectionLocationDialogState();

  static Future<int?> show(BuildContext context, {int? lastLocation}) {
    return showDialog<int>(
      context: context,
      builder: (context) => InjectionLocationDialog(
        lastLocation: lastLocation,
        onLocationSelected: (location) {
          Navigator.of(context).pop(location);
        },
      ),
    );
  }
}

class _InjectionLocationDialogState extends State<InjectionLocationDialog> {
  int? _selectedLocation;

  // 마지막 위치가 좌측인지 확인
  bool get _wasLastOnLeft {
    if (widget.lastLocation == null) return false;
    return InjectionLocation.isLeft(widget.lastLocation!);
  }

  // 추천 위치 계산 (좌/우 번갈아)
  int get _recommendedLocation {
    if (widget.lastLocation == null) {
      return 2; // 첫 주사는 왼쪽 아래 추천
    }
    return InjectionLocation.getNextRecommended(widget.lastLocation!);
  }

  // 추천 방향 텍스트
  String get _recommendedSideText {
    if (widget.lastLocation == null) return '왼쪽';
    return _wasLastOnLeft ? '오른쪽' : '왼쪽';
  }

  String _getLocationName(int index) => InjectionLocation.getName(index);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              children: [
                const Text('💉', style: TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.s),
                const Expanded(
                  child: Text('주사 부위를 선택해주세요', style: AppTextStyles.h3),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),

            // 추천 안내
            Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.lastLocation != null)
                          Text(
                            '어제: ${_getLocationName(widget.lastLocation!)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        Text(
                          '추천: $_recommendedSideText (${_getLocationName(_recommendedLocation)})',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryPurple,
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

            // 배 그림 (좌/우 분리)
            Container(
              width: 280,
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 중앙 세로선 (배꼽 라인)
                  Positioned(
                    top: 40,
                    bottom: 40,
                    child: Container(
                      width: 2,
                      color: AppColors.border.withOpacity(0.5),
                    ),
                  ),

                  // 배꼽 표시
                  Positioned(
                    top: 30,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '●',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 좌측 라벨
                  Positioned(
                    left: 25,
                    top: 8,
                    child: Text(
                      '왼쪽',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 우측 라벨
                  Positioned(
                    right: 20,
                    top: 8,
                    child: Text(
                      '오른쪽',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 좌측 4구역
                  Positioned(
                    left: 20,
                    top: 55,
                    child: Column(
                      children: InjectionLocation.leftLocations.map((index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildLocationButton(index),
                        );
                      }).toList(),
                    ),
                  ),

                  // 우측 4구역
                  Positioned(
                    right: 20,
                    top: 55,
                    child: Column(
                      children: InjectionLocation.rightLocations.map((index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildLocationButton(index),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s),

            // 선택된 위치 표시
            if (_selectedLocation != null)
              Text(
                '선택: ${_getLocationName(_selectedLocation!)}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryPurple,
                ),
              ),
            const SizedBox(height: AppSpacing.m),

            // 범례
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.primaryPurpleLight, '추천'),
                const SizedBox(width: AppSpacing.m),
                _buildLegendItem(AppColors.warning.withOpacity(0.3), '어제'),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // 저장 버튼
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: '취소',
                    type: AppButtonType.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: AppButton(
                    text: '저장',
                    onPressed: _selectedLocation != null
                        ? () {
                            widget.onLocationSelected(_selectedLocation!);
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton(int index) {
    final isSelected = _selectedLocation == index;
    final isRecommended = index == _recommendedLocation;
    final isLastUsed = index == widget.lastLocation;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocation = index;
        });
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple
              : isRecommended
                  ? AppColors.primaryPurpleLight
                  : isLastUsed
                      ? AppColors.warning.withOpacity(0.3)
                      : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurpleDark
                : isRecommended
                    ? AppColors.primaryPurple
                    : AppColors.border,
            width: isSelected || isRecommended ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isSelected
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
              : isRecommended
                  ? const Icon(
                      Icons.star,
                      color: AppColors.primaryPurple,
                      size: 18,
                    )
                  : isLastUsed
                      ? const Text(
                          '어제',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

/// 주사 완료 확인 다이얼로그
class InjectionCompleteDialog extends StatelessWidget {
  final String medicationName;
  final int selectedLocation;
  final int? nextRecommendedLocation;

  const InjectionCompleteDialog({
    super.key,
    required this.medicationName,
    required this.selectedLocation,
    this.nextRecommendedLocation,
  });

  String _getLocationName(int index) => InjectionLocation.getName(index);

  int _getNextRecommended(int current) => InjectionLocation.getNextRecommended(current);

  static Future<void> show(
    BuildContext context, {
    required String medicationName,
    required int selectedLocation,
    int? nextRecommendedLocation,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InjectionCompleteDialog(
        medicationName: medicationName,
        selectedLocation: selectedLocation,
        nextRecommendedLocation: nextRecommendedLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextRecommended = nextRecommendedLocation ?? _getNextRecommended(selectedLocation);
    final nextSide = InjectionLocation.isLeft(nextRecommended) ? '왼쪽' : '오른쪽';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 성공 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            Text(
              '완료되었습니다!',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.s),

            Text(
              medicationName,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),

            // 응원 문구
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                EncouragementMessages.getInjectionMessage(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // 오늘 주사 위치
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('오늘 주사 위치', style: AppTextStyles.caption),
                        Text(
                          _getLocationName(selectedLocation),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 내일 추천 위치
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lightbulb,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내일 추천: $nextSide',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        Text(
                          _getLocationName(nextRecommended),
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 좌우 표시 아이콘
                  Icon(
                    InjectionLocation.isLeft(nextRecommended)
                        ? Icons.arrow_back
                        : Icons.arrow_forward,
                    color: AppColors.primaryPurple,
                    size: 24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // 확인 버튼
            AppButton(
              text: '확인',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
