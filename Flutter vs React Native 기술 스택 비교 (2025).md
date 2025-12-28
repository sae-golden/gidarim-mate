# Flutter vs React Native 기술 스택 비교 (2025)

## 핵심 비교표

| 항목 | Flutter | React Native |
|------|---------|--------------|
| **개발사** | Google (2017) | Facebook/Meta (2015) |
| **언어** | Dart | JavaScript (JSX) |
| **UI 방식** | Widget 기반 | Component 기반 |
| **성능** | 일반적으로 더 빠름 | 요인에 따라 다름 |
| **컴파일** | AOT (Ahead-of-Time) | JIT (Just-in-Time) |
| **UI 컴포넌트** | 자체 컴포넌트 (Material Design) | 네이티브 UI 컴포넌트 |
| **Hot Reload** | 지원 (빠른 개발) | 지원 (빠른 반복) |
| **커뮤니티** | 성장 중, 강력한 지원 | 크고 활발한 커뮤니티 |
| **학습 곡선** | Dart 언어 + Flutter 프레임워크 학습 필요 | JavaScript/React 친숙도 필요 |
| **도구** | Flutter SDK | React Native CLI, Expo |
| **3D 지원** | 지원 안 함 | 더 나은 지원 |
| **성능 튜닝** | 더 많은 제어 가능 | 제한적 제어 |
| **네이티브 모듈** | 플랫폼별 채널 필요 | 브릿지를 통한 네이티브 통합 |
| **플랫폼 지원** | iOS, Android, Web, Desktop (실험적) | iOS, Android, Web |

## Flutter 장점
1. 뛰어난 UI 품질
2. 다양한 위젯 제공
3. 앱 속도가 빠름
4. 웹 앱 빌드 가능 (Flutter 2+)
5. 잘 정리된 문서와 커뮤니티
6. 다양한 기기에서 동일한 UI 구현 가능

## Flutter 단점
1. 네이티브가 아님
2. 앱 크기가 큼
3. 제한된 도구 세트

## React Native 장점
1. JavaScript 사용 (친숙한 언어)
2. 단일 코드베이스로 멀티 플랫폼 앱 생성
3. 코드 재사용성 강조
4. 성장하고 활발한 커뮤니티
5. 코딩 시간 단축

## React Native 단점
1. 네이티브가 아님
2. 혁신적인 기본 컴포넌트 부족
3. 제한된 선택지
4. 버려진 라이브러리/패키지 존재
5. UI가 쉽게 손상될 수 있음 (철저한 테스트 필요)
6. 앱 크기가 큼

## 실제 사용 사례

### Flutter 사용 기업
- Google Pay (인도 버전)
- Alibaba
- BMW (my BMW 앱)
- Philips Hue
- Hamilton

### React Native 사용 기업
- Facebook/Meta (Marketplace)
- Instagram
- Tesla
- Skype
- Uber Eats

## 성능 벤치마크 (2025)
- **시작 시간**: Flutter가 가장 빠름
- **일관성**: React Native가 가장 일관적
- **메모리**: Native가 가장 적게 사용, Flutter는 약 2배 메모리 사용

## IVF 앱 개발을 위한 추천

### Flutter 추천 이유
1. **UI 일관성**: 복잡한 주사 부위 마킹 UI를 iOS/Android에서 동일하게 구현 가능
2. **성능**: 알림 및 스케줄 관리에 빠른 반응 속도
3. **Google 지원**: 지속적인 업데이트와 안정성
4. **Material Design**: 깔끔한 헬스케어 앱 UI 구현에 적합

### React Native 추천 이유
1. **JavaScript 생태계**: 풍부한 라이브러리 (카카오톡 SDK 등)
2. **개발자 풀**: JavaScript 개발자가 더 많음
3. **Expo**: 빠른 프로토타이핑과 배포
4. **네이티브 모듈**: 카카오톡 연동 등 한국 특화 기능 구현 용이

### 최종 추천: **Flutter**
- IVF 앱의 핵심인 주사 부위 로테이션 UI, 복잡한 스케줄 캘린더 등 시각적 요소가 중요
- 일관된 UI/UX가 iOS와 Android 모두에서 필요
- 헬스케어 앱의 신뢰성과 안정성 중요
- 카카오톡 연동은 Flutter 플러그인으로도 가능 (kakao_flutter_sdk)
