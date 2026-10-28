import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
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

class DadosFijos implements Random {
  DadosFijos(List<int> valores) : _valores = List.of(valores);

  final List<int> _valores;
  var _indice = 0;

  @override
  int nextInt(int max) {
    if (_indice >= _valores.length) {
      throw StateError('DadosFijos no tiene más valores para lanzar.');
    }
    final valor = _valores[_indice++];
    if (valor < 1 || valor > max) {
      throw RangeError.range(valor, 1, max, 'valor del dado');
    }
    return valor - 1;
  }

  @override
  double nextDouble() =>
      throw UnsupportedError('DadosFijos solo sirve para lanzar dados.');

  @override
  bool nextBool() =>
      throw UnsupportedError('DadosFijos solo sirve para lanzar dados.');
}

Future<void> abrirPartida(
  WidgetTester tester,
  Partida partida, {
  Random? random,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TableroPage(partida: partida, random: random),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> abrirPantallaNueva(WidgetTester tester, {Random? random}) =>
    abrirPartida(tester, Partida(mapa: mapaUno), random: random);

Future<void> lanzarDados(WidgetTester tester) =>
    tocar(tester, find.byKey(const Key('roll-dice-button')));

Future<void> elegirAncla(WidgetTester tester, int ancla) =>
    tocar(tester, find.byKey(Key('anchor-option-$ancla')));

Future<void> tocarDestino(WidgetTester tester, int fila, int columna) =>
    tocar(tester, find.byKey(Key('cell-$fila-$columna')));

Future<void> ingresarNumerosIniciales(
  WidgetTester tester, {
  int cantidad = 6,
}) async {
  final celdas = mapaUno.celdasIniciales;
  for (var index = 0; index < cantidad; index++) {
    await ingresarNumeroInicial(tester, celdas[index], index + 1);
  }
}

Future<void> vaciarCeldaInicial(WidgetTester tester, (int, int) celda) async {
  await tocar(tester, find.byKey(Key('cell-${celda.$1}-${celda.$2}')));
  await tocar(tester, find.text('Vaciar celda'));
}
