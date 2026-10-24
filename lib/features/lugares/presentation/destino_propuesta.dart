import 'package:flutter/foundation.dart';

import '../../salidas/data/plan_model.dart';

// plan destino elegido para proponer; vive en memoria y se limpia al cerrar sesion
class DestinoPropuesta extends ChangeNotifier {
  String? _planId;
  String? _nombrePlan;

  String? get planId => _planId;
  String? get nombrePlan => _nombrePlan;
  bool get hayDestino => _planId != null;

  void fijar(PlanModel plan) {
    if (_planId == plan.id && _nombrePlan == plan.nombre) return;
    _planId = plan.id;
    _nombrePlan = plan.nombre;
    notifyListeners();
  }

  void limpiar() {
    if (_planId == null) return;
    _planId = null;
    _nombrePlan = null;
    notifyListeners();
  }
}
