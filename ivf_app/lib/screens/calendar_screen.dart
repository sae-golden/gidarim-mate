import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';

/// 캘린더 화면
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  // 임시 데이터: 날짜별 완료 상태
  final Map<DateTime, List<MedicationStatus>> _medicationData = {};

  @override
  void initState() {
    super.initState();
    // 샘플 데이터 제거 - Supabase에서 실제 데이터 로드
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '캘린더',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            // 월 선택 헤더
            _buildMonthHeader(),
            const SizedBox(height: AppSpacing.m),

            // 선택된 날짜의 상세 정보 (캘린더 위로 이동)
            _buildSelectedDateDetail(),
            const SizedBox(height: AppSpacing.m),

            // 캘린더
            _buildCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
            });
          },
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textPrimary,
        ),
        Text(
          '${_focusedMonth.year}년 ${_focusedMonth.month}월',
          style: AppTextStyles.h3,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
            });
          },
          icon: const Icon(Icons.chevron_right),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return AppCard(
      child: Column(
        children: [
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: day == '일'
                                ? AppColors.error
                                : day == '토'
                                    ? AppColors.info
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.s),

          // 날짜 그리드
          ..._buildCalendarWeeks(),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarWeeks() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startingWeekday = firstDay.weekday % 7;

    List<Widget> weeks = [];
    List<Widget> currentWeek = [];

    // 이전 달의 빈 칸
    for (int i = 0; i < startingWeekday; i++) {
      currentWeek.add(const Expanded(child: SizedBox(height: 60)));
    }

    // 현재 달의 날짜들
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      currentWeek.add(_buildDayCell(date));

      if (currentWeek.length == 7) {
        weeks.add(Row(children: currentWeek));
        weeks.add(const SizedBox(height: AppSpacing.xs));
        currentWeek = [];
      }
    }

    // 마지막 주 빈 칸 채우기
    while (currentWeek.length < 7 && currentWeek.isNotEmpty) {
      currentWeek.add(const Expanded(child: SizedBox(height: 60)));
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(Row(children: currentWeek));
    }

    return weeks;
  }

  Widget _buildDayCell(DateTime date) {
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, _selectedDate);
    final medications = _medicationData[DateTime(date.year, date.month, date.day)];

    int completed = 0;
    int total = 0;
    if (medications != null) {
      total = medications.length;
      completed = medications.where((m) => m.isCompleted).length;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryPurpleLight
                : isToday
                    ? AppColors.primaryPurple.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: AppColors.primaryPurple, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryPurpleDark : AppColors.textPrimary,
                ),
              ),
              if (total > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    total > 4 ? 4 : total,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: index < completed
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDateDetail() {
    final dateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final medications = _medicationData[dateKey];
    final isPastDate = dateKey.isBefore(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${_selectedDate.month}월 ${_selectedDate.day}일의 투약',
                style: AppTextStyles.h3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (medications == null || medications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(
                  '등록된 약물이 없습니다',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...medications.map((med) => _buildMedicationItem(med, isPastDate, dateKey)),
        ],
      ),
    );
  }

  Widget _buildMedicationItem(MedicationStatus med, bool isPastDate, DateTime dateKey) {
    // 주사 부위 텍스트
    String sideText = '';
    if (med.type == 'injection' && med.injectionSide != null) {
      sideText = med.injectionSide == 'left' ? '왼쪽' : '오른쪽';
    }

    // 시간 및 상태 텍스트
    String statusText = '';
    if (med.isCompleted) {
      statusText = '${med.formattedCompletedTime} 완료';
    } else {
      statusText = '${med.formattedTime} (미완료)';
    }

    return GestureDetector(
      onTap: () => _showMedicationActionSheet(med, dateKey),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: med.isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: med.isCompleted
                ? AppColors.success.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // 완료 체크 아이콘
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: med.isCompleted
                    ? AppColors.success
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: med.isCompleted
                    ? null
                    : Border.all(color: AppColors.border, width: 2),
              ),
              child: med.isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.s),

            // 약물 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        med.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: med.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: med.isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (sideText.isNotEmpty) ...[
                        Text(
                          ' · $sideText',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: AppTextStyles.caption.copyWith(
                      color: med.isCompleted
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 완료 버튼 (미완료 시)
            if (!med.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '완료',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMedicationActionSheet(MedicationStatus med, DateTime dateKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    Text(
                      med.name,
                      style: AppTextStyles.h3,
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedDate.month}월 ${_selectedDate.day}일',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),

                Text(
                  '이 약을 복용하셨나요?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                // 완료 버튼
                GestureDetector(
                  onTap: () {
                    setState(() {
                      med.isCompleted = true;
                      med.completedAt = DateTime.now();
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          '네, 복용했어요',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),

                // 건너뛰기 버튼
                GestureDetector(
                  onTap: () {
                    setState(() {
                      med.isCompleted = false;
                      med.completedAt = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          '아니요, 건너뛰었어요',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class MedicationStatus {
  final String id;
  final String name;
  final String type; // 'pill', 'injection', 'suppository', 'patch'
  final TimeOfDay scheduledTime;
  bool isCompleted;
  DateTime? completedAt;
  String? injectionSide; // 주사인 경우: 'left' / 'right'

  MedicationStatus({
    required this.id,
    required this.name,
    required this.type,
    required this.scheduledTime,
    required this.isCompleted,
    this.completedAt,
    this.injectionSide,
  });

  String get formattedTime {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    if (hour < 12) {
      return '오전 ${hour == 0 ? 12 : hour}:$minute';
    } else {
      return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
    }
  }

  String get formattedCompletedTime {
    if (completedAt == null) return '';
    final hour = completedAt!.hour;
    final minute = completedAt!.minute.toString().padLeft(2, '0');
    if (hour < 12) {
      return '오전 ${hour == 0 ? 12 : hour}:$minute';
    } else {
      return '오후 ${hour == 12 ? 12 : hour - 12}:$minute';
    }
  }
}
