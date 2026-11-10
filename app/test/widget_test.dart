import 'package:acupoints/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('застосунок запускається', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AcupointsApp()));

    expect(find.text('Точки надавлювання'), findsOneWidget);
  });
}
