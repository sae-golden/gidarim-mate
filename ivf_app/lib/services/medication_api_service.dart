import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medication_info.dart';

/// 공공데이터포털 의약품 API 서비스
///
/// API 문서: https://www.data.go.kr/data/15075057/openapi.do
/// - e약은요 (의약품 개요정보)
class MedicationApiService {
  // 공공데이터포털 API 키 (일반 인증키)
  static const String _serviceKey = '9452f9e3e312293e084b9a4b34ca590f2acf7f4342eae5fafc2b02920d470a15';

  // API 엔드포인트
  static const String _baseUrl = 'https://apis.data.go.kr/1471000/DrbEasyDrugInfoService';

  /// 의약품 검색 (품목명으로 검색)
  ///
  /// [itemName] 검색할 의약품명
  /// [pageNo] 페이지 번호 (기본값: 1)
  /// [numOfRows] 한 페이지 결과 수 (기본값: 10)
  static Future<List<MedicationSearchResult>> searchMedications({
    required String itemName,
    int pageNo = 1,
    int numOfRows = 10,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/getDrbEasyDrugList').replace(
        queryParameters: {
          'serviceKey': _serviceKey,
          'itemName': itemName,
          'pageNo': pageNo.toString(),
          'numOfRows': numOfRows.toString(),
          'type': 'json',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['body']?['items'] as List?;

        if (items == null || items.isEmpty) {
          // API 결과 없으면 로컬 데이터 병합
          return _getLocalSearchResults(itemName);
        }

        // API 결과와 로컬 IVF 데이터 병합
        final apiResults = items
            .map((item) => MedicationSearchResult.fromJson(item as Map<String, dynamic>))
            .toList();

        // 로컬 IVF 약물도 검색 결과에 포함
        final localResults = _getLocalSearchResults(itemName);
        final combined = [...localResults, ...apiResults];

        // 중복 제거 (이름 기준)
        final seen = <String>{};
        return combined.where((med) => seen.add(med.itemName)).take(numOfRows).toList();
      } else {
        return _getLocalSearchResults(itemName);
      }
    } catch (e) {
      // API 호출 실패 시 로컬 데이터 반환
      return _getLocalSearchResults(itemName);
    }
  }

