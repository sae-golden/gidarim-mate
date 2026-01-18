import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/additional_records.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 초음파 검사 기록 바텀시트
/// 기획서: 날짜 + 난포 크기(다중) + 내막 두께 + 메모(선택)
class UltrasoundBottomSheet extends StatefulWidget {
  final String? cycleId;
  final UltrasoundRecord? existingRecord; // null이면 새로 추가

  const UltrasoundBottomSheet({
    super.key,
    this.cycleId,
    this.existingRecord,
  });

  /// 새 초음파 검사 기록 추가용 바텀시트 표시
  static Future<UltrasoundRecord?> showForNew(
    BuildContext context, {
    String? cycleId,
  }) {
    return showModalBottomSheet<UltrasoundRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UltrasoundBottomSheet(cycleId: cycleId),
    );
  }

  /// 기존 초음파 검사 기록 편집용 바텀시트 표시
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required UltrasoundRecord record,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UltrasoundBottomSheet(
        cycleId: record.cycleId,
        existingRecord: record,
      ),
    );
  }

  @override
  State<UltrasoundBottomSheet> createState() => _UltrasoundBottomSheetState();
}

class _UltrasoundBottomSheetState extends State<UltrasoundBottomSheet> {
  late DateTime _selectedDate;
  final List<TextEditingController> _follicleControllers = [];
  late TextEditingController _endometriumController;
  late TextEditingController _memoController;

  bool get isEditing => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingRecord?.date ?? DateTime.now();
    _endometriumController = TextEditingController(
      text: widget.existingRecord?.endometriumThickness?.toString() ?? '',
    );
    _memoController = TextEditingController(
      text: widget.existingRecord?.memo ?? '',
    );

    // 기존 난포 데이터 로드
    if (widget.existingRecord?.follicleSizes != null &&
        widget.existingRecord!.follicleSizes!.isNotEmpty) {
      for (var size in widget.existingRecord!.follicleSizes!) {
        _follicleControllers.add(
          TextEditingController(text: size.toString()),
        );
      }
    } else {
      // 기본 1개 난포 입력 필드
      _follicleControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _follicleControllers) {
      controller.dispose();
    }
    _endometriumController.dispose();
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
                RecordType.ultrasound.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '초음파 검사',
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

                  // 난포 크기 입력
                  _buildFollicleSizeInput(),
                  const SizedBox(height: AppSpacing.m),

                  // 내막 두께 입력
                  _buildEndometriumInput(),
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
                  color: RecordType.ultrasound.color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 난포 크기 입력 위젯
  Widget _buildFollicleSizeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '난포 크기 (mm)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),

        // 난포 입력 필드들
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (int i = 0; i < _follicleControllers.length; i++)
              _buildFollicleChip(i),
          ],
        ),

        const SizedBox(height: AppSpacing.s),

        // 난포 추가 버튼
        InkWell(
          onTap: _addFollicle,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: RecordType.ultrasound.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: RecordType.ultrasound.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 16,
                  color: RecordType.ultrasound.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '난포 추가',
                  style: AppTextStyles.caption.copyWith(
                    color: RecordType.ultrasound.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 개별 난포 입력 칩
  Widget _buildFollicleChip(int index) {
    return Container(
      width: 80,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _follicleControllers[index],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          if (_follicleControllers.length > 1)
            InkWell(
              onTap: () => _removeFollicle(index),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 내막 두께 입력 위젯
  Widget _buildEndometriumInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내막 두께 (mm)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _endometriumController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: '예: 9.5',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textDisabled,
            ),
            suffixText: 'mm',
            suffixStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
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
              borderSide: BorderSide(color: RecordType.ultrasound.color),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
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
              borderSide: BorderSide(color: RecordType.ultrasound.color),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.m),
          ),
        ),
      ],
    );
  }

  void _addFollicle() {
    setState(() {
      _follicleControllers.add(TextEditingController());
    });
  }

  void _removeFollicle(int index) {
    setState(() {
      _follicleControllers[index].dispose();
      _follicleControllers.removeAt(index);
    });
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
              primary: RecordType.ultrasound.color,
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
    // 난포 크기 수집
    final follicleSizes = <double>[];
    for (var controller in _follicleControllers) {
      final value = double.tryParse(controller.text);
      if (value != null && value > 0) {
        follicleSizes.add(value);
      }
    }

    // 내막 두께
    final endometrium = double.tryParse(_endometriumController.text);

    final record = UltrasoundRecord(
      id: widget.existingRecord?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: widget.cycleId,
      date: _selectedDate,
      follicleSizes: follicleSizes.isEmpty ? null : follicleSizes,
      endometriumThickness: endometrium,
      memo: _memoController.text.isEmpty ? null : _memoController.text,
      createdAt: widget.existingRecord?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, record);
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '초음파 검사 기록을 삭제할까요?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      Navigator.pop(context, 'delete');
    }
  }
}
