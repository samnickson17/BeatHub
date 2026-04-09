# BeatHub Supabase Setup

This project is now wired to Supabase in Flutter.

## 1) Create Supabase project

1. Create a new Supabase project.
2. Copy:
   - Project URL
   - anon/public API key

## 2) Apply database/storage migration

1. Install Supabase CLI and login.
2. Link project:

```bash
supabase link --project-ref <your-project-ref>
```

3. Push schema:

```bash
supabase db push
```

Migration file:
- supabase/migrations/202604090001_initial_beathub_schema.sql

## 3) Configure Google Auth provider in Supabase

1. In Supabase dashboard, go to Auth -> Providers -> Google.
2. Enable Google provider.
3. Add Google OAuth client ID + secret.
4. Add redirect URL from Supabase provider page into Google Cloud Console.

## 4) Run app

This repo now includes default Supabase project URL + anon key in
`lib/core/supabase_config.dart`, so `flutter run` works without passing them.

Use dart defines only when you want to override defaults (for another project
or environment):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=SUPABASE_GOOGLE_SERVER_CLIENT_ID=<google-web-client-id> \
  --dart-define=SUPABASE_GOOGLE_CLIENT_ID=<google-platform-client-id-if-needed>
```

For release builds, pass the same defines in your CI/build pipeline.

## 5) Optional cleanup

These Firebase files are no longer required by runtime:
- firebase.json
- firestore.rules
- storage.rules
- google-services.json
- android/app/google-services.json
- android/app/google-services (1).json
- set_cors.mjs

Keep them only if you need rollback.
