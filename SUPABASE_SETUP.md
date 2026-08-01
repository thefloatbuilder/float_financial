# Supabase Production Setup

10-minute job once you have a Supabase project. Steps:

## 1. Create project

1. Go to https://supabase.com → New project (free tier is fine to start)
2. Copy your **Project URL** and **anon public key** (Settings → API)

## 2. Create tables

Run this in the Supabase SQL editor:

```sql
-- User profiles (extends Supabase auth.users)
create table profiles (
  id uuid references auth.users primary key,
  email text not null,
  name text,
  tier text default 'Drifter Deck',
  role text default 'client',
  created_at timestamptz default now()
);

-- Row-level security: users see only their own profile
alter table profiles enable row level security;
create policy "own profile" on profiles
  for all using (auth.uid() = id);

-- Portfolios
create table portfolios (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) not null,
  total_value numeric default 0,
  monthly_change numeric default 0,
  daily_yield_estimate_usd numeric default 0,
  bittensor_coldkey text,
  assets jsonb default '[]',
  roth_ira jsonb,
  updated_at timestamptz default now()
);
alter table portfolios enable row level security;
create policy "own portfolio" on portfolios
  for all using (auth.uid() = user_id);

-- Alerts
create table alerts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) not null,
  asset text not null,
  type text not null,
  condition text not null,
  is_active boolean default true,
  created_at timestamptz default now()
);
alter table alerts enable row level security;
create policy "own alerts" on alerts
  for all using (auth.uid() = user_id);
```

Admins (you) read all clients via the `profiles` table — set your own row's `role` to `'admin'` after signing up:

```sql
update profiles set role = 'admin' where email = 'your@email.com';
```

For admin cross-client reads, add a service-role key backend or an admin policy later. For launch, per-user RLS above is the safe default.

## 3. Enable email auth

Authentication → Providers → Email is on by default. For magic-link (passwordless) login, enable "Confirm email" off during early testing, on for real users.

## 4. Build with credentials

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

The release build refuses to start without these, so you can't accidentally ship demo mode.

## 5. Deploy

`build/web` is a static site — drop it on Cloudflare Pages, Netlify, Vercel, or Firebase Hosting. Add your domain in Supabase Auth → URL Configuration → Site URL + Redirect URLs.
