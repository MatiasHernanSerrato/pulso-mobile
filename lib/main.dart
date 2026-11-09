import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_mode_controller.dart';

void main() {
  runApp(const ProviderScope(child: PulsoApp()));
}

class PulsoApp extends ConsumerWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Pulso',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      routerConfig: router,
    );
  }
}
