import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../services/medication_storage_service.dart';
import '../widgets/injection_site_bottom_sheet.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'simple_record_screen.dart';
import 'settings_screen.dart';
import 'add_medication_screen.dart';
import 'quick_add_medication_screen.dart';
import 'voice_input_screen.dart';

// ==================== Refreshable Wrappers ====================

/// HomeScreen을 감싸는 새로고침 가능한 위젯
class HomeScreenRefreshable extends StatefulWidget {
  final VoidCallback? onMedicationStatusChanged;

  const HomeScreenRefreshable({super.key, this.onMedicationStatusChanged});

  @override
  State<HomeScreenRefreshable> createState() => _HomeScreenRefreshState();
}

class _HomeScreenRefreshState extends State<HomeScreenRefreshable> {
  Key _refreshKey = UniqueKey();

  void refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      key: _refreshKey,
      onMedicationStatusChanged: widget.onMedicationStatusChanged,
    );
  }
}

/// CalendarScreen을 감싸는 새로고침 가능한 위젯
class CalendarScreenRefreshable extends StatefulWidget {
  const CalendarScreenRefreshable({super.key});

  @override
  State<CalendarScreenRefreshable> createState() => _CalendarScreenRefreshState();
}

class _CalendarScreenRefreshState extends State<CalendarScreenRefreshable> {
  Key _refreshKey = UniqueKey();

  void refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalendarScreen(key: _refreshKey);
  }
}

/// SimpleRecordScreen을 감싸는 새로고침 가능한 위젯
class SimpleRecordScreenRefreshable extends StatefulWidget {
  final VoidCallback? onRecordChanged;

  const SimpleRecordScreenRefreshable({super.key, this.onRecordChanged});

  @override
  State<SimpleRecordScreenRefreshable> createState() => _SimpleRecordScreenRefreshState();
}

class _SimpleRecordScreenRefreshState extends State<SimpleRecordScreenRefreshable> {
  Key _refreshKey = UniqueKey();

  void refresh() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleRecordScreen(
      key: _refreshKey,
      onRecordChanged: widget.onRecordChanged,
    );
  }
}

