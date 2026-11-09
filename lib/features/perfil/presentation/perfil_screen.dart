import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme_mode_controller.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Invitado'),
            subtitle: Text('todavia no iniciaste sesion'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Balanzas conectadas'),
            subtitle: Text('ninguna'),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Alertas'),
            subtitle: Text('activadas'),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Tema'),
            subtitle: Text(_labelFor(mode)),
            trailing: PopupMenuButton<ThemeMode>(
              initialValue: mode,
              onSelected: (m) =>
                  ref.read(themeModeProvider.notifier).set(m),
              itemBuilder: (_) => const [
                PopupMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
                PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
              ],
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Acerca de'),
            subtitle: Text('Pulso v0.1.0'),
          ),
        ],
      ),
    );
  }

  String _labelFor(ThemeMode m) => switch (m) {
        ThemeMode.system => 'segun el sistema',
        ThemeMode.light => 'claro',
        ThemeMode.dark => 'oscuro',
      };
}
