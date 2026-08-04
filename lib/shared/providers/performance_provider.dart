import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../widgets/portfolio_performance_chart.dart';

/// Provider for portfolio performance data — real daily net worth history,
/// falling back to snapshots, then demo data if nothing recorded yet.
final performanceDataProvider = FutureProvider<List<PerformanceDataPoint>>((ref) async {
  final history = await LocalStorageService.loadDailyHistory();

  if (history.isNotEmpty) {
    return [
      for (final entry in history)
        PerformanceDataPoint(
          label: _formatDateLabel(DateTime.tryParse(entry['date'] as String? ?? '') ?? DateTime.now()),
          value: (entry['total_value'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(entry['date'] as String? ?? '') ?? DateTime.now(),
        ),
    ];
  }

  final snapshots = await LocalStorageService.loadSnapshots();

  if (snapshots.isEmpty) {
    // Return demo data showing growth
    final now = DateTime.now();
    return [
      PerformanceDataPoint(label: 'Jan', value: 125000, date: now.subtract(const Duration(days: 180))),
      PerformanceDataPoint(label: 'Feb', value: 132000, date: now.subtract(const Duration(days: 150))),
      PerformanceDataPoint(label: 'Mar', value: 128000, date: now.subtract(const Duration(days: 120))),
      PerformanceDataPoint(label: 'Apr', value: 141000, date: now.subtract(const Duration(days: 90))),
      PerformanceDataPoint(label: 'May', value: 148000, date: now.subtract(const Duration(days: 60))),
      PerformanceDataPoint(label: 'Jun', value: 152581, date: now.subtract(const Duration(days: 30))),
      PerformanceDataPoint(label: 'Jul', value: 158000, date: now),
    ];
  }
  
  // Convert snapshots to data points (newest first, so reverse for chart)
  final points = <PerformanceDataPoint>[];
  final reversed = snapshots.reversed.toList();
  
  for (int i = 0; i < reversed.length; i++) {
    final snap = reversed[i];
    final value = (snap['total_value'] as num?)?.toDouble() ?? 0.0;
    final dateStr = snap['saved_at'] as String?;
    final date = dateStr != null ? DateTime.tryParse(dateStr) ?? DateTime.now() : DateTime.now();
    
    points.add(PerformanceDataPoint(
      label: _formatDateLabel(date),
      value: value,
      date: date,
    ));
  }
  
  return points;
});

String _formatDateLabel(DateTime date) {
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}

/// Provider for lead count (for admin view)
final leadCountProvider = FutureProvider<int>((ref) async {
  final leads = await LocalStorageService.loadLeads();
  return leads.length;
});
