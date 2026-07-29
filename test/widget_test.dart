import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medreminder/services/storage_service.dart';
import 'package:medreminder/app/app.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('Splash screen shows app name and loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedCareApp());

    // Verify that the splash screen shows the app name.
    expect(find.text('MedCare+'), findsOneWidget);

    // Advance the splash duration timer (2.5 seconds) to allow navigation to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
