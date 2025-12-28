/// IVF 치료 단계
enum TreatmentStage {
  stimulation, // 채취 전 (난소 자극)
  retrieval, // 채취
  fertilization, // 수정
  culture, // 배양
  beforeTransfer, // 이식 전
  transfer, // 이식
  postTransfer, // 이식 후
}

/// 치료 단계 정보
class TreatmentStageInfo {
  final TreatmentStage stage;
  final String title;
  final String titleEn;
  
  const TreatmentStageInfo({
    required this.stage,
    required this.title,
    required this.titleEn,
  });
  
  static const Map<TreatmentStage, TreatmentStageInfo> stageInfo = {
    TreatmentStage.stimulation: TreatmentStageInfo(
      stage: TreatmentStage.stimulation,
      title: '채취 전',
      titleEn: 'Stimulation',
    ),
    TreatmentStage.retrieval: TreatmentStageInfo(
      stage: TreatmentStage.retrieval,
      title: '채취',
      titleEn: 'Retrieval',
    ),
    TreatmentStage.fertilization: TreatmentStageInfo(
      stage: TreatmentStage.fertilization,
      title: '수정',
      titleEn: 'Fertilization',
    ),
    TreatmentStage.culture: TreatmentStageInfo(
      stage: TreatmentStage.culture,
      title: '배양',
      titleEn: 'Culture',
    ),
    TreatmentStage.beforeTransfer: TreatmentStageInfo(
      stage: TreatmentStage.beforeTransfer,
      title: '이식 전',
      titleEn: 'Before Transfer',
    ),
    TreatmentStage.transfer: TreatmentStageInfo(
      stage: TreatmentStage.transfer,
      title: '이식',
      titleEn: 'Transfer',
    ),
    TreatmentStage.postTransfer: TreatmentStageInfo(
      stage: TreatmentStage.postTransfer,
      title: '이식 후',
      titleEn: 'Post Transfer',
    ),
  };
}

/// 치료 기록
class TreatmentRecord {
  final String id;
  final TreatmentStage stage;
  final DateTime? date;
  final Map<String, dynamic>? data; // 단계별 상세 데이터
  final String? memo;
  
  TreatmentRecord({
    required this.id,
    required this.stage,
    this.date,
    this.data,
    this.memo,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stage': stage.toString(),
      'date': date?.toIso8601String(),
      'data': data,
      'memo': memo,
    };
  }
  
  factory TreatmentRecord.fromJson(Map<String, dynamic> json) {
    return TreatmentRecord(
      id: json['id'],
      stage: TreatmentStage.values.firstWhere(
        (e) => e.toString() == json['stage'],
      ),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      data: json['data'],
      memo: json['memo'],
    );
  }
}
