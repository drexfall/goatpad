import 'package:flutter_test/flutter_test.dart';
import 'package:goatpad/main.dart';

void main() {
  testWidgets('App launches and displays text editor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GoatPadApp());

    expect(find.text('GoatPad'), findsOneWidget);
    expect(find.text('Start typing...'), findsOneWidget);
  });
}
