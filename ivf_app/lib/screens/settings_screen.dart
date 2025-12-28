import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/notification_settings_service.dart';
import '../models/notification_settings.dart' as settings_model;
import 'medication_search_screen.dart';
import 'auth_screen.dart';
import 'hospital_info_screen.dart';

/// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  settings_model.NotificationSettings _settings =
      settings_model.NotificationSettings.defaultSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationSettingsService.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _updateSettings(settings_model.NotificationSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    await NotificationSettingsService.saveSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '설정',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 알림 설정
            _buildSectionTitle('알림 설정'),
            const SizedBox(height: AppSpacing.s),
            _buildNotificationSettings(),
            const SizedBox(height: AppSpacing.l),

            // 약물 관리
            _buildSectionTitle('약물 관리'),
            const SizedBox(height: AppSpacing.s),
            _buildMedicationSettings(),
            const SizedBox(height: AppSpacing.l),

            // 치료 정보
            _buildSectionTitle('치료 정보'),
            const SizedBox(height: AppSpacing.s),
            _buildTreatmentInfo(),
            const SizedBox(height: AppSpacing.l),

            // 계정 관리
            _buildSectionTitle('계정'),
            const SizedBox(height: AppSpacing.s),
            _buildAccountSection(),
            const SizedBox(height: AppSpacing.l),

            // 앱 정보
            _buildSectionTitle('앱 정보'),
            const SizedBox(height: AppSpacing.s),
            _buildAppInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    if (_isLoading) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.l),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          // 알림 받기
          _buildSwitchTile(
            icon: Icons.notifications_outlined,
            title: '알림 받기',
            subtitle: '약물 복용 시간에 알림을 받습니다',
            value: _settings.isEnabled,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(isEnabled: value));
            },
          ),
          const Divider(height: 1),

          // 미리 알림
          _buildSwitchTile(
            icon: Icons.alarm,
            title: '미리 알림',
            subtitle: '복용 시간 전에 미리 알림을 받습니다',
            value: _settings.preNotification,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(preNotification: value));
            },
          ),
          if (_settings.preNotification) ...[
            const Divider(height: 1),
            _buildDropdownTile(
              icon: Icons.timer_outlined,
              title: '미리 알림 시간',
              value: '${_settings.preNotificationMinutes}분 전',
              options:
                  settings_model.NotificationSettings.preNotificationOptions
                      .map((m) => '$m분 전')
                      .toList(),
              onChanged: (value) {
                final minutes = int.parse(value!.replaceAll('분 전', ''));
                _updateSettings(
                    _settings.copyWith(preNotificationMinutes: minutes));
              },
            ),
          ],

          // 구분선
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Divider(height: 1),
          ),

          // 알람 스타일 (끌 때까지 울림)
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: '알람 스타일 (끌 때까지 울림)',
            subtitle: '화면이 켜지고 알람을 끌 때까지 울립니다',
            value: _settings.alarmStyle,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(alarmStyle: value));
            },
          ),
          const Divider(height: 1),

          // 미완료 시 재알림
          _buildSwitchTile(
            icon: Icons.refresh,
            title: '미완료 시 재알림',
            subtitle: '복용을 완료하지 않으면 다시 알려드려요',
            value: _settings.repeatIfNotCompleted,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(repeatIfNotCompleted: value));
            },
          ),
          if (_settings.repeatIfNotCompleted) ...[
            const Divider(height: 1),
            _buildDropdownTile(
              icon: Icons.timer,
              title: '재알림 간격',
              value: '${_settings.repeatIntervalMinutes}분 후',
              options: settings_model.NotificationSettings.repeatIntervalOptions
                  .map((m) => '$m분 후')
                  .toList(),
              onChanged: (value) {
                final minutes = int.parse(value!.replaceAll('분 후', ''));
                _updateSettings(
                    _settings.copyWith(repeatIntervalMinutes: minutes));
              },
            ),
          ],

          // 힌트 메시지
          if (_settings.repeatIfNotCompleted)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        '약 복용을 완료하지 않으면 ${_settings.repeatIntervalMinutes}분 후 다시 알려드려요',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 알림 테스트 버튼 (웹 제외)
          if (!kIsWeb) ...[
            const Divider(height: 1),
            _buildNavigationTile(
              icon: Icons.notifications_active,
              title: '알림 테스트',
              subtitle: '알림이 정상 작동하는지 확인',
              onTap: _testNotification,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('테스트 알림을 보냈습니다!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 전송 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildMedicationSettings() {
    return AppCard(
      child: Column(
        children: [
          _buildNavigationTile(
            icon: Icons.search,
            title: '약물 정보 검색',
            subtitle: 'IVF 관련 약물 효능/용법 확인',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MedicationSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentInfo() {
    return AppCard(
      child: Column(
        children: [
          _buildNavigationTile(
            icon: Icons.local_hospital_outlined,
            title: '병원 정보',
            subtitle: '담당 병원 및 의사 정보',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HospitalInfoScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    final isLoggedIn = SupabaseService.isLoggedIn;
    final currentUser = SupabaseService.currentUser;

    if (isLoggedIn && currentUser != null) {
      return AppCard(
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.email_outlined,
              title: '로그인 계정',
              value: currentUser.email ?? '알 수 없음',
            ),
            const Divider(height: 1),
            _buildNavigationTile(
              icon: Icons.logout,
              title: '로그아웃',
              subtitle: '다른 계정으로 로그인',
              onTap: _showLogoutConfirmDialog,
            ),
          ],
        ),
      );
    } else {
      return AppCard(
        child: _buildNavigationTile(
          icon: Icons.login,
          title: '로그인 / 회원가입',
          subtitle: '데이터를 클라우드에 동기화하세요',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          },
        ),
      );
    }
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('로그아웃에 실패했습니다'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildAppInfo() {
    return AppCard(
      child: Column(
        children: [
          _buildNavigationTile(
            icon: Icons.help_outline,
            title: '도움말',
            subtitle: '앱 사용법 안내',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildNavigationTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildNavigationTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: '앱 버전',
            value: '1.0.0',
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(title, style: AppTextStyles.body),
          ),
          DropdownButton<String>(
            value: value,
            items: options
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(opt, style: AppTextStyles.body),
                    ))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(title, style: AppTextStyles.body),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showMedicationList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.s),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('등록된 약물', style: AppTextStyles.h3),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.m),
                children: [
                  _buildMedicationItem('FSH 주사', '225IU', '매일 아침 8:00', true),
                  _buildMedicationItem('메트포르민', '500mg', '매일 저녁 8:00', false),
                  _buildMedicationItem('아스피린', '100mg', '매일 아침 7:00', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(String name, String dosage, String time, bool isInjection) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isInjection
                  ? AppColors.primaryPurpleLight
                  : AppColors.success.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isInjection ? Icons.vaccines : Icons.medication,
              color: isInjection ? AppColors.primaryPurple : Colors.green[700],
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyLarge),
                Text('$dosage | $time', style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _showAddMedicationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('약물 일정을 어떻게 추가할까요?', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.l),
            _buildAddOption(
              icon: Icons.camera_alt_outlined,
              title: '처방전 사진 찍기',
              subtitle: '가장 빠른 방법',
              onTap: () => Navigator.pop(context),
            ),
            _buildAddOption(
              icon: Icons.mic_outlined,
              title: '음성으로 말하기',
              subtitle: '"매일 아침 8시 주사"',
              onTap: () => Navigator.pop(context),
            ),
            _buildAddOption(
              icon: Icons.text_fields,
              title: '텍스트로 입력',
              subtitle: '복붙도 가능',
              onTap: () => Navigator.pop(context),
            ),
            _buildAddOption(
              icon: Icons.add,
              title: '직접 하나씩 입력',
              subtitle: '세부 조정용',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryPurple),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showInjectionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.s),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Text('주사 부위 기록', style: AppTextStyles.h3),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 배 그림 (9구역)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        children: List.generate(9, (index) {
                          final hasInjection = [0, 2, 4, 6].contains(index);
                          return Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: hasInjection
                                    ? AppColors.primaryPurple.withOpacity(0.5)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: hasInjection
                                  ? const Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: AppColors.primaryPurple,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      '최근 주사 위치가 표시됩니다',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('치료 단계 선택', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.m),
            _buildStageOption('채취 전 (Stimulation)', true),
            _buildStageOption('채취 (Retrieval)', false),
            _buildStageOption('수정 (Fertilization)', false),
            _buildStageOption('배양 (Culture)', false),
            _buildStageOption('이식 전 (Before Transfer)', false),
            _buildStageOption('이식 (Transfer)', false),
            _buildStageOption('이식 후 (Post Transfer)', false),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  Widget _buildStageOption(String title, bool isSelected) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurpleLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primaryPurple, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryPurple : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primaryPurple),
          ],
        ),
      ),
    );
  }
}
