import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/uuid.dart';
import '../data/plan_model.dart';
import '../data/salidas_repository.dart';

// limites configurables del plan con su valor inicial y rango (06_REQUIREMENTS.md seccion 5)
enum LimitePlan {
  propuestas(
    'Máx. de lugares propuestos',
    'Propuestas que puede enviar cada participante',
    1,
    5,
    3,
  ),
  candidatos(
    'Máx. de candidatos',
    'Lugares en la lista final de votación',
    2,
    10,
    6,
  ),
  selecciones(
    'Máx. de selecciones',
    'Lugares que cada persona puede votar',
    1,
    5,
    3,
  ),
  actividades(
    'Máx. de actividades',
    'Lugares que pasan al itinerario',
    1,
    5,
    3,
  );

  const LimitePlan(
    this.titulo,
    this.descripcion,
    this.minimo,
    this.maximo,
    this.inicial,
  );

  final String titulo;
  final String descripcion;
  final int minimo;
  final int maximo;
  final int inicial;
}

class CrearPlanViewModel extends ChangeNotifier {
  CrearPlanViewModel(this._repositorio);

  final SalidasRepository _repositorio;

  // se genera una vez: reintentar el envio reutiliza el mismo id y no duplica el plan
  final String _planId = generarUuidV4();

  final Map<LimitePlan, int> _valores = {
    for (final limite in LimitePlan.values) limite: limite.inicial,
  };
  bool _enviando = false;
  String? _error;
  bool _desechado = false;

  bool get enviando => _enviando;
  String? get error => _error;

  int valor(LimitePlan limite) => _valores[limite]!;

  bool puedeBajar(LimitePlan limite) =>
      !_enviando && valor(limite) > limite.minimo;

  bool puedeSubir(LimitePlan limite) =>
      !_enviando && valor(limite) < limite.maximo;

  String? get errorLimites =>
      valor(LimitePlan.selecciones) > valor(LimitePlan.candidatos)
      ? MensajesError.seleccionesMayoresQueCandidatos
      : null;

  void bajar(LimitePlan limite) {
    if (!puedeBajar(limite)) return;
    _valores[limite] = valor(limite) - 1;
    notifyListeners();
  }

  void subir(LimitePlan limite) {
    if (!puedeSubir(limite)) return;
    _valores[limite] = valor(limite) + 1;
    notifyListeners();
  }

  // devuelve el plan solo cuando el servidor lo confirmo
  Future<PlanModel?> crear({
    required String nombre,
    required double presupuestoSoles,
  }) async {
    if (_enviando || errorLimites != null) return null;
    _enviando = true;
    _error = null;
    _notificar();
    try {
      return await _repositorio.crearPlan(
        NuevoPlan(
          id: _planId,
          nombre: nombre,
          presupuestoSoles: presupuestoSoles,
          maxPropuestas: valor(LimitePlan.propuestas),
          maxCandidatos: valor(LimitePlan.candidatos),
          maxSelecciones: valor(LimitePlan.selecciones),
          maxActividades: valor(LimitePlan.actividades),
        ),
      );
    } catch (error) {
      _error = error is AppException ? error.mensaje : MensajesError.generico;
      return null;
    } finally {
      _enviando = false;
      _notificar();
    }
  }

  void _notificar() {
    if (!_desechado) notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    super.dispose();
  }
}
