import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';

void main() {
  runApp(const ProviderScope(child: PulsoApp()));
}

class PulsoApp extends ConsumerWidget {
  const PulsoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Pulso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2EC4B6)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
