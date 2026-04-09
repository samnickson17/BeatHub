class SupabaseConfig {
  // Repo default project values for local/dev convenience.
  // Still overridable with --dart-define.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://whudrczapcecsqescjku.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndodWRyY3phcGNlY3NxZXNjamt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjQzOTYsImV4cCI6MjA5MTMwMDM5Nn0.PJHcvULq96EAy7EOG1zcGwr0FiW1hbcaeUU7oKC3DSE',
  );

  // Defaults come from android/app/google-services.json.
  // They can still be overridden with --dart-define at runtime.
  // client_type=1 (Android), useful for native clientId where supported.
  static const String googleClientId = String.fromEnvironment(
    'SUPABASE_GOOGLE_CLIENT_ID',
    defaultValue:
        '1037602740027-m7v3rqi4ljfaipcreb4aq13pv32sir8r.apps.googleusercontent.com',
  );

  // client_type=3 (Web), required by google_sign_in_web.
  static const String googleWebClientId = String.fromEnvironment(
    'SUPABASE_GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1037602740027-7ctkskvqpdkmgfgl8u6qivob2nphfcl0.apps.googleusercontent.com',
  );

  // For Android native sign-in ID token exchange, this should be Web OAuth ID.
  static const String googleServerClientId = String.fromEnvironment(
    'SUPABASE_GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1037602740027-7ctkskvqpdkmgfgl8u6qivob2nphfcl0.apps.googleusercontent.com',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
