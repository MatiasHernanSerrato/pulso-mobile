import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ble_permissions.dart';
import '../application/scan_controller.dart';
import '../domain/discovered_scale.dart';

/// Pantalla para buscar balanzas cercanas. Entrada desde Salud ->
/// "Conectar balanza". No esta linkeada al router todavia porque
/// primero quiero probar el flow a mano con el launcher.
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  bool _onlyWeightScales = true;
  bool _permissionsOk = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final status = await ref.read(blePermissionsProvider).request();
    switch (status) {
      case BlePermissionStatus.granted:
        setState(() => _permissionsOk = true);
        _startScan();
      case BlePermissionStatus.denied:
        setState(() => _permissionError =
            'Necesitamos permisos de Bluetooth para buscar balanzas.');
      case BlePermissionStatus.permanentlyDenied:
        setState(() => _permissionError =
            'Habilitá Bluetooth y permisos desde Ajustes.');
      case BlePermissionStatus.bluetoothOff:
        setState(() =>
            _permissionError = 'Prendé el Bluetooth y volvé a intentar.');
      case BlePermissionStatus.unsupported:
        setState(() => _permissionError =
            'Este dispositivo no tiene Bluetooth Low Energy.');
    }
  }

  void _startScan() {
    ref.read(scanControllerProvider.notifier).start(
          onlyWeightScales: _onlyWeightScales,
        );
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar balanza'),
        actions: [
          if (scan.scanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _permissionsOk ? _startScan : null,
              icon: const Icon(Icons.refresh),
              tooltip: 'Volver a escanear',
            ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Solo balanzas estándar'),
            subtitle: const Text(
                'Filtra por el servicio Weight Scale (0x181D).'),
            value: _onlyWeightScales,
            onChanged: (v) {
              setState(() => _onlyWeightScales = v);
              if (_permissionsOk) _startScan();
            },
          ),
          if (_permissionError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _PermissionCard(
                message: _permissionError!,
                onRetry: _bootstrap,
              ),
            ),
          Expanded(
            child: scan.devices.isEmpty
                ? _EmptyState(scanning: scan.scanning)
                : ListView.separated(
                    itemCount: scan.devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (_, i) => _DeviceTile(
                      device: scan.devices[i],
                      onTap: () {
                        Navigator.of(context).pop(scan.devices[i]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onTap});
  final DiscoveredScale device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        device.advertisesWeightScaleService
            ? Icons.monitor_weight_outlined
            : Icons.bluetooth,
      ),
      title: Text(device.displayName),
      subtitle: Text('${device.rssi} dBm · ${device.id}'),
      trailing: _SignalBars(rssi: device.rssi),
      onTap: onTap,
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.rssi});
  final int rssi;

  int get _level {
    // RSSI tipico va de -40 (cerca) a -100 (muy lejos). Mapeamos a
    // 4 barritas.
    if (rssi >= -55) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final filled = i < _level;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 4,
            height: 6 + i * 4.0,
            decoration: BoxDecoration(
              color: filled ? color : color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scanning});
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              scanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              scanning
                  ? 'Buscando balanzas cercanas...'
                  : 'No encontramos nada todavia.\nPará arriba de la balanza para activarla.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
