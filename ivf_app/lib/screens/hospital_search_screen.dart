import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../models/hospital.dart';
import '../services/hospital_service.dart';

/// 병원 검색 화면
class HospitalSearchScreen extends StatefulWidget {
  const HospitalSearchScreen({super.key});

  @override
  State<HospitalSearchScreen> createState() => _HospitalSearchScreenState();
}

class _HospitalSearchScreenState extends State<HospitalSearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<Hospital> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // 선택된 시도 필터
  SidoCode? _selectedSido;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();

    if (keyword.isEmpty && _selectedSido == null) {
      setState(() {
        _errorMessage = '병원명을 입력하거나 지역을 선택해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await HospitalService.searchHospitals(
        keyword: keyword.isNotEmpty ? keyword : null,
        sidoCd: _selectedSido?.code,
        numOfRows: 50,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '검색 중 오류가 발생했습니다';
        _isLoading = false;
      });
    }
  }

  void _selectHospital(Hospital hospital) {
    Navigator.pop(context, hospital);
  }

  void _showDirectInputDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('병원 직접 입력'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '병원명 *',
                  hintText: '예: OO여성병원',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  hintText: '예: 02-1234-5678',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '예: 서울시 강남구...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              final hospital = Hospital(
                name: name,
                address: addressController.text.trim(),
                phone: phoneController.text.trim(),
              );

              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(this.context, hospital); // 검색 화면 닫기
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
          '병원 선택',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색 영역
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              children: [
                // 검색 입력
                _buildSearchField(),
                const SizedBox(height: AppSpacing.s),

                // 지역 필터
                _buildSidoFilter(),
              ],
            ),
          ),

          // 검색 결과
          Expanded(
            child: _buildSearchResults(),
          ),

          // 직접 입력 버튼
          _buildDirectInputButton(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.m),
          const Icon(Icons.search, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '병원명으로 검색',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.textDisabled,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.m,
                ),
              ),
              style: AppTextStyles.body,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            child: ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
              ),
              child: const Text('검색'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidoFilter() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 전체 버튼
          _buildFilterChip(null, '전체'),
          const SizedBox(width: AppSpacing.xs),
          // 시도 버튼들
          ...SidoCode.all.map((sido) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _buildFilterChip(sido, sido.name),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(SidoCode? sido, String label) {
    final isSelected = _selectedSido?.code == sido?.code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSido = sido;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              _errorMessage!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppColors.primaryPurple.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              '병원명 또는 지역으로\n검색해보세요',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              '검색 결과가 없습니다',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '다른 검색어로 시도하거나\n직접 입력해주세요',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textDisabled,
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
        final hospital = _searchResults[index];
        return _buildHospitalItem(hospital);
      },
    );
  }

  Widget _buildHospitalItem(Hospital hospital) {
    return GestureDetector(
      onTap: () => _selectHospital(hospital),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryPurpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital,
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
                    hospital.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hospital.address,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectInputButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: GestureDetector(
          onTap: _showDirectInputDialog,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.edit,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  '원하는 병원이 없나요? 직접 입력하기',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
