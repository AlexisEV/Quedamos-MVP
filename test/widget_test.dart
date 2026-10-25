import 'dart:async';

import 'package:app/app/router.dart';
import 'package:app/app/theme/app_theme.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/presentation/acceso_screen.dart';
import 'package:app/features/auth/presentation/sesion_view_model.dart';
import 'package:app/features/lugares/data/lugar_model.dart';
import 'package:app/features/lugares/data/lugares_repository.dart';
import 'package:app/features/lugares/data/propuestas_repository.dart';
import 'package:app/features/lugares/presentation/destino_propuesta.dart';
import 'package:app/features/lugares/presentation/explorar_screen.dart';
import 'package:app/features/lugares/presentation/ficha_lugar_screen.dart';
import 'package:app/features/perfil/data/perfil_model.dart';
import 'package:app/features/perfil/data/perfil_repository.dart';
import 'package:app/features/perfil/presentation/perfil_screen.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';
import 'package:app/features/salidas/presentation/detalle_plan_screen.dart';
import 'package:app/features/salidas/presentation/mis_salidas_screen.dart';
import 'package:app/features/votacion/data/votacion_repository.dart';
import 'package:app/features/votacion/presentation/preparar_votacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

// monta el router real con una sesion controlada por la prueba
Future<StreamController<bool>> montarApp(
  WidgetTester tester, {
  required bool haySesion,
  FakeAuthRepository? auth,
  FakeSalidasRepository? salidas,
  FakeLugaresRepository? lugares,
  FakePropuestasRepository? propuestas,
  FakeVotacionRepository? votacion,
}) async {
  final repoSalidas = salidas ?? FakeSalidasRepository();
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
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: auth ?? FakeAuthRepository()),
        Provider<PerfilRepository>.value(
          value: FakePerfilRepository(
            const PerfilModel(
              id: 'u1',
              nombreVisible: 'Mateo',
              correo: 'mateo@correo.com',
            ),
          ),
        ),
        Provider<SalidasRepository>.value(value: repoSalidas),
        Provider<LugaresRepository>.value(
          value: lugares ?? FakeLugaresRepository(),
        ),
        Provider<PropuestasRepository>.value(
          value: propuestas ?? FakePropuestasRepository(),
        ),
        Provider<VotacionRepository>.value(
          value: votacion ?? FakeVotacionRepository(repoSalidas),
        ),
        ChangeNotifierProvider<DestinoPropuesta>(
          create: (_) => DestinoPropuesta(),
        ),
      ],
      // mismo idioma que la app para probar calendario y reloj en espanol
      child: MaterialApp.router(
        theme: AppTheme.claro,
        routerConfig: router,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
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

  testWidgets('el registro valida los campos antes de llamar al servidor', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await montarApp(tester, haySesion: false, auth: auth);

    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu nombre visible.'), findsOneWidget);
    expect(find.text('Ingresa tu correo.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    expect(auth.llamadas, isEmpty);
  });

  testWidgets('la pestana perfil muestra nombre, correo y cerrar sesion', (
    tester,
  ) async {
    await montarApp(tester, haySesion: true);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(PerfilScreen), findsOneWidget);
    expect(find.text('Mateo'), findsOneWidget);
    expect(find.text('mateo@correo.com'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('crear plan valida, crea y lleva al detalle con el codigo', (
    tester,
  ) async {
    final salidas = FakeSalidasRepository();
    await montarApp(tester, haySesion: true, salidas: salidas);
    expect(find.text('Aún no tienes salidas'), findsOneWidget);

    await tester.tap(find.text('Crear nueva salida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear plan').last);
    await tester.pumpAndSettle();
    expect(find.text('Ingresa el nombre del plan.'), findsOneWidget);
    expect(find.text('Ingresa el presupuesto.'), findsOneWidget);
    expect(salidas.creados, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(0), 'Sábado');
    await tester.enterText(find.byType(TextFormField).at(1), '70');
    await tester.tap(find.text('Crear plan').last);
    await tester.pumpAndSettle();

    expect(find.byType(DetallePlanScreen), findsOneWidget);
    expect(find.text('AQP48X'), findsOneWidget);
    expect(find.text('Copiar código'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Planes activos'), findsOneWidget);
    expect(find.text('Sábado'), findsOneWidget);
  });

  testWidgets('explorar sin lugares muestra el estado vacio', (tester) async {
    await montarApp(tester, haySesion: true);

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay lugares en el catálogo'), findsOneWidget);
  });

  testWidgets('explorar abre la ficha y marca los datos desconocidos', (
    tester,
  ) async {
    final lugares = FakeLugaresRepository([
      lugarDePrueba(
        id: 'l1',
        nombre: 'Picantería de prueba',
        precioEstimadoPen: 38,
        precioNota: 'plato de fondo',
      ),
      lugarDePrueba(
        id: 'l2',
        nombre: 'Bar de prueba',
        categoria: CategoriaLugar.bares,
      ),
    ]);
    await montarApp(tester, haySesion: true, lugares: lugares);

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    expect(find.text('S/ 38.00 / pers. (estimado)'), findsOneWidget);
    expect(find.text('Precio desconocido'), findsOneWidget);
    expect(find.text('Horario desconocido'), findsNWidgets(2));

    await tester.tap(find.text('Bar de prueba'));
    await tester.pumpAndSettle();
    expect(find.byType(FichaLugarScreen), findsOneWidget);
    expect(find.text('Desconocido'), findsNWidgets(3));
    expect(find.text('Cercado, Arequipa'), findsNothing);
    expect(find.text('Yanahuara, Arequipa'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Picantería de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 38.00'), findsOneWidget);
    expect(
      find.text('plato de fondo\nPrecio orientativo, puede variar.'),
      findsOneWidget,
    );
  });

  testWidgets('la ficha propone eligiendo el plan y luego marca ya propuesto', (
    tester,
  ) async {
    final plan = planDePrueba(id: 'p1', nombre: 'Sábado');
    final propuestas = FakePropuestasRepository(
      salidas: [
        SalidaModel(
          plan: plan,
          miRol: RolPlan.administrador,
          esCreador: true,
          totalParticipantes: 2,
        ),
      ],
      lugares: {'l1': 'Bar de prueba'},
    );
    await montarApp(
      tester,
      haySesion: true,
      lugares: FakeLugaresRepository([
        lugarDePrueba(id: 'l1', nombre: 'Bar de prueba'),
      ]),
      propuestas: propuestas,
    );

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bar de prueba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proponer al grupo'));
    await tester.pumpAndSettle();
    expect(find.text('Elegir plan de destino'), findsOneWidget);
    expect(find.text('Tus propuestas 0/3'), findsOneWidget);

    await tester.tap(find.text('Sábado'));
    await tester.pumpAndSettle();
    expect(propuestas.llamadasProponer, ['p1:l1']);
    expect(find.text('Propuesto en Sábado.'), findsOneWidget);
    expect(find.text('Ya propuesto en este plan'), findsOneWidget);
    expect(find.text('Proponer para: Sábado'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Proponer para'), findsOneWidget);
  });

  testWidgets('sin salidas que reciban propuestas el selector lo explica', (
    tester,
  ) async {
    await montarApp(
      tester,
      haySesion: true,
      lugares: FakeLugaresRepository([lugarDePrueba(id: 'l1')]),
    );

    await tester.tap(find.byIcon(Icons.explore_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lugar de prueba'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proponer al grupo'));
    await tester.pumpAndSettle();
    expect(
      find.text('No tienes salidas recibiendo propuestas'),
      findsOneWidget,
    );
  });

  testWidgets('el admin prepara y abre la votacion con confirmacion', (
    tester,
  ) async {
    final salidas = FakeSalidasRepository()
      ..salidas.add(
        SalidaModel(
          plan: planDePrueba(),
          miRol: RolPlan.administrador,
          esCreador: true,
          totalParticipantes: 2,
        ),
      );
    final propuestas = FakePropuestasRepository()
      ..propuestas.addAll([
        propuestaDePrueba(id: 'pr1', lugarId: 'l1', nombreLugar: 'Café uno'),
        propuestaDePrueba(id: 'pr2', lugarId: 'l2', nombreLugar: 'Bar dos'),
      ]);
    final votacion = FakeVotacionRepository(salidas);
    // lista de la pantalla visible; el shell tiene otras ramas montadas
    Finder lista() => find
        .descendant(
          of: find.byType(ListView).hitTestable(),
          matching: find.byType(Scrollable),
        )
        .first;
    await montarApp(
      tester,
      haySesion: true,
      salidas: salidas,
      propuestas: propuestas,
      votacion: votacion,
    );

    await tester.tap(find.text('Sábado en Yanahuara'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Preparar votación'),
      200,
      scrollable: lista(),
    );
    await tester.tap(find.text('Preparar votación'));
    await tester.pumpAndSettle();
    expect(find.byType(PrepararVotacionScreen), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bar dos'),
      200,
      scrollable: lista(),
    );
    await tester.ensureVisible(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abrir votación'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se puede deshacer'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Abrir votación'));
    await tester.pumpAndSettle();

    expect(votacion.llamadas, ['candidatos:1', 'abrir']);
    expect(find.byType(DetallePlanScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Candidatos (1)'),
      -200,
      scrollable: lista(),
    );
    expect(find.text('Preparar votación'), findsNothing);
  });

  testWidgets('el plazo de voto se elige con reloj de 12 horas', (
    tester,
  ) async {
    final salidas = FakeSalidasRepository()
      ..salidas.add(
        SalidaModel(
          plan: planDePrueba(),
          miRol: RolPlan.administrador,
          esCreador: true,
          totalParticipantes: 2,
        ),
      );
    await montarApp(tester, haySesion: true, salidas: salidas);
    final router = GoRouter.of(tester.element(find.byType(MisSalidasScreen)));
    router.go('/salidas/p1/votacion');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Definir'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).hitTestable(),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Definir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Hora límite (hora de Lima)'), findsOneWidget);
    expect(find.text('a.m.'), findsOneWidget);
    expect(find.text('p.m.'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    expect(find.textContaining('20:00'), findsOneWidget);
  });
}
