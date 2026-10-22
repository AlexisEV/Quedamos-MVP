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

  static String? nombrePlan(String? valor) {
    if ((valor ?? '').trim().isEmpty) return 'Ingresa el nombre del plan.';
    return null;
  }

  // acepta punto o coma decimal y como maximo dos decimales
  static final _formatoMonto = RegExp(r'^\d+([.,]\d{1,2})?$');

  // tope tecnico de numeric(10, 2) en planes.presupuesto_soles
  static const _maxPresupuesto = 100000000;

  static double? leerPresupuesto(String? valor) {
    final texto = (valor ?? '').trim();
    if (!_formatoMonto.hasMatch(texto)) return null;
    final monto = double.tryParse(texto.replaceAll(',', '.'));
    if (monto == null || monto >= _maxPresupuesto) return null;
    return monto;
  }

  static String? presupuesto(String? valor) {
    if ((valor ?? '').trim().isEmpty) return 'Ingresa el presupuesto.';
    if (leerPresupuesto(valor) == null) {
      return 'Ingresa un monto válido, por ejemplo 70 o 70.50.';
    }
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
