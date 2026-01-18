# 시험관메이트 - 쿠팡 파트너스 광고 영역

## 개요
홈 화면과 기록 탭에 쿠팡 파트너스 추천 상품 영역 배치

---

## 배치 위치

| 위치 | 형태 | 설명 |
|------|------|------|
| 홈 화면 하단 | 가로 스크롤 | 여러 상품 노출 |
| 기록 탭 하단 | 단일 카드 | 현재 단계에 맞는 상품 |

---

## 1. 홈 화면 하단

```
┌─────────────────────────────────────────┐
│ 홈                                      │
├─────────────────────────────────────────┤
│                                         │
│ [오늘의 투약 카드]                      │
│                                         │
│ [다가오는 일정]                         │
│                                         │
├─────────────────────────────────────────┤
│ 이런 영양제 어때요?                     │
│                                         │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │  [📷]   │ │  [📷]   │ │  [📷]   │ →  │
│ │ 엽산    │ │ 비타민D │ │ 코엔자임│    │
│ │ ₩12,900 │ │ ₩15,900 │ │ ₩23,000 │    │
│ └─────────┘ └─────────┘ └─────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

### 상품 카드 (홈)
```dart
Container(
  width: 100,
  child: Column(
    children: [
      // 상품 이미지
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, height: 80, fit: BoxFit.cover),
      ),
      SizedBox(height: 8),
      // 상품명
      Text(
        name,
        style: TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // 가격
      Text(
        '₩${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    ],
  ),
)
```

### 가로 스크롤 리스트
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '이런 영양제 어때요?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    SizedBox(height: 12),
    SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openCoupangLink(products[index].affiliateUrl),
            child: ProductCard(product: products[index]),
          );
        },
      ),
    ),
  ],
)
```

---

## 2. 기록 탭 하단

```
┌─────────────────────────────────────────┐
│ 기록                                    │
│ 1차 시험관                       [편집] │
├─────────────────────────────────────────┤
│                                         │
│ [타임라인...]                           │
│                                         │
├─────────────────────────────────────────┤
│ 시험관 준비에 도움되는 영양제           │
│ ┌─────────────────────────────────────┐ │
│ │ [📷]  엽산 800                      │ │
│ │       ⭐ 4.8 · ₩12,900    구경하기 →│ │
│ └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│   새로운 시도 시작하기               >  │
└─────────────────────────────────────────┘
```

### 상품 카드 (기록)
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!),
  ),
  child: Row(
    children: [
      // 상품 이미지
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
      ),
      SizedBox(width: 12),
      // 상품 정보
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Row(
              children: [
                Text('⭐ $rating', style: TextStyle(fontSize: 12)),
                SizedBox(width: 8),
                Text('₩$price', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
      // 구경하기 버튼
      Text(
        '구경하기 →',
        style: TextStyle(fontSize: 13, color: Color(0xFF9B7ED9)),
      ),
    ],
  ),
)
```

---

## 단계별 추천 상품

| 현재 단계 | 추천 상품 | 문구 |
|-----------|-----------|------|
| 과배란 | 엽산, 비타민D, 알콜솜, 쿨링패드 | 과배란 준비에 도움되는 |
| 채취 후 | 단백질 보충제, 복부 찜질팩 | 채취 후 회복에 좋은 |
| 이식 후 | 좌욕기, 임산부 쿠션 | 이식 후 편안한 휴식을 위한 |
| 동결 대기 | 종합비타민, 오메가3 | 다음 준비를 위한 |
| 기본 (단계 없음) | 엽산, 비타민D | 시험관 준비에 도움되는 |

### 단계별 상품 로직
```dart
List<Product> getRecommendedProducts(TreatmentCycle? cycle) {
  if (cycle == null) {
    return defaultProducts;
  }
  
  final lastEvent = cycle.events.lastOrNull;
  
  switch (lastEvent?.type) {
    case EventType.stimulation:
      return stimulationProducts;  // 과배란
    case EventType.retrieval:
      return retrievalProducts;    // 채취 후
    case EventType.transfer:
      return transferProducts;     // 이식 후
    case EventType.freezing:
      return freezingProducts;     // 동결 대기
    default:
      return defaultProducts;
  }
}

String getRecommendationTitle(TreatmentCycle? cycle) {
  if (cycle == null) {
    return '시험관 준비에 도움되는 영양제';
  }
  
  final lastEvent = cycle.events.lastOrNull;
  
  switch (lastEvent?.type) {
    case EventType.stimulation:
      return '과배란 준비에 도움되는';
    case EventType.retrieval:
      return '채취 후 회복에 좋은';
    case EventType.transfer:
      return '이식 후 편안한 휴식을 위한';
    case EventType.freezing:
      return '다음 준비를 위한';
    default:
      return '시험관 준비에 도움되는 영양제';
  }
}
```

---

## 추천 상품 목록 예시

### 기본 (엽산, 비타민D)
```dart
final defaultProducts = [
  Product(
    name: '엽산 800mcg',
    price: 12900,
    rating: 4.8,
    imageUrl: '...',
    affiliateUrl: 'https://link.coupang.com/...',
  ),
  Product(
    name: '비타민D 2000IU',
    price: 15900,
    rating: 4.7,
    imageUrl: '...',
    affiliateUrl: 'https://link.coupang.com/...',
  ),
  Product(
    name: '코엔자임Q10',
    price: 23000,
    rating: 4.6,
    imageUrl: '...',
    affiliateUrl: 'https://link.coupang.com/...',
  ),
];
```

### 과배란 단계
```dart
final stimulationProducts = [
  Product(name: '엽산 800mcg', ...),
  Product(name: '비타민D 2000IU', ...),
  Product(name: '알콜솜 100매', price: 3900, ...),
  Product(name: '쿨링패드', price: 8900, ...),
];
```

### 이식 후 단계
```dart
final transferProducts = [
  Product(name: '좌욕기', price: 35000, ...),
  Product(name: '임산부 쿠션', price: 29000, ...),
  Product(name: '복부 찜질팩', price: 15000, ...),
];
```

---

## 데이터 모델

```dart
class Product {
  final String id;
  final String name;
  final int price;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final String affiliateUrl;  // 쿠팡 파트너스 링크
  final List<String> stages;  // 추천 단계
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    this.reviewCount = 0,
    required this.imageUrl,
    required this.affiliateUrl,
    this.stages = const [],
  });
}
```

---

## 쿠팡 링크 열기

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> openCoupangLink(String affiliateUrl) async {
  final uri = Uri.parse(affiliateUrl);
  
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
```

---

## 요약

| 위치 | 형태 | 상품 수 |
|------|------|---------|
| 홈 하단 | 가로 스크롤 | 3~5개 |
| 기록 하단 | 단일 카드 | 1개 (단계별) |

| 단계 | 추천 |
|------|------|
| 과배란 | 엽산, 비타민D, 알콜솜 |
| 채취 후 | 단백질, 찜질팩 |
| 이식 후 | 좌욕기, 쿠션 |
| 동결 대기 | 종합비타민 |
