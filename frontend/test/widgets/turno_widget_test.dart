import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: turno de juego', () {
    int? valorEn(Partida partida, int fila, int columna) =>
        partida.tablero.obtenerCelda(fila - 1, columna - 1).valor;

    Finder opcion(int ancla) => find.byKey(Key('anchor-option-$ancla'));

    bool opcionHabilitada(WidgetTester tester, int ancla) =>
        tester.widget<OutlinedButton>(opcion(ancla)).onPressed != null;

    Finder textoEnCelda(int fila, int columna, String texto) => find.descendant(
      of: find.byKey(Key('cell-$fila-$columna')),
      matching: find.text(texto),
    );

    Set<(int, int)> destinosIluminados(WidgetTester tester) => {
      for (var fila = 1; fila <= 7; fila++)
        for (var columna = 1; columna <= 7; columna++)
          if (find
              .byKey(Key('valid-move-cell-$fila-$columna'))
              .evaluate()
              .isNotEmpty)
            (fila, columna),
    };

    testWidgets(
      'Después de lanzar aparece el panel con las opciones de ancla',
      (tester) async {
        await abrirPartida(
          tester,
          partidaEnJuego(),
          random: DadosFijos([1, 2]),
        );
        expect(find.byKey(const Key('anchor-options-panel')), findsNothing);

        await lanzarDados(tester);

        expect(find.byKey(const Key('anchor-options-panel')), findsOneWidget);
        expect(find.text('Ancla 1 · colocar 2'), findsOneWidget);
        expect(find.text('Ancla 2 · colocar 1'), findsOneWidget);
        expect(opcionHabilitada(tester, 1), isTrue);
        expect(opcionHabilitada(tester, 2), isTrue);
      },
    );

    testWidgets(
      'Una opción cuyo número no está en el tablero sale deshabilitada',
      (tester) async {
        final partida = partidaEnJuego();
        partida.tablero.colocarDato(6, 4, null);
        expect(partida.tablero.valoresColocados, isNot(contains(6)));

        await abrirPartida(tester, partida, random: DadosFijos([1, 6]));
        await lanzarDados(tester);

        expect(opcionHabilitada(tester, 1), isTrue);
        expect(opcionHabilitada(tester, 6), isFalse);
      },
    );

    testWidgets('Con dados dobles solo aparece una opción de ancla', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego(), random: DadosFijos([4, 4]));

      await lanzarDados(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('anchor-options-panel')),
          matching: find.byType(OutlinedButton),
        ),
        findsOneWidget,
      );
      expect(find.text('Ancla 4 · colocar 4'), findsOneWidget);
    });

    testWidgets('Elegir un ancla ilumina solo los destinos válidos', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego(), random: DadosFijos([1, 2]));
      await lanzarDados(tester);
      expect(destinosIluminados(tester), isEmpty);

      await elegirAncla(tester, 1);

      expect(destinosIluminados(tester), {(1, 2), (1, 4)});
    });

    testWidgets(
      'Tocar un destino coloca el número del otro dado en esa celda',
      (tester) async {
        final partida = partidaEnJuego();
        await abrirPartida(tester, partida, random: DadosFijos([1, 2]));
        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        await tocarDestino(tester, 1, 2);

        expect(valorEn(partida, 1, 2), 2);
        expect(textoEnCelda(1, 2, '2'), findsOneWidget);
        expect(destinosIluminados(tester), isEmpty);
      },
    );

    testWidgets(
      'Después de colocar las anclas quedan bloqueadas hasta lanzar de nuevo',
      (tester) async {
        await abrirPartida(
          tester,
          partidaEnJuego(),
          random: DadosFijos([1, 2, 3, 4]),
        );
        await lanzarDados(tester);
        await elegirAncla(tester, 1);
        await tocarDestino(tester, 1, 2);

        expect(opcionHabilitada(tester, 1), isFalse);
        expect(opcionHabilitada(tester, 2), isFalse);
        expect(
          find.text('Lanza los dados para elegir otra ancla'),
          findsOneWidget,
        );

        await lanzarDados(tester);

        expect(opcionHabilitada(tester, 3), isTrue);
        expect(opcionHabilitada(tester, 4), isTrue);
        expect(find.text('Elige un ancla'), findsOneWidget);
      },
    );

    testWidgets('Tocar una celda que no está iluminada no coloca nada', (
      tester,
    ) async {
      final partida = partidaEnJuego();
      await abrirPartida(tester, partida, random: DadosFijos([1, 2]));
      await lanzarDados(tester);
      await elegirAncla(tester, 1);

      await tocarDestino(tester, 2, 3);
      await tocarDestino(tester, 7, 7);

      expect(valorEn(partida, 2, 3), isNull);
      expect(valorEn(partida, 7, 7), isNull);
      expect(partida.historialMovimientos.movimientos, isEmpty);
      expect(destinosIluminados(tester), {(1, 2), (1, 4)});
    });
  });
}
