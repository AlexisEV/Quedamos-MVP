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
}

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
