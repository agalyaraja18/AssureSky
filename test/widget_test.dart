import 'package:flutter_test/flutter_test.dart';
import 'package:assuresky/main.dart';

void main() {
  testWidgets('AssureSky app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AssureSkyApp());
    expect(find.text('AssureSky'), findsWidgets);
  });
}
