import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/zona.dart';

import '../helpers.dart';

void main() {
  group('Widgets: reglas de las zonas verde y azul', () {
    // Coordenadas en base 1, como las Keys de la pantalla.
    Zona zonaEn(Partida partida, int fila, int columna) => partida
        .tablero
        .regiones
        .singleWhere((zona) => zona.contieneCoordenada(fila - 1, columna - 1));

    int? valorEn(Partida partida, int fila, int columna) =>
        partida.tablero.obtenerCelda(fila - 1, columna - 1).valor;

    void colocar(Partida partida, int fila, int columna, int valor) =>
        partida.tablero.colocarDato(fila - 1, columna - 1, valor);

    Finder destinoIluminado(int fila, int columna) =>
        find.byKey(Key('valid-move-cell-$fila-$columna'));

    // Zona verde de la derecha: (3,6) libre junto al 2 inicial de (2,6),
    // con 4 inicial en (4,5) y otros dos valores puestos a mano.
    Partida partidaConVerdeMixta() {
      final partida = partidaEnJuego();
      colocar(partida, 4, 6, 4);
      colocar(partida, 4, 7, 1);

      final verde = zonaEn(partida, 3, 6);
      expect(verde.tipo.colorZona, ColorZona.verde);
      expect(verde.contieneCoordenada(3, 5), isTrue);
      expect(verde.obtenerValores()..sort(), [1, 4, 4]);
      expect(valorEn(partida, 3, 6), isNull);
      expect(valorEn(partida, 2, 6), 2);
      return partida;
    }

    // Zona azul de arriba: tiene el 1 inicial en (1,3) y (2,3) libre debajo.
    Partida partidaConAzulConUno() {
      final partida = partidaEnJuego();

      final azul = zonaEn(partida, 1, 3);
      expect(azul.tipo.colorZona, ColorZona.azul);
      expect(azul.contieneCoordenada(1, 2), isTrue);
      expect(azul.obtenerValores(), [1]);
      expect(valorEn(partida, 1, 3), 1);
      expect(valorEn(partida, 2, 3), isNull);
      return partida;
    }

    testWidgets(
      'La zona verde acepta un número que ya se repite en la zona',
      (tester) async {
        final partida = partidaConVerdeMixta();
        await abrirPartida(tester, partida, random: DadosFijos([2, 4]));

        await lanzarDados(tester);
        await elegirAncla(tester, 2);

        expect(destinoIluminado(3, 6), findsOneWidget);
      },
    );

    testWidgets(
      'La zona verde acepta un número que todavía no está en la zona',
      (tester) async {
        final partida = partidaConVerdeMixta();
        await abrirPartida(tester, partida, random: DadosFijos([2, 5]));

        await lanzarDados(tester);
        await elegirAncla(tester, 2);

        expect(destinoIluminado(3, 6), findsOneWidget);
      },
    );

    testWidgets(
      'La zona azul ilumina la celda libre para el mismo número que ya tiene',
      (tester) async {
        final partida = partidaConAzulConUno();
        await abrirPartida(tester, partida, random: DadosFijos([1, 1]));

        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        expect(destinoIluminado(2, 3), findsOneWidget);
      },
    );

    testWidgets(
      'La zona azul no ilumina la celda libre para un número distinto del que tiene',
      (tester) async {
        final partida = partidaConAzulConUno();
        await abrirPartida(tester, partida, random: DadosFijos([1, 3]));

        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        expect(destinoIluminado(2, 3), findsNothing);
        // El mismo ancla sí ilumina su vecina verde, así que la opción está activa.
        expect(destinoIluminado(1, 2), findsOneWidget);
      },
    );

    testWidgets('La zona azul vacía acepta cualquier número', (tester) async {
      final partida = partidaEnJuego();
      colocar(partida, 5, 6, 2);

      final azul = zonaEn(partida, 5, 7);
      expect(azul.tipo.colorZona, ColorZona.azul);
      expect(azul.obtenerValores(), isEmpty);
      expect(zonaEn(partida, 5, 6).tipo.colorZona, isNot(ColorZona.azul));

      await abrirPartida(tester, partida, random: DadosFijos([2, 5]));

      await lanzarDados(tester);
      await elegirAncla(tester, 2);

      expect(destinoIluminado(5, 7), findsOneWidget);
    });
  });
}
