import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:juego_brilliant/validador_anclas.dart';

void main() {
  testWidgets('muestra las opciones deshabilitadas si no hay anclas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LanzamientoDados(valoresPresentes: {})),
      ),
    );

    expect(find.byKey(const Key('anchor-options-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('anchor-options-panel')), findsOneWidget);
    final opciones = tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(opciones, isNotEmpty);
    expect(opciones.every((opcion) => opcion.onPressed == null), isTrue);
  });

  testWidgets('permite seleccionar una opción de ancla disponible', (
    tester,
  ) async {
    OpcionAncla? seleccionada;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanzamientoDados(
            valoresPresentes: {1, 2, 3, 4, 5, 6},
            onAnclaSeleccionada: (opcion) => seleccionada = opcion,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    final primeraOpcion = tester
        .widgetList<OutlinedButton>(find.byType(OutlinedButton))
        .first;
    expect(primeraOpcion.onPressed, isNotNull);
    await tester.tap(find.byWidget(primeraOpcion));

    expect(seleccionada, isNotNull);
    expect(seleccionada!.puedeSeleccionarse, isTrue);
  });

  testWidgets('no ofrece saltar turno si hay movimientos posibles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LanzamientoDados(
            valoresPresentes: {1, 2, 3, 4, 5, 6},
            puedeSaltarTurno: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skip-turn-button')), findsNothing);
    expect(find.byKey(const Key('no-moves-message')), findsNothing);
  });

  testWidgets('ofrece saltar turno con los dados quietos y avisa al tocarlo', (
    tester,
  ) async {
    var saltos = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 330,
            child: LanzamientoDados(
              valoresPresentes: const {1, 2, 3, 4, 5, 6},
              puedeSaltarTurno: true,
              onSaltarTurno: () => saltos++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('skip-turn-button')), findsNothing);
    expect(find.byKey(const Key('no-moves-message')), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skip-turn-button')), findsOneWidget);
    expect(
      find.text('No hay movimientos posibles con esta tirada'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('skip-turn-button')));
    await tester.pump();

    expect(saltos, 1);
    expect(tester.takeException(), isNull);
  });
}
