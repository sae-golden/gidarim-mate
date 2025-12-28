import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../models/treatment_stage.dart';

/// 메인 대시보드 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 현재 단계 (임시 데이터)
  final TreatmentStage currentStage = TreatmentStage.stimulation;
  final int daysRemaining = 5;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 단계 카드
              _buildCurrentStageCard(),
              
              const SizedBox(height: AppSpacing.s),
              
              // 오늘의 할 일
              _buildTodayTasksCard(),
              
              const SizedBox(height: AppSpacing.s),
              
              // 진행 상황
              _buildProgressCard(),
              
              const SizedBox(height: AppSpacing.s),
              
              // 단계별 흐름
              _buildStageFlowCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  /// 현재 단계 카드
  Widget _buildCurrentStageCard() {
    final stageInfo = TreatmentStageInfo.stageInfo[currentStage]!;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📍 현재 단계',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${stageInfo.title} (${stageInfo.titleEn})',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'D-$daysRemaining ($daysRemaining일 남음)',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  /// 오늘의 할 일 카드
  Widget _buildTodayTasksCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 20)),
              SizedBox(width: AppSpacing.xs),
              Text('오늘의 할 일', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          
          // 약물 항목들
          _buildMedicationItem(
            time: '아침 7:00',
            name: '아스피린',
            isCompleted: true,
          ),
          const SizedBox(height: AppSpacing.s),
          _buildMedicationItem(
            time: '아침 8:00',
            name: 'FSH 주사',
            isInjection: true,
            isCompleted: false,
          ),
          const SizedBox(height: AppSpacing.s),
          _buildMedicationItem(
            time: '저녁 8:00',
            name: '메트포르민',
            isCompleted: false,
          ),
        ],
      ),
    );
  }
  
  /// 약물 항목
  Widget _buildMedicationItem({
    required String time,
    required String name,
    bool isInjection = false,
    bool isCompleted = false,
  }) {
    return Row(
      children: [
        // 완료 표시
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.primaryPurple : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        
        // 시간 및 약물명
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: AppTextStyles.caption),
              Text(name, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
        
        // 완료 버튼
        AppButton(
          text: isInjection ? '완료 → 위치 입력' : '완료',
          onPressed: () {
            // TODO: 완료 처리
          },
          width: isInjection ? 140 : 80,
          height: 36,
        ),
      ],
    );
  }
  
  /// 진행 상황 카드
  Widget _buildProgressCard() {
    const completed = 42;
    const total = 65;
    const percentage = completed / total;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 20)),
              SizedBox(width: AppSpacing.xs),
              Text('진행 상황', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            '총 $total회 중 $completed회 완료',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.s),
          
          // 진행률 바
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(percentage * 100).toInt()}% 완료',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 단계별 흐름 카드
  Widget _buildStageFlowCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📅', style: TextStyle(fontSize: 20)),
              SizedBox(width: AppSpacing.xs),
              Text('단계별 흐름', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          
          _buildStageFlowItem(
            stage: TreatmentStage.stimulation,
            isActive: true,
            subtitle: 'D-5',
          ),
          _buildStageFlowItem(
            stage: TreatmentStage.retrieval,
            subtitle: 'D-Day',
          ),
          _buildStageFlowItem(
            stage: TreatmentStage.transfer,
            subtitle: 'D+3~5',
            isLast: true,
          ),
        ],
      ),
    );
  }
  
  /// 단계 흐름 항목
  Widget _buildStageFlowItem({
    required TreatmentStage stage,
    bool isActive = false,
    String? subtitle,
    bool isLast = false,
  }) {
    final stageInfo = TreatmentStageInfo.stageInfo[stage]!;
    
    return Column(
      children: [
        Row(
          children: [
            // 체크 아이콘
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryPurple
                    : AppColors.textDisabled,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            
            // 단계 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stageInfo.title} (${stageInfo.titleEn})',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
        
        // 연결선
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 16),
            width: 2,
            height: 24,
            color: AppColors.border,
          ),
      ],
    );
  }
  
  /// 하단 네비게이션 바
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, '홈', isActive: true),
          _buildNavItem(Icons.calendar_today, '캘린더'),
          _buildNavItem(Icons.bar_chart, '치료 기록'),
          _buildNavItem(Icons.settings, '설정'),
        ],
      ),
    );
  }
  
  /// 네비게이션 항목
  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primaryPurple : AppColors.textDisabled,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isActive ? AppColors.primaryPurple : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}
