import 'dart:async';

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/lugares/data/lugares_repository.dart';
import 'package:app/features/lugares/data/propuesta_model.dart';
import 'package:app/features/lugares/data/propuestas_repository.dart';
import 'package:app/features/perfil/data/perfil_model.dart';
import 'package:app/features/perfil/data/perfil_repository.dart';
import 'package:app/features/salidas/data/participante_model.dart';
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
  // integrantes por plan; nombrarAdministrador cambia el rol como la rpc
  final participantesPorPlan = <String, List<ParticipanteModel>>{};
  final nombrados = <String>[];
  AppException? errorNombrar;

  @override
  String? usuarioActualId = 'u1';
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

  @override
  Future<List<ParticipanteModel>> obtenerParticipantes(String planId) async {
    final falla = error;
    if (falla != null) throw falla;
    return List.of(participantesPorPlan[planId] ?? const [])
      ..sort(ParticipanteModel.comparar);
  }

  @override
  Future<void> nombrarAdministrador({
    required String planId,
    required String perfilId,
  }) async {
    nombrados.add(perfilId);
    final falla = errorNombrar;
    if (falla != null) throw falla;
    final lista = participantesPorPlan[planId] ?? [];
    final indice = lista.indexWhere((p) => p.perfilId == perfilId);
    if (indice < 0) {
      throw const AppException(MensajesError.participanteNoEncontrado);
    }
    final actual = lista[indice];
    lista[indice] = ParticipanteModel(
      perfilId: actual.perfilId,
      nombreVisible: actual.nombreVisible,
      rol: RolPlan.administrador,
      esCreador: actual.esCreador,
      unidoEn: actual.unidoEn,
    );
  }
}

ParticipanteModel participanteDePrueba(
  String perfilId, {
  RolPlan rol = RolPlan.participante,
  bool esCreador = false,
  int minuto = 0,
}) {
  return ParticipanteModel(
    perfilId: perfilId,
    nombreVisible: 'Persona $perfilId',
    rol: rol,
    esCreador: esCreador,
    unidoEn: DateTime.utc(2026, 10, 22, 12, minuto),
  );
}

// catalogo en memoria; solo contiene lugares publicados, como los devuelve rls
class FakeLugaresRepository implements LugaresRepository {
  FakeLugaresRepository([List<LugarModel>? lugares]) : lugares = lugares ?? [];

  final List<LugarModel> lugares;
  AppException? error;

  @override
  Future<List<LugarModel>> obtenerLugares() async {
    final falla = error;
    if (falla != null) throw falla;
    return List.of(lugares)..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  @override
  Future<LugarModel?> obtenerLugar(String lugarId) async {
    final falla = error;
    if (falla != null) throw falla;
    for (final lugar in lugares) {
      if (lugar.id == lugarId) return lugar;
    }
    return null;
  }
}

LugarModel lugarDePrueba({
  String id = 'l1',
  String nombre = 'Lugar de prueba',
  CategoriaLugar categoria = CategoriaLugar.restaurantes,
  ZonaLugar zona = ZonaLugar.yanahuara,
  String? direccion,
  String? horarioAtencion,
  double? precioEstimadoPen,
  String? precioNota,
}) {
  return LugarModel(
    id: id,
    nombre: nombre,
    categoria: categoria,
    zona: zona,
    direccion: direccion,
    horarioAtencion: horarioAtencion,
    precioEstimadoPen: precioEstimadoPen,
    precioNota: precioNota,
  );
}

// propuestas en memoria con las reglas de proponer_lugar y retirar_propuesta
class FakePropuestasRepository implements PropuestasRepository {
  FakePropuestasRepository({
    List<SalidaModel>? salidas,
    this.lugares = const {},
  }) : salidas = salidas ?? [];

  // salidas del usuario actual; solo las que reciben propuestas son destinos
  final List<SalidaModel> salidas;
  // nombre de cada lugar publicado del catalogo por id
  final Map<String, String> lugares;
  final propuestas = <PropuestaModel>[];
  final llamadasProponer = <String>[];
  AppException? error;
  AppException? errorProponer;
  AppException? errorRetirar;
  final _cambios = StreamController<String>.broadcast();

  @override
  String? usuarioActualId = 'u1';

  @override
  Stream<String> get cambios => _cambios.stream;

  @override
  Future<List<PropuestaModel>> obtenerPropuestas(String planId) async {
    final falla = error;
    if (falla != null) throw falla;
    return propuestas.where((p) => p.planId == planId).toList();
  }

  @override
  Future<List<DestinoPlan>> obtenerDestinos() async {
    final falla = error;
    if (falla != null) throw falla;
    return [
      for (final salida in salidas)
        if (salida.plan.estado == EstadoPlan.recibiendoPropuestas)
          DestinoPlan(
            salida: salida,
            misPropuestas: propuestas
                .where(
                  (p) =>
                      p.planId == salida.plan.id &&
                      p.propuestoPor == usuarioActualId,
                )
                .length,
            lugaresPropuestos: {
              for (final p in propuestas)
                if (p.planId == salida.plan.id) p.lugarId,
            },
          ),
    ];
  }

  @override
  Future<void> proponer({
    required String planId,
    required String lugarId,
  }) async {
    llamadasProponer.add('$planId:$lugarId');
    final falla = errorProponer;
    if (falla != null) throw falla;
    final destinos = await obtenerDestinos();
    final destino = destinos.where((d) => d.plan.id == planId).firstOrNull;
    if (destino == null) {
      throw const AppException(MensajesError.faseNoPermitePropuestas);
    }
    final existente = propuestas
        .where((p) => p.planId == planId && p.lugarId == lugarId)
        .firstOrNull;
    if (existente != null) {
      if (existente.propuestoPor == usuarioActualId) return;
      throw const AppException(MensajesError.lugarYaPropuesto);
    }
    if (destino.limiteAlcanzado) {
      throw const AppException(MensajesError.limitePropuestasAlcanzado);
    }
    propuestas.add(
      propuestaDePrueba(
        id: 'pr${propuestas.length + 1}',
        planId: planId,
        lugarId: lugarId,
        propuestoPor: usuarioActualId!,
        nombreLugar: lugares[lugarId],
      ),
    );
    _cambios.add(planId);
  }

  @override
  Future<void> retirar(PropuestaModel propuesta) async {
    final falla = errorRetirar;
    if (falla != null) throw falla;
    propuestas.removeWhere((p) => p.id == propuesta.id);
    _cambios.add(propuesta.planId);
  }
}

PropuestaModel propuestaDePrueba({
  String id = 'pr1',
  String planId = 'p1',
  String lugarId = 'l1',
  String propuestoPor = 'u1',
  String? nombreLugar = 'Lugar de prueba',
}) {
  return PropuestaModel(
    id: id,
    planId: planId,
    lugarId: lugarId,
    propuestoPor: propuestoPor,
    nombreAutor: 'Persona $propuestoPor',
    createdAt: DateTime.utc(2026, 10, 25),
    nombreLugar: nombreLugar,
    categoria: nombreLugar == null ? null : CategoriaLugar.restaurantes,
  );
}
