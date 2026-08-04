import 'package:flutter_test/flutter_test.dart';
import 'package:float_financial/shared/models/subnet_position.dart';
import 'package:float_financial/shared/utils/yield_alerts.dart';

void main() {
  group('YieldAlertEngine', () {
    final engine = YieldAlertEngine();

    SubnetPosition makePosition({required int id, required double apy, required double price, double staked = 10.0}) {
      return SubnetPosition.fromData(
        subnetId: id, name: 'SN$id', stakedTao: staked,
        alphaBalance: staked / price, alphaPriceTao: price,
        monthlyYieldTao: apy / 100 * staked / 12, // APY% → real monthly TAO yield
      );
    }

    test('no alerts when nothing changes', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isEmpty);
    });

    test('SubnetPosition toJson/fromJson round-trips alert-relevant fields', () {
      final p = makePosition(id: 53, apy: 21.0, price: 5.73, staked: 25.0);
      final restored = SubnetPosition.fromJson(p.toJson());
      expect(restored.subnetId, p.subnetId);
      expect(restored.name, p.name);
      expect(restored.stakedTao, closeTo(p.stakedTao, 1e-9));
      expect(restored.alphaBalance, closeTo(p.alphaBalance, 1e-9));
      expect(restored.alphaPriceTao, closeTo(p.alphaPriceTao, 1e-9));
      expect(restored.monthlyYieldTao, closeTo(p.monthlyYieldTao, 1e-9));
      expect(restored.apy, closeTo(p.apy, 1e-6));
    });

    test('APY drop alert fires when APY decreases beyond threshold', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 15.0, price: 15.0)]; // -2.5%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.type == 'apy_drop'), isTrue);
      expect(alerts.any((a) => a.subnetId == 64), isTrue);
    });

    test('APY spike alert fires when APY increases beyond threshold', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 20.0, price: 15.0)]; // +2.5%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.type == 'apy_spike'), isTrue);
    });

    test('no APY alert when change is within threshold', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 19.0, price: 15.0)]; // +1.5% (< 2.0%)
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isEmpty);
    });

    test('price drop alert fires when alpha price drops beyond threshold', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 17.5, price: 14.0)]; // -6.7%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.type == 'alpha_price_drop'), isTrue);
    });

    test('price spike alert fires when alpha price rises beyond threshold', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 17.5, price: 16.0)]; // +6.7%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isNotEmpty);
      expect(alerts.any((a) => a.type == 'alpha_price_spike'), isTrue);
    });

    test('no price alert when change is within threshold', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 17.5, price: 15.5)]; // +3.3% (< 5%)
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isEmpty);
    });

    test('no alerts for empty current list', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final alerts = engine.checkAlerts([], prev);
      expect(alerts, isEmpty);
    });

    test('no alerts for empty previous list', () {
      final curr = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final alerts = engine.checkAlerts(curr, []);
      expect(alerts, isEmpty);
    });

    test('multiple subnets generate multiple alerts', () {
      final prev = [
        makePosition(id: 64, apy: 17.5, price: 15.0),
        makePosition(id: 53, apy: 32.5, price: 5.0),
      ];
      final curr = [
        makePosition(id: 64, apy: 14.0, price: 15.0), // APY drop
        makePosition(id: 53, apy: 36.0, price: 5.0),  // APY spike
      ];
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts.length, greaterThanOrEqualTo(2));
      expect(alerts.any((a) => a.subnetId == 64), isTrue);
      expect(alerts.any((a) => a.subnetId == 53), isTrue);
    });

    test('alert message contains subnet ID', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 14.0, price: 15.0)];
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts[0].message, contains('64'));
    });

    test('alert message contains APY values', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 14.0, price: 15.0)];
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts[0].message, contains('17.5'));
      expect(alerts[0].message, contains('14.0'));
    });

    test('severity is high for large changes', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 10.0, price: 15.0)]; // -7.5%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts[0].severity, AlertSeverity.high);
    });

    test('severity is medium for moderate changes', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 14.0, price: 15.0)]; // -3.5%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts[0].severity, AlertSeverity.medium);
    });

    test('severity is low for small threshold-crossing changes', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 15.3, price: 15.0)]; // -2.2%
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts[0].severity, AlertSeverity.low);
    });

    test('skips subnets not in previous snapshot', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [
        makePosition(id: 64, apy: 17.5, price: 15.0),
        makePosition(id: 53, apy: 32.5, price: 5.0), // new subnet
      ];
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts, isEmpty);
    });

    test('alert has timestamp', () {
      final prev = [makePosition(id: 64, apy: 17.5, price: 15.0)];
      final curr = [makePosition(id: 64, apy: 14.0, price: 15.0)];
      final alerts = engine.checkAlerts(curr, prev);
      expect(alerts[0].timestamp, isNotNull);
      expect(alerts[0].timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
    });
  });
}
