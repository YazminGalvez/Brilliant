import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: saltar turno', () {
    final botonLanzar = find.byKey(const Key('roll-dice-button'));
    final botonSaltar = find.byKey(const Key('skip-turn-button'));
    final avisoSinJugadas = find.byKey(const Key('no-moves-message'));

    bool lanzarHabilitado(WidgetTester tester) =>
        tester.widget<FilledButton>(botonLanzar).onPressed != null;

    List<int?> valoresDelTablero(Partida partida) => [
      for (final celda in partida.tablero.celdas) celda.valor,
    ];

    Future<Partida> abrirTiradaSinJugadas(
      WidgetTester tester, {
      List<int> dadosSiguientes = const [],
    }) async {
      final partida = partidaCasiTerminada();
      await abrirPartida(
        tester,
        partida,
        random: DadosFijos([2, 3, ...dadosSiguientes]),
      );
      await lanzarDados(tester);
      expect(partida.hayMovimientosPosibles, isFalse);
      return partida;
    }

    testWidgets(
      'Sin movimientos posibles aparecen el aviso y el botón de saltar turno',
      (tester) async {
        await abrirTiradaSinJugadas(tester);

        expect(avisoSinJugadas, findsOneWidget);
        expect(botonSaltar, findsOneWidget);
      },
    );

    testWidgets(
      'Con movimientos posibles no aparecen el aviso ni el botón de saltar turno',
      (tester) async {
        final partida = partidaCasiTerminada();
        await abrirPartida(tester, partida, random: DadosFijos([1, 3]));

        await lanzarDados(tester);

        expect(partida.hayMovimientosPosibles, isTrue);
        expect(avisoSinJugadas, findsNothing);
        expect(botonSaltar, findsNothing);
      },
    );

    testWidgets(
      'Con una tirada sin movimientos no se puede lanzar hasta saltar el turno',
      (tester) async {
        final partida = await abrirTiradaSinJugadas(tester);

        expect(lanzarHabilitado(tester), isFalse);

        await tester.ensureVisible(botonLanzar);
        await tester.tap(botonLanzar, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(partida.historialLanzamientos.cantidad, 1);
        expect(find.byKey(const Key('dice-roll-history-item-2')), findsNothing);
      },
    );

    testWidgets(
      'Al saltar el turno se puede volver a lanzar y el aviso desaparece',
      (tester) async {
        await abrirTiradaSinJugadas(tester);

        await tocar(tester, botonSaltar);

        expect(lanzarHabilitado(tester), isTrue);
        expect(avisoSinJugadas, findsNothing);
        expect(botonSaltar, findsNothing);
      },
    );

    testWidgets('Saltar el turno no cambia el tablero ni la puntuación', (
      tester,
    ) async {
      final partida = await abrirTiradaSinJugadas(tester);
      final valoresAntes = valoresDelTablero(partida);
      final puntuacionAntes = partida.puntuacionTotal;
      final textoPuntuacion = tester
          .widget<Text>(find.byKey(const Key('total-score')))
          .data;

      await tocar(tester, botonSaltar);

      expect(valoresDelTablero(partida), valoresAntes);
      expect(partida.puntuacionTotal, puntuacionAntes);
      expect(
        tester.widget<Text>(find.byKey(const Key('total-score'))).data,
        textoPuntuacion,
      );
    });

    testWidgets('No se puede saltar dos veces seguidas la misma tirada', (
      tester,
    ) async {
      final partida = await abrirTiradaSinJugadas(tester);

      await tocar(tester, botonSaltar);

      expect(botonSaltar, findsNothing);
      expect(partida.puedeSaltarTurno, isFalse);
      expect(partida.historialMovimientos.cantidad, 1);
      expect(partida.historialLanzamientos.cantidad, 1);
    });
  });
}
