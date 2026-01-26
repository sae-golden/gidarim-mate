import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../models/simple_treatment_cycle.dart';
import '../services/simple_treatment_service.dart';
import 'app_button.dart';

/// 새 사이클 시작 바텀시트
/// 기획서에 맞춘 UI: 시술 종류 선택, 차수 선택, 옵션 체크박스
class NewCycleBottomSheet extends StatefulWidget {
  final TreatmentType? initialType;
  final bool isFirstCycle; // 첫 사이클 설정인지 여부

  const NewCycleBottomSheet({
    super.key,
    this.initialType,
    this.isFirstCycle = false,
  });

  /// 바텀시트 표시 후 결과 반환
  /// 반환값: TreatmentCycle (새 사이클) 또는 null (취소)
  static Future<TreatmentCycle?> show(
    BuildContext context, {
    TreatmentType? initialType,
    bool isFirstCycle = false,
  }) {
    return showModalBottomSheet<TreatmentCycle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NewCycleBottomSheet(
        initialType: initialType,
        isFirstCycle: isFirstCycle,
      ),
    );
  }

  @override
  State<NewCycleBottomSheet> createState() => _NewCycleBottomSheetState();
}

class _NewCycleBottomSheetState extends State<NewCycleBottomSheet> {
  late TreatmentType _selectedType;
  int _selectedCycleNumber = 1;
  bool _isNaturalCycle = false; // 자연주기 (인공수정)
  bool _isFrozenTransfer = false; // 동결배아 이식 (시험관)
  bool _isLoading = true;
  int _suggestedIvfNumber = 1;
  int _suggestedIuiNumber = 1;
  late DateTime _startDate; // 시작일

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? TreatmentType.ivf;
    _startDate = DateTime.now(); // 기본값: 오늘
    _loadSuggestedNumbers();
  }

  Future<void> _loadSuggestedNumbers() async {
    final ivfNumber =
        await SimpleTreatmentService.getNextCycleNumber(TreatmentType.ivf);
    final iuiNumber =
        await SimpleTreatmentService.getNextCycleNumber(TreatmentType.iui);

    setState(() {
      _suggestedIvfNumber = ivfNumber;
      _suggestedIuiNumber = iuiNumber;
      // 기본값은 1차로 설정 (기획서 요구사항)
      _selectedCycleNumber = 1;
      _isLoading = false;
    });
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

            // 제목
            Text(
              widget.isFirstCycle ? '시술 정보 설정' : '어떤 시술을 시작하시나요?',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.l),

            // 시술 종류 선택 탭
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.l),

            // 차수 선택
            _buildCycleNumberSelector(),
            const SizedBox(height: AppSpacing.m),

            // 옵션 체크박스
            _buildOptionCheckbox(),
            const SizedBox(height: AppSpacing.m),

            // 시작일 선택 (첫 사이클일 때만 표시)
            if (widget.isFirstCycle) ...[
              _buildStartDateSelector(),
              const SizedBox(height: AppSpacing.m),
            ],

            const SizedBox(height: AppSpacing.l),

            // 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: widget.isFirstCycle ? '저장' : '시작',
                    onPressed: _isLoading ? null : _handleStart,
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

  /// 시술 종류 선택 탭 (시험관 / 인공수정)
  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTypeTab(
            type: TreatmentType.ivf,
            label: '시험관',
            isSelected: _selectedType == TreatmentType.ivf,
          ),
          _buildTypeTab(
            type: TreatmentType.iui,
            label: '인공수정',
            isSelected: _selectedType == TreatmentType.iui,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab({
    required TreatmentType type,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            // 차수는 변경하지 않음 (사용자가 선택한 값 유지)
            // 옵션 초기화
            _isNaturalCycle = false;
            _isFrozenTransfer = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primaryPurple : AppColors.textSecondary,
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 차수 선택
  Widget _buildCycleNumberSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '몇 차 시도인가요?',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedCycleNumber,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: List.generate(10, (index) => index + 1)
                  .map((number) => DropdownMenuItem(
                        value: number,
                        child: Text(
                          '$number차',
                          style: AppTextStyles.body,
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCycleNumber = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 옵션 체크박스 (시술 종류에 따라 다름)
  Widget _buildOptionCheckbox() {
    if (_selectedType == TreatmentType.iui) {
      // 인공수정: 자연주기 옵션
      return _buildCheckboxTile(
        icon: '🌿',
        title: '자연주기로 진행해요',
        subtitle: '(과배란 주사 없이)',
        value: _isNaturalCycle,
        onChanged: (value) {
          setState(() {
            _isNaturalCycle = value ?? false;
          });
        },
      );
    } else {
      // 시험관: 동결배아 이식 옵션
      return _buildCheckboxTile(
        icon: '❄️',
        title: '보관하던 배아를 이식해요',
        subtitle: '(동결배아 이식)',
        value: _isFrozenTransfer,
        onChanged: (value) {
          setState(() {
            _isFrozenTransfer = value ?? false;
          });
        },
      );
    }
  }

  Widget _buildCheckboxTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryPurpleLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryPurple : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AppColors.primaryPurple : AppColors.border,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: AppSpacing.m),
            // 아이콘
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.s),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
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

  /// 시작일 선택
  Widget _buildStartDateSelector() {
    final dateText = '${_startDate.year}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.day.toString().padLeft(2, '0')}';

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
        GestureDetector(
          onTap: _selectStartDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.m,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateText, style: AppTextStyles.body),
                Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
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
      firstDate: DateTime(now.year - 1),
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

  Future<void> _handleStart() async {
    final newCycle = await SimpleTreatmentService.startNewCycle(
      type: _selectedType,
      cycleNumber: _selectedCycleNumber,
      isNaturalCycle: _isNaturalCycle,
      isFrozenTransfer: _isFrozenTransfer,
      startDate: widget.isFirstCycle ? _startDate : null,
    );

    if (mounted) {
      Navigator.pop(context, newCycle);
    }
  }
}
