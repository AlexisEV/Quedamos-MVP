// validaciones previas de formularios; devuelven el mensaje de error o null
abstract final class Validadores {
  static const maxNombreVisible = 40;
  static const minContrasena = 6;

  static final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // cuenta puntos de codigo como length de postgres en el check de perfiles
  static String? nombreVisible(String? valor) {
    final largo = (valor ?? '').trim().runes.length;
    if (largo == 0) return 'Ingresa tu nombre visible.';
    if (largo > maxNombreVisible) {
      return 'Máximo $maxNombreVisible caracteres.';
    }
    return null;
  }

  static String? correo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Ingresa tu correo.';
    if (!_formatoCorreo.hasMatch(texto)) return 'Ingresa un correo válido.';
    return null;
  }

  // el registro exige el minimo de supabase auth; el acceso solo que no este vacia
  static String? contrasena(String? valor, {required bool esRegistro}) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Ingresa tu contraseña.';
    if (esRegistro && texto.length < minContrasena) {
      return 'Usa al menos $minContrasena caracteres.';
    }
    return null;
  }
}
