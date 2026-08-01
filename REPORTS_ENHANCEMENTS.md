# Reports Enhancements (Marcus Parallel Track)

## Goal
Flesh out the Reports screen with more coldkey-driven visuals, polish, and dynamic elements while Kevin handles the animated counters + reactive ripples on Dashboard/Portfolio.

## Scope (keep scoped)
- Add more prominent "Coldkey Performance" sections with motifs.
- Improve bar chart to better reflect coldkey monthly yield.
- Add live "Coldkey drives X% of yield" callout with FloatLogo.
- Enhance snapshots with AnimatedNumber where not already.
- Add subtle performance-based theming (use existing performance prop logic).
- Ensure consistency with FloatHeader and motifs.

## Key Files to Touch
- lib/features/reports/reports_screen.dart (main work)
- Possibly tie into portfolio_provider.dart or bittensor_service.dart for data (minimal)
- Reuse lib/shared/widgets/animated_number.dart and float_logo.dart

## Specific Ideas to Implement
1. Above the bar chart, add a big "Coldkey Total" with AnimatedNumber and small FloatLogo that reacts to monthly_change.
2. Bar chart labels: "Est. Monthly from Coldkey", "Other Assets".
3. Add a section: "Coldkey Yield Breakdown" with rows using AnimatedNumber for daily/est monthly/annual.
4. "● live" indicator next to last synced.
5. If monthly_change positive, use positive performance on FloatLogo instances in reports.
6. Add a small note: "Coldkey (5EFcnuz...) drives ~92% of your yield"

## Next Steps After This
- Once Kevin delivers Dashboard/Portfolio changes, integrate if needed.
- Then move to testing or next feature.

Deliver clean code patches when ready.
