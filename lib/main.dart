import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_mode_controller.dart';

void main() {
  // preservo el splash nativo hasta que el primer frame de flutter
  // este listo. Si no, parpadea entre el splash y la pantalla en
  // blanco mientras arranca el engine.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  runApp(const ProviderScope(child: PulsoApp()));
}

class PulsoApp extends ConsumerStatefulWidget {
  const PulsoApp({super.key});

  @override
  ConsumerState<PulsoApp> createState() => _PulsoAppState();
}

class _PulsoAppState extends ConsumerState<PulsoApp> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
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
