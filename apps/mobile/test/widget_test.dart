import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentos_mobile/main.dart';

void main() {
  testWidgets('App boots and shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ParentOSApp()));
    await tester.pumpAndSettle();

    expect(find.text('ParentOS'), findsOneWidget);
  });
}
