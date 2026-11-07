import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulso_mobile/main.dart';

void main() {
  testWidgets('app arranca y muestra bottom nav con 4 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PulsoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Salud'), findsOneWidget);
    expect(find.text('Plata'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
