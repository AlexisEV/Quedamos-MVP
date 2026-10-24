import 'package:app/core/utils/formateador_codigo.dart';
import 'package:app/core/utils/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nombre visible entre 1 y 40 caracteres sin solo espacios', () {
    expect(Validadores.nombreVisible(''), isNotNull);
    expect(Validadores.nombreVisible('   '), isNotNull);
    expect(Validadores.nombreVisible('a' * 41), isNotNull);
    expect(Validadores.nombreVisible('  ${'a' * 40}  '), isNull);
    expect(Validadores.nombreVisible('Mateo'), isNull);
  });

  test('correo con formato valido', () {
    expect(Validadores.correo(''), isNotNull);
    expect(Validadores.correo('mateo'), isNotNull);
    expect(Validadores.correo('mateo@correo'), isNotNull);
    expect(Validadores.correo(' mateo@correo.com '), isNull);
  });

  test('contrasena minima solo en el registro', () {
    expect(Validadores.contrasena('', esRegistro: false), isNotNull);
    expect(Validadores.contrasena('123', esRegistro: false), isNull);
    expect(Validadores.contrasena('12345', esRegistro: true), isNotNull);
    expect(Validadores.contrasena('123456', esRegistro: true), isNull);
  });

  test('nombre del plan obligatorio', () {
    expect(Validadores.nombrePlan('  '), isNotNull);
    expect(Validadores.nombrePlan('Salida'), isNull);
  });

  test('presupuesto con punto o coma y hasta dos decimales', () {
    expect(Validadores.presupuesto(''), isNotNull);
    expect(Validadores.presupuesto('-5'), isNotNull);
    expect(Validadores.presupuesto('70.555'), isNotNull);
    expect(Validadores.presupuesto('abc'), isNotNull);
    expect(Validadores.presupuesto('100000000'), isNotNull);
    expect(Validadores.leerPresupuesto('0'), 0);
    expect(Validadores.leerPresupuesto('70'), 70);
    expect(Validadores.leerPresupuesto(' 70,5 '), 70.5);
  });

  test('codigo de invitacion con 6 letras o numeros', () {
    expect(Validadores.codigoInvitacion(''), isNotNull);
    expect(Validadores.codigoInvitacion('AQP48'), isNotNull);
    expect(Validadores.codigoInvitacion('AQP-48'), isNotNull);
    expect(Validadores.codigoInvitacion('AQP48XY'), isNotNull);
    expect(Validadores.codigoInvitacion('AQP48X'), isNull);
    expect(Validadores.codigoInvitacion(' twomoy '), isNull);
  });

  test('formateador de codigo pasa a mayusculas, filtra y corta en 6', () {
    String formatear(String texto) => FormateadorCodigo()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto))
        .text;

    expect(formatear('twomoy'), 'TWOMOY');
    expect(formatear('aqp-48x'), 'AQP48X');
    expect(formatear('ab cd ef gh'), 'ABCDEF');
  });
}
