import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/zona.dart';

import '../helpers.dart';

// Regla vigente: como máximo dos números diferentes por zona. Falta confirmar
// con el profe si deben ser exactamente dos.
void main() {
  group('Widgets: regla de la zona morada', () {
    // Coordenadas en base 1, como las Keys de la pantalla.
    Zona zonaEn(Partida partida, int fila, int columna) => partida
        .tablero
        .regiones
        .singleWhere((zona) => zona.contieneCoordenada(fila - 1, columna - 1));

    int? valorEn(Partida partida, int fila, int columna) =>
        partida.tablero.obtenerCelda(fila - 1, columna - 1).valor;

    void colocar(Partida partida, int fila, int columna, int? valor) =>
        partida.tablero.colocarDato(fila - 1, columna - 1, valor);

    Finder destinoIluminado(int fila, int columna) =>
        find.byKey(Key('valid-move-cell-$fila-$columna'));

    Future<void> jugar(
      WidgetTester tester,
      Partida partida,
      List<int> dados,
      int ancla,
    ) async {
      await abrirPartida(tester, partida, random: DadosFijos(dados));
      await lanzarDados(tester);
      await elegirAncla(tester, ancla);
    }

    // Zona morada de arriba: (3,5) libre junto al 4 inicial de (4,5); tiene
    // el 2 inicial en (2,6) y, si se indica, otro número en (1,6).
    Partida partidaConMoradaArriba(List<int> valoresEsperados, {int? extra}) {
      final partida = partidaEnJuego();
      if (extra != null) colocar(partida, 1, 6, extra);

      final morada = zonaEn(partida, 3, 5);
      expect(morada.tipo.colorZona, ColorZona.morado);
      expect(morada.contieneCoordenada(1, 5), isTrue);
      expect(morada.obtenerValores()..sort(), valoresEsperados);
      expect(valorEn(partida, 3, 5), isNull);
      expect(valorEn(partida, 4, 5), 4);
      return partida;
    }

    testWidgets('La zona morada vacía acepta cualquier número', (tester) async {
      final partida = partidaEnJuego();
      // En el Mapa 1 ambas zonas moradas tienen una celda inicial: se vacía la
      // de (2,6) para dejar la zona de arriba sin números.
      colocar(partida, 2, 6, null);

      final morada = zonaEn(partida, 3, 5);
      expect(morada.tipo.colorZona, ColorZona.morado);
      expect(morada.obtenerValores(), isEmpty);

      await jugar(tester, partida, [4, 3], 4);

      expect(destinoIluminado(3, 5), findsOneWidget);
    });

    testWidgets('Con un número en la zona morada se puede repetir ese número', (
      tester,
    ) async {
      final partida = partidaConMoradaArriba([2]);

      await jugar(tester, partida, [4, 2], 4);

      expect(destinoIluminado(3, 5), findsOneWidget);
    });

    testWidgets(
      'Con un número en la zona morada se acepta un segundo número distinto',
      (tester) async {
        final partida = partidaConMoradaArriba([2]);

        await jugar(tester, partida, [4, 6], 4);

        expect(destinoIluminado(3, 5), findsOneWidget);
      },
    );

    testWidgets(
      'Con dos números distintos en la zona morada se puede repetir el primero',
      (tester) async {
        final partida = partidaConMoradaArriba([2, 6], extra: 6);

        await jugar(tester, partida, [4, 2], 4);

        expect(destinoIluminado(3, 5), findsOneWidget);
      },
    );

    testWidgets(
      'Con dos números distintos en la zona morada se puede repetir el segundo',
      (tester) async {
        final partida = partidaConMoradaArriba([2, 6], extra: 6);

        await jugar(tester, partida, [4, 6], 4);

        expect(destinoIluminado(3, 5), findsOneWidget);
      },
    );

    testWidgets(
      'Con dos números distintos en la zona morada no se ilumina un tercer número',
      (tester) async {
        final partida = partidaConMoradaArriba([2, 6], extra: 6);

        await jugar(tester, partida, [4, 3], 4);

        expect(destinoIluminado(3, 5), findsNothing);
        // El mismo ancla sí ilumina su vecina roja, así que la opción está activa.
        expect(destinoIluminado(5, 5), findsOneWidget);
      },
    );

    testWidgets(
      'El tercer número prohibido en una zona morada se ilumina en la otra',
      (tester) async {
        final partida = partidaConMoradaArriba([2, 6], extra: 6);
        // Zona morada de abajo con {3, 5}; (4,3) libre junto a un 4 en (4,4).
        colocar(partida, 5, 4, 3);
        colocar(partida, 4, 4, 4);

        final moradaAbajo = zonaEn(partida, 4, 3);
        expect(moradaAbajo.tipo.colorZona, ColorZona.morado);
        expect(identical(moradaAbajo, zonaEn(partida, 3, 5)), isFalse);
        expect(moradaAbajo.obtenerValores()..sort(), [3, 5]);
        expect(valorEn(partida, 4, 3), isNull);

        await jugar(tester, partida, [4, 3], 4);

        expect(destinoIluminado(3, 5), findsNothing);
        expect(destinoIluminado(4, 3), findsOneWidget);
      },
    );
  });
}
