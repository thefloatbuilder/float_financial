import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../services/local_storage_service.dart';
import 'float_logo.dart';

/// Snapshot Comparison Widget 🛟
/// Lets Marcus pick two saved snapshots and see how the float drifted.
class SnapshotComparison extends StatefulWidget {
  const SnapshotComparison({super.key});

  @override
  State<SnapshotComparison> createState() => _SnapshotComparisonState();
}

class _SnapshotComparisonState extends State<SnapshotComparison> {
  List<Map<String, dynamic>> _snapshots = [];
  int? _aIdx;
  int? _bIdx;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snaps = await LocalStorageService.loadSnapshots();
    if (!mounted) return;
    setState(() {
      _snapshots = snaps;
      _loading = false;
      // Smart defaults: newest two
      if (snaps.length >= 2) {
        _aIdx = 1;
        _bIdx = 0;
      } else if (snaps.length == 1) {
        _aIdx = 0;
      }
    });
  }

  double _num(Map<String, dynamic> s, String key, [double fallback = 0]) {
    final v = s[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  String _fmtMoney(double v) {
    final abs = v.abs();
    if (abs >= 1000000) return '\$${(v / 1000000).toStringAsFixed(2)}M';
    if (abs >= 10000) return '\$${(v / 1000).toStringAsFixed(1)}k';
    return '\$${v.toStringAsFixed(0)}';
  }

  String _fmtDate(String? iso) {
    if (iso == null) return 'Unknown';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$mo/$d ${h}:$mi';
    } catch (_) {
      return iso.substring(0, iso.length > 16 ? 16 : iso.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurfaceAlt : AppColors.sand,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.moonlightSurface : Colors.grey[200]!,
        ),
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : _snapshots.isEmpty
              ? _buildEmpty(isDark)
              : _buildContent(isDark),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Snapshot History & Compare',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(width: 6),
            Text('🛟', style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'No snapshots saved yet. Hit "Save Snapshot" on Dashboard or Portfolio to start tracking your float over time. 🏖️',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    final a = _aIdx != null ? _snapshots[_aIdx!] : null;
    final b = _bIdx != null ? _snapshots[_bIdx!] : null;

    // Compute deltas (b minus a, i.e. newer minus older)
    double? dTotal, dYield, dChange;
    if (a != null && b != null) {
      dTotal = _num(b, 'total_value') - _num(a, 'total_value');
      dYield = _num(b, 'daily_yield_estimate_usd') - _num(a, 'daily_yield_estimate_usd');
      dChange = _num(b, 'monthly_change') - _num(a, 'monthly_change');
    }
    final netPositive = (dTotal ?? 0) >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Snapshot History & Compare',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_snapshots.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text('🛟', style: TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 14),

        // Pickers
        Row(
          children: [
            Expanded(
              child: _buildPicker(
                label: 'From (older) 🌅',
                value: _aIdx,
                isDark: isDark,
                onChanged: (v) => setState(() => _aIdx = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPicker(
                label: 'To (newer) 🌊',
                value: _bIdx,
                isDark: isDark,
                onChanged: (v) => setState(() => _bIdx = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Comparison
        if (a != null && b != null) ...[
          _row('Total Value',
              _fmtMoney(_num(a, 'total_value')),
              _fmtMoney(_num(b, 'total_value')),
              dTotal!, true, isDark),
          const SizedBox(height: 8),
          _row('Daily Yield',
              _fmtMoney(_num(a, 'daily_yield_estimate_usd')),
              _fmtMoney(_num(b, 'daily_yield_estimate_usd')),
              dYield!, true, isDark),
          const SizedBox(height: 8),
          _row(
              'Monthly Change',
              '${_num(a, 'monthly_change').toStringAsFixed(1)}%',
              '${_num(b, 'monthly_change').toStringAsFixed(1)}%',
              dChange!, false, isDark),
          const SizedBox(height: 16),

          // Verdict banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: netPositive
                    ? [AppColors.primaryTeal.withOpacity(0.15), Colors.green.withOpacity(0.08)]
                    : [Colors.red.withOpacity(0.12), Colors.orange.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: netPositive ? AppColors.primaryTeal.withOpacity(0.4) : Colors.red.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                FloatLogo(
                  size: 38,
                  animated: true,
                  showRipples: true,
                  showBubbles: false,
                  showExtraDecorations: false,
                  performance: netPositive ? 'positive' : 'negative',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        netPositive ? 'The float is riding higher! 🌊' : 'Slight chop on the water 🌬️',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        netPositive
                            ? 'Your portfolio grew ${_fmtMoney(dTotal.abs())} between these snapshots. Keep cruising. 🛟'
                            : 'Down ${_fmtMoney(dTotal.abs())} between snapshots. Drift happens — check your scopes. 🏝️',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.moonlightSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pick two snapshots above to compare them side-by-side 🛟',
              style: TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPicker({
    required String label,
    required int? value,
    required bool isDark,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.moonlightSurface : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              isDense: true,
              dropdownColor: isDark ? AppColors.moonlightSurface : Colors.white,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
              ),
              items: [
                for (int i = 0; i < _snapshots.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(
                      '${_fmtDate(_snapshots[i]['saved_at'] as String?)}  •  ${_fmtMoney(_num(_snapshots[i], 'total_value'))}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String aVal, String bVal, double delta, bool money, bool isDark) {
    final isUp = delta >= 0;
    final deltaColor = delta == 0
        ? (isDark ? Colors.white54 : Colors.grey)
        : (isUp ? Colors.green : Colors.red);
    final deltaStr = delta == 0
        ? '—'
        : '${isUp ? '+' : ''}${money ? _fmtMoney(delta.abs()).replaceFirst('\$', isUp ? '\$' : '-\$') : '${delta.abs().toStringAsFixed(1)}%'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              aVal,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              bVal,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              deltaStr,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: deltaColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
