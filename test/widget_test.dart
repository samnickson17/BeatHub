import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:beathub_final/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  testWidgets('Shows login screen when no active session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BeatHubApp());
    await tester.pumpAndSettle();

    expect(find.text('BeatHub'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
