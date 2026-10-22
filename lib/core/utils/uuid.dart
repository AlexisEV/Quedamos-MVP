import 'dart:math';

final _aleatorio = Random.secure();

// uuid v4 generado en el dispositivo; evita una dependencia solo para esto
String generarUuidV4() {
  final bytes = List<int>.generate(16, (_) => _aleatorio.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
