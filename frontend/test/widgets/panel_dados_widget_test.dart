import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: panel de dados', () {
    final botonLanzar = find.byKey(const Key('roll-dice-button'));

    bool lanzarHabilitado(WidgetTester tester) =>
        tester.widget<FilledButton>(botonLanzar).onPressed != null;

    testWidgets(
      'Antes de lanzar los dados muestran una raya y se puede lanzar',
      (tester) async {
        await abrirPartida(tester, partidaEnJuego(), random: DadosFijos([]));

        expect(find.text('Dado 1: —'), findsOneWidget);
        expect(find.text('Dado 2: —'), findsOneWidget);
        expect(lanzarHabilitado(tester), isTrue);
      },
    );

    testWidgets('Al lanzar los dos dados muestran los valores fijados', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego(), random: DadosFijos([2, 5]));

      await lanzarDados(tester);

      expect(find.byKey(const Key('die-face-2')), findsOneWidget);
      expect(find.byKey(const Key('die-face-5')), findsOneWidget);
      expect(find.text('Dado 1: 2'), findsOneWidget);
      expect(find.text('Dado 2: 5'), findsOneWidget);
    });

    testWidgets(
      'Mientras los dados giran no se puede lanzar y al terminar sí',
      (tester) async {
        await abrirPartida(
          tester,
          partidaEnJuego(),
          random: DadosFijos([1, 2]),
        );

        await tester.ensureVisible(botonLanzar);
        await tester.tap(botonLanzar);
        await tester.pump();
        expect(lanzarHabilitado(tester), isFalse);

        await tester.pumpAndSettle();
        expect(lanzarHabilitado(tester), isTrue);
      },
    );

    testWidgets('Cada lanzamiento suma una sola tirada al historial', (
      tester,
    ) async {
      final partida = partidaEnJuego();
      await abrirPartida(tester, partida, random: DadosFijos([1, 2, 3, 4]));
      expect(partida.historialLanzamientos.cantidad, 0);

      await lanzarDados(tester);
      expect(partida.historialLanzamientos.cantidad, 1);
      expect(find.byKey(const Key('dice-roll-history-item-1')), findsOneWidget);
      expect(find.byKey(const Key('dice-roll-history-item-2')), findsNothing);

      await lanzarDados(tester);
      expect(partida.historialLanzamientos.cantidad, 2);
      expect(find.byKey(const Key('dice-roll-history-item-2')), findsOneWidget);
      expect(find.byKey(const Key('dice-roll-history-item-3')), findsNothing);
    });

    testWidgets('Con la partida terminada no se puede lanzar', (tester) async {
      final partida = partidaCasiTerminada();
      await abrirPartida(tester, partida, random: DadosFijos([1, 3]));
      await lanzarDados(tester);
      await elegirAncla(tester, 1);

      await tocarDestino(tester, 7, 7);

      expect(partida.estado, EstadoPartida.terminada);
      expect(find.byKey(const Key('game-over-panel')), findsOneWidget);
      expect(lanzarHabilitado(tester), isFalse);
    });
  });
}
