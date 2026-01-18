import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 이벤트 편집/추가 바텀시트 (Step 2)
/// 기획서에 맞춘 UI: 채취 상세 정보, 다중 배아 지원
class EventEditBottomSheet extends StatefulWidget {
  final EventType eventType;
  final TreatmentEvent? existingEvent; // null이면 새로 추가
  final Function(TreatmentEvent) onSave;
  final VoidCallback? onDelete;

  const EventEditBottomSheet({
    super.key,
    required this.eventType,
    this.existingEvent,
    required this.onSave,
    this.onDelete,
  });

  /// 새 이벤트 추가용 바텀시트 표시
  static Future<TreatmentEvent?> showForNew(
    BuildContext context, {
    required EventType eventType,
  }) {
    return showModalBottomSheet<TreatmentEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventEditBottomSheet(
        eventType: eventType,
        onSave: (event) {
          Navigator.pop(context, event);
        },
      ),
    );
  }

  /// 기존 이벤트 편집용 바텀시트 표시
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required TreatmentEvent event,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventEditBottomSheet(
        eventType: event.type,
        existingEvent: event,
        onSave: (updatedEvent) {
          Navigator.pop(context, updatedEvent);
        },
        onDelete: () {
          Navigator.pop(context, 'delete');
        },
      ),
    );
  }

  @override
  State<EventEditBottomSheet> createState() => _EventEditBottomSheetState();
}

class _EventEditBottomSheetState extends State<EventEditBottomSheet> {
  late DateTime _selectedDate;

  // 채취 관련
  int? _count;
  int? _matureCount; // 성숙난자 (M2)
  int? _fertilizedCount; // 수정된 배아

  // 이식/동결: 다중 배아
  List<EmbryoInfo> _embryos = [];

  // 호환성: 단일 배양일수 (기존)
  int? _embryoDays;

  late TextEditingController _memoController;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingEvent?.date ?? DateTime.now();
    _count = widget.existingEvent?.count;
    _matureCount = widget.existingEvent?.matureCount;
    _fertilizedCount = widget.existingEvent?.fertilizedCount;
    _embryoDays = widget.existingEvent?.embryoDays;

    // 다중 배아 초기화
    if (widget.existingEvent?.embryos != null &&
        widget.existingEvent!.embryos!.isNotEmpty) {
      _embryos = List.from(widget.existingEvent!.embryos!);
    } else if (widget.eventType.hasMultipleEmbryoInput && !isEditing) {
      // 새로 추가할 때 기본 배아 하나 추가
      _embryos = [const EmbryoInfo(days: 5, count: 1)];
    }

