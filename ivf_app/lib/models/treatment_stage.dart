/// IVF 치료 단계 (5단계 - 사용자 행동 중심)
enum TreatmentStage {
  stimulation, // 과배란 (주사 맞기)
  retrieval, // 채취 (시술 받기)
  waiting, // 이식 대기 (결과 기다리기) - 병원 결과 입력
  transfer, // 이식 (시술 받기)
  result, // 판정 (결과 확인)
}

/// 치료 단계 정보
class TreatmentStageInfo {
  final TreatmentStage stage;
  final String title;
  final String titleEn;
  final String emoji;
  final String description;

  const TreatmentStageInfo({
    required this.stage,
    required this.title,
    required this.titleEn,
    required this.emoji,
    required this.description,
  });

  static const Map<TreatmentStage, TreatmentStageInfo> stageInfo = {
    TreatmentStage.stimulation: TreatmentStageInfo(
      stage: TreatmentStage.stimulation,
      title: '과배란',
      titleEn: 'Stimulation',
      emoji: '💉',
      description: '주사 맞기',
    ),
    TreatmentStage.retrieval: TreatmentStageInfo(
      stage: TreatmentStage.retrieval,
      title: '채취',
      titleEn: 'Retrieval',
      emoji: '🥚',
      description: '시술 받기',
    ),
    TreatmentStage.waiting: TreatmentStageInfo(
      stage: TreatmentStage.waiting,
      title: '이식 대기',
      titleEn: 'Waiting',
      emoji: '📞',
      description: '결과 기다리기',
    ),
    TreatmentStage.transfer: TreatmentStageInfo(
      stage: TreatmentStage.transfer,
      title: '이식',
      titleEn: 'Transfer',
      emoji: '🎯',
      description: '시술 받기',
    ),
    TreatmentStage.result: TreatmentStageInfo(
      stage: TreatmentStage.result,
      title: '판정',
      titleEn: 'Result',
      emoji: '🤰',
      description: '결과 확인',
    ),
  };
}

/// 병원 결과 타입
enum LabResultType {
  fertilization, // 수정 결과
  day3, // Day 3 배아
  day5, // Day 5 배반포
  frozen, // 동결
  other, // 기타
}

extension LabResultTypeExtension on LabResultType {
  String get displayName {
    switch (this) {
      case LabResultType.fertilization:
        return '수정 결과';
      case LabResultType.day3:
        return 'Day 3 배아';
      case LabResultType.day5:
        return 'Day 5 배반포';
      case LabResultType.frozen:
        return '동결';
      case LabResultType.other:
        return '기타';
    }
  }

  String get emoji {
    switch (this) {
      case LabResultType.fertilization:
        return '🔬';
      case LabResultType.day3:
        return '🧫';
      case LabResultType.day5:
        return '🌟';
      case LabResultType.frozen:
        return '❄️';
      case LabResultType.other:
        return '📝';
    }
  }
}
