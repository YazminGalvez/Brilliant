import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: valores iniciales según la zona', () {
    final botonInicio = find.byKey(const Key('start-game'));

    Finder celda(int fila, int columna) =>
        find.byKey(Key('cell-$fila-$columna'));

    Finder opcionDelDialogo(String texto) => find.descendant(
      of: find.byType(SimpleDialog),
      matching: find.text(texto),
    );

    testWidgets('El diálogo de la celda naranja de 4 a 6 no ofrece 1, 2 ni 3', (
      tester,
    ) async {
      await abrirPartida(tester, Partida(mapa: mapaCuatro));

      await tocar(tester, celda(1, 5));

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(opcionDelDialogo('1'), findsNothing);
      expect(opcionDelDialogo('2'), findsNothing);
      expect(opcionDelDialogo('3'), findsNothing);
      expect(opcionDelDialogo('4'), findsOneWidget);
      expect(opcionDelDialogo('5'), findsOneWidget);
      expect(opcionDelDialogo('6'), findsOneWidget);
    });

    testWidgets('El diálogo de la celda naranja de 1 a 3 no ofrece 4, 5 ni 6', (
      tester,
    ) async {
      await abrirPartida(tester, Partida(mapa: mapaCuatro));

      await tocar(tester, celda(7, 2));

      expect(opcionDelDialogo('1'), findsOneWidget);
      expect(opcionDelDialogo('2'), findsOneWidget);
      expect(opcionDelDialogo('3'), findsOneWidget);
      expect(opcionDelDialogo('4'), findsNothing);
      expect(opcionDelDialogo('5'), findsNothing);
      expect(opcionDelDialogo('6'), findsNothing);
    });

    testWidgets(
      'El diálogo tampoco ofrece un número que la zona acepta pero ya se usó',
      (tester) async {
        await abrirPartida(tester, Partida(mapa: mapaCuatro));
        await ingresarNumeroInicial(tester, (3, 3), 5);

        await tocar(tester, celda(1, 5));

        expect(opcionDelDialogo('4'), findsOneWidget);
        expect(opcionDelDialogo('5'), findsNothing);
        expect(opcionDelDialogo('6'), findsOneWidget);
        expect(opcionDelDialogo('3'), findsNothing);
      },
    );

    testWidgets('Una celda con número sigue ofreciendo su propio número', (
      tester,
    ) async {
      await abrirPartida(tester, Partida(mapa: mapaCuatro));
      await ingresarNumeroInicial(tester, (1, 5), 5);
      expect(
        find.descendant(of: celda(1, 5), matching: find.text('5')),
        findsOneWidget,
      );

      await tocar(tester, celda(1, 5));

      expect(opcionDelDialogo('4'), findsOneWidget);
      expect(opcionDelDialogo('5'), findsOneWidget);
      expect(opcionDelDialogo('6'), findsOneWidget);
      expect(opcionDelDialogo('Vaciar celda'), findsOneWidget);
    });

    testWidgets(
      'Una celda de una zona sin rango sigue ofreciendo los seis números',
      (tester) async {
        await abrirPartida(tester, Partida(mapa: mapaCuatro));

        await tocar(tester, celda(3, 3));

        expect(opcionDelDialogo('1'), findsOneWidget);
        expect(opcionDelDialogo('2'), findsOneWidget);
        expect(opcionDelDialogo('3'), findsOneWidget);
        expect(opcionDelDialogo('4'), findsOneWidget);
        expect(opcionDelDialogo('5'), findsOneWidget);
        expect(opcionDelDialogo('6'), findsOneWidget);
      },
    );

    testWidgets(
      'Con un reparto que respeta las zonas se habilita Inicio en el Mapa 4',
      (tester) async {
        await abrirPartida(tester, Partida(mapa: mapaCuatro));

        await ingresarNumeroInicial(tester, (1, 5), 6);
        await ingresarNumeroInicial(tester, (3, 3), 2);
        await ingresarNumeroInicial(tester, (3, 6), 3);
        await ingresarNumeroInicial(tester, (4, 1), 4);
        await ingresarNumeroInicial(tester, (6, 5), 5);
        await ingresarNumeroInicial(tester, (7, 2), 1);

        expect(tester.widget<FilledButton>(botonInicio).onPressed, isNotNull);
        await tocar(tester, botonInicio);
        expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);
      },
    );
  });
}
