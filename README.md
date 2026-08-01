# Float Financial

Your Portfolio, On Cruise Mode. Pool-float themed crypto portfolio tracker for Bittensor/ETH yield, with Sunlight/Moonlight themes, AI agents, alerts, reports, and an admin console.

## Quick start (demo mode)

```bash
flutter pub get
flutter run -d chrome
```

No credentials needed — the app runs with realistic mock data and shows a **DEMO MODE** banner on the login screen.

## Production build

Requires a Supabase project (see [SUPABASE_SETUP.md](SUPABASE_SETUP.md)):

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Release builds **refuse to start** without real credentials — a demo build can never ship by accident.

Serve locally:

```bash
cd build/web && python3 -m http.server 8080
```

## Stack

Flutter web · Riverpod · go_router · Supabase (auth + Postgres) · Hive (local storage) · fl_chart