    _memoController =
        TextEditingController(text: widget.existingEvent?.memo ?? '');
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SingleChildScrollView(
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

            // 제목 - 기획서에 맞춘 표현
            Row(
              children: [
                Text(widget.eventType.emoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.s),
                Text(
                  widget.eventType.displayText, // "과배란 중이에요" 등
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // 날짜 선택
            _buildDateSelector(),
            const SizedBox(height: AppSpacing.m),

            // 채취 관련 상세 입력
            if (widget.eventType == EventType.retrieval) ...[
              _buildRetrievalInputs(),
              const SizedBox(height: AppSpacing.m),
            ],

            // 이식/동결: 다중 배아 입력
            if (widget.eventType.hasMultipleEmbryoInput) ...[
              _buildMultipleEmbryoInputs(),
              const SizedBox(height: AppSpacing.m),
            ],

            // 메모 입력
            _buildMemoInput(),
            const SizedBox(height: AppSpacing.l),

            // 버튼들
            Row(
              children: [
                // 삭제 버튼 (편집 모드일 때만)
                if (isEditing && widget.onDelete != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _showDeleteConfirm,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.m),
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
                    text: '완료',
                    onPressed: _handleSave,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 날짜 선택 위젯
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 날짜',
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

  /// 채취 관련 입력 (기획서: 채취/성숙/수정 개수)
  Widget _buildRetrievalInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 채취 개수
        _buildCountRow(
          icon: '🥚',
          label: '채취',
          value: _count,
          onChanged: (value) => setState(() => _count = value),
        ),
        const SizedBox(height: AppSpacing.m),

        // 성숙난자 (M2) - 선택
        _buildCountRow(
          icon: '🧫',
          label: '성숙 (M2)',
          value: _matureCount,
          onChanged: (value) => setState(() => _matureCount = value),
          isOptional: true,
        ),
        const SizedBox(height: AppSpacing.m),

        // 수정된 배아 - 선택
        _buildCountRow(
          icon: '💉',
          label: '수정',
          value: _fertilizedCount,
          onChanged: (value) => setState(() => _fertilizedCount = value),
          isOptional: true,
        ),
      ],
    );
  }

  /// 개수 입력 행
  Widget _buildCountRow({
    required String icon,
    required String label,
    required int? value,
    required ValueChanged<int?> onChanged,
    bool isOptional = false,
  }) {
    return Row(
      children: [
        // 라벨
        SizedBox(
          width: 100,
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // 조절 버튼
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 감소 버튼
              GestureDetector(
                onTap: value != null && value > 0
                    ? () => onChanged(value - 1)
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove,
                    color: value != null && value > 0
                        ? AppColors.primaryPurple
                        : AppColors.textDisabled,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              // 개수 표시
              SizedBox(
                width: 60,
                child: Text(
                  value != null ? '$value개' : '-',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: value != null
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              // 증가 버튼
              GestureDetector(
                onTap: () => onChanged((value ?? 0) + 1),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        // 선택 입력 표시
        if (isOptional)
          Text(
            '(선택)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
      ],
    );
  }

  /// 다중 배아 입력 (이식/동결)
  Widget _buildMultipleEmbryoInputs() {
    final isTransfer = widget.eventType == EventType.transfer;
    final title = isTransfer ? '🌱 이식 배아' : '❄️ 동결 배아';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),

        // 배아 목록
        ..._embryos.asMap().entries.map((entry) {
          final index = entry.key;
          final embryo = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: _buildEmbryoRow(
              embryo: embryo,
              canDelete: _embryos.length > 1,
              onDaysChanged: (days) {
                setState(() {
                  _embryos[index] = embryo.copyWith(days: days);
                });
              },
              onCountChanged: (count) {
                setState(() {
                  _embryos[index] = embryo.copyWith(count: count);
                });
              },
              onDelete: () {
                setState(() {
                  _embryos.removeAt(index);
                });
              },
            ),
          );
        }),

        // 배아 추가 버튼
        Center(
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _embryos.add(const EmbryoInfo(days: 5, count: 1));
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('배아 추가'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  /// 개별 배아 행
  Widget _buildEmbryoRow({
    required EmbryoInfo embryo,
    required bool canDelete,
    required ValueChanged<int> onDaysChanged,
    required ValueChanged<int> onCountChanged,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 배양일수 드롭다운
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: embryo.days,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  items: [2, 3, 4, 5, 6]
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d일', style: AppTextStyles.body),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onDaysChanged(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),

          // 개수 드롭다운
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: embryo.count,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  items: List.generate(10, (i) => i + 1)
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c개', style: AppTextStyles.body),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onCountChanged(value);
                  },
                ),
              ),
            ),
          ),

          // 삭제 버튼
          if (canDelete) ...[
            const SizedBox(width: AppSpacing.s),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.red, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 메모 입력 위젯
  Widget _buildMemoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 메모 (선택)',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: _memoController,
          maxLines: 2,
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
              borderSide: BorderSide(color: AppColors.primaryPurple),
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
        _selectedDate = picked;
      });
    }
  }

  void _handleSave() {
    final memoText = _memoController.text.trim();

    // 다중 배아 처리
    List<EmbryoInfo>? embryosToSave;
    int? countToSave = _count;
    int? embryoDaysToSave = _embryoDays;

    if (widget.eventType.hasMultipleEmbryoInput && _embryos.isNotEmpty) {
      embryosToSave = _embryos;
      // 총 개수 계산
      countToSave = _embryos.fold<int>(0, (sum, e) => sum + e.count);
      // 첫 번째 배아의 배양일수 (호환성)
      embryoDaysToSave = _embryos.first.days;
    }

    final event = TreatmentEvent(
      id: widget.existingEvent?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: widget.eventType,
      date: _selectedDate,
      count: countToSave,
      embryoDays: embryoDaysToSave,
      memo: memoText.isNotEmpty ? memoText : null,
      matureCount: _matureCount,
      fertilizedCount: _fertilizedCount,
      embryos: embryosToSave,
      createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
    );

    widget.onSave(event);
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '${widget.eventType.name} 기록을 삭제할까요?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      widget.onDelete?.call();
    }
  }
}
