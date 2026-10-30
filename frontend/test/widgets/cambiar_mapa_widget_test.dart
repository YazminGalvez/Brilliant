import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/seleccion_mapa.dart';

import '../helpers.dart';

void main() {
  group('Widgets: cambiar de mapa', () {
    final botonCambiarMapa = find.byKey(const Key('change-map-button'));
    final opcionMapaUno = find.byKey(const Key('map-option-1'));

    testWidgets('La pantalla del juego muestra el botón Cambiar de mapa', (
      tester,
    ) async {
      await abrirPartida(tester, partidaEnJuego());

      expect(botonCambiarMapa, findsOneWidget);
      expect(
        find.descendant(
          of: botonCambiarMapa,
          matching: find.text('Cambiar de mapa'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Cambiar de mapa desde una partida abierta en el menú regresa al menú',
      (tester) async {
        await abrirMenuDeMapas(tester);
        await tocar(tester, opcionMapaUno);
        expect(find.byType(TableroPage), findsOneWidget);

        await tocar(tester, botonCambiarMapa);

        expect(find.byType(TableroPage), findsNothing);
        expect(find.byType(SeleccionMapaPage), findsOneWidget);
        expect(find.text('Elige tu mapa'), findsOneWidget);
      },
    );

    testWidgets(
      'Cambiar de mapa descarta la partida y la siguiente empieza vacía',
      (tester) async {
        await abrirMenuDeMapas(tester);
        await tocar(tester, opcionMapaUno);
        await ingresarNumerosIniciales(tester, cantidad: 3);
        expect(find.text('+'), findsNWidgets(3));

        await tocar(tester, botonCambiarMapa);
        await tocar(tester, opcionMapaUno);

        expect(find.text('+'), findsNWidgets(6));
        expect(find.byKey(const Key('start-game')), findsOneWidget);
      },
    );

    testWidgets(
      'Cambiar de mapa en plena partida descarta los lanzamientos hechos',
      (tester) async {
        await abrirMenuDeMapas(tester, random: DadosFijos([1, 2]));
        await tocar(tester, opcionMapaUno);
        await ingresarNumerosIniciales(tester);
        await tocar(tester, find.byKey(const Key('start-game')));
        await lanzarDados(tester);
        expect(find.text('Tirada 1: 1 y 2'), findsOneWidget);

        await tocar(tester, botonCambiarMapa);
        await tocar(tester, opcionMapaUno);

        expect(find.byKey(const Key('start-game')), findsOneWidget);
        expect(find.byKey(const Key('roll-dice-button')), findsNothing);
        expect(find.text('Tirada 1: 1 y 2'), findsNothing);
      },
    );

    testWidgets(
      'Cambiar de mapa abre el menú aunque el juego se haya abierto directo',
      (tester) async {
        await abrirPartida(tester, partidaEnJuego());

        await tocar(tester, botonCambiarMapa);

        expect(find.byType(TableroPage), findsNothing);
        expect(find.byType(SeleccionMapaPage), findsOneWidget);
      },
    );

    testWidgets(
      'El botón Cambiar de mapa cabe sin desbordes en una pantalla de 360 px',
      (tester) async {
        usarTamanoDePantalla(tester, const Size(360, 800));

        await abrirPartida(tester, partidaEnJuego());

        expect(tester.takeException(), isNull);
        expect(tester.getRect(botonCambiarMapa).right, lessThanOrEqualTo(360));
      },
    );
  });
}
