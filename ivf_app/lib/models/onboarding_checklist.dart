/// 온보딩 체크리스트 모델
class OnboardingChecklist {
  final bool isHospitalRegistered; // 병원 등록 여부
  final bool isNotificationEnabled; // 알림 ON 여부
  final bool hasMedication; // 약 등록 여부
  final bool hasTreatmentStage; // 치료 단계 설정 여부

  OnboardingChecklist({
    this.isHospitalRegistered = false,
    this.isNotificationEnabled = false,
    this.hasMedication = false,
    this.hasTreatmentStage = false,
  });

  /// 모든 항목 완료 여부
  bool get isAllCompleted =>
      isHospitalRegistered &&
      isNotificationEnabled &&
      hasMedication &&
      hasTreatmentStage;

  /// 완료된 항목 수
  int get completedCount {
    int count = 0;
    if (isHospitalRegistered) count++;
    if (isNotificationEnabled) count++;
    if (hasMedication) count++;
    if (hasTreatmentStage) count++;
    return count;
  }

  /// 전체 항목 수
  int get totalCount => 4;

  /// 미완료 항목 목록
  List<ChecklistItem> get incompleteItems {
    List<ChecklistItem> items = [];
    if (!isHospitalRegistered) items.add(ChecklistItem.hospital);
    if (!isNotificationEnabled) items.add(ChecklistItem.notification);
    if (!hasMedication) items.add(ChecklistItem.medication);
    if (!hasTreatmentStage) items.add(ChecklistItem.treatmentStage);
    return items;
  }

  OnboardingChecklist copyWith({
    bool? isHospitalRegistered,
    bool? isNotificationEnabled,
    bool? hasMedication,
    bool? hasTreatmentStage,
  }) {
    return OnboardingChecklist(
      isHospitalRegistered: isHospitalRegistered ?? this.isHospitalRegistered,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      hasMedication: hasMedication ?? this.hasMedication,
      hasTreatmentStage: hasTreatmentStage ?? this.hasTreatmentStage,
    );
  }
}

/// 체크리스트 항목
enum ChecklistItem {
  hospital, // 병원 등록
  notification, // 알림 켜기
  medication, // 약 등록
  treatmentStage, // 치료 단계
}

/// 체크리스트 항목 확장
extension ChecklistItemExtension on ChecklistItem {
  String get emoji {
    switch (this) {
      case ChecklistItem.hospital:
        return '🏥';
      case ChecklistItem.notification:
        return '🔔';
      case ChecklistItem.medication:
        return '💊';
      case ChecklistItem.treatmentStage:
        return '📋';
    }
  }

  String get title {
    switch (this) {
      case ChecklistItem.hospital:
        return '병원 등록하기';
      case ChecklistItem.notification:
        return '알림 켜기';
      case ChecklistItem.medication:
        return '첫 약 등록하기';
      case ChecklistItem.treatmentStage:
        return '치료 단계 등록하기';
    }
  }

  String get subtitle {
    switch (this) {
      case ChecklistItem.hospital:
        return '담당 병원 정보를 등록해요';
      case ChecklistItem.notification:
        return '복용 시간을 알려드려요';
      case ChecklistItem.medication:
        return '복용 중인 약을 추가해요';
      case ChecklistItem.treatmentStage:
        return '현재 치료 단계를 선택해요';
    }
  }
}

/// 온보딩용 치료 단계 (간소화)
enum OnboardingTreatmentStage {
  notStarted, // 아직 시작 전
  ovulation, // 과배란 주사 중
  waitingTransfer, // 채취 완료, 이식 대기
  waitingResult, // 이식 완료, 판정 대기
}

extension OnboardingTreatmentStageExtension on OnboardingTreatmentStage {
  String get emoji {
    switch (this) {
      case OnboardingTreatmentStage.notStarted:
        return '🌱';
      case OnboardingTreatmentStage.ovulation:
        return '💉';
      case OnboardingTreatmentStage.waitingTransfer:
        return '🥚';
      case OnboardingTreatmentStage.waitingResult:
        return '🎯';
    }
  }

  String get title {
    switch (this) {
      case OnboardingTreatmentStage.notStarted:
        return '아직 시작 전이에요';
      case OnboardingTreatmentStage.ovulation:
        return '과배란 주사 중이에요';
      case OnboardingTreatmentStage.waitingTransfer:
        return '채취 완료, 이식 대기 중이에요';
      case OnboardingTreatmentStage.waitingResult:
        return '이식 완료, 판정 기다리는 중이에요';
    }
  }

  String get shortTitle {
    switch (this) {
      case OnboardingTreatmentStage.notStarted:
        return '시작 전';
      case OnboardingTreatmentStage.ovulation:
        return '과배란';
      case OnboardingTreatmentStage.waitingTransfer:
        return '이식 대기';
      case OnboardingTreatmentStage.waitingResult:
        return '판정 대기';
    }
  }
}
