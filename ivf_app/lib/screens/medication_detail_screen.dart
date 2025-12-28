import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../services/medication_api_service.dart';
import '../models/medication_info.dart';

/// 약물 상세 정보 화면
class MedicationDetailScreen extends StatefulWidget {
  final String itemSeq;
  final String itemName;

  const MedicationDetailScreen({
    super.key,
    required this.itemSeq,
    required this.itemName,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  MedicationInfo? _medicationInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicationDetail();
  }

  Future<void> _loadMedicationDetail() async {
    try {
      final info = await MedicationApiService.getMedicationDetail(widget.itemSeq);
      if (mounted) {
        setState(() {
          _medicationInfo = info;
          _isLoading = false;
          if (info == null) {
            _error = '약물 정보를 찾을 수 없습니다';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '정보를 불러오는 중 오류가 발생했습니다';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 앱바
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primaryPurple,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.itemName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              titlePadding: const EdgeInsets.only(
                left: 56,
                right: 16,
                bottom: 16,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.primaryPurpleDark,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medication,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),

          // 컨텐츠
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                  )
                : _error != null
                    ? _buildErrorView()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              _error!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final info = _medicationInfo!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제조사 정보
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '제조/수입사',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      info.entpName,
                      style: AppTextStyles.bodyBold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // 효능효과
          _buildInfoSection(
            icon: Icons.healing,
            title: '효능효과',
            content: info.cleanEfcy,
            color: AppColors.success,
          ),

          // 용법용량
          _buildInfoSection(
            icon: Icons.schedule,
            title: '용법용량',
            content: info.cleanUseMethod,
            color: AppColors.info,
          ),

          // 주의사항
          if (info.cleanAtpnWarn.isNotEmpty)
            _buildInfoSection(
              icon: Icons.warning_amber,
              title: '경고',
              content: info.cleanAtpnWarn,
              color: AppColors.error,
              isWarning: true,
            ),

          _buildInfoSection(
            icon: Icons.info_outline,
            title: '주의사항',
            content: info.cleanAtpn,
            color: AppColors.warning,
          ),

          // 부작용
          _buildInfoSection(
            icon: Icons.report_problem_outlined,
            title: '부작용',
            content: info.cleanSe,
            color: AppColors.error,
          ),

          // 상호작용
          _buildInfoSection(
            icon: Icons.sync_alt,
            title: '상호작용',
            content: info.cleanIntrc,
            color: AppColors.primaryPurple,
          ),

          // 보관법
          _buildInfoSection(
            icon: Icons.inventory_2,
            title: '보관법',
            content: info.cleanDepositMethod,
            color: AppColors.textSecondary,
          ),

          const SizedBox(height: AppSpacing.xl),

          // 면책 조항
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withAlpha(50),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    '이 정보는 참고용이며 의료 전문가의 처방과 상담을 대신할 수 없습니다. '
                    '정확한 복용법은 담당 의료진에게 문의하세요.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    bool isWarning = false,
  }) {
    if (content.isEmpty || content == '정보 없음') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isWarning ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: isWarning
                    ? AppColors.error.withAlpha(13)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content,
                style: AppTextStyles.body.copyWith(
                  height: 1.6,
                  color: isWarning
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
