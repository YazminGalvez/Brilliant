import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_dos.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: mapa dos', () {
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

    void llenarTablero(Partida partida, List<String> valores) {
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          final letra = valores[fila][columna];
          if (letra == '.') continue;
          partida.tablero.colocarDato(fila, columna, int.parse(letra));
        }
      }
    }

    testWidgets(
      'La tarjeta del Mapa 2 aparece disponible y al tocarla abre este mapa',
      (tester) async {
        await abrirMenuDeMapas(tester);
        final tarjeta = find.byKey(const Key('map-option-2'));

        expect(
          find.descendant(of: tarjeta, matching: find.text('Disponible')),
          findsOneWidget,
        );

        await tocar(tester, tarjeta);

        final pantalla = tester.widget<TableroPage>(find.byType(TableroPage));
        expect(pantalla.partida!.mapa, same(mapaDos));
        expect(pantalla.partida!.estado, EstadoPartida.preparando);
        expect(find.byKey(const Key('start-game')), findsOneWidget);
      },
    );

    testWidgets('Se ven las 49 celdas y las seis celdas iniciales del Mapa 2', (
      tester,
    ) async {
      await abrirPartida(tester, Partida(mapa: mapaDos));

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
      for (final (fila, columna) in mapaDos.celdasIniciales) {
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
      'Cada tipo de celda del Mapa 2 se pinta con el color de su zona',
      (tester) async {
        await abrirPartida(tester, Partida(mapa: mapaDos));

        expect(colorDeCelda(tester, 1, 1), colorDeZona(ColorZona.morado));
        expect(colorDeCelda(tester, 1, 4), colorDeZona(ColorZona.gris));
        expect(colorDeCelda(tester, 1, 5), colorDeZona(ColorZona.verde));
        expect(colorDeCelda(tester, 2, 2), colorDeZona(ColorZona.amarillo));
        expect(colorDeCelda(tester, 2, 3), colorDeZona(ColorZona.azul));
        expect(colorDeCelda(tester, 3, 2), colorDeZona(ColorZona.rojo));
      },
    );

    testWidgets(
      'Completar la zona gris muestra sus 3 puntos y el total los suma',
      (tester) async {
        final partida = partidaIniciada(mapaDos);
        partida.tablero.colocarDato(0, 3, 1);
        await abrirPartida(tester, partida, random: DadosFijos([6, 1]));
        expect(filaDeZona(1), findsNothing);

        await jugar(tester, ancla: 6, destino: (7, 4));

        expect(textoDe(tester, filaDeZona(1)), 'Zona Gris 2: 3 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 3');
      },
    );

    testWidgets(
      'Completar la zona amarilla muestra sus 6 puntos y el total los suma',
      (tester) async {
        final partida = partidaIniciada(mapaDos);
        partida.tablero.colocarDato(1, 1, 1);
        partida.tablero.colocarDato(1, 5, 2);
        partida.tablero.colocarDato(3, 3, 3);
        await abrirPartida(tester, partida, random: DadosFijos([4, 6]));
        expect(filaDeZona(3), findsNothing);

        await jugar(tester, ancla: 4, destino: (6, 6));

        expect(textoDe(tester, filaDeZona(3)), 'Zona Amarilla 4: 6 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 6');
      },
    );

    testWidgets(
      'Completar la zona gris y la amarilla suma 9 puntos en el total',
      (tester) async {
        final partida = partidaIniciada(mapaDos);
        partida.tablero.colocarDato(0, 3, 1);
        partida.tablero.colocarDato(1, 1, 1);
        partida.tablero.colocarDato(1, 5, 2);
        partida.tablero.colocarDato(3, 3, 3);
        await abrirPartida(tester, partida, random: DadosFijos([6, 1, 4, 6]));

        await jugar(tester, ancla: 6, destino: (7, 4));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 3');

        await jugar(tester, ancla: 4, destino: (6, 6));

        expect(textoDe(tester, filaDeZona(1)), 'Zona Gris 2: 3 puntos');
        expect(textoDe(tester, filaDeZona(3)), 'Zona Amarilla 4: 6 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 9');
      },
    );

    testWidgets(
      'Con el tablero lleno la puntuación mostrada llega a 55 y no la supera',
      (tester) async {
        final partida = partidaIniciada(mapaDos);
        llenarTablero(partida, const [
          '2221111',
          '2133321',
          '2123311',
          '4533235',
          '1633646',
          '1533346',
          '111.666',
        ]);
        await abrirPartida(tester, partida, random: DadosFijos([6, 1]));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 52');

        await jugar(tester, ancla: 6, destino: (7, 4));

        expect(partida.estado, EstadoPartida.terminada);
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 55');
        expect(
          textoDe(tester, find.byKey(const Key('final-score'))),
          'Puntuación final: 55 de 55',
        );
        expect(partida.puntuacionTotal, lessThanOrEqualTo(55));
        for (var id = 0; id < 10; id++) {
          expect(filaDeZona(id), findsOneWidget, reason: 'zona $id');
        }
        expect(filaDeZona(10), findsNothing);
      },
    );

    testWidgets(
      'Un número distinto del que tiene la zona gris no ilumina su celda',
      (tester) async {
        final partida = partidaIniciada(mapaDos);
        partida.tablero.colocarDato(0, 3, 1);
        await abrirPartida(tester, partida, random: DadosFijos([6, 2]));

        await lanzarDados(tester);
        await elegirAncla(tester, 6);

        expect(destinoIluminado(7, 4), findsNothing);
        expect(destinoIluminado(6, 5), findsOneWidget);
        expect(destinoIluminado(7, 6), findsOneWidget);
      },
    );

    testWidgets(
      'Un número repetido en la zona amarilla no ilumina su celda separada',
      (tester) async {
        await abrirPartida(
          tester,
          partidaIniciada(mapaDos),
          random: DadosFijos([4, 5]),
        );

        await lanzarDados(tester);
        await elegirAncla(tester, 4);

        expect(destinoIluminado(6, 6), findsNothing);
        expect(destinoIluminado(4, 6), findsOneWidget);
        expect(destinoIluminado(5, 5), findsOneWidget);
        expect(destinoIluminado(5, 7), findsOneWidget);
      },
    );
  });
}
