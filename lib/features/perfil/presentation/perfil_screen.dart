import 'package:flutter/material.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Invitado'),
            subtitle: Text('todavia no iniciaste sesion'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.bluetooth),
            title: Text('Balanzas conectadas'),
            subtitle: Text('ninguna'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Alertas'),
            subtitle: Text('activadas'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Acerca de'),
            subtitle: Text('Pulso v0.1.0'),
          ),
        ],
      ),
    );
  }
}
