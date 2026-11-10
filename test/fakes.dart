import 'dart:async';

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/itinerario/data/actividad_model.dart';
import 'package:app/features/itinerario/data/cambio_plan_model.dart';
import 'package:app/features/itinerario/data/estimacion_presupuesto.dart';
import 'package:app/features/itinerario/data/itinerario_repository.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/lugares/data/lugares_repository.dart';
import 'package:app/features/lugares/data/propuesta_model.dart';
import 'package:app/features/lugares/data/propuestas_repository.dart';
import 'package:app/features/notificaciones/data/avisos_locales.dart';
import 'package:app/features/notificaciones/data/notificacion_model.dart';
import 'package:app/features/notificaciones/data/notificaciones_repository.dart';
import 'package:app/features/perfil/data/perfil_model.dart';
import 'package:app/features/perfil/data/perfil_repository.dart';
import 'package:app/features/salidas/data/participante_model.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';
import 'package:app/features/votacion/data/candidato_model.dart';
import 'package:app/features/votacion/data/votacion_repository.dart';

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
  int maxCandidatos = 6,
  int maxSelecciones = 3,
  int maxActividades = 3,
  DateTime? fechaLimiteVoto,
  DateTime? fechaLimiteAsistencia,
}) {
  return PlanModel(
    id: id,
    nombre: nombre,
    estado: estado,
    presupuestoSoles: 70,
    maxPropuestasPorPersona: 3,
    maxCandidatos: maxCandidatos,
    maxSelecciones: maxSelecciones,
    maxActividades: maxActividades,
    codigoInvitacion: 'AQP48X',
    creadoPor: 'u1',
    createdAt: createdAt ?? DateTime.utc(2026, 10, 22),
    fechaLimiteVoto: fechaLimiteVoto,
    fechaLimiteAsistencia: fechaLimiteAsistencia,
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
  final respuestas = <EstadoAsistencia>[];
  AppException? errorAsistencia;
  AppException? errorCancelar;
  var cancelados = 0;

  @override
  String? usuarioActualId = 'u1';
  AppException? error;
  final _cambios = StreamController<void>.broadcast();

  @override
  Stream<void> get cambios => _cambios.stream;

  @override
  void avisarCambio() => _cambios.add(null);

  final _cambiosDeAvisos = StreamController<void>.broadcast();
  var avisosDeCambio = 0;

  @override
  Stream<void> get cambiosDeAvisos => _cambiosDeAvisos.stream;

  @override
  void avisarCambioDeAvisos() {
    avisosDeCambio++;
    _cambiosDeAvisos.add(null);
  }

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
      asistencia: actual.asistencia,
    );
  }

  // misma regla que la rpc: cancelado es final y un reintento no falla
  @override
  Future<PlanModel> cancelarPlan(String planId) async {
    final falla = errorCancelar;
    if (falla != null) throw falla;
    final indice = salidas.indexWhere((s) => s.plan.id == planId);
    final actual = salidas[indice];
    if (!actual.esAdministrador) {
      throw const AppException(MensajesError.noAutorizado);
    }
    if (actual.plan.estado == EstadoPlan.cancelado) return actual.plan;
    cancelados++;
    final p = actual.plan;
    final plan = PlanModel(
      id: p.id,
      nombre: p.nombre,
      estado: EstadoPlan.cancelado,
      presupuestoSoles: p.presupuestoSoles,
      maxPropuestasPorPersona: p.maxPropuestasPorPersona,
      maxCandidatos: p.maxCandidatos,
      maxSelecciones: p.maxSelecciones,
      maxActividades: p.maxActividades,
      codigoInvitacion: p.codigoInvitacion,
      creadoPor: p.creadoPor,
      createdAt: p.createdAt,
      fechaLimiteVoto: p.fechaLimiteVoto,
      fechaLimiteAsistencia: p.fechaLimiteAsistencia,
      canceladoEn: DateTime.utc(2026, 11, 10, 15),
    );
    salidas[indice] = SalidaModel(
      plan: plan,
      miRol: actual.miRol,
      esCreador: actual.esCreador,
      totalParticipantes: actual.totalParticipantes,
    );
    avisarCambio();
    return plan;
  }

  // misma regla que la rpc: solo confirmado y nunca pendiente
  @override
  Future<void> responderAsistencia({
    required String planId,
    required EstadoAsistencia estado,
  }) async {
    respuestas.add(estado);
    final falla = errorAsistencia;
    if (falla != null) throw falla;
    if (estado == EstadoAsistencia.pendiente) {
      throw const AppException(MensajesError.asistenciaInvalida);
    }
    final salida = await obtenerSalida(planId);
    if (salida?.plan.estado != EstadoPlan.confirmado) {
      throw const AppException(MensajesError.planNoConfirmado);
    }
    final lista = participantesPorPlan[planId] ?? [];
    final indice = lista.indexWhere((p) => p.perfilId == usuarioActualId);
    if (indice >= 0) lista[indice] = lista[indice].conAsistencia(estado);
  }
}

