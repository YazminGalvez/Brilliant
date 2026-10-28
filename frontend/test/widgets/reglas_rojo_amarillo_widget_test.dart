import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/zona.dart';

import '../helpers.dart';

void main() {
  group('Widgets: reglas de las zonas roja y amarilla', () {
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

    // Zona roja de la izquierda: el 3 inicial en (4,2) y (3,2) libre encima.
    Partida partidaConRojaConTres() {
      final partida = partidaEnJuego();

      final roja = zonaEn(partida, 3, 2);
      expect(roja.tipo.colorZona, ColorZona.rojo);
      expect(roja.contieneCoordenada(3, 1), isTrue);
      expect(roja.obtenerValores(), [3]);
      expect(valorEn(partida, 4, 2), 3);
      expect(valorEn(partida, 3, 2), isNull);
      return partida;
    }

    // Zona amarilla: (4,4) libre junto al 4 inicial de (4,5), y (1,1),
    // separada en la esquina, con un número puesto a mano.
    Partida partidaConAmarillaConCinco() {
      final partida = partidaEnJuego();
      colocar(partida, 1, 1, 5);

      final amarilla = zonaEn(partida, 4, 4);
      expect(amarilla.tipo.colorZona, ColorZona.amarillo);
      expect(identical(zonaEn(partida, 1, 1), amarilla), isTrue);
      expect(amarilla.obtenerValores(), [5]);
      expect(valorEn(partida, 4, 4), isNull);
      expect(valorEn(partida, 4, 5), 4);
      return partida;
    }

    testWidgets(
      'La zona roja ilumina la celda libre para un número que no tiene',
      (tester) async {
        final partida = partidaConRojaConTres();

        await jugar(tester, partida, [3, 4], 3);

        expect(destinoIluminado(3, 2), findsOneWidget);
      },
    );

    testWidgets(
      'La zona roja no ilumina la celda libre para un número que ya tiene',
      (tester) async {
        final partida = partidaConRojaConTres();

        await jugar(tester, partida, [3, 3], 3);

        expect(destinoIluminado(3, 2), findsNothing);
        // El mismo ancla sí ilumina su vecina verde, así que la opción está activa.
        expect(destinoIluminado(4, 1), findsOneWidget);
      },
    );

    testWidgets(
      'La zona amarilla ilumina la celda libre para un número que no tiene',
      (tester) async {
        final partida = partidaConAmarillaConCinco();

        await jugar(tester, partida, [4, 2], 4);

        expect(destinoIluminado(4, 4), findsOneWidget);
      },
    );

    testWidgets(
      'Un número usado en una celda amarilla no se ilumina en otra celda amarilla separada',
      (tester) async {
        final partida = partidaConAmarillaConCinco();

        await jugar(tester, partida, [4, 5], 4);

        expect(destinoIluminado(4, 4), findsNothing);
        // El mismo ancla sí ilumina su vecina roja, así que la opción está activa.
        expect(destinoIluminado(5, 5), findsOneWidget);
      },
    );

    testWidgets('La zona roja vacía acepta cualquier número', (tester) async {
      final partida = partidaEnJuego();
      // En el Mapa 1 ambas zonas rojas tienen una celda inicial: se vacía la
      // de (7,5) para dejar la zona de abajo sin números.
      colocar(partida, 7, 5, null);

      final roja = zonaEn(partida, 5, 5);
      expect(roja.tipo.colorZona, ColorZona.rojo);
      expect(roja.obtenerValores(), isEmpty);
      expect(valorEn(partida, 4, 5), 4);

      await jugar(tester, partida, [4, 6], 4);

      expect(destinoIluminado(5, 5), findsOneWidget);
    });

    testWidgets('La zona amarilla vacía acepta cualquier número', (
      tester,
    ) async {
      final partida = partidaEnJuego();

      final amarilla = zonaEn(partida, 4, 4);
      expect(amarilla.tipo.colorZona, ColorZona.amarillo);
      expect(amarilla.obtenerValores(), isEmpty);
      expect(valorEn(partida, 4, 5), 4);

      await jugar(tester, partida, [4, 1], 4);

      expect(destinoIluminado(4, 4), findsOneWidget);
    });
  });
}
