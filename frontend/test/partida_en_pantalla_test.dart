import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';

import 'helpers.dart';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    Partida partida, {
    List<List<int>>? tiradas,
  }) => tester.pumpWidget(
    MaterialApp(
      home: TableroPage(
        partida: partida,
        random: tiradas == null ? null : Random(semillaParaTiradas(tiradas)),
      ),
    ),
  );

  FilledButton botonLanzar(WidgetTester tester) => tester.widget<FilledButton>(
    find.byKey(const Key('roll-dice-button')),
  );

  testWidgets('con una partida en juego se abre ya jugando', (tester) async {
    await abrir(tester, partidaEnJuego());

    expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);
    expect(find.byKey(const Key('dice-roll-history-panel')), findsOneWidget);
    expect(find.byKey(const Key('movement-history-panel')), findsOneWidget);
    expect(find.byKey(const Key('scoreboard')), findsOneWidget);
    expect(find.byKey(const Key('start-game')), findsNothing);
  });

  testWidgets('Inicio se habilita solo con los 6 números válidos', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TableroPage()));
    FilledButton botonInicio() =>
        tester.widget<FilledButton>(find.byKey(const Key('start-game')));

    final celdas = mapaUno.celdasIniciales;
    for (var index = 0; index < 5; index++) {
      await ingresarNumeroInicial(tester, celdas[index], index + 1);
    }
    expect(botonInicio().onPressed, isNull);

    await ingresarNumeroInicial(tester, celdas.last, 6);
    expect(botonInicio().onPressed, isNotNull);
  });

  testWidgets('lanza, elige ancla y coloca en un destino válido', (
    tester,
  ) async {
    await abrir(
      tester,
      partidaEnJuego(),
      tiradas: [
        [4, 6],
      ],
    );

    await tocar(tester, find.byKey(const Key('roll-dice-button')));
    await tocar(tester, find.byKey(const Key('anchor-option-4')));
    expect(find.byKey(const Key('valid-move-marker-4-4')), findsOneWidget);
    await tocar(tester, find.byKey(const Key('cell-4-4')));

    expect(
      find.descendant(
        of: find.byKey(const Key('cell-4-4')),
        matching: find.text('6'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Tirada 1: colocaste el 6 en fila 4, columna 4 (ancla 4)'),
      findsOneWidget,
    );
  });

  testWidgets('al llenar una zona el marcador muestra sus puntos', (
    tester,
  ) async {
    final partida = partidaEnJuego();
    partida.tablero
      ..colocarDato(1, 2, 1)
      ..colocarDato(1, 3, 1);
    await abrir(
      tester,
      partida,
      tiradas: [
        [1, 1],
      ],
    );

    await tocar(tester, find.byKey(const Key('roll-dice-button')));
    await tocar(tester, find.byKey(const Key('anchor-option-1')));
    await tocar(tester, find.byKey(const Key('cell-3-4')));

    expect(find.text('Puntuación total: 7'), findsOneWidget);
    expect(find.byKey(const Key('zone-score-2')), findsOneWidget);
    expect(find.text('Zona Azul 3: 7 puntos'), findsOneWidget);
    expect(find.text('Tirada 1: completaste la zona azul'), findsOneWidget);
    expect(find.text('Tirada 1: ganaste 7 puntos'), findsOneWidget);
  });

  testWidgets('muestra el fin de partida y permite empezar otra', (
    tester,
  ) async {
    final partida = partidaCasiTerminada();
    await abrir(
      tester,
      partida,
      tiradas: [
        [1, 2],
      ],
    );
    expect(find.byKey(const Key('game-over-panel')), findsNothing);

    await tocar(tester, find.byKey(const Key('roll-dice-button')));
    await tocar(tester, find.byKey(const Key('anchor-option-1')));
    await tocar(tester, find.byKey(const Key('cell-7-7')));

    expect(find.byKey(const Key('game-over-panel')), findsOneWidget);
    expect(find.text('Partida terminada'), findsOneWidget);
    expect(find.text('Puntuación final: 4 de 4'), findsOneWidget);
    expect(find.byKey(const Key('final-score')), findsOneWidget);
    expect(botonLanzar(tester).onPressed, isNull);
    expect(find.byKey(const Key('skip-turn-button')), findsNothing);

    await tocar(tester, find.byKey(const Key('new-game-button')));

    expect(find.byKey(const Key('start-game')), findsOneWidget);
    expect(find.byKey(const Key('game-over-panel')), findsNothing);
    expect(find.byKey(const Key('roll-dice-button')), findsNothing);
    expect(partida.estado, EstadoPartida.preparando);
    expect(partida.puntuacionTotal, 0);
    for (var fila = 1; fila <= 7; fila++) {
      for (var columna = 1; columna <= 7; columna++) {
        expect(
          find.descendant(
            of: find.byKey(Key('cell-$fila-$columna')),
            matching: find.byWidgetPredicate(
              (widget) => widget is Text && widget.data != '+',
            ),
          ),
          findsNothing,
          reason: 'Celda ($fila, $columna)',
        );
      }
    }
  });
}
