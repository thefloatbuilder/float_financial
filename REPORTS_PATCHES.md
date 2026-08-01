# Reports Enhancements - Starter Patches (Marcus Track)

## 1. Add reactive FloatLogo + AnimatedNumber to Coldkey Header

In reports_screen.dart, around the main coldkey summary card:

Replace the static total with:
```dart
FloatLogo(
  size: 48,
  performance: monthlyChange >= 0 ? 'positive' : 'negative',
),
Text('Coldkey Total'),
AnimatedNumber(
  value: coldkeyTotal,
  prefix: '\$',
  duration: Duration(milliseconds: 620),
  curve: Curves.easeOutExpo,
  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
    fontWeight: FontWeight.w700,
  ),
),
```

## 2. Make Bar Chart more coldkey-specific

Update the fl_chart BarChart:
- Series 1: "Coldkey Est. Monthly" (use daily_yield_estimate_usd * ~30)
- Series 2: "Other Yield"

Add label: "Coldkey drives ~92% of your portfolio yield"

## 3. Coldkey Yield Breakdown section

Add after the chart:
Column(
  children: [
    _buildYieldRow('Daily from Coldkey', dailyFromColdkey, isPositive),
    _buildYieldRow('Est. Monthly from Coldkey', monthlyFromColdkey, isPositive),
    _buildYieldRow('Est. Annual from Coldkey', annualFromColdkey, isPositive),
  ],
)

Use AnimatedNumber in each row.

## 4. Last Synced Polish

Row(
  children: [
    Text('Last synced: $lastSynced'),
    if (justRefreshed) Text('  ● live', style: TextStyle(color: Colors.green)),
    IconButton(onPressed: refresh, icon: Icon(Icons.refresh)),
  ],
)

## Additional Reports Polish (Marcus Parallel Continuation)

### 5. Performance-aware FloatLogo in snapshots and breakdown
In the snapshots section and yield breakdown, pass performance based on overall monthly_change:
```dart
FloatLogo(
  size: 32,
  performance: (portfolioData['monthly_change'] ?? 0) >= 0 ? 'positive' : 'negative',
  showExtraDecorations: false,
),
```

### 6. Use AnimatedNumber for all value displays in Reports
Replace static Text for:
- Coldkey Total
- Est. Daily / Monthly / Annual
- Snapshot values

Example:
AnimatedNumber(
  value: value,
  prefix: '\$',
  suffix: ' /mo',
  duration: const Duration(milliseconds: 650),
  curve: Curves.easeOutQuart,
  style: ..., 
)

### 7. Add subtle "Refreshing..." state
When refresh is triggered:
- Show a small loading indicator next to the refresh button.
- Disable the button temporarily.
- After data updates, show "Updated just now" briefly.

Use a ValueNotifier or Riverpod state for isRefreshing.

### 8. File paths for these changes
Main file: lib/features/reports/reports_screen.dart
Reuse: lib/shared/widgets/animated_number.dart and float_logo.dart
Data: from providers (portfolioProvider or bittensor service mock)

These are ready-to-adapt patches. Keep the style consistent with Sunlight theme and existing motifs.


## Full Example Patch for reports_screen.dart (additive, not full rewrite)

# Find the coldkey header section and replace/enhance the total display
# Around line where coldkey total is shown:

// Before (example static):
// Text('\$${coldkeyTotal.toStringAsFixed(0)}', style: ... )

// After:
FloatLogo(
  size: 52,
  performance: (coldkeyMonthlyChange ?? 0) >= 0 ? 'positive' : 'negative',
),
const SizedBox(height: 8),
AnimatedNumber(
  value: coldkeyTotal,
  prefix: '\$',
  duration: const Duration(milliseconds: 650),
  curve: Curves.easeOutExpo,
  style: Theme.of(context).textTheme.displaySmall?.copyWith(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).colorScheme.onSurface,
  ),
),
Text('Coldkey Portfolio Value', style: Theme.of(context).textTheme.bodySmall),

