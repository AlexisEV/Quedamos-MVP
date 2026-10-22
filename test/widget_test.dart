import 'dart:async';

import 'package:app/app/router.dart';
import 'package:app/app/theme/app_theme.dart';
import 'package:app/features/auth/presentation/acceso_screen.dart';
import 'package:app/features/auth/presentation/sesion_view_model.dart';
import 'package:app/features/lugares/presentation/explorar_screen.dart';
import 'package:app/features/salidas/presentation/mis_salidas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// monta el router real con una sesion controlada por la prueba
Future<StreamController<bool>> montarApp(
  WidgetTester tester, {
  required bool haySesion,
}) async {
  final cambios = StreamController<bool>();
  final sesion = SesionViewModel(
    haySesionInicial: haySesion,
    cambiosDeSesion: cambios.stream,
  );
  final router = crearRouter(sesion);
  addTearDown(() {
    router.dispose();
    sesion.dispose();
    cambios.close();
  });
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.claro, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return cambios;
}

void main() {
  testWidgets('sin sesion redirige a acceso', (tester) async {
    await montarApp(tester, haySesion: false);

    expect(find.byType(AccesoScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('con sesion muestra las 4 pestanas y cambia de pestana', (
    tester,
  ) async {
    await montarApp(tester, haySesion: true);

    expect(find.byType(MisSalidasScreen), findsOneWidget);
    for (final etiqueta in ['Mis salidas', 'Explorar', 'Avisos', 'Perfil']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(etiqueta),
        ),
        findsOneWidget,
      );
    }

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ExplorarScreen), findsOneWidget);
  });

  testWidgets('al cerrar sesion vuelve a acceso', (tester) async {
    final cambios = await montarApp(tester, haySesion: true);

    cambios.add(false);
    await tester.pumpAndSettle();
    expect(find.byType(AccesoScreen), findsOneWidget);
  });
}
