import 'dart:async';

import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/perfil/data/perfil_model.dart';
import 'package:app/features/perfil/data/perfil_repository.dart';

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
