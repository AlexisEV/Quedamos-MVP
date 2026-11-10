import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_datos;
import 'package:timezone/timezone.dart' as tz;

// avisos locales del dispositivo; la interfaz permite reemplazarlos en tests
abstract class AvisosLocales {
  // al tocar un aviso se recibe su payload (ruta de destino)
  Future<void> inicializar(void Function(String? payload) alTocar);

  // payload del aviso que abrio la app desde cerrada, si lo hubo
  Future<String?> payloadDeArranque();

  Future<bool> permisoConcedido();

  // muestra el dialogo del sistema si aun puede mostrarse
  Future<bool> pedirPermiso();

  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime momento,
    required String payload,
  });

  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
    required String payload,
  });

  Future<void> cancelar(int id);

  Future<void> cancelarTodo();
}

// implementacion con flutter_local_notifications para android e ios
class AvisosLocalesPlugin implements AvisosLocales {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'avisos_plan',
      'Avisos de salidas',
      channelDescription:
          'Recordatorios de actividades, votos, asistencia y cambios del plan',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> inicializar(void Function(String? payload) alTocar) async {
    if (_inicializado) return;
    // los momentos llegan en utc; no hace falta la zona del dispositivo
    tz_datos.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // el permiso se pide aparte, tras iniciar sesion
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (respuesta) =>
          alTocar(respuesta.payload),
    );
    _inicializado = true;
  }

  @override
  Future<String?> payloadDeArranque() async {
    final detalles = await _plugin.getNotificationAppLaunchDetails();
    if (detalles == null || !detalles.didNotificationLaunchApp) return null;
    return detalles.notificationResponse?.payload;
  }

  @override
  Future<bool> permisoConcedido() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    final opciones = await _ios?.checkPermissions();
    return opciones?.isEnabled ?? false;
  }

  @override
  Future<bool> pedirPermiso() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> programar({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime momento,
    required String payload,
  }) async {
    Future<void> programarCon(AndroidScheduleMode modo) =>
        _plugin.zonedSchedule(
          id: id,
          title: titulo,
          body: cuerpo,
          scheduledDate: tz.TZDateTime.from(momento.toUtc(), tz.UTC),
          notificationDetails: _detalles,
          androidScheduleMode: modo,
          payload: payload,
        );
    try {
      // exacto con use_exact_alarm (decision 2026-11-10)
      await programarCon(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException {
      // sin permiso de alarma exacta se programa inexacto
      await programarCon(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  @override
  Future<void> mostrar({
    required int id,
    required String titulo,
    required String cuerpo,
    required String payload,
  }) {
    return _plugin.show(
      id: id,
      title: titulo,
      body: cuerpo,
      notificationDetails: _detalles,
      payload: payload,
    );
  }

  @override
  Future<void> cancelar(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelarTodo() => _plugin.cancelAll();
}
