import 'package:flutter_test/flutter_test.dart';
import 'package:jksecurityapp/main.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    await tester.pumpWidget(const JKSecurityApp());
  });
}