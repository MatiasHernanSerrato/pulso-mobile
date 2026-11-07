import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulso_mobile/main.dart';

void main() {
  testWidgets('app arranca y muestra el placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const PulsoApp());

    expect(find.text('Pulso'), findsOneWidget);
    expect(find.text('arrancando'), findsOneWidget);
  });
}
