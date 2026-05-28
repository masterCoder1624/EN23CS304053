import 'package:flutter_test/flutter_test.dart';
import 'package:clarifi_ai/main.dart';

void main() {
  testWidgets('App renders bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(const InsightHubApp());

    // Verify the bottom nav items exist
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });
}