ParticipanteModel participanteDePrueba(
  String perfilId, {
  RolPlan rol = RolPlan.participante,
  bool esCreador = false,
  int minuto = 0,
  EstadoAsistencia asistencia = EstadoAsistencia.pendiente,
}) {
  return ParticipanteModel(
    perfilId: perfilId,
    nombreVisible: 'Persona $perfilId',
    rol: rol,
    esCreador: esCreador,
    unidoEn: DateTime.utc(2026, 10, 22, 12, minuto),
    asistencia: asistencia,
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

  // mismas reglas que la consulta rf13: precio conocido, orden por precio y nombre
  @override
  Future<List<LugarModel>> obtenerRecomendaciones({
    required ZonaLugar zona,
    required CategoriaLugar categoria,
    required double presupuestoSoles,
  }) async {
    final falla = error;
    if (falla != null) throw falla;
    final filtrados =
        lugares.where((l) {
          final precio = l.precioEstimadoPen;
          return l.zona == zona &&
              l.categoria == categoria &&
              precio != null &&
              precio <= presupuestoSoles;
        }).toList()..sort((a, b) {
          final porPrecio = a.precioEstimadoPen!.compareTo(
            b.precioEstimadoPen!,
          );
          return porPrecio != 0 ? porPrecio : a.nombre.compareTo(b.nombre);
        });
    return filtrados.take(LugaresRepository.maxRecomendaciones).toList();
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

// lista final y limites en memoria con las reglas de las rpc de preparar votacion;
// los planes se leen y actualizan en el repositorio de salidas
class FakeVotacionRepository implements VotacionRepository {
  FakeVotacionRepository([FakeSalidasRepository? salidas])
    : salidas = salidas ?? FakeSalidasRepository();

  final FakeSalidasRepository salidas;
  final candidatosPorPlan = <String, List<String>>{};
  // orden de las llamadas para verificar la secuencia de guardado
  final llamadas = <String>[];
  AppException? errorLimites;
  AppException? errorCandidatos;
  AppException? errorPlazos;
  AppException? errorAbrir;
  // seleccion guardada del usuario actual por plan
  final misVotosPorPlan = <String, Set<String>>{};
  // votos de los demas por candidato; el total suma la seleccion propia
  final votosAjenos = <String, int>{};
  AppException? errorGuardarVotos;
  AppException? errorTotales;
  var guardadosVotos = 0;
  // instantanea de totales y seleccion guardada al cerrar, por candidato
  final totalesCerrados = <String, int>{};
  final seleccionados = <String>{};
  AppException? errorCerrar;
  AppException? errorEmpate;

  @override
  Future<List<CandidatoModel>> obtenerCandidatos(String planId) async {
    return [
      for (final lugarId in candidatosPorPlan[planId] ?? const <String>[])
        CandidatoModel(
          id: 'c$lugarId',
          planId: planId,
          lugarId: lugarId,
          nombreLugar: 'Lugar $lugarId',
          totalVotos: totalesCerrados['c$lugarId'],
          seleccionado: seleccionados.contains('c$lugarId'),
        ),
    ];
  }

  PlanModel _plan(String planId) =>
      salidas.salidas.firstWhere((s) => s.plan.id == planId).plan;

  void _reemplazar(PlanModel plan) {
    final indice = salidas.salidas.indexWhere((s) => s.plan.id == plan.id);
    final actual = salidas.salidas[indice];
    salidas.salidas[indice] = SalidaModel(
      plan: plan,
      miRol: actual.miRol,
      esCreador: actual.esCreador,
      totalParticipantes: actual.totalParticipantes,
    );
  }

  PlanModel _copiar(
    PlanModel plan, {
    EstadoPlan? estado,
    int? maxCandidatos,
    int? maxSelecciones,
    int? maxActividades,
    DateTime? fechaLimiteVoto,
    bool cambiarPlazo = false,
    DateTime? fechaLimiteAsistencia,
  }) {
    return planDePrueba(
      id: plan.id,
      nombre: plan.nombre,
      estado: estado ?? plan.estado,
      createdAt: plan.createdAt,
      maxCandidatos: maxCandidatos ?? plan.maxCandidatos,
      maxSelecciones: maxSelecciones ?? plan.maxSelecciones,
      maxActividades: maxActividades ?? plan.maxActividades,
      fechaLimiteVoto: cambiarPlazo ? fechaLimiteVoto : plan.fechaLimiteVoto,
      fechaLimiteAsistencia: cambiarPlazo
          ? fechaLimiteAsistencia
          : plan.fechaLimiteAsistencia,
    );
  }

  void _exigirPreparacion(PlanModel plan) {
    if (plan.estado != EstadoPlan.recibiendoPropuestas) {
      throw const AppException(MensajesError.faseNoPermitePreparacion);
    }
  }

  @override
  Future<PlanModel> actualizarLimites({
    required String planId,
    required int maxCandidatos,
    required int maxSelecciones,
    required int maxActividades,
  }) async {
    llamadas.add('limites:$maxCandidatos/$maxSelecciones/$maxActividades');
    final falla = errorLimites;
    if (falla != null) throw falla;
    final plan = _plan(planId);
    _exigirPreparacion(plan);
    if ((candidatosPorPlan[planId]?.length ?? 0) > maxCandidatos) {
      throw const AppException(MensajesError.candidatosSuperanMaximo);
    }
    final nuevo = _copiar(
      plan,
      maxCandidatos: maxCandidatos,
      maxSelecciones: maxSelecciones,
      maxActividades: maxActividades,
    );
    _reemplazar(nuevo);
    return nuevo;
  }

  @override
  Future<void> definirCandidatos({
    required String planId,
    required Set<String> lugarIds,
  }) async {
    llamadas.add('candidatos:${lugarIds.length}');
    final falla = errorCandidatos;
    if (falla != null) throw falla;
    final plan = _plan(planId);
    _exigirPreparacion(plan);
    if (lugarIds.length > plan.maxCandidatos) {
      throw const AppException(MensajesError.candidatosSuperanMaximo);
    }
    candidatosPorPlan[planId] = lugarIds.toList();
  }

  @override
  Future<PlanModel> definirPlazos({
    required String planId,
    required DateTime? fechaLimiteVoto,
    required DateTime? fechaLimiteAsistencia,
  }) async {
    llamadas.add('plazos');
    final falla = errorPlazos;
    if (falla != null) throw falla;
    final nuevo = _copiar(
      _plan(planId),
      fechaLimiteVoto: fechaLimiteVoto,
      fechaLimiteAsistencia: fechaLimiteAsistencia,
      cambiarPlazo: true,
    );
    _reemplazar(nuevo);
    return nuevo;
  }

  @override
  Future<PlanModel> abrirVotacion(String planId) async {
    llamadas.add('abrir');
    final falla = errorAbrir;
    if (falla != null) throw falla;
    final plan = _plan(planId);
    if (plan.estado == EstadoPlan.enVotacion) return plan;
    _exigirPreparacion(plan);
    if ((candidatosPorPlan[planId] ?? const []).isEmpty) {
      throw const AppException(MensajesError.sinCandidatos);
    }
    final nuevo = _copiar(plan, estado: EstadoPlan.enVotacion);
    _reemplazar(nuevo);
    salidas.avisarCambio();
    return nuevo;
  }

  @override
  Future<Set<String>> obtenerMisVotos(String planId) async => {
    ...?misVotosPorPlan[planId],
  };

  @override
  Future<Map<String, int>> obtenerTotales(String planId) async {
    final falla = errorTotales;
    if (falla != null) throw falla;
    final mios = misVotosPorPlan[planId] ?? const <String>{};
    return {
      for (final candidato in await obtenerCandidatos(planId))
        candidato.id:
            (votosAjenos[candidato.id] ?? 0) +
            (mios.contains(candidato.id) ? 1 : 0),
    };
  }

  @override
  Future<void> guardarVotos({
    required String planId,
    required Set<String> candidatoIds,
  }) async {
    llamadas.add('votos:${candidatoIds.join(',')}');
    final falla = errorGuardarVotos;
    if (falla != null) throw falla;
    final plan = _plan(planId);
    if (plan.estado != EstadoPlan.enVotacion) {
      throw const AppException(MensajesError.votacionCerrada);
    }
    if (candidatoIds.isEmpty) {
      throw const AppException(MensajesError.seleccionVacia);
    }
    if (candidatoIds.length > plan.maxSelecciones) {
      throw const AppException(MensajesError.limiteSeleccionesSuperado);
    }
    misVotosPorPlan[planId] = {...candidatoIds};
    guardadosVotos++;
  }

  // misma regla de seleccion que cerrar_votacion
  @override
  Future<PlanModel> cerrarVotacion(String planId) async {
    llamadas.add('cerrar');
    final falla = errorCerrar;
    if (falla != null) throw falla;
    final plan = _plan(planId);
    if (plan.estado != EstadoPlan.enVotacion) return plan;
    final totales = await obtenerTotales(planId);
    if (totales.values.every((total) => total == 0)) {
      throw const AppException(MensajesError.sinVotos);
    }
    totalesCerrados.addAll(totales);
    final votados = totales.values.where((t) => t > 0).toList()
      ..sort((a, b) => b.compareTo(a));
    final maximo = plan.maxActividades;
    final corte = votados.length > maximo ? votados[maximo - 1] : 1;
    final hayEmpate =
        votados.length > maximo &&
        votados.where((t) => t >= corte).length > maximo;
    seleccionados.addAll([
      for (final MapEntry(:key, :value) in totales.entries)
        if (hayEmpate ? value > corte : value >= corte) key,
    ]);
    final nuevo = _copiar(plan, estado: EstadoPlan.preparandoItinerario);
    _reemplazar(nuevo);
    salidas.avisarCambio();
    return nuevo;
  }

  @override
  Future<void> resolverEmpate({
    required String planId,
    required Set<String> candidatoIds,
  }) async {
    llamadas.add('empate:${candidatoIds.join(',')}');
    final falla = errorEmpate;
    if (falla != null) throw falla;
    seleccionados.addAll(candidatoIds);
  }
}

// itinerario en memoria que aplica las reglas de guardar_itinerario y confirmar_plan
class FakeItinerarioRepository implements ItinerarioRepository {
  FakeItinerarioRepository(this.salidas);

  final FakeSalidasRepository salidas;
  final actividadesPorPlan = <String, List<ActividadModel>>{};
  // precio por lugar; null es desconocido
  final precios = <String, double?>{};
  AppException? errorGuardar;
  AppException? errorConfirmar;
  AppException? errorReemplazo;
  AppException? errorHorario;
  var guardados = 0;
  var confirmados = 0;
  // historial por plan, del mas reciente al mas antiguo
  final cambiosPorPlan = <String, List<CambioPlanModel>>{};

  // agrega actividades sin fecha y hora con lugares l1, l2, ...
  void sembrar(String planId, List<String> lugarIds) {
    actividadesPorPlan[planId] = [
      for (final (i, lugarId) in lugarIds.indexed)
        ActividadModel(
          id: 'a$lugarId',
          planId: planId,
          lugarId: lugarId,
          posicion: i + 1,
          nombreLugar: 'Lugar $lugarId',
          precioEstimadoPen: precios[lugarId],
        ),
    ];
  }

  @override
  Future<List<ActividadModel>> obtenerActividades(String planId) async =>
      List.of(actividadesPorPlan[planId] ?? const []);

  @override
  Future<EstimacionPresupuesto> obtenerEstimacion(String planId) async {
    final plan = salidas.salidas.firstWhere((s) => s.plan.id == planId).plan;
    final actividades = actividadesPorPlan[planId] ?? const [];
    final conocidos = actividades
        .map((a) => a.precioEstimadoPen)
        .whereType<double>();
    final total = conocidos.fold<double>(0, (suma, p) => suma + p);
    final sinPrecio = actividades.length - conocidos.length;
    return EstimacionPresupuesto(
      presupuestoSoles: plan.presupuestoSoles,
      totalEstimado: total,
      actividades: actividades.length,
      sinPrecio: sinPrecio,
      incompleta: sinPrecio > 0,
      excede: total > plan.presupuestoSoles,
    );
  }

  @override
  Future<void> guardarItinerario({
    required String planId,
    required List<ActividadModel> actividades,
  }) async {
    final falla = errorGuardar;
    if (falla != null) throw falla;
    guardados++;
    actividadesPorPlan[planId] = [
      for (final (i, a) in actividades.indexed)
        a.copiarCon(posicion: i + 1, inicio: a.inicio),
    ];
  }

  @override
  Future<PlanModel> confirmarPlan(String planId) async {
    final falla = errorConfirmar;
    if (falla != null) throw falla;
    final actividades = actividadesPorPlan[planId] ?? const [];
    if (actividades.any((a) => a.inicio == null)) {
      throw const AppException(MensajesError.actividadesSinHorario);
    }
    confirmados++;
    final indice = salidas.salidas.indexWhere((s) => s.plan.id == planId);
    final actual = salidas.salidas[indice];
    final plan = planDePrueba(
      id: actual.plan.id,
      nombre: actual.plan.nombre,
      estado: EstadoPlan.confirmado,
      createdAt: actual.plan.createdAt,
      maxActividades: actual.plan.maxActividades,
    );
    salidas.salidas[indice] = SalidaModel(
      plan: plan,
      miRol: actual.miRol,
      esCreador: actual.esCreador,
      totalParticipantes: actual.totalParticipantes,
    );
    return plan;
  }

  ActividadModel _actividad(String actividadId) => actividadesPorPlan.values
      .expand((lista) => lista)
      .firstWhere((a) => a.id == actividadId);

  void _exigirConfirmado(String planId) {
    final plan = salidas.salidas.firstWhere((s) => s.plan.id == planId).plan;
    if (plan.estado == EstadoPlan.cancelado) {
      throw const AppException(MensajesError.planCancelado);
    }
    if (plan.estado != EstadoPlan.confirmado) {
      throw const AppException(MensajesError.planNoConfirmado);
    }
  }

  void _guardarActividad(ActividadModel nueva) {
    final lista = actividadesPorPlan[nueva.planId]!;
    final indice = lista.indexWhere((a) => a.id == nueva.id);
    lista[indice] = nueva;
  }

  void _registrar(String planId, CambioPlanModel cambio) {
    cambiosPorPlan.putIfAbsent(planId, () => []).insert(0, cambio);
  }

  // mismas reglas que reemplazar_actividad: confirmado, sin repetir lugares
  @override
  Future<ActividadModel> reemplazarActividad({
    required String actividadId,
    required String lugarId,
  }) async {
    final falla = errorReemplazo;
    if (falla != null) throw falla;
    final actual = _actividad(actividadId);
    _exigirConfirmado(actual.planId);
    if (actual.lugarId == lugarId) return actual;
    if (actividadesPorPlan[actual.planId]!.any((a) => a.lugarId == lugarId)) {
      throw const AppException(MensajesError.lugarEnItinerario);
    }
    final nueva = ActividadModel(
      id: actual.id,
      planId: actual.planId,
      lugarId: lugarId,
      posicion: actual.posicion,
      inicio: actual.inicio,
      nombreLugar: 'Lugar $lugarId',
      precioEstimadoPen: precios[lugarId],
    );
    _guardarActividad(nueva);
    _registrar(
      actual.planId,
      CambioPlanModel(
        id: 'cambio${cambiosPorPlan[actual.planId]?.length ?? 0}',
        tipo: TipoCambio.reemplazo,
        creadoEn: DateTime.utc(2026, 11, 10, 15),
        lugarAnterior: actual.nombreLugar,
        lugarNuevo: nueva.nombreLugar,
        inicioAnterior: actual.inicio,
        inicioNuevo: actual.inicio,
        realizadoPor: 'Persona ${salidas.usuarioActualId}',
      ),
    );
    return nueva;
  }

  // mismas reglas que cambiar_horario_actividad: confirmado e inicio futuro
  @override
  Future<ActividadModel> cambiarHorario({
    required String actividadId,
    required DateTime inicio,
  }) async {
    final falla = errorHorario;
    if (falla != null) throw falla;
    final actual = _actividad(actividadId);
    _exigirConfirmado(actual.planId);
    if (actual.inicio == inicio) return actual;
    if (!inicio.isAfter(DateTime.now())) {
      throw const AppException(MensajesError.inicioEnPasado);
    }
    final nueva = actual.copiarCon(posicion: actual.posicion, inicio: inicio);
    _guardarActividad(nueva);
    _registrar(
      actual.planId,
      CambioPlanModel(
        id: 'cambio${cambiosPorPlan[actual.planId]?.length ?? 0}',
        tipo: TipoCambio.horario,
        creadoEn: DateTime.utc(2026, 11, 10, 15),
        lugarAnterior: actual.nombreLugar,
        lugarNuevo: actual.nombreLugar,
        inicioAnterior: actual.inicio,
        inicioNuevo: inicio,
        realizadoPor: 'Persona ${salidas.usuarioActualId}',
      ),
    );
    return nueva;
  }

  @override
  Future<List<CambioPlanModel>> obtenerCambios(String planId) async =>
      List.of(cambiosPorPlan[planId] ?? const []);
}

// notificaciones propias en memoria; marcar registra ids y marcas
class FakeNotificacionesRepository implements NotificacionesRepository {
  List<NotificacionModel> filas = [];
  AppException? error;
  AppException? errorMarcar;
  var lecturas = 0;
  final marcadasEntregadas = <String>[];
  final marcadasLeidas = <String>[];

  @override
  Future<List<NotificacionModel>> obtenerNotificaciones() async {
    lecturas++;
    final falla = error;
    if (falla != null) throw falla;
    return List.of(filas);
  }

  @override
  Future<void> marcar(
    List<String> ids, {
    bool entregada = false,
    bool leida = false,
  }) async {
    final falla = errorMarcar;
    if (falla != null) throw falla;
    if (entregada) marcadasEntregadas.addAll(ids);
    if (leida) marcadasLeidas.addAll(ids);
  }
}

// avisos locales en memoria: guarda lo programado, mostrado y cancelado
class FakeAvisosLocales implements AvisosLocales {
  bool permiso = true;
  bool concederAlPedir = true;
  var pedidos = 0;
  final programados = <int, DateTime>{};
  final mostrados = <int>[];
  final cancelados = <int>[];
  var cancelarTodoLlamadas = 0;

  @override
  Future<void> inicializar(void Function(String? payload) alTocar) async {}

  @override
  Future<String?> payloadDeArranque() async => null;

  @override
  Future<bool> permisoConcedido() async => permiso;

  @override
  Future<bool> pedirPermiso() async {
    pedidos++;
    permiso = concederAlPedir;
    return permiso;
  }

  @override
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime momento,
    required String payload,
  }) async => programados[id] = momento;

  @override
  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
    required String payload,
  }) async => mostrados.add(id);

  @override
  Future<void> cancelar(int id) async => cancelados.add(id);

  @override
  Future<void> cancelarTodo() async => cancelarTodoLlamadas++;
}
