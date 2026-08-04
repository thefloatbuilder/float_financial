import 'package:flutter_test/flutter_test.dart';
import 'package:float_financial/shared/models/subnet_position.dart';
import 'package:float_financial/shared/utils/rebalance_engine.dart';

void main() {
  group('RebalanceEngine', () {
    SubnetPosition makePosition({required int id, required double value, double price = 1.0}) {
      return SubnetPosition.fromData(
        subnetId: id, name: 'SN$id', stakedTao: value,
        alphaBalance: price > 0 ? value / price : value,
        alphaPriceTao: price, monthlyYieldTao: value * 0.15 / 12,
      );
    }

    test('no suggestions when portfolio is perfectly balanced', () {
      final positions = [
        makePosition(id: 64, value: 30.0),
        makePosition(id: 4, value: 25.0),
        makePosition(id: 53, value: 25.0),
        makePosition(id: 0, value: 20.0),
      ];
      final targets = {64: 30.0, 4: 25.0, 53: 25.0, 0: 20.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      expect(suggestions, isEmpty);
    });

    test('trim suggestion for overweight subnet', () {
      final positions = [
        makePosition(id: 64, value: 50.0), // 50% but target 30%
        makePosition(id: 53, value: 50.0), // 50% but target 70%
      ];
      final targets = {64: 30.0, 53: 70.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      final trim = suggestions.where((s) => s.action == RebalanceAction.trim).toList();
      expect(trim, isNotEmpty);
      expect(trim[0].subnetId, 64);
      expect(trim[0].driftPct, greaterThan(0));
    });

    test('add suggestion for underweight subnet', () {
      final positions = [
        makePosition(id: 64, value: 10.0), // 10% but target 30%
        makePosition(id: 53, value: 90.0), // 90% but target 70%
      ];
      final targets = {64: 30.0, 53: 70.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      final add = suggestions.where((s) => s.action == RebalanceAction.add).toList();
      expect(add, isNotEmpty);
      expect(add[0].subnetId, 64);
      expect(add[0].driftPct, lessThan(0));
    });

    test('no suggestion when drift is below threshold', () {
      final positions = [
        makePosition(id: 64, value: 31.0), // ~31% vs 30% target
        makePosition(id: 53, value: 69.0), // ~69% vs 70% target
      ];
      final targets = {64: 30.0, 53: 70.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      expect(suggestions, isEmpty);
    });

    test('empty positions returns empty suggestions', () {
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: [], targetAllocations: {64: 30.0},
      );
      expect(suggestions, isEmpty);
    });

    test('single position portfolio works', () {
      final positions = [makePosition(id: 64, value: 100.0)];
      final targets = {64: 100.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      expect(suggestions, isEmpty);
    });

    test('suggestions sorted by absolute drift (largest first)', () {
      final positions = [
        makePosition(id: 64, value: 45.0), // +15% drift
        makePosition(id: 4, value: 5.0),   // -20% drift
        makePosition(id: 53, value: 50.0), // -5% drift
      ];
      final targets = {64: 30.0, 4: 25.0, 53: 55.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      expect(suggestions.length, greaterThanOrEqualTo(2));
      expect(suggestions[0].driftPct.abs(), greaterThanOrEqualTo(suggestions[1].driftPct.abs()));
    });

    test('needsRebalance returns true when drift exceeds threshold', () {
      final positions = [
        makePosition(id: 64, value: 50.0),
        makePosition(id: 53, value: 50.0),
      ];
      final targets = {64: 30.0, 53: 70.0};
      expect(RebalanceEngine.needsRebalance(
        positions: positions, targetAllocations: targets,
      ), isTrue);
    });

    test('needsRebalance returns false when balanced', () {
      final positions = [
        makePosition(id: 64, value: 30.0),
        makePosition(id: 53, value: 70.0),
      ];
      final targets = {64: 30.0, 53: 70.0};
      expect(RebalanceEngine.needsRebalance(
        positions: positions, targetAllocations: targets,
      ), isFalse);
    });

    test('skips subnets with no target allocation', () {
      final positions = [
        makePosition(id: 64, value: 50.0),
        makePosition(id: 53, value: 50.0), // no target for 53
      ];
      final targets = {64: 100.0}; // only target 64
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      expect(suggestions.every((s) => s.subnetId == 64), isTrue);
    });

    test('amountTao is positive for both trim and add', () {
      final positions = [
        makePosition(id: 64, value: 50.0),
        makePosition(id: 53, value: 50.0),
      ];
      final targets = {64: 30.0, 53: 70.0};
      final suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      for (final s in suggestions) {
        expect(s.amountTao, greaterThan(0));
      }
    });

    test('custom drift threshold works', () {
      final positions = [
        makePosition(id: 64, value: 33.0), // ~33% vs 30% target = 3% drift
        makePosition(id: 53, value: 67.0), // ~67% vs 70% target = 3% drift
      ];
      final targets = {64: 30.0, 53: 70.0};
      // Default threshold (5%) — no suggestions
      var suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets,
      );
      expect(suggestions, isEmpty);
      // Custom threshold (2%) — should suggest
      suggestions = RebalanceEngine.calculateRebalance(
        positions: positions, targetAllocations: targets, driftThreshold: 2.0,
      );
      expect(suggestions, isNotEmpty);
    });
  });
}
