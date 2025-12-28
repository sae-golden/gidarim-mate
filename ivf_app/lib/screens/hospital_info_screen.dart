import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../models/hospital.dart';
import '../services/hospital_service.dart';
import 'hospital_search_screen.dart';

/// 병원 정보 화면
class HospitalInfoScreen extends StatefulWidget {
  const HospitalInfoScreen({super.key});

  @override
  State<HospitalInfoScreen> createState() => _HospitalInfoScreenState();
}

class _HospitalInfoScreenState extends State<HospitalInfoScreen> {
  UserHospitalInfo? _userHospitalInfo;
  bool _isLoading = true;

  final _doctorController = TextEditingController();
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitalInfo() async {
    final info = await HospitalService.loadUserHospitalInfo();
    setState(() {
      _userHospitalInfo = info;
      _doctorController.text = info?.doctorName ?? '';
      _memoController.text = info?.memo ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveInfo() async {
    final newInfo = UserHospitalInfo(
      hospital: _userHospitalInfo?.hospital,
      doctorName: _doctorController.text.trim(),
      memo: _memoController.text.trim(),
    );

    await HospitalService.saveUserHospitalInfo(newInfo);

    setState(() {
      _userHospitalInfo = newInfo;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('저장되었습니다'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _selectHospital() async {
    final result = await Navigator.push<Hospital>(
      context,
      MaterialPageRoute(
        builder: (context) => const HospitalSearchScreen(),
      ),
    );

    if (result != null) {
      final newInfo = UserHospitalInfo(
        hospital: result,
        doctorName: _doctorController.text.trim(),
        memo: _memoController.text.trim(),
      );

      await HospitalService.saveUserHospitalInfo(newInfo);

      setState(() {
        _userHospitalInfo = newInfo;
      });
    }
  }

  Future<void> _callHospital() async {
    final phone = _userHospitalInfo?.hospital?.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('전화번호가 없습니다'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '병원 정보',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveInfo,
            child: Text(
              '저장',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 등록된 병원
                  _buildSectionTitle('🏥 등록된 병원'),
                  const SizedBox(height: AppSpacing.s),
                  _buildHospitalCard(),
                  const SizedBox(height: AppSpacing.l),

                  // 담당 선생님
                  _buildSectionTitle('👨‍⚕️ 담당 선생님'),
                  const SizedBox(height: AppSpacing.s),
                  _buildDoctorInput(),
                  const SizedBox(height: AppSpacing.l),

                  // 메모
                  _buildSectionTitle('📝 메모'),
                  const SizedBox(height: AppSpacing.s),
                  _buildMemoInput(),
                  const SizedBox(height: AppSpacing.xl),

                  // 전화하기 버튼
                  if (_userHospitalInfo?.hospital != null)
                    AppButton(
                      text: '📞 병원 전화하기',
                      onPressed: _callHospital,
                      type: AppButtonType.secondary,
                    ),
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
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    final hospital = _userHospitalInfo?.hospital;

    return AppCard(
      child: hospital != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospital.shortAddress,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (hospital.phone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              hospital.phone!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryPurple,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _selectHospital,
                      child: Text(
                        '변경하기',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : InkWell(
              onTap: _selectHospital,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      '병원을 선택해주세요',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDoctorInput() {
    return AppCard(
      child: TextField(
        controller: _doctorController,
        decoration: InputDecoration(
          hintText: '예: 김OO 교수님',
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.textDisabled,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.body,
      ),
    );
  }

  Widget _buildMemoInput() {
    return AppCard(
      child: TextField(
        controller: _memoController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: '예: 3층 생식의학센터, 예약 시 주의사항 등',
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.textDisabled,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppTextStyles.body,
      ),
    );
  }
}
