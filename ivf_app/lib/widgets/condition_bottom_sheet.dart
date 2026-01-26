import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/additional_records.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 몸 상태 기록 바텀시트
/// 기획서: 날짜 + 증상 다중선택(8가지) + 메모(선택)
class ConditionBottomSheet extends StatefulWidget {
  final String? cycleId;
  final ConditionRecord? existingRecord; // null이면 새로 추가

  const ConditionBottomSheet({
    super.key,
    this.cycleId,
    this.existingRecord,
  });

  /// 새 몸 상태 기록 추가용 바텀시트 표시
  static Future<ConditionRecord?> showForNew(
    BuildContext context, {
    String? cycleId,
  }) {
    return showModalBottomSheet<ConditionRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConditionBottomSheet(cycleId: cycleId),
    );
  }

  /// 기존 몸 상태 기록 편집용 바텀시트 표시
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required ConditionRecord record,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConditionBottomSheet(
        cycleId: record.cycleId,
        existingRecord: record,
      ),
    );
  }

  @override
  State<ConditionBottomSheet> createState() => _ConditionBottomSheetState();
}

class _ConditionBottomSheetState extends State<ConditionBottomSheet> {
  late DateTime _selectedDate;
  final Set<SymptomType> _selectedSymptoms = {};
  late TextEditingController _memoController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _memoFocusNode = FocusNode();

  bool get isEditing => widget.existingRecord != null;
  bool get canSave => _selectedSymptoms.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingRecord?.date ?? DateTime.now();
    _memoController = TextEditingController(
      text: widget.existingRecord?.memo ?? '',
    );

    // 기존 증상 로드
    if (widget.existingRecord != null) {
      _selectedSymptoms.addAll(widget.existingRecord!.symptoms);
    }

    // 메모 필드 포커스 시 스크롤
    _memoFocusNode.addListener(_onMemoFocusChange);
  }

  void _onMemoFocusChange() {
    if (_memoFocusNode.hasFocus) {
      // 약간의 딜레이 후 스크롤 (키보드가 올라온 후)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _scrollController.dispose();
    _memoFocusNode.removeListener(_onMemoFocusChange);
    _memoFocusNode.dispose();
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
                RecordType.condition.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '몸 상태 기록',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // 스크롤 가능 영역
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 선택
                  _buildDateSelector(),
                  const SizedBox(height: AppSpacing.m),

                  // 증상 선택
                  _buildSymptomSelector(),
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
                  color: RecordType.condition.color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 증상 선택 위젯
  Widget _buildSymptomSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '어떤 증상이 있나요?',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '해당하는 항목을 선택하세요',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textDisabled,
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
            children: SymptomType.values.map((symptom) {
              final isSelected = _selectedSymptoms.contains(symptom);
              final isLast = symptom == SymptomType.values.last;

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedSymptoms.remove(symptom);
                        } else {
                          _selectedSymptoms.add(symptom);
                        }
                      });
                    },
                    borderRadius: BorderRadius.vertical(
                      top: symptom == SymptomType.bloating
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottom: isLast ? const Radius.circular(12) : Radius.zero,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? RecordType.condition.color.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.vertical(
                          top: symptom == SymptomType.bloating
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 체크박스
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? RecordType.condition.color
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? RecordType.condition.color
                                    : AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.m),
                          // 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      symptom.emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      symptom.name,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? RecordType.condition.color
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  symptom.description,
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
          focusNode: _memoFocusNode,
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
              borderSide: BorderSide(color: RecordType.condition.color),
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
              primary: RecordType.condition.color,
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
    if (_selectedSymptoms.isEmpty) return;

    final record = ConditionRecord(
      id: widget.existingRecord?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: widget.cycleId,
      date: _selectedDate,
      symptoms: _selectedSymptoms.toList(),
      memo: _memoController.text.isEmpty ? null : _memoController.text,
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, record);
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '몸 상태 기록을 삭제할까요?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      Navigator.pop(context, 'delete');
    }
  }
}
