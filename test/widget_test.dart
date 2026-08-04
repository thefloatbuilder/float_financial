import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:float_financial/app.dart';
import 'package:float_financial/features/auth/login_screen.dart';
import 'package:float_financial/features/splash/splash_screen.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    // FloatFinancialApp is a ConsumerWidget — it needs a ProviderScope.
    // The router's initial location is /splash, which shows the logo for
    // 1850ms before routing to / (login) in demo mode.
    await tester.pumpWidget(const ProviderScope(child: FloatFinancialApp()));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Let the splash timer elapse so no Timer is left pending at teardown.
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
