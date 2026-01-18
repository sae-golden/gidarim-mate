import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/additional_records.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 임신 테스트 기록 바텀시트
/// 기획서: 날짜 + 결과(양성/희미/음성) + 테스트 종류 + 메모(선택)
class PregnancyTestBottomSheet extends StatefulWidget {
  final String? cycleId;
  final PregnancyTestRecord? existingRecord; // null이면 새로 추가

  const PregnancyTestBottomSheet({
    super.key,
    this.cycleId,
    this.existingRecord,
  });

  /// 새 임신 테스트 기록 추가용 바텀시트 표시
  static Future<PregnancyTestRecord?> showForNew(
    BuildContext context, {
    String? cycleId,
  }) {
    return showModalBottomSheet<PregnancyTestRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PregnancyTestBottomSheet(cycleId: cycleId),
    );
  }

  /// 기존 임신 테스트 기록 편집용 바텀시트 표시
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required PregnancyTestRecord record,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PregnancyTestBottomSheet(
        cycleId: record.cycleId,
        existingRecord: record,
      ),
    );
  }

  @override
  State<PregnancyTestBottomSheet> createState() =>
      _PregnancyTestBottomSheetState();
}

class _PregnancyTestBottomSheetState extends State<PregnancyTestBottomSheet> {
  late DateTime _selectedDate;
  PregnancyTestResult? _selectedResult;
  PregnancyTestType? _selectedTestType;
  late TextEditingController _memoController;

  bool get isEditing => widget.existingRecord != null;
  bool get canSave => _selectedResult != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingRecord?.date ?? DateTime.now();
    _selectedResult = widget.existingRecord?.result;
    _selectedTestType = widget.existingRecord?.testType;
    _memoController = TextEditingController(
      text: widget.existingRecord?.memo ?? '',
    );
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
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
          Row(
            children: [
              Text(
                RecordType.pregnancyTest.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '임신 테스트',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // 스크롤 가능 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 선택
                  _buildDateSelector(),
                  const SizedBox(height: AppSpacing.m),

                  // 결과 선택
                  _buildResultSelector(),
                  const SizedBox(height: AppSpacing.m),

                  // 테스트 종류 선택
                  _buildTestTypeSelector(),
                  const SizedBox(height: AppSpacing.m),

                  // 메모 입력
                  _buildMemoInput(),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          // 버튼들
          Row(
            children: [
              // 삭제 버튼 (편집 모드일 때만)
              if (isEditing) ...[
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
              ],
              // 저장 버튼
              Expanded(
                flex: isEditing ? 2 : 1,
                child: AppButton(
                  text: '저장',
                  onPressed: canSave ? _handleSave : null,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 날짜 선택 위젯
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        InkWell(
          onTap: _selectDate,
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
                  '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: AppTextStyles.body,
                ),
                Icon(
                  Icons.calendar_today,
                  color: RecordType.pregnancyTest.color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 결과 선택 위젯
  Widget _buildResultSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결과를 선택해주세요',
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
          child: Column(
            children: PregnancyTestResult.values.map((result) {
              final isSelected = _selectedResult == result;
              final isLast = result == PregnancyTestResult.values.last;

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedResult = result;
                      });
                    },
                    borderRadius: BorderRadius.circular(isLast ? 12 : 0),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? result.color.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: result == PregnancyTestResult.positive
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 라디오 버튼
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? result.color
                                    : AppColors.textDisabled,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: result.color,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.m),
                          // 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.name,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? result.color
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  result.description,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 이모지
                          Text(
                            result.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 1,
                      color: AppColors.border.withOpacity(0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 테스트 종류 선택 위젯
  Widget _buildTestTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '테스트 종류',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: PregnancyTestType.values.map((type) {
            final isSelected = _selectedTestType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type == PregnancyTestType.home ? AppSpacing.s : 0,
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTestType = isSelected ? null : type;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.m,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? RecordType.pregnancyTest.color.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? RecordType.pregnancyTest.color
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        type.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? RecordType.pregnancyTest.color
                              : AppColors.textPrimary,
                        ),
                      ),
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

  /// 메모 입력 위젯
  Widget _buildMemoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (선택)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _memoController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '메모를 입력하세요',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
            ),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: RecordType.pregnancyTest.color),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.m),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: RecordType.pregnancyTest.color,
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
        _selectedDate = picked;
      });
    }
  }

  void _handleSave() {
    if (_selectedResult == null) return;

    final record = PregnancyTestRecord(
      id: widget.existingRecord?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: widget.cycleId,
      date: _selectedDate,
      result: _selectedResult!,
      testType: _selectedTestType,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, record);
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '임신 테스트 기록을 삭제할까요?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      Navigator.pop(context, 'delete');
    }
  }
}
