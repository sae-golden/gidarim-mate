/// 의약품 정보 모델 (공공데이터포털 API 기반)
class MedicationInfo {
  final String itemSeq; // 품목일련번호
  final String itemName; // 품목명
  final String entpName; // 업체명
  final String? efcyQesitm; // 효능
  final String? useMethodQesitm; // 용법
  final String? atpnWarnQesitm; // 주의사항 경고
  final String? atpnQesitm; // 주의사항
  final String? intrcQesitm; // 상호작용
  final String? seQesitm; // 부작용
  final String? depositMethodQesitm; // 보관법
  final String? itemImage; // 이미지 URL

  MedicationInfo({
    required this.itemSeq,
    required this.itemName,
    required this.entpName,
    this.efcyQesitm,
    this.useMethodQesitm,
    this.atpnWarnQesitm,
    this.atpnQesitm,
    this.intrcQesitm,
    this.seQesitm,
    this.depositMethodQesitm,
    this.itemImage,
  });

  factory MedicationInfo.fromXml(Map<String, String> xml) {
    return MedicationInfo(
      itemSeq: xml['itemSeq'] ?? '',
      itemName: xml['itemName'] ?? '',
      entpName: xml['entpName'] ?? '',
      efcyQesitm: xml['efcyQesitm'],
      useMethodQesitm: xml['useMethodQesitm'],
      atpnWarnQesitm: xml['atpnWarnQesitm'],
      atpnQesitm: xml['atpnQesitm'],
      intrcQesitm: xml['intrcQesitm'],
      seQesitm: xml['seQesitm'],
      depositMethodQesitm: xml['depositMethodQesitm'],
      itemImage: xml['itemImage'],
    );
  }

  factory MedicationInfo.fromJson(Map<String, dynamic> json) {
    return MedicationInfo(
      itemSeq: json['itemSeq']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      entpName: json['entpName']?.toString() ?? '',
      efcyQesitm: json['efcyQesitm']?.toString(),
      useMethodQesitm: json['useMethodQesitm']?.toString(),
      atpnWarnQesitm: json['atpnWarnQesitm']?.toString(),
      atpnQesitm: json['atpnQesitm']?.toString(),
      intrcQesitm: json['intrcQesitm']?.toString(),
      seQesitm: json['seQesitm']?.toString(),
      depositMethodQesitm: json['depositMethodQesitm']?.toString(),
      itemImage: json['itemImage']?.toString(),
    );
  }

  /// HTML 태그 제거
  static String? cleanHtml(String? text) {
    if (text == null || text.isEmpty) return null;
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .trim();
  }

  String get cleanEfcy => cleanHtml(efcyQesitm) ?? '정보 없음';
  String get cleanUseMethod => cleanHtml(useMethodQesitm) ?? '정보 없음';
  String get cleanAtpnWarn => cleanHtml(atpnWarnQesitm) ?? '';
  String get cleanAtpn => cleanHtml(atpnQesitm) ?? '정보 없음';
  String get cleanIntrc => cleanHtml(intrcQesitm) ?? '정보 없음';
  String get cleanSe => cleanHtml(seQesitm) ?? '정보 없음';
  String get cleanDepositMethod => cleanHtml(depositMethodQesitm) ?? '정보 없음';
}

/// 의약품 검색 결과 (간략 정보)
class MedicationSearchResult {
  final String itemSeq;
  final String itemName;
  final String entpName;
  final String? itemImage;

  MedicationSearchResult({
    required this.itemSeq,
    required this.itemName,
    required this.entpName,
    this.itemImage,
  });

  factory MedicationSearchResult.fromXml(Map<String, String> xml) {
    return MedicationSearchResult(
      itemSeq: xml['itemSeq'] ?? '',
      itemName: xml['itemName'] ?? '',
      entpName: xml['entpName'] ?? '',
      itemImage: xml['itemImage'],
    );
  }

  factory MedicationSearchResult.fromJson(Map<String, dynamic> json) {
    return MedicationSearchResult(
      itemSeq: json['itemSeq']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      entpName: json['entpName']?.toString() ?? '',
      itemImage: json['itemImage']?.toString(),
    );
  }
}
