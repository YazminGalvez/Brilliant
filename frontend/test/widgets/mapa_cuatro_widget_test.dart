import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: mapa cuatro', () {
    final puntuacionTotal = find.byKey(const Key('total-score'));

    Finder celda(int fila, int columna) =>
        find.byKey(Key('cell-$fila-$columna'));

    Finder destinoIluminado(int fila, int columna) =>
        find.byKey(Key('valid-move-cell-$fila-$columna'));

    Finder filaDeZona(int id) => find.byKey(Key('zone-score-$id'));

    String? textoDe(WidgetTester tester, Finder finder) =>
        tester.widget<Text>(finder).data;

    Color? colorDeCelda(WidgetTester tester, int fila, int columna) => tester
        .widget<Material>(
          find
              .ancestor(
                of: celda(fila, columna),
                matching: find.byType(Material),
              )
              .first,
        )
        .color;

    Future<void> jugar(
      WidgetTester tester, {
      required int ancla,
      required (int, int) destino,
    }) async {
      await lanzarDados(tester);
      await elegirAncla(tester, ancla);
      await tocarDestino(tester, destino.$1, destino.$2);
    }

    void colocar(Partida partida, Map<(int, int), int> valores) {
      for (final MapEntry(key: (fila, columna), value: valor)
          in valores.entries) {
        partida.tablero.colocarDato(fila, columna, valor);
      }
    }

    void dejarNaranjaDeArribaCasiCompleta(Partida partida) => colocar(partida, {
      (0, 0): 4,
      (0, 1): 4,
      (0, 2): 4,
      (0, 5): 4,
      (0, 6): 4,
    });

    void dejarNaranjaDeAbajoCasiCompleta(Partida partida) => colocar(partida, {
      (6, 0): 2,
      (6, 2): 2,
      (6, 4): 2,
      (6, 5): 2,
      (6, 6): 2,
    });

    void dejarAzulCasiCompleta(Partida partida) =>
        colocar(partida, {(1, 2): 5, (3, 2): 5, (3, 4): 5, (5, 2): 5});

    testWidgets(
      'La tarjeta del Mapa 4 aparece disponible y al tocarla abre este mapa',
      (tester) async {
        await abrirMenuDeMapas(tester);
        final tarjeta = find.byKey(const Key('map-option-4'));

        expect(
          find.descendant(of: tarjeta, matching: find.text('Disponible')),
          findsOneWidget,
        );

        await tocar(tester, tarjeta);

        final pantalla = tester.widget<TableroPage>(find.byType(TableroPage));
        expect(pantalla.partida!.mapa, same(mapaCuatro));
        expect(pantalla.partida!.estado, EstadoPartida.preparando);
        expect(find.byKey(const Key('start-game')), findsOneWidget);
      },
    );

    testWidgets('Se ven las 49 celdas y las seis celdas iniciales del Mapa 4', (
      tester,
    ) async {
      await abrirPartida(tester, Partida(mapa: mapaCuatro));

      for (var fila = 1; fila <= 7; fila++) {
        for (var columna = 1; columna <= 7; columna++) {
          expect(
            celda(fila, columna),
            findsOneWidget,
            reason: '($fila, $columna)',
          );
        }
      }
      expect(celda(8, 1), findsNothing);
      expect(find.text('+'), findsNWidgets(6));
      for (final (fila, columna) in mapaCuatro.celdasIniciales) {
        expect(
          find.descendant(of: celda(fila, columna), matching: find.text('+')),
          findsOneWidget,
          reason: '($fila, $columna)',
        );
        expect(
          tester.widget<InkWell>(celda(fila, columna)).onTap,
          isNotNull,
          reason: '($fila, $columna)',
        );
      }
    });

    testWidgets(
      'Cada tipo de celda del Mapa 4 se pinta con el color de su zona',
      (tester) async {
        await abrirPartida(tester, Partida(mapa: mapaCuatro));

        expect(colorDeCelda(tester, 1, 1), colorDeZona(ColorZona.naranja));
        expect(colorDeCelda(tester, 2, 1), colorDeZona(ColorZona.amarillo));
        expect(colorDeCelda(tester, 2, 2), colorDeZona(ColorZona.rojo));
        expect(colorDeCelda(tester, 2, 3), colorDeZona(ColorZona.azul));
        expect(colorDeCelda(tester, 2, 4), colorDeZona(ColorZona.verde));
        expect(colorDeCelda(tester, 3, 3), colorDeZona(ColorZona.morado));
      },
    );

    testWidgets(
      'Completar la naranja de arriba muestra sus 6 puntos y el total los suma',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        dejarNaranjaDeArribaCasiCompleta(partida);
        await abrirPartida(tester, partida, random: DadosFijos([6, 5]));
        expect(filaDeZona(0), findsNothing);

        await jugar(tester, ancla: 6, destino: (1, 4));

        expect(textoDe(tester, filaDeZona(0)), 'Zona Naranja 1: 6 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 6');
      },
    );

    testWidgets(
      'Completar la naranja de abajo muestra sus 6 puntos y el total los suma',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        dejarNaranjaDeAbajoCasiCompleta(partida);
        await abrirPartida(tester, partida, random: DadosFijos([2, 3]));
        expect(filaDeZona(7), findsNothing);

        await jugar(tester, ancla: 2, destino: (7, 4));

        expect(textoDe(tester, filaDeZona(7)), 'Zona Naranja 8: 6 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 6');
      },
    );

    testWidgets(
      'Completar la zona azul unida muestra sus 8 puntos y el total los suma',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        dejarAzulCasiCompleta(partida);
        await abrirPartida(tester, partida, random: DadosFijos([6, 5]));
        expect(filaDeZona(3), findsNothing);

        await jugar(tester, ancla: 6, destino: (2, 5));

        expect(textoDe(tester, filaDeZona(3)), 'Zona Azul 4: 8 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 8');
      },
    );

    testWidgets(
      'Completar la zona amarilla unida muestra sus 8 puntos y el total los suma',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        colocar(partida, {
          (1, 0): 1,
          (1, 6): 2,
          (3, 6): 3,
          (5, 0): 5,
          (4, 6): 1,
        });
        await abrirPartida(tester, partida, random: DadosFijos([1, 6]));
        expect(filaDeZona(1), findsNothing);

        await jugar(tester, ancla: 1, destino: (6, 7));

        expect(textoDe(tester, filaDeZona(1)), 'Zona Amarilla 2: 8 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 8');
      },
    );

    testWidgets(
      'Completar la zona verde unida muestra sus 3 puntos y el total los suma',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        colocar(partida, {(1, 3): 2, (3, 5): 2, (5, 3): 2});
        await abrirPartida(tester, partida, random: DadosFijos([4, 1]));
        expect(filaDeZona(4), findsNothing);

        await jugar(tester, ancla: 4, destino: (4, 2));

        expect(textoDe(tester, filaDeZona(4)), 'Zona Verde 5: 3 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 3');
      },
    );

    testWidgets(
      'Completar la roja de la izquierda unida por partes muestra sus 6 puntos y el total los suma',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        colocar(partida, {
          (1, 1): 1,
          (2, 0): 2,
          (2, 1): 3,
          (4, 0): 5,
          (4, 1): 6,
        });
        await abrirPartida(tester, partida, random: DadosFijos([1, 4]));
        expect(filaDeZona(2), findsNothing);

        await jugar(tester, ancla: 1, destino: (6, 2));

        expect(textoDe(tester, filaDeZona(2)), 'Zona Roja 3: 6 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 6');
      },
    );

    testWidgets(
      'Completar las dos naranjas y la azul suma 20 puntos en el total',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        dejarNaranjaDeArribaCasiCompleta(partida);
        dejarNaranjaDeAbajoCasiCompleta(partida);
        dejarAzulCasiCompleta(partida);
        await abrirPartida(
          tester,
          partida,
          random: DadosFijos([6, 5, 6, 5, 2, 3]),
        );

        await jugar(tester, ancla: 6, destino: (1, 4));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 6');

        await jugar(tester, ancla: 6, destino: (2, 5));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 14');

        await jugar(tester, ancla: 2, destino: (7, 4));

        expect(textoDe(tester, filaDeZona(0)), 'Zona Naranja 1: 6 puntos');
        expect(textoDe(tester, filaDeZona(3)), 'Zona Azul 4: 8 puntos');
        expect(textoDe(tester, filaDeZona(7)), 'Zona Naranja 8: 6 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 20');
      },
    );

    testWidgets(
      'Con el tablero lleno la puntuación mostrada llega a 50 y no la supera',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        const valores = [
          '444.644',
          '1151512',
          '2322232',
          '4152513',
          '5622245',
          '5451566',
          '1111111',
        ];
        for (var fila = 0; fila < 7; fila++) {
          for (var columna = 0; columna < 7; columna++) {
            final letra = valores[fila][columna];
            if (letra == '.') continue;
            partida.tablero.colocarDato(fila, columna, int.parse(letra));
          }
        }
        await abrirPartida(tester, partida, random: DadosFijos([6, 5]));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 44');

        await jugar(tester, ancla: 6, destino: (1, 4));

        expect(partida.estado, EstadoPartida.terminada);
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 50');
        expect(
          textoDe(tester, find.byKey(const Key('final-score'))),
          'Puntuación final: 50 de 50',
        );
        expect(partida.puntuacionTotal, lessThanOrEqualTo(50));
        for (var id = 0; id < 8; id++) {
          expect(filaDeZona(id), findsOneWidget, reason: 'zona $id');
        }
        expect(filaDeZona(8), findsNothing);
      },
    );

    testWidgets(
      'Un número fuera del rango de la naranja de arriba no ilumina su celda',
      (tester) async {
        final partida = partidaEnJuegoMapaCuatro();
        colocar(partida, {(1, 3): 1});
        await abrirPartida(tester, partida, random: DadosFijos([1, 2]));

        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        expect(destinoIluminado(1, 4), findsNothing);
        expect(destinoIluminado(3, 4), findsOneWidget);
        expect(destinoIluminado(7, 1), findsOneWidget);
      },
    );

    testWidgets(
      'Un número fuera del rango de la naranja de abajo no ilumina su celda',
      (tester) async {
        await abrirPartida(
          tester,
          partidaEnJuegoMapaCuatro(),
          random: DadosFijos([1, 5]),
        );

        await lanzarDados(tester);
        await elegirAncla(tester, 1);

        expect(destinoIluminado(7, 1), findsNothing);
        expect(destinoIluminado(7, 3), findsNothing);
        expect(destinoIluminado(6, 2), findsOneWidget);
      },
    );
  });
}