  /// 의약품 상세 정보 조회
  ///
  /// [itemSeq] 품목일련번호
  static Future<MedicationInfo?> getMedicationDetail(String itemSeq) async {
    // 로컬 IVF 데이터인 경우 (IVF로 시작)
    if (itemSeq.startsWith('IVF')) {
      return _getLocalMedicationDetail(itemSeq);
    }

    try {
      final uri = Uri.parse('$_baseUrl/getDrbEasyDrugList').replace(
        queryParameters: {
          'serviceKey': _serviceKey,
          'itemSeq': itemSeq,
          'type': 'json',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['body']?['items'] as List?;

        if (items == null || items.isEmpty) {
          return _getLocalMedicationDetail(itemSeq);
        }

        return MedicationInfo.fromJson(items.first as Map<String, dynamic>);
      } else {
        return _getLocalMedicationDetail(itemSeq);
      }
    } catch (e) {
      return _getLocalMedicationDetail(itemSeq);
    }
  }

  /// 로컬 IVF 관련 의약품 데이터베이스
  static final List<Map<String, dynamic>> _ivfMedications = [
    // 과배란 유도제
    {
      'itemSeq': 'IVF001',
      'itemName': '고날에프펜주 (폴리트로핀알파)',
      'entpName': '머크',
      'efcyQesitm': '난포 성장 촉진, 과배란 유도에 사용됩니다. 체외수정(IVF) 시술 시 다수의 난자를 채취하기 위해 사용합니다.',
      'useMethodQesitm': '피하주사로 투여합니다. 의사의 지시에 따라 월경 2-3일차부터 시작하여 8-12일간 매일 투여합니다. 용량은 개인별로 조절됩니다.',
      'atpnQesitm': '과배란 증후군(OHSS) 발생 가능성이 있으므로 정기적인 초음파 모니터링이 필요합니다. 다태임신 위험이 증가할 수 있습니다.',
      'seQesitm': '주사 부위 반응, 두통, 복부 팽만감, 기분 변화가 나타날 수 있습니다.',
      'depositMethodQesitm': '냉장보관(2-8°C). 얼리지 마세요.',
    },
    {
      'itemSeq': 'IVF002',
      'itemName': '퓨레곤펜주 (폴리트로핀베타)',
      'entpName': 'MSD',
      'efcyQesitm': '난포자극호르몬(FSH)으로 난포 발달을 촉진합니다. 과배란 유도 및 체외수정 시술에 사용됩니다.',
      'useMethodQesitm': '피하주사합니다. 용량과 기간은 난포 반응에 따라 개별 조절됩니다.',
      'atpnQesitm': '난소과자극증후군 주의. 다태임신 가능성 증가.',
      'seQesitm': '복부 불편감, 주사 부위 반응, 두통',
      'depositMethodQesitm': '냉장보관(2-8°C)',
    },
    {
      'itemSeq': 'IVF003',
      'itemName': '메노푸어주 (메노트로핀)',
      'entpName': '페링',
      'efcyQesitm': 'FSH와 LH를 함께 포함한 약물로 난포 성장을 촉진합니다.',
      'useMethodQesitm': '피하 또는 근육주사. 의사 지시에 따라 투여.',
      'atpnQesitm': 'OHSS 주의, 정기 모니터링 필요',
      'seQesitm': '주사 부위 통증, 복부 팽만',
      'depositMethodQesitm': '실온보관',
    },
    // GnRH 길항제
    {
      'itemSeq': 'IVF004',
      'itemName': '세트로타이드주 (세트로렐릭스)',
      'entpName': '머크',
      'efcyQesitm': 'GnRH 길항제로 조기 배란을 방지합니다. 과배란 유도 중 LH 급등을 억제합니다.',
      'useMethodQesitm': '피하주사. 과배란 유도 5-6일차부터 시작하여 hCG 투여일까지 매일 투여합니다.',
      'atpnQesitm': '과민반응 주의',
      'seQesitm': '주사 부위 반응, 두통, 메스꺼움',
      'depositMethodQesitm': '냉장보관(2-8°C)',
    },
    {
      'itemSeq': 'IVF005',
      'itemName': '오가루트란주 (가니렐릭스)',
      'entpName': 'MSD',
      'efcyQesitm': 'GnRH 길항제. 체외수정 시 조기 배란 방지에 사용됩니다.',
      'useMethodQesitm': '피하주사. 난포자극 치료 5-6일차부터 hCG 투여일까지.',
      'atpnQesitm': '과민반응 주의',
      'seQesitm': '복부 불편감, 두통',
      'depositMethodQesitm': '냉장보관',
    },
    // 배란 유도제
    {
      'itemSeq': 'IVF006',
      'itemName': '오비드렐프리필드주 (코리오고나도트로핀알파)',
      'entpName': '머크',
      'efcyQesitm': '재조합 hCG로 최종 난포 성숙과 배란을 유도합니다. 난자 채취 전 트리거 주사로 사용됩니다.',
      'useMethodQesitm': '피하주사. 난포가 충분히 성숙하면 1회 투여. 투여 후 34-36시간 후 난자 채취.',
      'atpnQesitm': 'OHSS 고위험군 주의',
      'seQesitm': '주사 부위 반응, 복부 불편감',
      'depositMethodQesitm': '냉장보관(2-8°C)',
    },
    {
      'itemSeq': 'IVF007',
      'itemName': '루크린데포주 (류프로렐린)',
      'entpName': '애보트',
      'efcyQesitm': 'GnRH 작용제. 장기 프로토콜에서 뇌하수체 억제에 사용됩니다.',
      'useMethodQesitm': '피하 또는 근육주사. 보통 월경 21일차에 시작.',
      'atpnQesitm': '골밀도 감소 가능성',
      'seQesitm': '안면홍조, 두통, 질 건조',
      'depositMethodQesitm': '냉장보관',
    },
    // 황체기 보조
    {
      'itemSeq': 'IVF008',
      'itemName': '크리논겔 (프로게스테론)',
      'entpName': '머크',
      'efcyQesitm': '질정 프로게스테론. 황체기 보조 및 착상 지원에 사용됩니다. 임신 초기 유지에 도움을 줍니다.',
      'useMethodQesitm': '질 내 삽입. 배아이식일부터 시작하여 임신 10-12주까지 매일 사용.',
      'atpnQesitm': '땅콩 알레르기 환자 주의',
      'seQesitm': '질 불편감, 분비물',
      'depositMethodQesitm': '실온보관(25°C 이하)',
    },
    {
      'itemSeq': 'IVF009',
      'itemName': '유트로게스탄연질캡슐 (프로게스테론)',
      'entpName': '베셍스',
      'efcyQesitm': '천연 프로게스테론. 황체기 보조에 사용됩니다.',
      'useMethodQesitm': '경구 또는 질 내 투여. 의사 지시에 따름.',
      'atpnQesitm': '간 기능 이상 환자 주의',
      'seQesitm': '졸음, 두통, 유방 통증',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF010',
      'itemName': '프로게스테론주 (프로게스테론)',
      'entpName': '다양',
      'efcyQesitm': '주사용 프로게스테론. 황체기 보조에 사용됩니다.',
      'useMethodQesitm': '근육주사. 매일 또는 격일로 투여.',
      'atpnQesitm': '주사 부위 통증 가능',
      'seQesitm': '주사 부위 통증, 멍',
      'depositMethodQesitm': '실온보관',
    },
    // 보조 약물
    {
      'itemSeq': 'IVF011',
      'itemName': '아스피린프로텍트정 (아스피린)',
      'entpName': '바이엘',
      'efcyQesitm': '저용량 아스피린. 자궁내막 혈류 개선 및 착상률 향상에 도움을 줄 수 있습니다.',
      'useMethodQesitm': '1일 1회 100mg 복용. 보통 시술 시작 시부터 복용.',
      'atpnQesitm': '출혈 위험 증가. 아스피린 과민증 환자 금기.',
      'seQesitm': '위장 장애, 출혈 경향',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF012',
      'itemName': '엽산정 (엽산)',
      'entpName': '다양',
      'efcyQesitm': '태아 신경관 결손 예방. 임신 준비 및 초기에 필수적입니다.',
      'useMethodQesitm': '1일 1회 400-800mcg 복용. 임신 3개월 전부터 복용 시작 권장.',
      'atpnQesitm': '비타민 B12 결핍 마스킹 가능',
      'seQesitm': '거의 없음',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF013',
      'itemName': '메트포르민정 (메트포르민)',
      'entpName': '다양',
      'efcyQesitm': '다낭성 난소 증후군(PCOS) 환자에서 배란 개선에 도움을 줄 수 있습니다.',
      'useMethodQesitm': '식사와 함께 복용. 저용량부터 시작하여 점진적 증량.',
      'atpnQesitm': '신장 기능 장애 환자 주의. 시술 전 일시 중단 필요할 수 있음.',
      'seQesitm': '위장 장애, 메스꺼움, 설사',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF014',
      'itemName': '에스트라디올정 (에스트라디올)',
      'entpName': '다양',
      'efcyQesitm': '자궁내막 성장 촉진. 동결배아 이식 주기에서 사용됩니다.',
      'useMethodQesitm': '경구 또는 패치/질정. 의사 지시에 따름.',
      'atpnQesitm': '혈전 위험 증가',
      'seQesitm': '유방 통증, 두통, 기분 변화',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF015',
      'itemName': '클로미펜정 (클로미펜)',
      'entpName': '다양',
      'efcyQesitm': '배란 유도제. 경구 복용으로 배란을 유도합니다.',
      'useMethodQesitm': '월경 3-5일차부터 5일간 복용. 1일 50-150mg.',
      'atpnQesitm': '다태임신 위험. 장기 사용 시 자궁내막 얇아질 수 있음.',
      'seQesitm': '안면홍조, 시각 장애, 복부 팽만',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF016',
      'itemName': '레트로졸정 (레트로졸)',
      'entpName': '노바티스',
      'efcyQesitm': '아로마타제 억제제. 배란 유도에 오프라벨로 사용됩니다.',
      'useMethodQesitm': '월경 3-5일차부터 5일간 복용. 1일 2.5-7.5mg.',
      'atpnQesitm': '골밀도 감소 가능',
      'seQesitm': '두통, 안면홍조, 관절통',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF017',
      'itemName': '덱사메타손정 (덱사메타손)',
      'entpName': '다양',
      'efcyQesitm': '스테로이드. 면역 조절 목적으로 착상 보조에 사용될 수 있습니다.',
      'useMethodQesitm': '저용량으로 의사 지시에 따라 복용.',
      'atpnQesitm': '장기 사용 시 부작용 주의',
      'seQesitm': '불면, 식욕 증가, 혈당 상승',
      'depositMethodQesitm': '실온보관',
    },
    {
      'itemSeq': 'IVF018',
      'itemName': '헤파린주 (헤파린)',
      'entpName': '다양',
      'efcyQesitm': '항응고제. 반복 착상 실패나 항인지질항체증후군에서 사용될 수 있습니다.',
      'useMethodQesitm': '피하주사. 용량과 기간은 개별화.',
      'atpnQesitm': '출혈 위험',
      'seQesitm': '주사 부위 멍, 출혈',
      'depositMethodQesitm': '실온보관',
    },
  ];

  /// 로컬 검색 결과 반환
  static List<MedicationSearchResult> _getLocalSearchResults(String query) {
    final lowerQuery = query.toLowerCase();

    return _ivfMedications
        .where((med) =>
            med['itemName'].toString().toLowerCase().contains(lowerQuery) ||
            med['entpName'].toString().toLowerCase().contains(lowerQuery))
        .map((med) => MedicationSearchResult(
              itemSeq: med['itemSeq'] as String,
              itemName: med['itemName'] as String,
              entpName: med['entpName'] as String,
            ))
        .toList();
  }

  /// 로컬 상세 정보 반환
  static MedicationInfo? _getLocalMedicationDetail(String itemSeq) {
    final med = _ivfMedications.firstWhere(
      (m) => m['itemSeq'] == itemSeq,
      orElse: () => {},
    );

    if (med.isEmpty) return null;

    return MedicationInfo(
      itemSeq: med['itemSeq'] as String,
      itemName: med['itemName'] as String,
      entpName: med['entpName'] as String,
      efcyQesitm: med['efcyQesitm'] as String?,
      useMethodQesitm: med['useMethodQesitm'] as String?,
      atpnQesitm: med['atpnQesitm'] as String?,
      seQesitm: med['seQesitm'] as String?,
      depositMethodQesitm: med['depositMethodQesitm'] as String?,
    );
  }

  /// IVF 관련 추천 약물 목록
  static List<MedicationSearchResult> getIvfRecommendedMedications() {
    return _ivfMedications
        .map((med) => MedicationSearchResult(
              itemSeq: med['itemSeq'] as String,
              itemName: med['itemName'] as String,
              entpName: med['entpName'] as String,
            ))
        .toList();
  }

  /// 카테고리별 약물 목록
  static Map<String, List<MedicationSearchResult>> getIvfMedicationsByCategory() {
    return {
      '과배란 유도제': _ivfMedications
          .where((m) => ['IVF001', 'IVF002', 'IVF003'].contains(m['itemSeq']))
          .map((m) => MedicationSearchResult(
                itemSeq: m['itemSeq'] as String,
                itemName: m['itemName'] as String,
                entpName: m['entpName'] as String,
              ))
          .toList(),
      'GnRH 길항제': _ivfMedications
          .where((m) => ['IVF004', 'IVF005'].contains(m['itemSeq']))
          .map((m) => MedicationSearchResult(
                itemSeq: m['itemSeq'] as String,
                itemName: m['itemName'] as String,
                entpName: m['entpName'] as String,
              ))
          .toList(),
      '배란 유도/트리거': _ivfMedications
          .where((m) => ['IVF006', 'IVF007'].contains(m['itemSeq']))
          .map((m) => MedicationSearchResult(
                itemSeq: m['itemSeq'] as String,
                itemName: m['itemName'] as String,
                entpName: m['entpName'] as String,
              ))
          .toList(),
      '황체기 보조': _ivfMedications
          .where((m) => ['IVF008', 'IVF009', 'IVF010'].contains(m['itemSeq']))
          .map((m) => MedicationSearchResult(
                itemSeq: m['itemSeq'] as String,
                itemName: m['itemName'] as String,
                entpName: m['entpName'] as String,
              ))
          .toList(),
      '보조 약물': _ivfMedications
          .where((m) => ['IVF011', 'IVF012', 'IVF013', 'IVF014', 'IVF015', 'IVF016', 'IVF017', 'IVF018']
              .contains(m['itemSeq']))
          .map((m) => MedicationSearchResult(
                itemSeq: m['itemSeq'] as String,
                itemName: m['itemName'] as String,
                entpName: m['entpName'] as String,
              ))
          .toList(),
    };
  }
}
