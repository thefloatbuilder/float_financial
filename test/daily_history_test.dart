import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:float_financial/shared/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageService daily history', () {
    test('records and loads a daily value', () async {
      await LocalStorageService.recordDailyValue(150000.0);
      final history = await LocalStorageService.loadDailyHistory();
      expect(history.length, 1);
      expect(history.first['total_value'], 150000.0);
    });

    test('same-day re-record updates instead of duplicating', () async {
      await LocalStorageService.recordDailyValue(150000.0);
      await LocalStorageService.recordDailyValue(151500.0);
      final history = await LocalStorageService.loadDailyHistory();
      expect(history.length, 1);
      expect(history.first['total_value'], 151500.0);
    });

    test('history comes back sorted oldest-first', () async {
      // Seed two days manually via prefs
      SharedPreferences.setMockInitialValues({
        'portfolio_daily_history':
            '[{"date":"2026-08-02","total_value":149000.0},{"date":"2026-08-01","total_value":148000.0}]',
      });
      final history = await LocalStorageService.loadDailyHistory();
      expect(history.first['date'], '2026-08-01');
      expect(history.last['date'], '2026-08-02');
    });
  });
}
