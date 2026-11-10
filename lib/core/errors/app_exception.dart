import 'package:supabase_flutter/supabase_flutter.dart';

// error con un mensaje en espanol listo para mostrar en la interfaz
class AppException implements Exception {
  const AppException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract final class MensajesError {
  static const generico = 'Ocurrió un error. Inténtalo otra vez.';
  static const sinConexion =
      'No se pudo conectar. Revisa tu conexión e inténtalo otra vez.';
  static const credencialesIncorrectas = 'Correo o contraseña incorrectos.';
  static const correoRegistrado =
      'Ese correo ya tiene una cuenta. Inicia sesión.';
  static const contrasenaDebil =
      'La contraseña es muy débil. Usa al menos 6 caracteres.';
  static const correoInvalido = 'El correo no tiene un formato válido.';
  static const demasiadosIntentos =
      'Demasiados intentos. Espera un momento e inténtalo otra vez.';
  static const sinSesion = 'Tu sesión terminó. Vuelve a iniciar sesión.';
  static const nombreInvalido =
      'El nombre visible debe tener entre 1 y 40 caracteres.';
  static const noAutorizado = 'No tienes permiso para esta acción.';
  static const nombrePlanRequerido = 'Ingresa el nombre del plan.';
  static const presupuestoInvalido = 'Ingresa un presupuesto válido.';
  static const limiteFueraDeRango = 'Algún límite está fuera de su rango.';
  static const seleccionesMayoresQueCandidatos =
      'Las selecciones no pueden superar a los candidatos.';
  static const codigoInvalido =
      'El código no es válido o la salida fue cancelada.';
  static const planCancelado = 'La salida fue cancelada.';
  static const participanteNoEncontrado =
      'Esa persona ya no participa en la salida.';
  static const faseNoPermitePropuestas = 'La salida ya no recibe propuestas.';
  static const lugarNoDisponible = 'Este lugar ya no está disponible.';
  static const lugarYaPropuesto = 'Ese lugar ya fue propuesto en esta salida.';
  static const limitePropuestasAlcanzado =
      'Llegaste a tu límite de propuestas en esta salida.';
  static const faseNoPermitePreparacion =
      'La votación ya se abrió: la lista y los límites están fijos.';
  static const candidatosSuperanMaximo =
      'Hay más candidatos seleccionados que el máximo permitido.';
  static const lugarNoPropuesto =
      'Algún candidato ya no está entre las propuestas. Recarga la lista.';
  static const plazoEnPasado = 'El plazo debe ser una fecha futura.';
  static const sinCandidatos =
      'Elige al menos un candidato para abrir la votación.';
  static const votacionNoAbierta = 'La votación todavía no se abrió.';
  static const votacionCerrada =
      'La votación ya se cerró: tu selección no se guardó.';
  static const seleccionVacia = 'Elige al menos un lugar para guardar tu voto.';
  static const candidatoNoValido =
      'Algún lugar ya no es candidato. Recarga la votación.';
  static const limiteSeleccionesSuperado =
      'Elegiste más lugares de los permitidos.';
  static const sinVotos =
      'Nadie votó todavía: la votación sigue abierta hasta que haya votos.';
  static const faseNoPermiteDesempate =
      'Solo se resuelve un empate con la votación cerrada.';
  static const sinEmpatePendiente =
      'El empate ya se resolvió. Recarga la salida.';
  static const candidatoNoEmpatado =
      'Algún lugar elegido no está empatado. Recarga la salida.';
  static const cantidadDesempateInvalida =
      'Elige exactamente los lugares que faltan para el itinerario.';
  static const faseNoPermiteItinerario =
      'El itinerario ya no se puede editar en esta fase. Recarga la salida.';
  static const empatePendiente =
      'Primero hay que resolver el empate del último puesto.';
  static const actividadesNoCoinciden =
      'Las actividades cambiaron. Recarga el itinerario.';
  static const inicioEnPasado =
      'La fecha y hora de cada actividad debe ser futura.';
  static const faseNoPermiteConfirmar =
      'El itinerario solo se confirma tras cerrar la votación.';
  static const sinActividades = 'El itinerario no tiene actividades.';
  static const actividadesSinHorario =
      'Asigna fecha y hora a todas las actividades antes de confirmar.';
  static const asistenciaInvalida = 'Elige Asistiré o No asistiré.';
  static const planNoConfirmado =
      'Esta acción requiere el itinerario confirmado. Recarga la salida.';
  static const lugarEnItinerario =
      'Ese lugar ya está en el itinerario. Elige otro.';
  static const inicioRequerido = 'Elige la fecha y hora de la actividad.';
}

// codigos que lanzan las rpc con raise exception; ver 04_DATABASE_SCHEMA.md seccion 6
const _mensajesRpc = {
  'no_autenticado': MensajesError.sinSesion,
  'no_autorizado': MensajesError.noAutorizado,
  'nombre_requerido': MensajesError.nombrePlanRequerido,
  'presupuesto_invalido': MensajesError.presupuestoInvalido,
  'limite_fuera_de_rango': MensajesError.limiteFueraDeRango,
  'selecciones_mayores_que_candidatos':
      MensajesError.seleccionesMayoresQueCandidatos,
  'codigo_invalido': MensajesError.codigoInvalido,
  'plan_cancelado': MensajesError.planCancelado,
  'participante_no_encontrado': MensajesError.participanteNoEncontrado,
  'fase_no_permite_propuestas': MensajesError.faseNoPermitePropuestas,
  'lugar_no_disponible': MensajesError.lugarNoDisponible,
  'lugar_ya_propuesto': MensajesError.lugarYaPropuesto,
  'limite_propuestas_alcanzado': MensajesError.limitePropuestasAlcanzado,
  'fase_no_permite_preparacion': MensajesError.faseNoPermitePreparacion,
  'candidatos_superan_maximo': MensajesError.candidatosSuperanMaximo,
  'lugar_no_propuesto': MensajesError.lugarNoPropuesto,
  'plazo_en_pasado': MensajesError.plazoEnPasado,
  'sin_candidatos': MensajesError.sinCandidatos,
  'votacion_no_abierta': MensajesError.votacionNoAbierta,
  'votacion_cerrada': MensajesError.votacionCerrada,
  'seleccion_vacia': MensajesError.seleccionVacia,
  'candidato_no_valido': MensajesError.candidatoNoValido,
  'limite_selecciones_superado': MensajesError.limiteSeleccionesSuperado,
  'sin_votos': MensajesError.sinVotos,
  'fase_no_permite_desempate': MensajesError.faseNoPermiteDesempate,
  'sin_empate_pendiente': MensajesError.sinEmpatePendiente,
  'candidato_no_empatado': MensajesError.candidatoNoEmpatado,
  'cantidad_desempate_invalida': MensajesError.cantidadDesempateInvalida,
  'fase_no_permite_itinerario': MensajesError.faseNoPermiteItinerario,
  'empate_pendiente': MensajesError.empatePendiente,
  'actividades_no_coinciden': MensajesError.actividadesNoCoinciden,
  'inicio_en_pasado': MensajesError.inicioEnPasado,
  'fase_no_permite_confirmar': MensajesError.faseNoPermiteConfirmar,
  'sin_actividades': MensajesError.sinActividades,
  'actividades_sin_horario': MensajesError.actividadesSinHorario,
  'asistencia_invalida': MensajesError.asistenciaInvalida,
  'plan_no_confirmado': MensajesError.planNoConfirmado,
  'lugar_en_itinerario': MensajesError.lugarEnItinerario,
  'inicio_requerido': MensajesError.inicioRequerido,
};

// traduce excepciones de supabase a mensajes en espanol
AppException traducirError(Object error) {
  if (error is AppException) return error;
  if (error is AuthRetryableFetchException) {
    return const AppException(MensajesError.sinConexion);
  }
  if (error is AuthException) return _traducirAuth(error);
  if (error is PostgrestException) return _traducirPostgrest(error);
  // los errores que no vienen del servidor suelen ser fallos de red
  return const AppException(MensajesError.sinConexion);
}

AppException _traducirAuth(AuthException error) {
  switch (error.code) {
    case 'invalid_credentials':
      return const AppException(MensajesError.credencialesIncorrectas);
    case 'user_already_exists':
    case 'email_exists':
      return const AppException(MensajesError.correoRegistrado);
    case 'weak_password':
      return const AppException(MensajesError.contrasenaDebil);
    case 'email_address_invalid':
      return const AppException(MensajesError.correoInvalido);
    case 'over_request_rate_limit':
    case 'over_email_send_rate_limit':
      return const AppException(MensajesError.demasiadosIntentos);
    case 'session_not_found':
    case 'session_expired':
    case 'refresh_token_not_found':
      return const AppException(MensajesError.sinSesion);
  }
  return const AppException(MensajesError.generico);
}

AppException _traducirPostgrest(PostgrestException error) {
  switch (error.code) {
    // raise exception de una rpc: el mensaje es el codigo legible
    case 'P0001':
      return AppException(
        _mensajesRpc[error.message] ?? MensajesError.generico,
      );
    // violacion de check: nombre_visible fuera de rango
    case '23514':
      return const AppException(MensajesError.nombreInvalido);
    // jwt expirado o invalido
    case 'PGRST301':
    case 'PGRST303':
      return const AppException(MensajesError.sinSesion);
  }
  return const AppException(MensajesError.generico);
}
