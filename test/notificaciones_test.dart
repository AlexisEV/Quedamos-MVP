import 'dart:async';

import 'package:app/app/theme/app_theme.dart';
import 'package:app/core/errors/app_exception.dart';
import 'package:app/features/notificaciones/data/notificacion_model.dart';
import 'package:app/features/notificaciones/presentation/notificaciones_screen.dart';
import 'package:app/features/notificaciones/presentation/notificaciones_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

// viernes 13 nov 2026 a las 07:00 en lima
final _ahora = DateTime.utc(2026, 11, 13, 12);

NotificacionModel _aviso(
  String id, {
  int idLocal = 1,
  TipoNotificacion tipo = TipoNotificacion.actividad,
  Duration desfase = const Duration(hours: -1),
  bool activa = true,
  bool entregada = false,
  bool leida = false,
  String plan = 'Prueba hora',
  String ruta = '/salidas/p1',
}) {
  return NotificacionModel(
    id: id,
    idLocal: idLocal,
    planId: 'p1',
    nombrePlan: plan,
    tipo: tipo,
    titulo: '$plan: aviso $id',
    cuerpo: 'Cuerpo del aviso $id.',
    rutaDestino: ruta,
    programadaPara: _ahora.add(desfase),
    activa: activa,
    entregadaEn: entregada ? _ahora : null,
    leidaEn: leida ? _ahora : null,
  );
}

// temporizador manual: registra la espera y vence solo cuando el test lo pide
class _TemporizadorFalso implements Timer {
  _TemporizadorFalso(this.espera, this._alVencer);

  final Duration espera;
  final void Function() _alVencer;
  bool _activo = true;

  void vencer() {
    if (!_activo) return;
    _activo = false;
    _alVencer();
  }

  @override
  void cancel() => _activo = false;

  @override
  bool get isActive => _activo;

  @override
  int get tick => 0;
}

class _Escenario {
  final repositorio = FakeNotificacionesRepository();
  final avisos = FakeAvisosLocales();
  final cambios = StreamController<void>.broadcast();
  final temporizadores = <_TemporizadorFalso>[];
  DateTime ahora = _ahora;

  late final vm = NotificacionesViewModel(
    repositorio,
    avisos,
    cambios: cambios.stream,
    reloj: () => ahora,
    temporizador: (espera, alVencer) {
      final t = _TemporizadorFalso(espera, alVencer);
      temporizadores.add(t);
      return t;
    },
  );

  _TemporizadorFalso? get refrescoActivo =>
      temporizadores.where((t) => t.isActive).firstOrNull;
}

