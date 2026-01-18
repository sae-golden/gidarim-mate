/// IVF 약물 음성인식 보정 및 매칭 서비스
///
/// 음성인식 결과를 IVF 약물 사전과 매칭하여 오타/오인식 보정
class IvfMedicationMatcher {
  /// IVF 자주 사용 약물 사전 (50개+)
  /// key: 정식 약물명, value: 음성인식 가능한 변형들
  static final Map<String, IvfMedicationData> _medicationDictionary = {
    // =========================================================================
    // 과배란 유도제 (FSH/hMG)
    // =========================================================================
    '고날에프': IvfMedicationData(
      name: '고날에프',
      aliases: ['고날에프', '고날', '고나레프', '고날레프', '고나에프', '고날f', '고날 에프'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사 (폴리트로핀 알파)',
    ),
    '퓨레곤': IvfMedicationData(
      name: '퓨레곤',
      aliases: ['퓨레곤', '퓨레건', '퓨래곤', '퓨레콘', '푸레곤', '퓨레곤펜'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사 (폴리트로핀 베타)',
    ),
    '크녹산': IvfMedicationData(
      name: '크녹산',
      aliases: ['크녹산', '큰옥산', '큰 옥산', '크녹상', '크녀산', '그녹산', '크낙산', '크녹'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사',
    ),
    '메노푸어': IvfMedicationData(
      name: '메노푸어',
      aliases: ['메노푸어', '메노퓨어', '메노푸아', '매노푸어', '메노퓨아', '메노퓨'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH+LH 주사 (메노트로핀)',
    ),
    '폴리트롭': IvfMedicationData(
      name: '폴리트롭',
      aliases: ['폴리트롭', '폴리트랍', '폴리트럽', '폴리트롭', '폴리트'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사',
    ),
    '메리오날': IvfMedicationData(
      name: '메리오날',
      aliases: ['메리오날', '메리오넬', '메리오랄', '매리오날', '메리오'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'hMG 주사 (FSH+LH)',
    ),
    '아이브이에프엠': IvfMedicationData(
      name: 'IVF-M',
      aliases: ['아이브이에프엠', 'ivf엠', 'ivfm', 'ivf-m', '아이브이에프 엠'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'hMG 주사',
    ),
    '고나도핀': IvfMedicationData(
      name: '고나도핀',
      aliases: ['고나도핀', '고나도팬', '고나도펀', '고나도삔'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사',
    ),
    '폴리몬': IvfMedicationData(
      name: '폴리몬',
      aliases: ['폴리몬', '폴리문', '풀리몬', '포리몬'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사',
    ),
    '포스티몬': IvfMedicationData(
      name: '포스티몬',
      aliases: ['포스티몬', '포스티문', '포스타몬', '포스티먼'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사',
    ),
    '엘론바': IvfMedicationData(
      name: '엘론바',
      aliases: ['엘론바', 'elonva', '엘론바주', '엘론봐', '에론바'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: '장기지속형 FSH (코리폴리트로핀 알파)',
    ),
    '베르메바': IvfMedicationData(
      name: '베르메바',
      aliases: ['베르메바', '버메바', '베르메봐', '벌메바'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH 주사',
    ),
    '퍼고베리스': IvfMedicationData(
      name: '퍼고베리스',
      aliases: ['퍼고베리스', '퍼고베리', '퍼고배리스', '퍼고'],
      type: MedicationFormType.injection,
      category: '과배란 유도제',
      description: 'FSH+LH 복합 주사',
    ),

    // =========================================================================
    // 경구 배란유도제
    // =========================================================================
    '클로미펜': IvfMedicationData(
      name: '클로미펜',
      aliases: ['클로미펜', '클로미드', '클로미핀', '클로미팬', '클로미'],
      type: MedicationFormType.oral,
      category: '경구 배란유도제',
      description: '배란유도제 (클로미펜시트레이트)',
    ),
    '레트로졸': IvfMedicationData(
      name: '레트로졸',
      aliases: ['레트로졸', '레트로솔', '레트로줄', '페마라', '레트로'],
      type: MedicationFormType.oral,
      category: '경구 배란유도제',
      description: '배란유도제 (아로마타제 억제제)',
    ),
    '페마라': IvfMedicationData(
      name: '페마라',
      aliases: ['페마라', '페마라정', '페마라 정', '패마라'],
      type: MedicationFormType.oral,
      category: '경구 배란유도제',
      description: '레트로졸 (아로마타제 억제제)',
    ),
    '타목시펜': IvfMedicationData(
      name: '타목시펜',
      aliases: ['타목시펜', '타목시팬', '타목시핀', '놀바덱스'],
      type: MedicationFormType.oral,
      category: '경구 배란유도제',
      description: '선택적 에스트로겐 수용체 조절제',
    ),

    // =========================================================================
    // GnRH 길항제
    // =========================================================================
    '세트로타이드': IvfMedicationData(
      name: '세트로타이드',
      aliases: ['세트로타이드', '세트로', '쎄트로타이드', '세트로타이트', '세트로 타이드'],
      type: MedicationFormType.injection,
      category: 'GnRH 길항제',
      description: '조기배란 방지 (세트로렐릭스)',
    ),
    '오가루트란': IvfMedicationData(
      name: '오가루트란',
      aliases: ['오가루트란', '오가루트', '오가루', '오가르트란', '가니렐릭스'],
      type: MedicationFormType.injection,
      category: 'GnRH 길항제',
      description: '조기배란 방지 (가니렐릭스)',
    ),
    '피르고닉스': IvfMedicationData(
      name: '피르고닉스',
      aliases: ['피르고닉스', '필고닉스', '피르고', '피르고닉'],
      type: MedicationFormType.injection,
      category: 'GnRH 길항제',
      description: '조기배란 방지',
    ),

    // =========================================================================
    // GnRH 작용제
    // =========================================================================
    '데카펩틸': IvfMedicationData(
      name: '데카펩틸',
      aliases: ['데카펩틸', '데카펩틸', '데카펩', '디카펩틸', '데카 펩틸'],
      type: MedicationFormType.injection,
      category: 'GnRH 작용제',
      description: 'GnRH 작용제 (트립토렐린)',
    ),
    '루프린': IvfMedicationData(
      name: '루프린',
      aliases: ['루프린', '루프론', '루프린주', '류프린', '루프린데포'],
      type: MedicationFormType.injection,
      category: 'GnRH 작용제',
      description: 'GnRH 작용제 (류프로렐린)',
    ),
    '졸라덱스': IvfMedicationData(
      name: '졸라덱스',
      aliases: ['졸라덱스', '조라덱스', '졸라 덱스', '졸라'],
      type: MedicationFormType.injection,
      category: 'GnRH 작용제',
      description: 'GnRH 작용제 (고세렐린)',
    ),
    '슈프리팩트': IvfMedicationData(
      name: '슈프리팩트',
      aliases: ['슈프리팩트', '슈프리펙트', '슈프리팩', '수프리팩트'],
      type: MedicationFormType.injection,
      category: 'GnRH 작용제',
      description: 'GnRH 작용제 (부세렐린)',
    ),
    '시나렐': IvfMedicationData(
      name: '시나렐',
      aliases: ['시나렐', '시나렐 비강', '시나렐비강', '시나렐스프레이'],
      type: MedicationFormType.injection,
      category: 'GnRH 작용제',
      description: 'GnRH 작용제 비강분무 (나파렐린)',
    ),

    // =========================================================================
    // 배란 유도 (트리거) - hCG
    // =========================================================================
    '오비드렐': IvfMedicationData(
      name: '오비드렐',
      aliases: ['오비드렐', '오비드랠', '오비드', '오비드럴', '오비트렐'],
      type: MedicationFormType.injection,
      category: '배란 유도',
      description: 'hCG 트리거 주사 (코리오고나도트로핀 알파)',
    ),
    '트리거주사': IvfMedicationData(
      name: '트리거 주사',
      aliases: ['트리거', '트리거주사', '트리거 주사', '트리거샷', '트리거 샷'],
      type: MedicationFormType.injection,
      category: '배란 유도',
      description: '배란 유도 주사',
    ),
    '프레그닐': IvfMedicationData(
      name: '프레그닐',
      aliases: ['프레그닐', '프레그날', '프래그닐', '프레그닐주'],
      type: MedicationFormType.injection,
      category: '배란 유도',
      description: 'hCG 주사',
    ),
    '고나트로핀': IvfMedicationData(
      name: '고나트로핀',
      aliases: ['고나트로핀', '고나트로팬', '고나트로핀주', '고나트'],
      type: MedicationFormType.injection,
      category: '배란 유도',
      description: 'hCG 주사',
    ),
    'IVF-C': IvfMedicationData(
      name: 'IVF-C',
      aliases: ['아이브이에프씨', 'ivfc', 'ivf-c', 'ivf씨', '아이브이에프 씨'],
      type: MedicationFormType.injection,
      category: '배란 유도',
      description: 'hCG 주사',
    ),

    // =========================================================================
    // 황체기 보조 (프로게스테론)
    // =========================================================================
    '크리논': IvfMedicationData(
      name: '크리논',
      aliases: ['크리논', '크리넌', '클리논', '크리온', '크리논겔', '크리논 겔'],
      type: MedicationFormType.vaginal,
      category: '황체기 보조',
      description: '질 프로게스테론 겔 8%',
    ),
    '루티너스': IvfMedicationData(
      name: '루티너스',
      aliases: ['루티너스', '루티나스', '루테너스', '루티누스', '루티너스질정'],
      type: MedicationFormType.vaginal,
      category: '황체기 보조',
      description: '질정 프로게스테론 100mg',
    ),
    '유트로게스탄': IvfMedicationData(
      name: '유트로게스탄',
      aliases: ['유트로게스탄', '유트로게스탕', '유트게스탄', '유트로게스턴', '유트로게스탄질좌제'],
      type: MedicationFormType.vaginal,
      category: '황체기 보조',
      description: '질정/경구 프로게스테론 200mg',
    ),
    '사이클로제스트': IvfMedicationData(
      name: '사이클로제스트',
      aliases: ['사이클로제스트', '싸이클로제스트', '사이클로게스트', '사이클로'],
      type: MedicationFormType.vaginal,
      category: '황체기 보조',
      description: '질좌제 프로게스테론 400mg',
    ),
    '프로게스테론주사': IvfMedicationData(
      name: '프로게스테론 주사',
      aliases: ['프로게스테론주사', '프로게스테론 주사', '프게주사', '프게 주사', '피주사', '프게'],
      type: MedicationFormType.injection,
      category: '황체기 보조',
      description: '근육 프로게스테론 25/50mg',
    ),
    '듀파스톤': IvfMedicationData(
      name: '듀파스톤',
      aliases: ['듀파스톤', '듀파스턴', '두파스톤', '듀파스돈', '듀파스통', '듀파스톤정'],
      type: MedicationFormType.oral,
      category: '황체기 보조',
      description: '경구 프로게스테론 (디드로게스테론)',
    ),
    '프로게스타젯': IvfMedicationData(
      name: '프로게스타젯',
      aliases: ['프로게스타젯', '프로게스타켓', '프게스타젯', '프로게스타'],
      type: MedicationFormType.injection,
      category: '황체기 보조',
      description: '프로게스테론 주사',
    ),
    '프로루톤': IvfMedicationData(
      name: '프로루톤',
      aliases: ['프로루톤', '프로루튼', '프롤루톤', '프로루'],
      type: MedicationFormType.injection,
      category: '황체기 보조',
      description: '프로게스테론 주사',
    ),
    '루테움': IvfMedicationData(
      name: '루테움',
      aliases: ['루테움', '루테엄', '루태움', '루테움주'],
      type: MedicationFormType.injection,
      category: '황체기 보조',
      description: '프로게스테론 주사',
    ),
    '엔도메트린': IvfMedicationData(
      name: '엔도메트린',
      aliases: ['엔도메트린', '엔도매트린', '앤도메트린', '엔도 메트린'],
      type: MedicationFormType.vaginal,
      category: '황체기 보조',
      description: '질정 프로게스테론 100mg',
    ),

    // =========================================================================
    // 에스트로겐
    // =========================================================================
    '프로기노바': IvfMedicationData(
      name: '프로기노바',
      aliases: ['프로기노바', '프로기노봐', '프로게노바', '프로기노바정'],
      type: MedicationFormType.oral,
      category: '에스트로겐',
      description: '에스트라디올 발레레이트 2mg',
    ),
    '에스트라디올패치': IvfMedicationData(
      name: '에스트라디올 패치',
      aliases: ['에스트로겐패치', '에스트로겐 패치', '패치', '에스패치', '에스트라디올패치', '클리마라'],
      type: MedicationFormType.patch,
      category: '에스트로겐',
      description: '에스트라디올 패치',
    ),
    '에스트로펨': IvfMedicationData(
      name: '에스트로펨',
      aliases: ['에스트로펨', '에스트로팸', '에스트로펨정'],
      type: MedicationFormType.oral,
      category: '에스트로겐',
      description: '에스트라디올 2mg',
    ),
    '씨클리타': IvfMedicationData(
      name: '씨클리타',
      aliases: ['씨클리타', '시클리타', '씨클리타정'],
      type: MedicationFormType.oral,
      category: '에스트로겐',
      description: '에스트라디올+프로게스테론 복합',
    ),
    '디비겔': IvfMedicationData(
      name: '디비겔',
      aliases: ['디비겔', '디비젤', '디비겔 젤'],
      type: MedicationFormType.patch,
      category: '에스트로겐',
      description: '에스트라디올 피부겔',
    ),

    // =========================================================================
    // 면역/착상 보조제
    // =========================================================================
    '아스피린': IvfMedicationData(
      name: '아스피린',
      aliases: ['아스피린', '아스프린', '아스피닌', '아스피른', '저용량아스피린', '베이비아스피린'],
      type: MedicationFormType.oral,
      category: '보조제',
      description: '저용량 아스피린 (혈류개선) 100mg',
    ),
    '프레드니솔론': IvfMedicationData(
      name: '프레드니솔론',
      aliases: ['프레드니솔론', '프레드니손', '프레니솔론', '프레드니', '프레드', '소론도'],
      type: MedicationFormType.oral,
      category: '보조제',
      description: '스테로이드 (면역조절)',
    ),
    '덱사메타손': IvfMedicationData(
      name: '덱사메타손',
      aliases: ['덱사메타손', '덱사메타존', '덱사메사손', '덱사'],
      type: MedicationFormType.oral,
      category: '보조제',
      description: '스테로이드 (면역조절)',
    ),
    '메틸프레드니솔론': IvfMedicationData(
      name: '메틸프레드니솔론',
      aliases: ['메틸프레드니솔론', '메드롤', '메틸프레드', '솔루메드롤'],
      type: MedicationFormType.oral,
      category: '보조제',
      description: '스테로이드 (면역조절)',
    ),
    '인트라리피드': IvfMedicationData(
      name: '인트라리피드',
      aliases: ['인트라리피드', '인트라리핏', '인트라리피드주', '리피드'],
      type: MedicationFormType.injection,
      category: '보조제',
      description: '지방유제 (면역조절)',
    ),

    // =========================================================================
    // 영양/비타민 보조제
    // =========================================================================
    '엽산': IvfMedicationData(
      name: '엽산',
      aliases: ['엽산', '옆산', '염산', '엽상', '폴산', '폴릭애씨드', '폴릭산'],
      type: MedicationFormType.oral,
      category: '영양제',
      description: '태아 신경관 발달 400-800mcg',
    ),
    '철분제': IvfMedicationData(
      name: '철분제',
      aliases: ['철분제', '철분', '헤모페론', '훼럼', '페로바', '철분 보충제'],
      type: MedicationFormType.oral,
      category: '영양제',
      description: '빈혈 예방/치료',
    ),
    '비타민D': IvfMedicationData(
      name: '비타민D',
      aliases: ['비타민d', '비타민디', '비타민 d', '비타민 디', '콜레칼시페롤'],
      type: MedicationFormType.oral,
      category: '영양제',
      description: '착상 및 임신 유지 보조',
    ),
    '코엔자임큐텐': IvfMedicationData(
      name: '코엔자임Q10',
      aliases: ['코엔자임큐텐', '코엔자임q10', '코큐텐', 'coq10', '코엔자임'],
      type: MedicationFormType.oral,
      category: '영양제',
      description: '난자/정자 질 개선',
    ),
    'DHEA': IvfMedicationData(
      name: 'DHEA',
      aliases: ['디에이치이에이', 'dhea', '디에이치이 에이', '디하이드로에피안드로스테론'],
      type: MedicationFormType.oral,
      category: '영양제',
      description: '난소 기능 보조',
    ),
    '오메가3': IvfMedicationData(
      name: '오메가3',
      aliases: ['오메가3', '오메가쓰리', '오메가 3', '피쉬오일', '오매가3'],
      type: MedicationFormType.oral,
      category: '영양제',
      description: '혈류 개선/착상 보조',
    ),

    // =========================================================================
    // PCOS/대사 보조제
    // =========================================================================
    '메트포르민': IvfMedicationData(
      name: '메트포르민',
      aliases: ['메트포르민', '멧포르민', '메트폴민', '메포민', '글루코파지', '다이아벡스'],
      type: MedicationFormType.oral,
      category: 'PCOS 보조',
      description: 'PCOS 인슐린저항성 개선',
    ),
    '이노시톨': IvfMedicationData(
      name: '이노시톨',
      aliases: ['이노시톨', '이노시톨', '미오이노시톨', '디카이로이노시톨', '이노시톨분말'],
      type: MedicationFormType.oral,
      category: 'PCOS 보조',
      description: 'PCOS 배란/대사 개선',
    ),

    // =========================================================================
    // 자궁내막 보조
    // =========================================================================
    '바이아그라': IvfMedicationData(
      name: '바이아그라 질정',
      aliases: ['바이아그라', '바이아그라질정', '실데나필', '비아그라'],
      type: MedicationFormType.vaginal,
      category: '자궁내막 보조',
      description: '자궁내막 혈류 개선 (실데나필)',
    ),
    '펜톡시필린': IvfMedicationData(
      name: '펜톡시필린',
      aliases: ['펜톡시필린', '트렌탈', '펜톡시', '펜톡사필린'],
      type: MedicationFormType.oral,
      category: '자궁내막 보조',
      description: '혈액순환 개선',
    ),
    '비타민E': IvfMedicationData(
      name: '비타민E',
      aliases: ['비타민e', '비타민이', '비타민 e', '토코페롤'],
      type: MedicationFormType.oral,
      category: '자궁내막 보조',
      description: '자궁내막 혈류 개선',
    ),

    // =========================================================================
    // 기타
    // =========================================================================
    '헤파린': IvfMedicationData(
      name: '헤파린',
      aliases: ['헤파린', '헤파린주사', '클렉산', '프락시파린', '저분자헤파린'],
      type: MedicationFormType.injection,
      category: '항응고제',
      description: '혈전 예방 (착상 보조)',
    ),
    '프로게스테론경구': IvfMedicationData(
      name: '프로게스테론 경구',
      aliases: ['프로게스테론경구', '프로메트리움', '프로게스테론알약'],
      type: MedicationFormType.oral,
      category: '황체기 보조',
      description: '경구 프로게스테론',
    ),
    '갑상선약': IvfMedicationData(
      name: '갑상선 호르몬',
      aliases: ['갑상선약', '씬지로이드', '레보티록신', '갑상선호르몬', '유트록신'],
      type: MedicationFormType.oral,
      category: '보조제',
      description: '갑상선 기능 조절',
    ),
    '카버골린': IvfMedicationData(
      name: '카버골린',
      aliases: ['카버골린', '카버골린정', '도스티넥스', '카베골린'],
      type: MedicationFormType.oral,
      category: '보조제',
      description: 'OHSS 예방/프로락틴 조절',
    ),
  };

  /// 음성인식 텍스트에서 약물 매칭
  static MatchResult? matchMedication(String voiceText) {
    final normalized = voiceText.toLowerCase().replaceAll(' ', '');

    MatchResult? bestMatch;
    double bestScore = 0;

    for (final entry in _medicationDictionary.entries) {
      final data = entry.value;

      for (final alias in data.aliases) {
        final normalizedAlias = alias.toLowerCase().replaceAll(' ', '');

        // 완전 일치
        if (normalized.contains(normalizedAlias)) {
          final score = normalizedAlias.length / normalized.length;
          if (score > bestScore) {
            bestScore = score;
            bestMatch = MatchResult(
              medication: data,
              confidence: 1.0,
              matchedAlias: alias,
            );
          }
        }

        // 유사도 계산 (레벤슈타인 거리 기반)
        final similarity = _calculateSimilarity(normalized, normalizedAlias);
        if (similarity > 0.6 && similarity > bestScore) {
          bestScore = similarity;
          bestMatch = MatchResult(
            medication: data,
            confidence: similarity,
            matchedAlias: alias,
          );
        }
      }
    }

    return bestMatch;
  }

  /// 추천 약물 목록 반환 (상위 3개)
  static List<MatchResult> getSuggestions(String voiceText, {int limit = 3}) {
    final results = <MatchResult>[];
    final normalized = voiceText.toLowerCase().replaceAll(' ', '');

    for (final entry in _medicationDictionary.entries) {
      final data = entry.value;
      double maxSimilarity = 0;
      String? bestAlias;

      for (final alias in data.aliases) {
        final normalizedAlias = alias.toLowerCase().replaceAll(' ', '');

        // 포함 여부 체크
        if (normalized.contains(normalizedAlias) ||
            normalizedAlias.contains(normalized)) {
          final score = _calculateSimilarity(normalized, normalizedAlias);
          if (score > maxSimilarity) {
            maxSimilarity = score;
            bestAlias = alias;
          }
        } else {
          // 유사도 계산
          final similarity = _calculateSimilarity(normalized, normalizedAlias);
          if (similarity > maxSimilarity) {
            maxSimilarity = similarity;
            bestAlias = alias;
          }
        }
      }

      if (maxSimilarity > 0.4 && bestAlias != null) {
        results.add(MatchResult(
          medication: data,
          confidence: maxSimilarity,
          matchedAlias: bestAlias,
        ));
      }
    }

    // 신뢰도 순 정렬
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results.take(limit).toList();
  }

  /// 카테고리별 약물 목록
  static Map<String, List<IvfMedicationData>> getMedicationsByCategory() {
    final result = <String, List<IvfMedicationData>>{};

    for (final data in _medicationDictionary.values) {
      result.putIfAbsent(data.category, () => []).add(data);
    }

    return result;
  }

  /// 전체 약물 목록
  static List<IvfMedicationData> getAllMedications() {
    return _medicationDictionary.values.toList();
  }

  /// 레벤슈타인 거리 기반 유사도 계산
  static double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0;
    if (s1 == s2) return 1.0;

    final len1 = s1.length;
    final len2 = s2.length;

    // 길이 차이가 너무 크면 유사도 낮음
    if ((len1 - len2).abs() > (len1 + len2) / 2) return 0;

    // 레벤슈타인 거리 계산
    final matrix = List.generate(
      len1 + 1,
      (i) => List.generate(len2 + 1, (j) => 0),
    );

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final distance = matrix[len1][len2];
    final maxLen = len1 > len2 ? len1 : len2;

    return 1 - (distance / maxLen);
  }
}

/// 약물 형태
enum MedicationFormType {
  injection, // 주사
  oral,      // 경구약 (알약)
  vaginal,   // 질정
  patch,     // 한약 (기존 patch 유지 - DB 호환성)
}

extension MedicationFormTypeExtension on MedicationFormType {
  String get displayName {
    switch (this) {
      case MedicationFormType.injection:
        return '주사';
      case MedicationFormType.oral:
        return '알약';
      case MedicationFormType.vaginal:
        return '질정';
      case MedicationFormType.patch:
        return '한약';
    }
  }

  String get unit {
    switch (this) {
      case MedicationFormType.injection:
        return '대';
      case MedicationFormType.oral:
        return '알';
      case MedicationFormType.vaginal:
        return '개';
      case MedicationFormType.patch:
        return '팩';
    }
  }

  String get icon {
    switch (this) {
      case MedicationFormType.injection:
        return '💉';
      case MedicationFormType.oral:
        return '💊';
      case MedicationFormType.vaginal:
        return '🔵';
      case MedicationFormType.patch:
        return '🍵';
    }
  }
}

/// IVF 약물 데이터
class IvfMedicationData {
  final String name;
  final List<String> aliases;
  final MedicationFormType type;
  final String category;
  final String description;

  const IvfMedicationData({
    required this.name,
    required this.aliases,
    required this.type,
    required this.category,
    required this.description,
  });
}

/// 매칭 결과
class MatchResult {
  final IvfMedicationData medication;
  final double confidence;
  final String matchedAlias;

  const MatchResult({
    required this.medication,
    required this.confidence,
    required this.matchedAlias,
  });

  String get confidencePercent => '${(confidence * 100).toInt()}%';
}
