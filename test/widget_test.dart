import 'package:flutter_test/flutter_test.dart';
import 'package:float_financial/app.dart';  // or main if needed

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    // Use the actual root widget
    await tester.pumpWidget(const FloatFinancialApp());
    // Basic smoke test - look for something that exists in the app
    expect(find.textContaining('Good morning'), findsOneWidget);
  });
}
