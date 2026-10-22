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
}
