import 'package:flutter/material.dart';

class SaludScreen extends StatelessWidget {
  const SaludScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salud')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aca vamos a mostrar peso, grasa corporal y tendencia. Falta conectar la balanza.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Cargar peso'),
      ),
    );
  }
}