# In the bar chart data section, make it coldkey-focused:
final coldkeyMonthly = (portfolio['coldkey_monthly_yield'] ?? 0.0) as double;
final otherMonthly = (portfolio['other_monthly_yield'] ?? 0.0) as double;

BarChartData(
  barGroups: [
    BarChartGroupData(x: 0, barRods: [
      BarChartRodData(toY: coldkeyMonthly, color: Colors.teal, width: 18),
    ]),
    BarChartGroupData(x: 1, barRods: [
      BarChartRodData(toY: otherMonthly, color: Colors.grey, width: 18),
    ]),
  ],
)

# Add this widget somewhere after the chart:
Widget _buildColdkeyBreakdown(BuildContext context, Map<String, dynamic> data) {
  final change = (data['monthly_change'] ?? 0.0) as double;
  final perf = change >= 0 ? 'positive' : 'negative';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          FloatLogo(size: 28, performance: perf, showExtraDecorations: false),
          const SizedBox(width: 8),
          const Text('Coldkey Yield Breakdown', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      const SizedBox(height: 12),
      _buildYieldRow('Est. Daily', data['coldkey_daily'] ?? 0.0, perf == 'positive'),
      _buildYieldRow('Est. Monthly', data['coldkey_monthly'] ?? 0.0, perf == 'positive'),
      _buildYieldRow('Est. Annual', (data['coldkey_monthly'] ?? 0.0) * 12, perf == 'positive'),
    ],
  );
}

# Call it in the build method after the main chart.
# Ensure you import the widgets:
# import '../../shared/widgets/animated_number.dart';
# import '../../shared/widgets/float_logo.dart';

# For the last synced:
Text('Last synced: ${lastSyncTime}', style: TextStyle(fontSize: 11, color: Colors.grey)),
if (justUpdated) 
  const Text(' • just now', style: TextStyle(fontSize: 11, color: Colors.green)),


## 9. Snapshots with AnimatedNumber + reactive motif
For each snapshot card in the list:

Instead of static values:
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Est. Monthly Yield', style: Theme.of(context).textTheme.bodySmall),
          AnimatedNumber(
            value: snapshot['monthly_yield'] ?? 0.0,
            prefix: '\$',
            duration: const Duration(milliseconds: 580),
            curve: Curves.easeOutCubic,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
    FloatLogo(
      size: 26,
      performance: (snapshot['change'] ?? 0) >= 0 ? 'positive' : 'negative',
      showExtraDecorations: false,
    ),
  ],
)

This keeps the visual language consistent while Kevin handles the main dashboard/portfolio totals.


## 10. Quick integration note
- Pull monthly_change / coldkey data from the same source used in dashboard/portfolio (portfolioProvider or bittensor mock).
- Pass the performance string consistently so ripples match across screens once Kevin's changes land.
- After applying, run flutter run -d windows to test the numbers and logos.
- These patches are additive — drop them into the existing _buildColdkeyHeader, chart data, and snapshot list builders.

Keep the Sunlight theme and existing motifs (🌊 etc.) for consistency.


## 11. Full _buildColdkeyBreakdown helper (ready to paste)
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

## 12. Example _buildYieldRow helper (add if not present)
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

## Next proposed step (greenlight requested)
Add the above two helpers + call _buildColdkeyBreakdown after the bar chart in reports_screen.dart.
This is low-risk additive code using only existing widgets and data already in the mocks.



## Next Proposed Greenlight Item (Marcus Parallel - Reports)

### 13. Snapshots polish with AnimatedNumber + performance motif
In the snapshots list (after the bar chart / breakdown):

For each snapshot item, ensure:
- Value uses AnimatedNumber
- Small FloatLogo with performance based on change
- Consistent styling

Example addition:
AnimatedNumber(
  value: snapshotValue,
  prefix: '\$',
  duration: const Duration(milliseconds: 520),
  curve: Curves.easeOut,
  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
),

FloatLogo(size: 20, performance: change >= 0 ? 'positive' : 'negative', showExtraDecorations: false),

This keeps everything feeling alive and on-brand.

Greenlight to add this section + example code to the patches?

