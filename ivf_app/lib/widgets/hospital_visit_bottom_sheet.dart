import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/additional_records.dart';
import 'app_button.dart';

/// 병원 예약 기록 바텀시트
class HospitalVisitBottomSheet extends StatefulWidget {
  final HospitalVisitRecord? record; // null이면 새로 생성
  final String? cycleId;

  const HospitalVisitBottomSheet({
    super.key,
    this.record,
    this.cycleId,
  });

  /// 새 기록 추가용 바텀시트 표시
  static Future<HospitalVisitRecord?> showForNew(
    BuildContext context, {
    String? cycleId,
  }) async {
    return showModalBottomSheet<HospitalVisitRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HospitalVisitBottomSheet(cycleId: cycleId),
    );
  }

  /// 기존 기록 편집용 바텀시트 표시
  /// 반환값: HospitalVisitRecord (수정됨) 또는 'delete' (삭제) 또는 null (취소)
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required HospitalVisitRecord record,
  }) async {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HospitalVisitBottomSheet(record: record),
    );
  }

  @override
  State<HospitalVisitBottomSheet> createState() => _HospitalVisitBottomSheetState();
}

class _HospitalVisitBottomSheetState extends State<HospitalVisitBottomSheet> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  final _memoController = TextEditingController();

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _selectedDate = widget.record!.date;
      _selectedTime = widget.record!.time;
      _memoController.text = widget.record!.memo ?? '';
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = null;
    }
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
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.l),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // 제목
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Row(
              children: [
                Text(
                  RecordType.hospitalVisit.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    _isEditing ? '병원 예약 수정' : '병원 예약 기록',
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _showDeleteConfirm,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // 스크롤 가능 영역
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 선택
                  _buildSectionTitle('예약 날짜'),
                  _buildDateSelector(),
                  const SizedBox(height: AppSpacing.l),

                  // 시간 선택
                  _buildSectionTitle('예약 시간 (선택)'),
                  _buildTimeSelector(),
                  const SizedBox(height: AppSpacing.l),

                  // 메모
                  _buildSectionTitle('메모 (선택)'),
                  _buildMemoField(),
                  const SizedBox(height: AppSpacing.xl),

                  // 저장 버튼
                  AppButton(
                    text: _isEditing ? '수정하기' : '저장하기',
                    onPressed: _save,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: RecordType.hospitalVisit.color,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.m),
            Text(
              _formatDate(_selectedDate),
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: _selectedTime != null ? RecordType.hospitalVisit.color : AppColors.textDisabled,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.m),
            Text(
              _selectedTime != null ? _formatTime(_selectedTime!) : '시간 선택',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: _selectedTime != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (_selectedTime != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedTime = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.textDisabled,
              )
            else
              Icon(Icons.chevron_right, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoField() {
    return TextField(
      controller: _memoController,
      decoration: InputDecoration(
        hintText: '예: 초음파 검사, 채취 상담',
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
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
          borderSide: BorderSide(color: RecordType.hospitalVisit.color, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.m),
      ),
      maxLines: 2,
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: DateTime(now.year + 2, 12, 31),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: RecordType.hospitalVisit.color,
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: RecordType.hospitalVisit.color,
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
      setState(() => _selectedTime = picked);
    }
  }

  void _save() {
    final memo = _memoController.text.trim();

    if (_isEditing) {
      final updated = widget.record!.copyWith(
        date: _selectedDate,
        time: _selectedTime,
        memo: memo.isEmpty ? null : memo,
        clearMemo: memo.isEmpty,
        enableReminder: false,
        clearReminder: true,
      );
      Navigator.pop(context, updated);
    } else {
      final record = HospitalVisitRecord.create(
        cycleId: widget.cycleId,
        date: _selectedDate,
        time: _selectedTime,
        memo: memo.isEmpty ? null : memo,
        enableReminder: false,
      );
      Navigator.pop(context, record);
    }
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 병원 예약 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog 닫기
              Navigator.pop(this.context, 'delete'); // BottomSheet 닫기
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}년 ${date.month}월 ${date.day}일 (${weekdays[date.weekday - 1]})';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period $displayHour:${minute.toString().padLeft(2, '0')}';
  }
}
