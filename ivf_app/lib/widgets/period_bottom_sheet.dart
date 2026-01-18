import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/additional_records.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 생리 시작일 기록 바텀시트
/// 기획서: 날짜 + 메모(선택)
class PeriodBottomSheet extends StatefulWidget {
  final String? cycleId;
  final PeriodRecord? existingRecord; // null이면 새로 추가

  const PeriodBottomSheet({
    super.key,
    this.cycleId,
    this.existingRecord,
  });

  /// 새 생리 시작일 기록 추가용 바텀시트 표시
  static Future<PeriodRecord?> showForNew(
    BuildContext context, {
    String? cycleId,
  }) {
    return showModalBottomSheet<PeriodRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodBottomSheet(cycleId: cycleId),
    );
  }

  /// 기존 생리 시작일 기록 편집용 바텀시트 표시
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required PeriodRecord record,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PeriodBottomSheet(
        cycleId: record.cycleId,
        existingRecord: record,
      ),
    );
  }

  @override
  State<PeriodBottomSheet> createState() => _PeriodBottomSheetState();
}

class _PeriodBottomSheetState extends State<PeriodBottomSheet> {
  late DateTime _selectedDate;
  late TextEditingController _memoController;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingRecord?.date ?? DateTime.now();
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
                RecordType.period.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '생리 시작했어요',
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // 날짜 선택
          _buildDateSelector(),
          const SizedBox(height: AppSpacing.m),

          // 메모 입력
          _buildMemoInput(),
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
              // 완료 버튼
              Expanded(
                flex: isEditing ? 2 : 1,
                child: AppButton(
                  text: '완료',
                  onPressed: _handleSave,
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
                  color: RecordType.period.color,
                  size: 20,
                ),
              ],
            ),
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
              borderSide: BorderSide(color: RecordType.period.color),
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
              primary: RecordType.period.color,
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
    final record = PeriodRecord(
      id: widget.existingRecord?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: widget.cycleId,
      date: _selectedDate,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, record);
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '생리 시작일 기록을 삭제할까요?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      Navigator.pop(context, 'delete');
    }
  }
}
