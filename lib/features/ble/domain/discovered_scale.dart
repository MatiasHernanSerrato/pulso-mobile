/// Un device que aparecio en el scan y que pensamos que puede ser
/// una balanza. No es necesariamente una: el filtro final lo hacemos
/// cuando conectamos y descubrimos servicios.
class DiscoveredScale {
  const DiscoveredScale({
    required this.id,
    required this.name,
    required this.rssi,
    required this.advertisedAt,
    this.advertisesWeightScaleService = false,
  });

  /// El remoteId (MAC en Android, UUID opaco en iOS). Lo usamos como
  /// key en la lista y para reconectar despues.
  final String id;

  /// El advertised name. A veces viene vacio ("" no null) cuando el
  /// device no advierte localName, ahi caemos al id.
  final String name;

  /// Signal strength en dBm. Lo mostramos como barritas para ayudar
  /// al usuario a saber cual de todas las balanzas de la casa agarra.
  final int rssi;

  /// Momento del ultimo advertisement. Lo uso para sacar de la lista
  /// los que dejaron de advertir hace mucho (balanzas que se duermen).
  final DateTime advertisedAt;

  /// Si el advertisement incluia el service UUID 0x181D (Weight Scale).
  /// Las balanzas BLE estandar lo advierten, las de marca random no.
  /// En la UI marcamos con un icono distinto las que si.
  final bool advertisesWeightScaleService;

  String get displayName => name.isEmpty ? id : name;

  DiscoveredScale copyWith({
    int? rssi,
    DateTime? advertisedAt,
    bool? advertisesWeightScaleService,
  }) {
    return DiscoveredScale(
      id: id,
      name: name,
      rssi: rssi ?? this.rssi,
      advertisedAt: advertisedAt ?? this.advertisedAt,
      advertisesWeightScaleService:
          advertisesWeightScaleService ?? this.advertisesWeightScaleService,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DiscoveredScale && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
