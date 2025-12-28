import 'package:flutter_test/flutter_test.dart';
import 'package:ivf_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const IVFApp());

    // 앱이 로드되는지 확인
    expect(find.text('오늘도 화이팅!'), findsOneWidget);
  });
}
