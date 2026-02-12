import 'package:flutter_test/flutter_test.dart';
import 'package:goatpad/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches and displays text editor', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(GoatPadApp(prefs: prefs));

    expect(find.text('GoatPad'), findsOneWidget);
    expect(find.text('Start typing or open a file...'), findsOneWidget);
  });
}
