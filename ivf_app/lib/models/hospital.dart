/// 병원 정보 모델
class Hospital {
  final String? ykiho; // 요양기관 번호
  final String name; // 병원명 (yadmNm)
  final String address; // 주소 (addr)
  final String? phone; // 전화번호 (telno)
  final String? sidoName; // 시도명 (sidoCdNm)
  final String? sgguName; // 시군구명 (sgguCdNm)
  final double? latitude; // 위도 (YPos)
  final double? longitude; // 경도 (XPos)
  final String? clCdNm; // 종별명 (의원, 병원, 종합병원 등)

  Hospital({
    this.ykiho,
    required this.name,
    required this.address,
    this.phone,
    this.sidoName,
    this.sgguName,
    this.latitude,
    this.longitude,
    this.clCdNm,
  });

  /// 간략 주소 (시도 시군구)
  String get shortAddress {
    if (sidoName != null && sgguName != null) {
      return '$sidoName $sgguName';
    }
    return address.length > 20 ? '${address.substring(0, 20)}...' : address;
  }

  /// API 응답에서 파싱
  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      ykiho: json['ykiho']?.toString(),
      name: json['yadmNm']?.toString() ?? '',
      address: json['addr']?.toString() ?? '',
      phone: json['telno']?.toString(),
      sidoName: json['sidoCdNm']?.toString(),
      sgguName: json['sgguCdNm']?.toString(),
      latitude: _parseDouble(json['YPos']),
      longitude: _parseDouble(json['XPos']),
      clCdNm: json['clCdNm']?.toString(),
    );
  }

  /// JSON으로 변환 (저장용)
  Map<String, dynamic> toJson() {
    return {
      'ykiho': ykiho,
      'name': name,
      'address': address,
      'phone': phone,
      'sidoName': sidoName,
      'sgguName': sgguName,
      'latitude': latitude,
      'longitude': longitude,
      'clCdNm': clCdNm,
    };
  }

  /// 저장된 JSON에서 복원
  factory Hospital.fromStoredJson(Map<String, dynamic> json) {
    return Hospital(
      ykiho: json['ykiho'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      sidoName: json['sidoName'],
      sgguName: json['sgguName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      clCdNm: json['clCdNm'],
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// 사용자 병원 정보 (선택한 병원 + 추가 정보)
class UserHospitalInfo {
  final Hospital? hospital;
  final String? doctorName;
  final String? memo;

  UserHospitalInfo({
    this.hospital,
    this.doctorName,
    this.memo,
  });

  Map<String, dynamic> toJson() {
    return {
      'hospital': hospital?.toJson(),
      'doctorName': doctorName,
      'memo': memo,
    };
  }

  factory UserHospitalInfo.fromJson(Map<String, dynamic> json) {
    return UserHospitalInfo(
      hospital: json['hospital'] != null
          ? Hospital.fromStoredJson(json['hospital'])
          : null,
      doctorName: json['doctorName'],
      memo: json['memo'],
    );
  }

  UserHospitalInfo copyWith({
    Hospital? hospital,
    String? doctorName,
    String? memo,
  }) {
    return UserHospitalInfo(
      hospital: hospital ?? this.hospital,
      doctorName: doctorName ?? this.doctorName,
      memo: memo ?? this.memo,
    );
  }
}

/// 시도 코드
class SidoCode {
  final String code;
  final String name;

  const SidoCode(this.code, this.name);

  static const List<SidoCode> all = [
    SidoCode('110000', '서울'),
    SidoCode('210000', '부산'),
    SidoCode('220000', '인천'),
    SidoCode('230000', '대구'),
    SidoCode('240000', '광주'),
    SidoCode('250000', '대전'),
    SidoCode('260000', '울산'),
    SidoCode('310000', '경기'),
    SidoCode('320000', '강원'),
    SidoCode('330000', '충북'),
    SidoCode('340000', '충남'),
    SidoCode('350000', '전북'),
    SidoCode('360000', '전남'),
    SidoCode('370000', '경북'),
    SidoCode('380000', '경남'),
    SidoCode('390000', '제주'),
    SidoCode('410000', '세종'),
  ];
}