/// 메인 화면 (하단 네비게이션 포함)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  // 화면 갱신을 위한 GlobalKey
  final GlobalKey<_HomeScreenRefreshState> _homeKey = GlobalKey();
  final GlobalKey<_CalendarScreenRefreshState> _calendarKey = GlobalKey();
  final GlobalKey<_SimpleRecordScreenRefreshState> _recordKey = GlobalKey();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreenRefreshable(
        key: _homeKey,
        onMedicationStatusChanged: _refreshCalendar,
      ),
      CalendarScreenRefreshable(key: _calendarKey),
      SimpleRecordScreenRefreshable(
        key: _recordKey,
        onRecordChanged: _onRecordChanged,
      ),
      const SettingsScreen(),
    ];
  }

  /// 캘린더 화면 새로고침
  void _refreshCalendar() {
    _calendarKey.currentState?.refresh();
  }

  /// 기록 변경 시 캘린더와 홈 새로고침
  void _onRecordChanged() {
    _calendarKey.currentState?.refresh();
    _homeKey.currentState?.refresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 주사 부위 선택 바텀시트 표시 (새로운 UI + 축하 애니메이션)
  Future<void> _showInjectionLocationDialog(String medicationId, String medicationName) async {
    // 마지막 주사 부위 조회
    final lastSide = await MedicationStorageService.getLastInjectionSite();

    if (!mounted) return;

    // 새로운 주사 부위 선택 바텀시트 표시 (축하 애니메이션 포함)
    final selectedSide = await InjectionSiteBottomSheet.show(
      context,
      medicationName: medicationName,
      lastSide: lastSide,
    );

    if (selectedSide != null && mounted) {
      // 주사 완료 처리 (부위 포함)
      await MedicationStorageService.markMedicationCompleted(
        medicationId: medicationId,
        date: DateTime.now(),
        scheduledCount: 1,
      );

      // 주사 부위 기록
      await MedicationStorageService.addInjectionSite(
        InjectionSiteRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          medicationId: medicationId,
          dateTime: DateTime.now(),
          site: selectedSide,
          location: selectedSide == 'left' ? '왼쪽' : '오른쪽',
        ),
      );

      // 축하 애니메이션이 바텀시트에 포함되어 있으므로 별도 다이얼로그 불필요

      // 화면 새로고침
      refreshScreens();
    }
  }

  /// 약물 추가 바텀시트 표시
  void _showAddMedicationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddMedicationBottomSheet(
        onOptionSelected: (option) async {
          Navigator.pop(context);

          final Widget targetScreen = switch (option) {
            AddMedicationOption.camera => const OcrInputScreen(),
            AddMedicationOption.voice => const ImprovedVoiceInputScreen(),
            AddMedicationOption.manual => const QuickAddMedicationScreen(),
          };

          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );

          // 약 추가 후 홈화면과 캘린더 새로고침
          // result가 null이 아니면 (Medication 객체 또는 다른 값) 새로고침
          if (result != null) {
            _homeKey.currentState?.refresh();
            _calendarKey.currentState?.refresh();
          }
        },
      ),
    );
  }

  /// 외부에서 호출 가능한 새로고침 메서드
  void refreshScreens() {
    _homeKey.currentState?.refresh();
    _calendarKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, '홈'),
                _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, '캘린더'),
                _buildCenterNavItem(), // + 버튼 아래 텍스트
                _buildNavItem(2, Icons.bar_chart_outlined, Icons.bar_chart, '기록'),
                _buildNavItem(3, Icons.settings_outlined, Icons.settings, '설정'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 중앙 + 버튼
  Widget _buildCenterNavItem() {
    return GestureDetector(
      onTap: _showAddMedicationBottomSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 원형 + 버튼
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            // 추가 텍스트
            Transform.translate(
              offset: const Offset(0, -12),
              child: Text(
                '추가',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _previousIndex = _currentIndex;
        setState(() {
          _currentIndex = index;
        });
        // 기록 탭에서 다른 탭으로 이동 시 해당 탭 새로고침
        if (_previousIndex == 2 && index != 2) {
          if (index == 0) {
            _homeKey.currentState?.refresh();
          } else if (index == 1) {
            _calendarKey.currentState?.refresh();
          }
        }
        // 캘린더 탭으로 이동 시 항상 새로고침
        if (index == 1 && _previousIndex != 1) {
          _calendarKey.currentState?.refresh();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryPurple : AppColors.textDisabled,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primaryPurple : AppColors.textDisabled,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 약물 추가 바텀시트 ====================

/// 약물 추가 옵션
enum AddMedicationOption {
  camera,
  voice,
  manual,
}

/// 약물 추가 바텀시트 위젯
class _AddMedicationBottomSheet extends StatelessWidget {
  final Function(AddMedicationOption) onOptionSelected;

  const _AddMedicationBottomSheet({
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: AppSpacing.l + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들 바
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
            '약물 일정을 어떻게 추가할까요?',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.m),

          // 처방전 사진 찍기 (추후 지원)
          Builder(
            builder: (context) => _buildOptionCard(
              icon: '📷',
              title: '처방전 사진 찍기 (추후지원)',
              subtitle: '준비 중이에요',
              isDisabled: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('준비 중입니다'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // 음성으로 말하기
          _buildOptionCard(
            icon: '🎤',
            title: '음성으로 말하기',
            subtitle: '여러 약 한번에 입력 가능',
            onTap: () => onOptionSelected(AddMedicationOption.voice),
          ),
          const SizedBox(height: AppSpacing.s),

          // 직접 입력
          _buildOptionCard(
            icon: '✏️',
            title: '직접 입력',
            subtitle: '간편한 한 페이지 입력',
            isRecommended: true,
            onTap: () => onOptionSelected(AddMedicationOption.manual),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String icon,
    required String title,
    required String subtitle,
    bool isRecommended = false,
    bool isDisabled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // 아이콘
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.m),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? AppColors.textSecondary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 추천 배지
              if (isRecommended)
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
                    '추천',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
