# GREENLIT - Reports Coldkey Breakdown Helpers (Approved 2026-07-18)

## File to edit
lib/features/reports/reports_screen.dart

## Instructions
1. Add the two helper methods at the bottom of the _ReportsScreenState class (or as private methods in the widget).
2. Call _buildColdkeyBreakdown(context, portfolio) after the main bar chart section in the build method.
3. Make sure imports for FloatLogo and AnimatedNumber are present (they should already be).

## Code to paste (add the helpers)

Widget _buildColdkeyBreakdown(BuildContext context, Map<String, dynamic> data) {
  final monthlyChange = (data['monthly_change'] as num? ?? 0).toDouble();
  final perf = monthlyChange >= 0 ? 'positive' : 'negative';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          FloatLogo(
            size: 28,
            animated: false,
            showRipples: true,
            showBubbles: false,
            showExtraDecorations: false,
            performance: perf,
          ),
          const SizedBox(width: 8),
          Text(
            'Coldkey Yield Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildYieldRow(
        'Est. Daily from Coldkey',
        (data['coldkey_daily'] ?? 0.0) as double,
        perf == 'positive',
      ),
      _buildYieldRow(
        'Est. Monthly from Coldkey',
        (data['coldkey_monthly'] ?? 0.0) as double,
        perf == 'positive',
      ),
      _buildYieldRow(
        'Est. Annual from Coldkey',
        ((data['coldkey_monthly'] ?? 0.0) as double) * 12,
        perf == 'positive',
      ),
    ],
  );
}

Widget _buildYieldRow(String label, double value, bool isPositive) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        AnimatedNumber(
          value: value,
          prefix: '\$',
          suffix: isPositive ? ' ↑' : ' ↓',
          duration: const Duration(milliseconds: 580),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isPositive ? Colors.teal : Colors.redAccent,
          ),
        ),
      ],
    ),
  );
}

## Where to call it
After the bar chart section, add:
_buildColdkeyBreakdown(context, portfolio),

# End of greenlit patch


# GREENLIT 2 - Reports Refresh State + More AnimatedNumber (Approved 2026-07-18)

## File to edit
lib/features/reports/reports_screen.dart

## Changes (additive, minimal)

### 1. Add isRefreshing state (near top of build or as a local var / Riverpod if you prefer)
bool _isRefreshing = false;

### 2. Update the refresh button / action area
// Find the refresh button or the last synced row and replace/enhance:

IconButton(
  icon: _isRefreshing 
      ? SizedBox(
          width: 20, 
          height: 20, 
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
      : const Icon(Icons.refresh),
  onPressed: _isRefreshing ? null : () async {
    setState(() => _isRefreshing = true);
    try {
      await BittensorService.refreshColdkeyData(); // or your existing refresh
      ref.read(coldkeyLastSyncProvider.notifier).state = DateTime.now();
      ref.invalidate(portfolioProvider(user.id));
      // ... other invalidates
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  },
),

// Optional: Show subtle text
if (_isRefreshing)
  Text('Refreshing coldkey data...', style: TextStyle(fontSize: 12, color: Colors.grey)),

### 3. Replace more static values with AnimatedNumber
// Examples in the coldkey summary or other cards:

// Instead of:
// Text('\$${someValue.toStringAsFixed(2)}')

// Use:
AnimatedNumber(
  value: someValue,
  prefix: '\$',
  duration: const Duration(milliseconds: 580),
  curve: Curves.easeOutCubic,
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
),

// Do this for Est. Daily, Est. Monthly, any other number displays in the report.

### 4. File paths
Main: lib/features/reports/reports_screen.dart
Reuse: lib/shared/widgets/animated_number.dart
Data: from portfolioProvider / bittensor mock

# End of greenlit patch 2


# GREENLIT 3 - Snapshots Polish (Approved 2026-07-18)

## File to edit
lib/features/reports/reports_screen.dart

## Scope
Add AnimatedNumber + small performance-aware FloatLogo to the snapshots list items.
Keep it additive and consistent with previous greenlit helpers.

## Exact changes

### Find the snapshots list section (after the bar chart / coldkey breakdown)
Look for something like:
ListView.builder or Column of snapshot cards/tiles.
(From current code pattern: a list of snapshot items showing values.)

### Replace each snapshot value display with:

Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          snapshot['label'] ?? 'Snapshot',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        AnimatedNumber(
          value: (snapshot['value'] as num?)?.toDouble() ?? 0.0,
          prefix: '\$',
          duration: const Duration(milliseconds: 580),
          curve: Curves.easeOutCubic,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
    FloatLogo(
      size: 24,
      animated: false,
      showRipples: true,
      showBubbles: false,
      showExtraDecorations: false,
      performance: ((snapshot['change'] as num?)?.toDouble() ?? 0) >= 0 
          ? 'positive' 
          : 'negative',
    ),
  ],
),

### Notes
- Assumes snapshot data has 'value' and 'change' (or adapt keys to your mock: e.g. 'monthly_yield', 'change').
- Reuse the same performance logic as the coldkey header.
- This makes snapshots feel alive and tied to the same visual language.

# End of GREENLIT 3
