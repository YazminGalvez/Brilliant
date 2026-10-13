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
}
