import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import '../services/blood_test_service.dart';
import 'app_button.dart';
import 'confirm_bottom_sheet.dart';

/// 피검사 기록 바텀시트
/// 기획서에 맞춘 UI: 체크박스로 항목 선택 후 값 입력
class BloodTestBottomSheet extends StatefulWidget {
  final String cycleId;
  final BloodTest? existingTest; // null이면 새로 추가

  const BloodTestBottomSheet({
    super.key,
    required this.cycleId,
    this.existingTest,
  });

  /// 새 피검사 기록 추가용 바텀시트 표시
  static Future<BloodTest?> showForNew(
    BuildContext context, {
    required String cycleId,
  }) {
    return showModalBottomSheet<BloodTest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BloodTestBottomSheet(cycleId: cycleId),
    );
  }

  /// 기존 피검사 기록 편집용 바텀시트 표시
  static Future<dynamic> showForEdit(
    BuildContext context, {
    required BloodTest test,
  }) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BloodTestBottomSheet(
        cycleId: test.cycleId,
        existingTest: test,
      ),
    );
  }

  @override
  State<BloodTestBottomSheet> createState() => _BloodTestBottomSheetState();
}

class _BloodTestBottomSheetState extends State<BloodTestBottomSheet> {
  late DateTime _selectedDate;
  final Set<BloodTestType> _selectedTypes = {};
  final Map<BloodTestType, TextEditingController> _controllers = {};
  final Map<BloodTestType, FocusNode> _focusNodes = {};
  final Map<BloodTestType, GlobalKey> _itemKeys = {};

  bool get isEditing => widget.existingTest != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingTest?.date ?? DateTime.now();

    // 컨트롤러, 포커스 노드, 키 초기화
    for (var type in BloodTestType.values) {
      _controllers[type] = TextEditingController();
      _focusNodes[type] = FocusNode();
      _focusNodes[type]!.addListener(() => _onFocusChange(type));
      _itemKeys[type] = GlobalKey();
    }

    // 기존 데이터 로드
    if (widget.existingTest != null) {
      final test = widget.existingTest!;
      if (test.e2 != null) {
        _selectedTypes.add(BloodTestType.e2);
        _controllers[BloodTestType.e2]!.text = test.e2.toString();
      }
      if (test.fsh != null) {
        _selectedTypes.add(BloodTestType.fsh);
        _controllers[BloodTestType.fsh]!.text = test.fsh.toString();
      }
      if (test.lh != null) {
        _selectedTypes.add(BloodTestType.lh);
        _controllers[BloodTestType.lh]!.text = test.lh.toString();
      }
      if (test.p4 != null) {
        _selectedTypes.add(BloodTestType.p4);
        _controllers[BloodTestType.p4]!.text = test.p4.toString();
      }
      if (test.hcg != null) {
        _selectedTypes.add(BloodTestType.hcg);
        _controllers[BloodTestType.hcg]!.text = test.hcg.toString();
      }
      if (test.amh != null) {
        _selectedTypes.add(BloodTestType.amh);
        _controllers[BloodTestType.amh]!.text = test.amh.toString();
      }
      if (test.tsh != null) {
        _selectedTypes.add(BloodTestType.tsh);
        _controllers[BloodTestType.tsh]!.text = test.tsh.toString();
      }
      if (test.vitD != null) {
        _selectedTypes.add(BloodTestType.vitD);
        _controllers[BloodTestType.vitD]!.text = test.vitD.toString();
      }
    }
  }

  void _onFocusChange(BloodTestType type) {
    if (_focusNodes[type]?.hasFocus == true) {
      // 약간의 딜레이 후 해당 항목이 보이도록 스크롤
      Future.delayed(const Duration(milliseconds: 300), () {
        final key = _itemKeys[type];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: 0.5,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = bottomPadding > 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 (항상 고정)
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

          // 스크롤 가능 영역 (버튼 제외)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: AppSpacing.l,
                right: AppSpacing.l,
                top: AppSpacing.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Row(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        '피검사 기록',
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 날짜 선택
                  _buildDateSelector(),
                  const SizedBox(height: AppSpacing.m),

                  // 안내 문구
                  Text(
                    '어떤 수치를 기록할까요?',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '해당하는 항목을 선택하세요',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // 수치 항목들
                  ...BloodTestType.values.map((type) => _buildTestItem(type)),

                  const SizedBox(height: AppSpacing.m),
                ],
              ),
            ),
          ),

          // 버튼들 (스크롤 밖에 고정, 키보드 위에 표시)
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.l,
              right: AppSpacing.l,
              top: AppSpacing.m,
              bottom: hasKeyboard ? bottomPadding + AppSpacing.m : AppSpacing.l,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              boxShadow: hasKeyboard
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 삭제 버튼 (편집 모드일 때만)
                if (isEditing) ...[
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
                    text: '저장',
                    onPressed: _selectedTypes.isEmpty ? null : _handleSave,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
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

  /// 개별 수치 항목
  Widget _buildTestItem(BloodTestType type) {
    final isSelected = _selectedTypes.contains(type);

    return Container(
      key: _itemKeys[type],
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryPurpleLight : AppColors.background,
        border: Border.all(
          color: isSelected ? AppColors.primaryPurple : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 헤더 (탭하면 선택/해제)
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedTypes.remove(type);
                } else {
                  _selectedTypes.add(type);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  // 체크박스
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPurple : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primaryPurple : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  // 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.displayName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
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
                ],
              ),
            ),
          ),

          // 입력 필드 (선택 시에만 표시)
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.m,
              ),
              child: TextField(
                controller: _controllers[type],
                focusNode: _focusNodes[type],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  suffixText: type.unit,
                  suffixStyle: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s,
                  ),
                ),
              ),
            ),
        ],
      ),
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

  double? _getValue(BloodTestType type) {
    if (!_selectedTypes.contains(type)) return null;
    final text = _controllers[type]?.text ?? '';
    return double.tryParse(text);
  }

  Future<void> _handleSave() async {
    final bloodTest = BloodTest(
      id: widget.existingTest?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      cycleId: widget.cycleId,
      date: _selectedDate,
      e2: _getValue(BloodTestType.e2),
      fsh: _getValue(BloodTestType.fsh),
      lh: _getValue(BloodTestType.lh),
      p4: _getValue(BloodTestType.p4),
      hcg: _getValue(BloodTestType.hcg),
      amh: _getValue(BloodTestType.amh),
      tsh: _getValue(BloodTestType.tsh),
      vitD: _getValue(BloodTestType.vitD),
      createdAt: widget.existingTest?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      await BloodTestService.updateBloodTest(bloodTest);
    } else {
      await BloodTestService.addBloodTest(bloodTest);
    }

    if (mounted) {
      Navigator.pop(context, bloodTest);
    }
  }

  Future<void> _showDeleteConfirm() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '피검사 기록을 삭제할까요?',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      if (widget.existingTest != null) {
        await BloodTestService.removeBloodTest(widget.existingTest!.id);
      }
      if (mounted) {
        Navigator.pop(context, 'delete');
      }
    }
  }
}
