import 'package:app/app/theme/app_theme.dart';
import 'package:app/features/itinerario/data/itinerario_repository.dart';
import 'package:app/features/itinerario/presentation/revisar_itinerario_screen.dart';
import 'package:app/features/salidas/data/plan_model.dart';
import 'package:app/features/salidas/data/salidas_repository.dart';
import 'package:app/features/votacion/data/votacion_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

void main() {
  // con el tema real: sus botones tienen ancho infinito y fallan dentro de una fila
  testWidgets('el admin ve flechas, fecha y hora y confirmar desactivado', (
    tester,
  ) async {
    final salidas = FakeSalidasRepository();
    salidas.salidas.add(
      SalidaModel(
        plan: planDePrueba(estado: EstadoPlan.preparandoItinerario),
        miRol: RolPlan.administrador,
        esCreador: true,
        totalParticipantes: 2,
      ),
    );
    final votacion = FakeVotacionRepository(salidas);
    votacion.candidatosPorPlan['p1'] = ['l1', 'l2'];
    votacion.totalesCerrados.addAll({'cl1': 2, 'cl2': 1});
    votacion.seleccionados.addAll({'cl1', 'cl2'});
    final itinerario = FakeItinerarioRepository(salidas)
      ..sembrar('p1', ['l1', 'l2']);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SalidasRepository>.value(value: salidas),
          Provider<VotacionRepository>.value(value: votacion),
          Provider<ItinerarioRepository>.value(value: itinerario),
        ],
        child: MaterialApp(
          theme: AppTheme.claro,
          home: const RevisarItinerarioScreen(planId: 'p1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Asignar fecha y hora'), findsWidgets);
    expect(find.text('Sin fecha/hora'), findsWidgets);

    await tester.tap(find.byTooltip('Bajar').first);
    await tester.pump();
    final nombres = tester
        .widgetList<Text>(find.textContaining('Lugar l'))
        .map((t) => t.data)
        .toList();
    expect(nombres.take(2), ['Lugar l2', 'Lugar l1']);

    await tester.scrollUntilVisible(find.text('Confirmar itinerario'), 300);
    final confirmar = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Confirmar itinerario'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    expect(confirmar.onPressed, isNull);
    expect(
      find.text('Asigna fecha y hora a todas las actividades para confirmar.'),
      findsOneWidget,
    );
  });
}
