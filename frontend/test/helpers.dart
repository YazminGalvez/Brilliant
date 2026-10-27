import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/dados.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';

class MapaTodoVerde extends Mapa {
  const MapaTodoVerde();

  @override
  int get numero => 0;

  @override
  List<List<ColorZona>> get colores =>
      List.generate(7, (_) => List.filled(7, ColorZona.verde));

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (1, 6),
  ];

  @override
  Set<ColorZona> get coloresUnidos => const {};
}

Partida partidaIniciada(Mapa mapa) {
  final partida = Partida(mapa: mapa);
  final celdas = mapa.celdasIniciales;
  for (var index = 0; index < celdas.length; index++) {
    final (fila, columna) = celdas[index];
    partida.colocarValorInicial(fila - 1, columna - 1, index + 1);
  }
  partida.iniciar();
  return partida;
}

Partida partidaEnJuego() => partidaIniciada(mapaUno);

Partida partidaCasiTerminada() {
  final partida = partidaIniciada(const MapaTodoVerde());
  for (final celda in partida.tablero.celdas) {
    if (celda.valor == null && !(celda.fila == 6 && celda.columna == 6)) {
      celda.valor = 1;
    }
  }
  return partida;
}

int semillaParaTiradas(List<List<int>> objetivo) {
  for (var semilla = 0; semilla < 1000000; semilla++) {
    final dados = Dados(cantidad: 2, random: Random(semilla));
    final coincide = objetivo.every((tirada) {
      final resultado = dados.lanzar();
      return resultado[0] == tirada[0] && resultado[1] == tirada[1];
    });
    if (coincide) return semilla;
  }
  throw StateError('No se encontró semilla para las tiradas solicitadas.');
}

Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> ingresarNumeroInicial(
  WidgetTester tester,
  (int, int) coordenada,
  int numero,
) async {
  await tocar(
    tester,
    find.byKey(Key('cell-${coordenada.$1}-${coordenada.$2}')),
  );
  await tester.tap(find.text('$numero').last);
  await tester.pumpAndSettle();
}
