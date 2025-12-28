import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../services/medication_api_service.dart';
import '../models/medication_info.dart';
import 'medication_detail_screen.dart';

/// 약물 검색 화면 (자동완성 지원)
class MedicationSearchScreen extends StatefulWidget {
  /// true면 선택한 약물을 반환, false면 상세화면으로 이동
  final bool selectMode;

  const MedicationSearchScreen({
    super.key,
    this.selectMode = false,
  });

  @override
  State<MedicationSearchScreen> createState() => _MedicationSearchScreenState();
}

class _MedicationSearchScreenState extends State<MedicationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MedicationSearchResult> _searchResults = [];
  Map<String, List<MedicationSearchResult>> _categoryMedications = {};
  bool _isLoading = false;
  bool _showCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    _categoryMedications = MedicationApiService.getIvfMedicationsByCategory();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showCategories = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showCategories = false;
    });

    try {
      final results = await MedicationApiService.searchMedications(
        itemName: query,
      );
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onMedicationTap(MedicationSearchResult medication) {
    if (widget.selectMode) {
      Navigator.pop(context, medication);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MedicationDetailScreen(
            itemSeq: medication.itemSeq,
            itemName: medication.itemName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true, // 키보드 출력 시 화면 자동 조절
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.selectMode ? '약물 선택' : '약물 검색',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: '약물명을 입력하세요',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryPurple,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // 결과 영역
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  )
                : _showCategories
                    ? _buildCategoryList()
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      children: [
        Text(
          'IVF 관련 약물',
          style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          '카테고리별로 분류된 시험관 시술 관련 약물입니다',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.m),
        ..._categoryMedications.entries.map((entry) {
          return _buildCategorySection(entry.key, entry.value);
        }),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildCategorySection(
      String category, List<MedicationSearchResult> medications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                category,
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...medications.map((med) => _buildMedicationTile(med)),
        const SizedBox(height: AppSpacing.m),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '과배란 유도제':
        return AppColors.primaryPurple;
      case 'GnRH 길항제':
        return AppColors.info;
      case '배란 유도/트리거':
        return AppColors.success;
      case '황체기 보조':
        return AppColors.warning;
      case '보조 약물':
        return AppColors.textSecondary;
      default:
        return AppColors.primaryPurple;
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              '검색 결과가 없습니다',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              '다른 검색어를 입력해보세요',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildMedicationTile(_searchResults[index]);
      },
    );
  }

  Widget _buildMedicationTile(MedicationSearchResult medication) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        onTap: () => _onMedicationTap(medication),
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
                Icons.medication,
                color: AppColors.primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.itemName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    medication.entpName,
                    style: AppTextStyles.caption.copyWith(
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
}
