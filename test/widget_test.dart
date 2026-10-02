import 'package:flutter_test/flutter_test.dart';

import 'package:solace/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    expect(const SolaceApp(), isNotNull);
  });
}
