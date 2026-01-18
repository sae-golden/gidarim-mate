import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../services/supabase_service.dart';
import '../services/notification_settings_service.dart';
import '../services/sync_service.dart';
import '../services/medication_storage_service.dart';
import '../models/notification_settings.dart' as settings_model;
import 'auth_screen.dart';
import 'hospital_info_screen.dart';
import 'app_info_screen.dart';
import '../widgets/confirm_bottom_sheet.dart';

/// 설정 화면 (간소화 버전)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  settings_model.NotificationSettings _settings =
      settings_model.NotificationSettings.defaultSettings;
  bool _isLoading = true;

  // 동기화 관련 상태
  SyncStatus _syncStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSyncStatus();
    _subscribeSyncStatus();
  }

  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationSettingsService.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _loadSyncStatus() async {
    final lastSync = await MedicationStorageService.getLastSyncTime();
    setState(() {
      _syncStatus = SyncService.status;
      _lastSyncTime = lastSync;
    });
  }

  void _subscribeSyncStatus() {
    _syncStatusSubscription = SyncService.statusStream.listen((status) {
      setState(() {
        _syncStatus = status;
      });
      if (status == SyncStatus.success || status == SyncStatus.failed) {
        _loadSyncStatus();
      }
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
    final isLoggedIn = SupabaseService.isLoggedIn;

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
            // 내 정보
            _buildSectionTitle('내 정보'),
            const SizedBox(height: AppSpacing.s),
            _buildMyInfoSection(),
            const SizedBox(height: AppSpacing.l),

            // 알림
            _buildSectionTitle('알림'),
            const SizedBox(height: AppSpacing.s),
            _buildNotificationSection(),
            const SizedBox(height: AppSpacing.l),

            // 데이터 초기화 + 앱 정보
            _buildDataAndAppInfoSection(),

            // 로그아웃 (로그인 상태일 때만)
            if (isLoggedIn) ...[
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton(
                  onPressed: _showLogoutConfirmDialog,
                  child: Text(
                    '로그아웃',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.l),
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

  /// 내 정보 섹션
  Widget _buildMyInfoSection() {
    final isLoggedIn = SupabaseService.isLoggedIn;
    final currentUser = SupabaseService.currentUser;

    return AppCard(
      child: Column(
        children: [
          // 계정 정보
          if (isLoggedIn && currentUser != null) ...[
            _buildAccountTile(currentUser.email ?? '알 수 없음'),
          ] else ...[
            _buildNavigationTile(
              icon: Icons.person_outline,
              title: '로그인 / 회원가입',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            ),
          ],
          const Divider(height: 1),
          // 병원 정보
          _buildNavigationTile(
            icon: Icons.local_hospital_outlined,
            title: '병원 정보',
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

  /// 알림 섹션 (간소화)
  Widget _buildNotificationSection() {
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
            value: _settings.isEnabled,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(isEnabled: value));
            },
          ),
          const Divider(height: 1),

          // 미리 알림 (한 줄로 통합)
          _buildSwitchWithValueTile(
            icon: Icons.alarm,
            title: '미리 알림',
            valueText: '${_settings.preNotificationMinutes}분 전',
            value: _settings.preNotification,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(preNotification: value));
            },
            onValueTap: _settings.preNotification ? _showPreNotificationPicker : null,
          ),
          const Divider(height: 1),

          // 재알림 (한 줄로 통합)
          _buildSwitchWithValueTile(
            icon: Icons.refresh,
            title: '재알림',
            valueText: '${_settings.repeatIntervalMinutes}분 후',
            value: _settings.repeatIfNotCompleted,
            onChanged: (value) {
              _updateSettings(_settings.copyWith(repeatIfNotCompleted: value));
            },
            onValueTap: _settings.repeatIfNotCompleted ? _showRepeatIntervalPicker : null,
          ),
          // 잠금화면 설정 (Android만, 웹 제외)
          if (!kIsWeb && Platform.isAndroid) ...[
            const Divider(height: 1),
            _buildNavigationTile(
              icon: Icons.lock_open_outlined,
              title: '잠금화면 알림 설정',
              onTap: _showLockScreenPermissionGuide,
            ),
          ],
        ],
      ),
    );
  }

  /// 데이터 초기화 + 앱 정보 섹션 (통합)
  Widget _buildDataAndAppInfoSection() {
    final isLoggedIn = SupabaseService.isLoggedIn;

    return AppCard(
      child: Column(
        children: [
          // 클라우드 동기화 (로그인 상태일 때만)
          if (isLoggedIn) ...[
            _buildSyncTile(),
            const Divider(height: 1),
          ],
          // 데이터 초기화
          _buildNavigationTile(
            icon: Icons.delete_outline,
            title: '데이터 초기화',
            onTap: isLoggedIn ? _showDeleteAllDataDialog : _showDeleteLocalDataDialog,
          ),
          const Divider(height: 1),
          // 앱 정보
          _buildInfoNavigationTile(
            icon: Icons.info_outline,
            title: '앱 정보',
            value: 'v1.0.0',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppInfoScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== 위젯 빌더 ====================

  /// 계정 타일 (이메일만 표시)
  Widget _buildAccountTile(String email) {
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
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              email,
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 스위치 타일
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }

  /// 스위치 + 값 표시 타일 (미리 알림, 재알림용)
  Widget _buildSwitchWithValueTile({
    required IconData icon,
    required String title,
    required String valueText,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onValueTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
            child: Row(
              children: [
                Text(title, style: AppTextStyles.body),
                if (value) ...[
                  const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: onValueTap,
                    child: Text(
                      valueText,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  ),
                ],
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

  /// 동기화 타일 (탭하면 동기화)
  Widget _buildSyncTile() {
    String syncText = '방금 전';
    if (_lastSyncTime != null) {
      final diff = DateTime.now().difference(_lastSyncTime!);
      if (diff.inMinutes < 1) {
        syncText = '방금 전';
      } else if (diff.inMinutes < 60) {
        syncText = '${diff.inMinutes}분 전';
      } else if (diff.inHours < 24) {
        syncText = '${diff.inHours}시간 전';
      } else {
        syncText = '${diff.inDays}일 전';
      }
    }

    final isSyncing = _syncStatus == SyncStatus.syncing;

    return InkWell(
      onTap: isSyncing ? null : _handleSync,
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
              child: isSyncing
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.cloud_outlined,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text('클라우드 동기화', style: AppTextStyles.body),
            ),
            Text(
              isSyncing ? '동기화 중...' : syncText,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 네비게이션 타일
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
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
              child: Text(title, style: AppTextStyles.body),
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

  /// 정보 + 네비게이션 타일 (앱 정보용)
  Widget _buildInfoNavigationTile({
    required IconData icon,
    required String title,
    required String value,
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
              child: Row(
                children: [
                  Text(title, style: AppTextStyles.body),
                  const Text(' · ', style: TextStyle(color: AppColors.textSecondary)),
                  Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

  // ==================== 액션 핸들러 ====================

  void _showPreNotificationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.m),
              child: Text('미리 알림 시간', style: AppTextStyles.h3),
            ),
            ...settings_model.NotificationSettings.preNotificationOptions.map((minutes) {
              return ListTile(
                title: Text('$minutes분 전'),
                trailing: _settings.preNotificationMinutes == minutes
                    ? const Icon(Icons.check, color: AppColors.primaryPurple)
                    : null,
                onTap: () {
                  _updateSettings(_settings.copyWith(preNotificationMinutes: minutes));
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  void _showRepeatIntervalPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.m),
              child: Text('재알림 간격', style: AppTextStyles.h3),
            ),
            ...settings_model.NotificationSettings.repeatIntervalOptions.map((minutes) {
              return ListTile(
                title: Text('$minutes분 후'),
                trailing: _settings.repeatIntervalMinutes == minutes
                    ? const Icon(Icons.check, color: AppColors.primaryPurple)
                    : null,
                onTap: () {
                  _updateSettings(_settings.copyWith(repeatIntervalMinutes: minutes));
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSync() async {
    final result = await SyncService.syncAll();

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('동기화 완료! ${result.syncedItems}개 항목'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? '동기화 실패'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteLocalDataDialog() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '모든 약물 데이터를 삭제할까요?\n\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      await _deleteLocalData();
    }
  }

  Future<void> _deleteLocalData() async {
    try {
      await MedicationStorageService.clearAllMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('데이터가 초기화되었습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllDataDialog() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '로컬과 클라우드의 모든 데이터를 삭제할까요?\n\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '전체 삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      await _deleteAllData();
    }
  }

  Future<void> _deleteAllData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('삭제 중...'),
          ],
        ),
      ),
    );

    try {
      await MedicationStorageService.clearAllMedications();
      await _deleteCloudData();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('모든 데이터가 초기화되었습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _deleteCloudData() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final client = SupabaseService.client;
    await client.from('user_medications').delete().eq('user_id', userId);
    await client.from('medication_logs').delete().eq('user_id', userId);
    await client.from('injection_sites').delete().eq('user_id', userId);
  }

  Future<void> _showLogoutConfirmDialog() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '정말 로그아웃 할까요?',
      confirmText: '로그아웃',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      await _logout();
    }
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
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// 잠금화면 알림 설정 안내 다이얼로그
  void _showLockScreenPermissionGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Text('잠금화면 알림 설정'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '약물 알림이 잠금화면에 표시되도록 하려면 아래 설정을 확인해주세요.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '📱 알림 설정',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 8),
              Text(
                '1. 설정 > 앱 > 기다림메이트 > 알림\n'
                '2. "잠금 화면에 표시" 활성화\n'
                '3. "전체 화면 알림" 허용',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                '🔋 배터리 최적화',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 8),
              Text(
                '1. 설정 > 앱 > 기다림메이트 > 배터리\n'
                '2. "제한 없음" 또는 "최적화 안함" 선택',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                '⚠️ 제조사별 추가 설정이 필요할 수 있어요.\n'
                '(삼성: 절전 제외, 샤오미: 자동 시작 등)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('설정 열기', style: TextStyle(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    );
  }
}
