import 'dart:async';

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/auth/presentation/acceso_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository repositorio;
  late AccesoViewModel vm;

  setUp(() {
    repositorio = FakeAuthRepository();
    vm = AccesoViewModel(repositorio);
  });

  Future<bool> enviar() => vm.enviar(
    nombreVisible: 'Mateo',
    correo: 'mateo@correo.com',
    contrasena: 'secreto1',
  );

  test('inicia en modo iniciar sesion y llama a iniciarSesion', () async {
    expect(vm.modo, ModoAcceso.iniciarSesion);

    final exito = await enviar();

    expect(exito, isTrue);
    expect(repositorio.llamadas, ['iniciarSesion:mateo@correo.com']);
    expect(vm.error, isNull);
    expect(vm.enviando, isFalse);
  });

  test('en modo registro envia el nombre visible', () async {
    vm.cambiarModo(ModoAcceso.registrarse);

    final exito = await enviar();

    expect(exito, isTrue);
    expect(repositorio.llamadas, ['registrar:Mateo:mateo@correo.com']);
  });

  test('un error del servidor no se muestra como exito', () async {
    repositorio.error = const AppException(MensajesError.correoRegistrado);
    vm.cambiarModo(ModoAcceso.registrarse);

    final exito = await enviar();

    expect(exito, isFalse);
    expect(vm.error, MensajesError.correoRegistrado);
    expect(vm.enviando, isFalse);
  });

  test('mientras envia ignora un segundo envio', () async {
    repositorio.pendiente = Completer<void>();

    final primero = enviar();
    expect(vm.enviando, isTrue);
    final segundo = await enviar();
    repositorio.pendiente!.complete();
    await primero;

    expect(segundo, isFalse);
    expect(repositorio.llamadas, hasLength(1));
  });

  test('cambiar de modo limpia el error', () async {
    repositorio.error = const AppException(
      MensajesError.credencialesIncorrectas,
    );
    await enviar();
    expect(vm.error, isNotNull);

    vm.cambiarModo(ModoAcceso.registrarse);

    expect(vm.error, isNull);
    expect(vm.esRegistro, isTrue);
  });
}
