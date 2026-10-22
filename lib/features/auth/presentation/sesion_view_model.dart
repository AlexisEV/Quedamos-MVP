import 'dart:async';

import 'package:flutter/foundation.dart';

// estado global de sesion; el router lo escucha para redirigir
class SesionViewModel extends ChangeNotifier {
  SesionViewModel({
    required bool haySesionInicial,
    required Stream<bool> cambiosDeSesion,
  }) : _haySesion = haySesionInicial {
    _suscripcion = cambiosDeSesion.listen(_actualizar);
  }

  late final StreamSubscription<bool> _suscripcion;
  bool _haySesion;

  bool get haySesion => _haySesion;

  void _actualizar(bool haySesion) {
    if (haySesion == _haySesion) return;
    _haySesion = haySesion;
    notifyListeners();
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }
}