Widget _pantalla(NotificacionesViewModel vm, {List<String>? visitas}) {
  final router = GoRouter(
    initialLocation: '/notificaciones',
    routes: [
      GoRoute(
        path: '/notificaciones',
        builder: (context, state) => const NotificacionesScreen(),
      ),
      GoRoute(
        path: '/salidas/:planId',
        builder: (context, state) {
          visitas?.add(state.uri.toString());
          return const Scaffold(body: Text('Detalle del plan'));
        },
        routes: [
          GoRoute(
            path: 'votacion',
            builder: (context, state) {
              visitas?.add(state.uri.toString());
              return const Scaffold(body: Text('Votacion'));
            },
          ),
        ],
      ),
    ],
  );
  return ChangeNotifierProvider<NotificacionesViewModel>.value(
    value: vm,
    child: MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
}

void main() {
  group('NotificacionesViewModel', () {
    test(
      'programa futuros, cancela anulados y muestra cambios sin entregar',
      () async {
        final e = _Escenario();
        e.repositorio.filas = [
          _aviso('futuro', idLocal: 1, desfase: const Duration(hours: 5)),
          _aviso('anulado', idLocal: 2, activa: false),
          _aviso('cambio', idLocal: 3, tipo: TipoNotificacion.cambio),
          _aviso(
            'cancelado',
            idLocal: 4,
            tipo: TipoNotificacion.cancelacion,
            entregada: true,
          ),
          _aviso('pasado', idLocal: 5),
        ];

        await e.vm.sincronizar();

        expect(e.avisos.programados.keys, [1]);
        expect(e.avisos.cancelados, [2]);
        expect(e.avisos.mostrados, [3]);
        expect(e.repositorio.marcadasEntregadas, ['cambio']);
        // el futuro y el anulado no entran al historial
        expect(e.vm.historial.map((n) => n.id).toSet(), {
          'cambio',
          'cancelado',
          'pasado',
        });
        expect(e.vm.noLeidas, 3);
      },
    );

    test('sin permiso no programa ni muestra, pero cancela', () async {
      final e = _Escenario();
      e.avisos.permiso = false;
      e.repositorio.filas = [
        _aviso('futuro', idLocal: 1, desfase: const Duration(hours: 5)),
        _aviso('anulado', idLocal: 2, activa: false),
        _aviso('cambio', idLocal: 3, tipo: TipoNotificacion.cambio),
      ];

      await e.vm.sincronizar();

      expect(e.avisos.programados, isEmpty);
      expect(e.avisos.mostrados, isEmpty);
      expect(e.avisos.cancelados, [2]);
      expect(e.repositorio.marcadasEntregadas, isEmpty);
      expect(e.vm.permiso, isFalse);
    });

    test('pide el permiso una sola vez por sesion', () async {
      final e = _Escenario();
      e.avisos.permiso = false;
      e.avisos.concederAlPedir = false;

      await e.vm.alIniciarSesion();
      await e.vm.alIniciarSesion();

      expect(e.avisos.pedidos, 1);
      expect(e.vm.permisoBloqueado, isTrue);

      await e.vm.limpiar();
      await e.vm.alIniciarSesion();
      expect(e.avisos.pedidos, 2);
    });

    test('con permiso concedido no lo vuelve a pedir', () async {
      final e = _Escenario();
      await e.vm.alIniciarSesion();
      expect(e.avisos.pedidos, 0);
      expect(e.repositorio.lecturas, 1);
    });

    test('una accion propia sincroniza los avisos al instante', () async {
      final e = _Escenario();
      e.repositorio.filas = [
        _aviso(
          'voto',
          tipo: TipoNotificacion.voto,
          desfase: Duration(hours: 3),
        ),
      ];
      await e.vm.sincronizar();
      expect(e.avisos.programados.keys, [1]);

      // el servidor anulo el aviso de voto tras guardar elecciones
      e.repositorio.filas = [
        _aviso(
          'voto',
          tipo: TipoNotificacion.voto,
          desfase: const Duration(hours: 3),
          activa: false,
        ),
      ];
      e.cambios.add(null);
      await pumpEventQueue();

      expect(e.repositorio.lecturas, 2);
      expect(e.avisos.cancelados, [1]);
    });

    test('marcar todas como leidas solo tras el servidor', () async {
      final e = _Escenario();
      e.repositorio.filas = [
        _aviso('a'),
        _aviso('b', leida: true),
        _aviso('c', desfase: const Duration(hours: -2)),
      ];
      await e.vm.sincronizar();
      expect(e.vm.noLeidas, 2);

      e.repositorio.errorMarcar = const AppException('Sin conexión.');
      await e.vm.marcarTodas();
      expect(e.vm.noLeidas, 2);
      expect(e.vm.errorMarcar, 'Sin conexión.');

      e.repositorio.errorMarcar = null;
      await e.vm.marcarTodas();
      expect(e.repositorio.marcadasLeidas, ['a', 'c']);
      expect(e.vm.noLeidas, 0);
      expect(e.vm.errorMarcar, isNull);
    });

    test('cerrar sesion cancela todos los avisos y vacia la lista', () async {
      final e = _Escenario();
      e.repositorio.filas = [_aviso('a')];
      await e.vm.sincronizar();

      await e.vm.limpiar();

      expect(e.avisos.cancelarTodoLlamadas, 1);
      expect(e.vm.historial, isEmpty);
      // tras cerrar sesion una senal de cambio no vuelve a leer
      e.cambios.add(null);
      await pumpEventQueue();
      expect(e.repositorio.lecturas, 1);
    });

    test(
      'con la app abierta el historial se refresca al vencer un aviso',
      () async {
        final e = _Escenario();
        e.repositorio.filas = [
          _aviso('pasado'),
          _aviso('pronto', idLocal: 2, desfase: const Duration(minutes: 30)),
          _aviso('tarde', idLocal: 3, desfase: const Duration(hours: 2)),
          _aviso(
            'anulado',
            idLocal: 4,
            desfase: const Duration(minutes: 10),
            activa: false,
          ),
        ];
        await e.vm.sincronizar();
        expect(e.vm.noLeidas, 1);

        // espera hasta el aviso activo mas cercano, no hasta el anulado
        final primero = e.refrescoActivo!;
        expect(primero.espera, const Duration(minutes: 30, seconds: 1));

        var avisosAlOyente = 0;
        e.vm.addListener(() => avisosAlOyente++);
        e.ahora = _ahora.add(const Duration(minutes: 30, seconds: 1));
        primero.vencer();

        expect(avisosAlOyente, 1);
        expect(e.vm.noLeidas, 2);
        expect(e.vm.historial.first.id, 'pronto');
        // queda programado el siguiente
        expect(e.refrescoActivo!.espera, const Duration(hours: 1, minutes: 30));
      },
    );

    test(
      'sin avisos futuros no programa refresco y cerrar sesion lo cancela',
      () async {
        final e = _Escenario();
        e.repositorio.filas = [_aviso('pasado')];
        await e.vm.sincronizar();
        expect(e.refrescoActivo, isNull);

        e.repositorio.filas = [
          _aviso('futuro', desfase: const Duration(hours: 1)),
        ];
        await e.vm.sincronizar();
        final refresco = e.refrescoActivo!;

        // una nueva sincronizacion reemplaza el refresco anterior
        await e.vm.sincronizar();
        expect(refresco.isActive, isFalse);
        expect(e.temporizadores.where((t) => t.isActive).length, 1);

        await e.vm.limpiar();
        expect(e.refrescoActivo, isNull);
      },
    );

    test('error al leer conserva el mensaje', () async {
      final e = _Escenario();
      e.repositorio.error = const AppException('Sin conexión.');
      await e.vm.sincronizar();
      expect(e.vm.error, 'Sin conexión.');
      expect(e.vm.cargado, isFalse);
    });

    test('payload con id y ruta', () {
      final aviso = _aviso('n1', ruta: '/salidas/p1/votacion');
      final payload = NotificacionesViewModel.payloadDe(aviso);
      final datos = NotificacionesViewModel.leerPayload(payload);
      expect(datos?.id, 'n1');
      expect(datos?.ruta, '/salidas/p1/votacion');
      expect(NotificacionesViewModel.leerPayload('sin-separador'), isNull);
      expect(NotificacionesViewModel.leerPayload(null), isNull);
    });
  });

  group('NotificacionesScreen', () {
    testWidgets('muestra permiso activado, avisos con plan y boton por tipo', (
      tester,
    ) async {
      final e = _Escenario();
      e.repositorio.filas = [
        _aviso('a', tipo: TipoNotificacion.voto, ruta: '/salidas/p1/votacion'),
        _aviso(
          'b',
          tipo: TipoNotificacion.cancelacion,
          desfase: const Duration(hours: -3),
          leida: true,
          plan: 'Tarde en Cayma',
        ),
      ];
      await e.vm.sincronizar();

      await tester.pumpWidget(_pantalla(e.vm));
      await tester.pumpAndSettle();

      expect(find.text('Avisos activados'), findsOneWidget);
      expect(find.text('Activar avisos'), findsNothing);
      expect(find.text('1 nueva'), findsOneWidget);
      expect(find.text('Prueba hora'), findsOneWidget);
      expect(find.text('Tarde en Cayma'), findsOneWidget);
      expect(find.text('Ir a votar'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Detalles'), 200);
      expect(find.text('Detalles'), findsOneWidget);
      expect(find.bySemanticsLabel('No leído'), findsOneWidget);
    });

    testWidgets('abrir un aviso lo marca leido y va a su ruta', (tester) async {
      final e = _Escenario();
      e.repositorio.filas = [
        _aviso('a', tipo: TipoNotificacion.voto, ruta: '/salidas/p1/votacion'),
      ];
      await e.vm.sincronizar();
      final visitas = <String>[];

      await tester.pumpWidget(_pantalla(e.vm, visitas: visitas));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ir a votar'));
      await tester.pumpAndSettle();

      expect(find.text('Votacion'), findsOneWidget);
      expect(visitas.last, '/salidas/p1/votacion');
      expect(e.repositorio.marcadasLeidas, ['a']);
      expect(e.vm.noLeidas, 0);
    });

    testWidgets('leidas marca todos y oculta el contador', (tester) async {
      final e = _Escenario();
      e.repositorio.filas = [_aviso('a'), _aviso('b')];
      await e.vm.sincronizar();

      await tester.pumpWidget(_pantalla(e.vm));
      await tester.pumpAndSettle();
      expect(find.text('2 nuevas'), findsOneWidget);

      await tester.tap(find.text('Leídas'));
      await tester.pumpAndSettle();

      expect(find.text('2 nuevas'), findsNothing);
      expect(e.repositorio.marcadasLeidas, ['a', 'b']);
    });

    testWidgets('sin permiso ofrece activarlo e indica ajustes si se niega', (
      tester,
    ) async {
      final e = _Escenario();
      e.avisos.permiso = false;
      e.avisos.concederAlPedir = false;
      await e.vm.sincronizar();

      await tester.pumpWidget(_pantalla(e.vm));
      await tester.pumpAndSettle();
      expect(find.text('Avisos desactivados'), findsOneWidget);
      expect(find.textContaining('Ajustes del teléfono'), findsNothing);

      await tester.tap(find.text('Activar avisos'));
      await tester.pumpAndSettle();

      expect(e.avisos.pedidos, 1);
      expect(find.textContaining('Ajustes del teléfono'), findsOneWidget);
    });

    testWidgets('historial vacio', (tester) async {
      final e = _Escenario();
      await e.vm.sincronizar();

      await tester.pumpWidget(_pantalla(e.vm));
      await tester.pumpAndSettle();

      expect(find.text('Sin avisos todavía'), findsOneWidget);
      expect(find.textContaining('30 minutos antes'), findsOneWidget);
    });

    testWidgets('error de carga con reintento', (tester) async {
      final e = _Escenario();
      e.repositorio.error = const AppException('Sin conexión.');
      await e.vm.sincronizar();

      await tester.pumpWidget(_pantalla(e.vm));
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión.'), findsOneWidget);

      e.repositorio.error = null;
      e.repositorio.filas = [_aviso('a')];
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Prueba hora'), findsOneWidget);
    });
  });
}
