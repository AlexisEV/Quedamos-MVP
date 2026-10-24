import 'dart:async';

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/perfil/data/perfil_model.dart';
import 'package:app/features/perfil/data/perfil_repository.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';

// repositorio de auth en memoria; error define la falla de la siguiente llamada
class FakeAuthRepository implements AuthRepository {
  AppException? error;
  Completer<void>? pendiente;
  final llamadas = <String>[];

  @override
  bool haySesion = false;

  @override
  Stream<bool> get cambiosDeSesion => const Stream.empty();

  Future<void> _responder(String llamada) async {
    llamadas.add(llamada);
    if (pendiente != null) await pendiente!.future;
    final falla = error;
    if (falla != null) throw falla;
  }

  @override
  Future<void> registrar({
    required String nombreVisible,
    required String correo,
    required String contrasena,
  }) => _responder('registrar:$nombreVisible:$correo');

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) => _responder('iniciarSesion:$correo');

  @override
  Future<void> cerrarSesion() => _responder('cerrarSesion');
}

class FakePerfilRepository implements PerfilRepository {
  FakePerfilRepository(this.perfil);

  PerfilModel perfil;
  AppException? error;

  @override
  Future<PerfilModel> obtenerPerfilPropio() async {
    final falla = error;
    if (falla != null) throw falla;
    return perfil;
  }

  @override
  Future<PerfilModel> actualizarNombreVisible(String nombreVisible) async {
    final falla = error;
    if (falla != null) throw falla;
    perfil = perfil.copyWith(nombreVisible: nombreVisible.trim());
    return perfil;
  }
}

PlanModel planDePrueba({
  String id = 'p1',
  String nombre = 'Sábado en Yanahuara',
  EstadoPlan estado = EstadoPlan.recibiendoPropuestas,
  DateTime? createdAt,
}) {
  return PlanModel(
    id: id,
    nombre: nombre,
    estado: estado,
    presupuestoSoles: 70,
    maxPropuestasPorPersona: 3,
    maxCandidatos: 6,
    maxSelecciones: 3,
    maxActividades: 3,
    codigoInvitacion: 'AQP48X',
    creadoPor: 'u1',
    createdAt: createdAt ?? DateTime.utc(2026, 10, 22),
  );
}

// repositorio de salidas en memoria; crearPlan y unirseConCodigo son idempotentes como las rpc
class FakeSalidasRepository implements SalidasRepository {
  final salidas = <SalidaModel>[];
  final creados = <NuevoPlan>[];
  // planes a los que se puede unir por codigo; los cancelados son invalidos
  final planesPorCodigo = <String, PlanModel>{};
  final codigosEnviados = <String>[];
  AppException? error;
  final _cambios = StreamController<void>.broadcast();

  @override
  Stream<void> get cambios => _cambios.stream;

  @override
  Future<List<SalidaModel>> obtenerMisSalidas() async {
    final falla = error;
    if (falla != null) throw falla;
    return List.of(salidas);
  }

  @override
  Future<SalidaModel?> obtenerSalida(String planId) async {
    final falla = error;
    if (falla != null) throw falla;
    for (final salida in salidas) {
      if (salida.plan.id == planId) return salida;
    }
    return null;
  }

  @override
  Future<PlanModel> crearPlan(NuevoPlan nuevo) async {
    creados.add(nuevo);
    final falla = error;
    if (falla != null) throw falla;
    final existente = await obtenerSalida(nuevo.id);
    if (existente != null) return existente.plan;
    final plan = planDePrueba(id: nuevo.id, nombre: nuevo.nombre.trim());
    salidas.add(
      SalidaModel(
        plan: plan,
        miRol: RolPlan.administrador,
        esCreador: true,
        totalParticipantes: 1,
      ),
    );
    _cambios.add(null);
    return plan;
  }

  @override
  Future<ResultadoUnion> unirseConCodigo(String codigo) async {
    final normalizado = codigo.trim().toUpperCase();
    codigosEnviados.add(normalizado);
    final falla = error;
    if (falla != null) throw falla;
    final plan = planesPorCodigo[normalizado];
    if (plan == null || plan.estado == EstadoPlan.cancelado) {
      throw const AppException(MensajesError.codigoInvalido);
    }
    final existente = await obtenerSalida(plan.id);
    if (existente != null) {
      return ResultadoUnion(planId: plan.id, yaParticipaba: true);
    }
    salidas.add(
      SalidaModel(
        plan: plan,
        miRol: RolPlan.participante,
        esCreador: false,
        totalParticipantes: 2,
      ),
    );
    _cambios.add(null);
    return ResultadoUnion(planId: plan.id, yaParticipaba: false);
  }
}
