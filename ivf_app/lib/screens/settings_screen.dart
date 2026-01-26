import 'dart:convert' show utf8;
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../services/notification_settings_service.dart';
import '../services/medication_storage_service.dart';
import '../services/backup_service.dart';
import '../services/additional_record_service.dart';
import '../services/simple_treatment_service.dart';
import '../services/blood_test_service.dart';
import '../services/hospital_service.dart';
import '../models/notification_settings.dart' as settings_model;
import 'hospital_info_screen.dart';
import 'app_info_screen.dart';
import '../widgets/confirm_bottom_sheet.dart';
import '../services/notification_scheduler_service.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';

/// 설정 화면 (로컬 저장 전용 버전)
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
    final oldSettings = _settings;
    setState(() {
      _settings = newSettings;
    });
    await NotificationSettingsService.saveSettings(newSettings);

    // 알림 ON/OFF 변경 시
    if (oldSettings.isEnabled != newSettings.isEnabled) {
      if (newSettings.isEnabled) {
        // ON: 알림 재스케줄링
        await NotificationSchedulerService.scheduleAllMedications();
      } else {
        // OFF: 모든 알림 취소
        await NotificationService.cancelAllNotifications();
      }
    }
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

  /// 내 정보 섹션 (병원 정보만)
  Widget _buildMyInfoSection() {
    return AppCard(
      child: Column(
        children: [
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

  /// 알림 섹션 (단순화 버전)
  /// - 푸시 알림만
  /// - 스누즈 5분 고정 (1회만)
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

          // 잠금화면 설정 (Android만, 웹 제외)
          if (!kIsWeb && Platform.isAndroid) ...[
            const Divider(height: 1),
            _buildNavigationTile(
              icon: Icons.lock_open_outlined,
              title: '잠금화면 알림 설정',
              onTap: _showLockScreenPermissionGuide,
            ),
          ],

          // 알림 방식 안내
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.xs),
            child: Row(
              children: [
                const SizedBox(width: 52), // 아이콘 영역 맞춤
                Expanded(
                  child: Text(
                    '"나중에" 버튼 클릭 시 5분 후 1회 재알림',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 데이터 관리 + 앱 정보 섹션
  Widget _buildDataAndAppInfoSection() {
    return AppCard(
      child: Column(
        children: [
          // 데이터 백업
          _buildNavigationTile(
            icon: Icons.backup_outlined,
            title: '데이터 백업',
            onTap: _exportBackup,
          ),
          const Divider(height: 1),
          // 데이터 복원
          _buildNavigationTile(
            icon: Icons.restore_outlined,
            title: '데이터 복원',
            onTap: _importBackup,
          ),
          const Divider(height: 1),
          // 데이터 초기화
          _buildNavigationTile(
            icon: Icons.delete_outline,
            title: '데이터 초기화',
            onTap: _showDeleteLocalDataDialog,
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

  Future<void> _showDeleteLocalDataDialog() async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      message: '모든 데이터를 삭제할까요?\n\n• 약물 및 복용 기록\n• 시술 기록 (과배란, 채취, 이식, 동결)\n• 검사 기록 (피검사, 초음파, 임신 테스트)\n• 일상 기록 (몸 상태, 생리)\n• 병원 예약\n• 시도 정보 (1차/2차 시험관 등)\n\n이 작업은 되돌릴 수 없습니다.',
      confirmText: '삭제',
      cancelText: '취소',
    );

    if (confirmed && mounted) {
      await _deleteLocalData();
    }
  }

  Future<void> _deleteLocalData() async {
    try {
      // 약물 데이터 초기화
      await MedicationStorageService.clearAllMedications();

      // 치료 사이클 데이터 초기화 (시술 기록, 시도 정보)
      await SimpleTreatmentService.clearAllData();

      // 추가 기록 초기화 (생리, 초음파, 임신테스트, 몸상태, 병원예약)
      await AdditionalRecordService.clearAllData();

      // 피검사 기록 초기화
      await BloodTestService.clearAllData();

      // 병원 정보 초기화
      await HospitalService.clearUserHospitalInfo();

      // 모든 알림 취소
      await NotificationService.cancelAllNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('모든 데이터가 초기화되었습니다'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // 메인 화면으로 이동하여 앱 새로고침
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// 데이터 백업 (JSON 파일로 내보내기)
  Future<void> _exportBackup() async {
    try {
      // 백업 데이터 생성 (로딩 표시 전에 먼저 데이터 준비)
      final jsonData = await BackupService.exportAllData();
      final fileName = BackupService.generateBackupFileName();

      // SAF를 통해 저장 위치 선택 (Android)
      // file_picker의 saveFile 사용
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: '백업 파일 저장',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonData),
      );

      if (savedPath == null) {
        // 사용자가 취소함
        return;
      }

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 완료: $savedPath'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('백업 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// 데이터 복원 (JSON 파일에서 가져오기)
  Future<void> _importBackup() async {
    try {
      // 파일 선택
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // 취소됨
      }

      final file = result.files.first;
      String jsonData;

      // 파일 내용 읽기
      if (kIsWeb) {
        // 웹에서는 bytes 사용
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('파일을 읽을 수 없습니다');
        }
        jsonData = String.fromCharCodes(bytes);
      } else {
        // 모바일/데스크톱에서는 path 사용
        final path = file.path;
        if (path == null) {
          throw Exception('파일 경로를 찾을 수 없습니다');
        }
        jsonData = await File(path).readAsString();
      }

      // 백업 파일 유효성 검사
      final validation = await BackupService.validateBackupFile(jsonData);

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.errorMessage ?? '유효하지 않은 백업 파일입니다'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      // 복원 확인 다이얼로그
      if (!mounted) return;
      final confirmed = await _showRestoreConfirmDialog(validation.summary!);

      if (!confirmed) return;

      // 로딩 표시
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
      );

      // 데이터 복원
      await BackupService.importAllData(jsonData);

      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 성공 메시지 및 앱 재시작 안내
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('복원 완료'),
              ],
            ),
            content: const Text(
              '백업 데이터가 성공적으로 복원되었습니다.\n\n앱을 다시 시작합니다.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // 메인 화면으로 이동하여 앱 새로고침
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  '확인',
                  style: TextStyle(color: AppColors.primaryPurple),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 로딩이 열려있으면 닫기
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('복원 실패: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// 복원 확인 다이얼로그
  Future<bool> _showRestoreConfirmDialog(BackupSummary summary) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('데이터 복원'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '기존 데이터가 모두 삭제되고 백업 데이터로 대체됩니다.\n\n이 작업은 되돌릴 수 없습니다.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '백업 정보',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSummaryRow('백업 일시', dateFormat.format(summary.createdAt)),
              _buildSummaryRow('약물', '${summary.medicationCount}개'),
              _buildSummaryRow('복용 기록', '${summary.medicationLogCount}개'),
              _buildSummaryRow('치료 사이클', '${summary.cycleCount}개'),
              _buildSummaryRow('생리 기록', '${summary.periodRecordCount}개'),
              _buildSummaryRow('초음파 기록', '${summary.ultrasoundRecordCount}개'),
              _buildSummaryRow('임신 테스트', '${summary.pregnancyTestRecordCount}개'),
              _buildSummaryRow('몸 상태', '${summary.conditionRecordCount}개'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('복원', style: TextStyle(color: AppColors.primaryPurple)),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
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
                '2. "잠금 화면에 표시" 활성화',
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
