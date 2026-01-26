/// IVF 시술 중인 분들을 위한 응원 문구
/// 알림과 함께 표시되어 따뜻한 마음을 전합니다
class EncouragementMessages {
  /// 랜덤 응원 문구 가져오기
  static String getRandomMessage() {
    final index = DateTime.now().millisecondsSinceEpoch % _messages.length;
    return _messages[index];
  }

  /// 시간대별 응원 문구 가져오기
  static String getMessageByTime() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 9) {
      // 아침
      return _morningMessages[
          DateTime.now().millisecondsSinceEpoch % _morningMessages.length];
    } else if (hour >= 9 && hour < 12) {
      // 오전
      return _dayMessages[
          DateTime.now().millisecondsSinceEpoch % _dayMessages.length];
    } else if (hour >= 12 && hour < 18) {
      // 오후
      return _afternoonMessages[
          DateTime.now().millisecondsSinceEpoch % _afternoonMessages.length];
    } else if (hour >= 18 && hour < 22) {
      // 저녁
      return _eveningMessages[
          DateTime.now().millisecondsSinceEpoch % _eveningMessages.length];
    } else {
      // 밤
      return _nightMessages[
          DateTime.now().millisecondsSinceEpoch % _nightMessages.length];
    }
  }

  /// 아침 응원 문구
  static const List<String> _morningMessages = [
    '오늘 하루도 당신을 응원해요',
    '새로운 아침, 새로운 희망이에요',
    '좋은 아침이에요! 오늘도 화이팅',
    '아침 햇살처럼 따뜻한 하루 되세요',
    '오늘도 한 걸음 더 가까워졌어요',
  ];

  /// 오전 응원 문구
  static const List<String> _dayMessages = [
    '잘하고 있어요, 정말 대단해요',
    '당신의 노력은 분명 빛날 거예요',
    '힘든 만큼 더 큰 기쁨이 올 거예요',
    '오늘도 묵묵히 잘 해내고 있어요',
    '당신은 충분히 강한 사람이에요',
  ];

  /// 오후 응원 문구
  static const List<String> _afternoonMessages = [
    '조금만 더 힘내요, 할 수 있어요',
    '지금 이 순간도 기적의 일부예요',
    '당신의 사랑이 곧 열매 맺을 거예요',
    '포기하지 않는 당신이 멋져요',
    '오후도 무사히 보내고 있네요',
  ];

  /// 저녁 응원 문구
  static const List<String> _eveningMessages = [
    '오늘 하루도 수고 많았어요',
    '편안한 저녁 시간 보내세요',
    '오늘도 잘 버텨줘서 고마워요',
    '따뜻한 저녁 식사하셨나요?',
    '하루를 잘 마무리하고 있어요',
  ];

  /// 밤 응원 문구
  static const List<String> _nightMessages = [
    '오늘 밤도 편안히 쉬세요',
    '좋은 꿈 꾸세요, 내일도 응원할게요',
    '푹 쉬어야 내일도 힘낼 수 있어요',
    '밤사이 좋은 일이 생길 거예요',
    '편안한 밤 되세요',
  ];

  /// 전체 응원 문구 (랜덤용)
  static const List<String> _messages = [
    // 따뜻한 위로
    '당신은 이미 충분히 잘하고 있어요',
    '힘든 시간도 지나갈 거예요',
    '당신의 노력을 응원합니다',
    '오늘 하루도 정말 수고했어요',
    '잘하고 있어요, 걱정 마세요',

    // 희망의 메시지
    '좋은 소식이 곧 올 거예요',
    '기적은 매일 조금씩 일어나고 있어요',
    '당신의 작은 씨앗이 곧 피어날 거예요',
    '희망을 잃지 마세요, 분명 좋은 결과가 있을 거예요',
    '지금 이 순간도 기적을 향해 가고 있어요',

    // 엄마들의 마음
    '사랑하는 마음이 가장 큰 힘이에요',
    '아기가 엄마를 기다리고 있을 거예요',
    '당신의 사랑은 이미 충분해요',
    '좋은 엄마가 될 준비를 하고 있는 거예요',
    '엄마의 마음으로 하루하루 보내고 있네요',

    // 격려
    '포기하지 않는 당신이 정말 대단해요',
    '당신은 강한 사람이에요',
    '이 시간도 잘 견뎌내고 있어요',
    '매일 조금씩 더 강해지고 있어요',
    '당신의 인내심이 빛을 발할 거예요',

    // 함께하는 마음
    '혼자가 아니에요, 함께 응원해요',
    '같은 길을 걷는 많은 분들이 함께해요',
    '당신 곁에 항상 응원하는 마음이 있어요',
    '힘들 때는 잠시 쉬어가도 괜찮아요',
    '천천히 가도 돼요, 괜찮아요',

    // 긍정 에너지
    '오늘도 좋은 일이 생길 거예요',
    '웃는 날이 더 많아질 거예요',
    '행복한 미래가 기다리고 있어요',
    '당신에게 좋은 기운을 보내요',
    '모든 것이 잘 될 거예요',

    // 건강 응원
    '오늘도 건강하게 보내요',
    '몸과 마음 모두 챙기세요',
    '충분히 쉬는 것도 중요해요',
    '맛있는 것 드시고 힘내세요',
    '건강이 최고예요, 잘 챙기세요',

    // 계절/시기별 (범용)
    '이 시간이 지나면 더 행복해질 거예요',
    '지금의 노력이 기쁨이 될 거예요',
    '당신의 이야기는 해피엔딩일 거예요',
    '조금만 더 기다려봐요',
    '좋은 결과를 믿어요',
  ];

  /// 주사 관련 특별 응원 문구
  static const List<String> injectionMessages = [
    '따끔하지만 금방 지나가요',
    '주사 맞는 것도 사랑이에요',
    '아프지만 잘 참고 있어요',
    '오늘 주사도 무사히 끝!',
    '용감하게 잘 맞았어요',
    '조금만 참으면 돼요',
    '아기를 위한 사랑의 주사예요',
    '주사 한 번이 기적에 한 걸음이에요',
  ];

  /// 주사 응원 문구 가져오기
  static String getInjectionMessage() {
    final index =
        DateTime.now().millisecondsSinceEpoch % injectionMessages.length;
    return injectionMessages[index];
  }

  /// 약물 복용 응원 문구 (일반)
  static const List<String> medicationMessages = [
    '오늘도 잘 챙겨 먹었어요',
    '꾸준함이 가장 중요해요',
    '잊지 않고 챙기는 당신이 대단해요',
    '매일 같은 시간, 잘하고 있어요',
    '건강을 위한 한 알이에요',
  ];

  /// 약물 복용 응원 문구 가져오기
  static String getMedicationMessage() {
    final index =
        DateTime.now().millisecondsSinceEpoch % medicationMessages.length;
    return medicationMessages[index];
  }

  /// 알약/한약/질정용 응원 문구
  static const List<String> oralMessages = [
    '오늘도 잊지 않고 복용 완료!',
    '꾸준함이 기적을 만들어요',
    '잘 챙겨 먹었어요!',
    '오늘도 한 걸음 더 가까워졌어요',
    '매일 챙기는 당신이 멋져요',
    '작은 습관이 큰 결과를 만들어요',
    '오늘도 잘하고 있어요!',
  ];

  /// 알약/한약/질정용 응원 문구 가져오기
  static String getOralMessage() {
    final index =
        DateTime.now().millisecondsSinceEpoch % oralMessages.length;
    return oralMessages[index];
  }
}
