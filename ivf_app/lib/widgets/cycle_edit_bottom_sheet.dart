import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 시술 정보 수정 바텀시트
/// 기획서: 차수, 시술 종류, 시작일 수정 가능
class CycleEditBottomSheet extends StatefulWidget {
  final TreatmentCycle cycle;

  const CycleEditBottomSheet({
    super.key,
    required this.cycle,
  });

  /// 바텀시트 표시
  /// 반환값: 수정된 TreatmentCycle 또는 'delete' (삭제 요청) 또는 null (취소)
  static Future<dynamic> show(
    BuildContext context, {
    required TreatmentCycle cycle,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CycleEditBottomSheet(cycle: cycle),
    );
  }

  @override
  State<CycleEditBottomSheet> createState() => _CycleEditBottomSheetState();
}

class _CycleEditBottomSheetState extends State<CycleEditBottomSheet> {
  late int _cycleNumber;
  late TreatmentType _treatmentType;
  late DateTime _startDate;
  late bool _isNaturalCycle;
  late bool _isFrozenTransfer;

  @override
  void initState() {
    super.initState();
    _cycleNumber = widget.cycle.cycleNumber;
    _treatmentType = widget.cycle.type;
    _startDate = widget.cycle.startDate;
    _isNaturalCycle = widget.cycle.isNaturalCycle;
    _isFrozenTransfer = widget.cycle.isFrozenTransfer;
  }

  bool get _hasChanges {
    return _cycleNumber != widget.cycle.cycleNumber ||
        _treatmentType != widget.cycle.type ||
        !_isSameDay(_startDate, widget.cycle.startDate) ||
        _isNaturalCycle != widget.cycle.isNaturalCycle ||
        _isFrozenTransfer != widget.cycle.isFrozenTransfer;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            '시술 정보 수정',
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.l),

          // 스크롤 가능 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 차수 선택
                  _buildAttemptNumberSelector(),
                  const SizedBox(height: AppSpacing.l),

                  // 시술 종류 선택
                  _buildTreatmentTypeSelector(),
                  const SizedBox(height: AppSpacing.l),

                  // 추가 옵션 (IUI인 경우 자연주기, IVF인 경우 동결배아)
                  if (_treatmentType == TreatmentType.iui) ...[
                    _buildNaturalCycleOption(),
                    const SizedBox(height: AppSpacing.l),
                  ] else ...[
                    _buildFrozenTransferOption(),
                    const SizedBox(height: AppSpacing.l),
                  ],

                  // 시작일 선택
                  _buildStartDateSelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          // 버튼들
          Row(
            children: [
              // 삭제 버튼
              Expanded(
                child: OutlinedButton(
                  onPressed: _showDeleteConfirm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('삭제'),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              // 저장 버튼
              Expanded(
                flex: 2,
                child: AppButton(
                  text: '저장',
                  onPressed: _hasChanges ? _handleSave : null,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 차수 선택 위젯
  Widget _buildAttemptNumberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '차수',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // 감소 버튼
              IconButton(
                onPressed: _cycleNumber > 1
                    ? () => setState(() => _cycleNumber--)
                    : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: _cycleNumber > 1
                      ? AppColors.primaryPurple
                      : AppColors.textDisabled,
                ),
              ),
              // 현재 차수
              Expanded(
                child: Center(
                  child: Text(
                    '$_cycleNumber차',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),
              // 증가 버튼
              IconButton(
                onPressed: _cycleNumber < 20
                    ? () => setState(() => _cycleNumber++)
                    : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: _cycleNumber < 20
                      ? AppColors.primaryPurple
                      : AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 시술 종류 선택 위젯
  Widget _buildTreatmentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시술 종류',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: TreatmentType.values.map((type) {
            final isSelected = _treatmentType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == TreatmentType.ivf ? AppSpacing.s : 0,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _treatmentType = type;
                      // IVF로 변경 시 자연주기 해제
                      if (type == TreatmentType.ivf) {
                        _isNaturalCycle = false;
                      }
                      // IUI로 변경 시 동결배아 해제
                      if (type == TreatmentType.iui) {
                        _isFrozenTransfer = false;
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.m,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryPurple.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryPurple
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          type.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          type.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryPurple
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          type.description,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 자연주기 옵션 (IUI용)
  Widget _buildNaturalCycleOption() {
    return InkWell(
      onTap: () {
        setState(() {
          _isNaturalCycle = !_isNaturalCycle;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: _isNaturalCycle
              ? AppColors.primaryPurple.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isNaturalCycle ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _isNaturalCycle ? AppColors.primaryPurple : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      _isNaturalCycle ? AppColors.primaryPurple : AppColors.border,
                  width: 2,
                ),
              ),
              child: _isNaturalCycle
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌿 자연주기',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isNaturalCycle
                          ? AppColors.primaryPurple
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '과배란 주사 없이 자연 배란으로 진행',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 동결배아 이식 옵션 (IVF용)
  Widget _buildFrozenTransferOption() {
    return InkWell(
      onTap: () {
        setState(() {
          _isFrozenTransfer = !_isFrozenTransfer;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: _isFrozenTransfer
              ? AppColors.primaryPurple.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFrozenTransfer ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _isFrozenTransfer ? AppColors.primaryPurple : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      _isFrozenTransfer ? AppColors.primaryPurple : AppColors.border,
                  width: 2,
                ),
              ),
              child: _isFrozenTransfer
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '❄️ 동결배아 이식',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isFrozenTransfer
                          ? AppColors.primaryPurple
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '이전에 동결한 배아로 이식 진행',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시작일 선택 위젯
  Widget _buildStartDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시작일',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        InkWell(
          onTap: _selectStartDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}',
                  style: AppTextStyles.body,
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
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

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _handleSave() {
    // 수정된 사이클 생성
    final updatedCycle = widget.cycle.copyWith(
      cycleNumber: _cycleNumber,
      type: _treatmentType,
      startDate: _startDate,
      isNaturalCycle: _isNaturalCycle,
      isFrozenTransfer: _isFrozenTransfer,
    );

    Navigator.pop(context, updatedCycle);
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '${widget.cycle.cycleNumber}차 시술 기록을 삭제할까요?\n\n이 주기에 포함된 모든 이벤트와 기록이 함께 삭제됩니다.',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      Navigator.pop(context, 'delete');
    }
  }
}
