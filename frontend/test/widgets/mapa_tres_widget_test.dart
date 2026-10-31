import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_tres.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';

void main() {
  group('Widgets: mapa tres', () {
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

    void dejarGrisCasiCompleta(Partida partida) {
      partida.tablero.colocarDato(0, 3, 3);
      partida.tablero.colocarDato(1, 0, 3);
      partida.tablero.colocarDato(1, 6, 3);
    }

    void dejarAmarillaCasiCompleta(Partida partida) {
      partida.tablero.colocarDato(0, 0, 1);
      partida.tablero.colocarDato(0, 1, 3);
      partida.tablero.colocarDato(0, 5, 4);
      partida.tablero.colocarDato(0, 6, 5);
    }

    void dejarMoradaDeAbajoCasiCompleta(Partida partida) {
      partida.tablero.colocarDato(6, 0, 6);
      partida.tablero.colocarDato(6, 1, 6);
      partida.tablero.colocarDato(6, 4, 1);
      partida.tablero.colocarDato(6, 5, 1);
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
      'La tarjeta del Mapa 3 aparece disponible y al tocarla abre este mapa',
      (tester) async {
        await abrirMenuDeMapas(tester);
        final tarjeta = find.byKey(const Key('map-option-3'));

        expect(
          find.descendant(of: tarjeta, matching: find.text('Disponible')),
          findsOneWidget,
        );

        await tocar(tester, tarjeta);

        final pantalla = tester.widget<TableroPage>(find.byType(TableroPage));
        expect(pantalla.partida!.mapa, same(mapaTres));
        expect(pantalla.partida!.estado, EstadoPartida.preparando);
        expect(find.byKey(const Key('start-game')), findsOneWidget);
      },
    );

    testWidgets('Se ven las 49 celdas y las seis celdas iniciales del Mapa 3', (
      tester,
    ) async {
      await abrirPartida(tester, Partida(mapa: mapaTres));

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
      for (final (fila, columna) in mapaTres.celdasIniciales) {
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
      'Cada tipo de celda del Mapa 3 se pinta con el color de su zona',
      (tester) async {
        await abrirPartida(tester, Partida(mapa: mapaTres));

        expect(colorDeCelda(tester, 1, 1), colorDeZona(ColorZona.amarillo));
        expect(colorDeCelda(tester, 1, 3), colorDeZona(ColorZona.morado));
        expect(colorDeCelda(tester, 1, 4), colorDeZona(ColorZona.gris));
        expect(colorDeCelda(tester, 3, 1), colorDeZona(ColorZona.rojo));
        expect(colorDeCelda(tester, 5, 1), colorDeZona(ColorZona.verde));
        expect(colorDeCelda(tester, 5, 2), colorDeZona(ColorZona.azul));
      },
    );

    testWidgets(
      'Completar la zona gris muestra sus 8 puntos y el total los suma',
      (tester) async {
        final partida = partidaIniciada(mapaTres);
        dejarGrisCasiCompleta(partida);
        await abrirPartida(tester, partida, random: DadosFijos([6, 3]));
        expect(filaDeZona(2), findsNothing);

        await jugar(tester, ancla: 6, destino: (7, 4));

        expect(textoDe(tester, filaDeZona(2)), 'Zona Gris 3: 8 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 8');
      },
    );

    testWidgets(
      'Completar la zona amarilla muestra sus 7 puntos y el total los suma',
      (tester) async {
        final partida = partidaIniciada(mapaTres);
        dejarAmarillaCasiCompleta(partida);
        await abrirPartida(tester, partida, random: DadosFijos([1, 6]));
        expect(filaDeZona(0), findsNothing);

        await jugar(tester, ancla: 1, destino: (2, 2));

        expect(textoDe(tester, filaDeZona(0)), 'Zona Amarilla 1: 7 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 7');
      },
    );

    testWidgets(
      'Completar la zona morada de abajo unida por partes muestra sus 7 puntos y el total los suma',
      (tester) async {
        final partida = partidaIniciada(mapaTres);
        dejarMoradaDeAbajoCasiCompleta(partida);
        await abrirPartida(tester, partida, random: DadosFijos([1, 6]));
        expect(filaDeZona(7), findsNothing);

        await jugar(tester, ancla: 1, destino: (7, 7));

        expect(textoDe(tester, filaDeZona(7)), 'Zona Morada 8: 7 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 7');
      },
    );

    testWidgets(
      'Completar la gris, la amarilla y la morada de abajo suma 22 puntos en el total',
      (tester) async {
        final partida = partidaIniciada(mapaTres);
        dejarGrisCasiCompleta(partida);
        dejarAmarillaCasiCompleta(partida);
        dejarMoradaDeAbajoCasiCompleta(partida);
        await abrirPartida(
          tester,
          partida,
          random: DadosFijos([6, 3, 1, 6, 1, 6]),
        );

        await jugar(tester, ancla: 6, destino: (7, 4));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 8');

        await jugar(tester, ancla: 1, destino: (2, 2));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 15');

        await jugar(tester, ancla: 1, destino: (7, 7));

        expect(textoDe(tester, filaDeZona(0)), 'Zona Amarilla 1: 7 puntos');
        expect(textoDe(tester, filaDeZona(2)), 'Zona Gris 3: 8 puntos');
        expect(textoDe(tester, filaDeZona(7)), 'Zona Morada 8: 7 puntos');
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 22');
      },
    );

    testWidgets(
      'Con el tablero lleno la puntuación mostrada llega a 54 y no la supera',
      (tester) async {
        final partida = partidaIniciada(mapaTres);
        llenarTablero(partida, const [
          '1313145',
          '3611123',
          '1231123',
          '4563456',
          '1444445',
          '1111111',
          '666.666',
        ]);
        await abrirPartida(tester, partida, random: DadosFijos([6, 3]));
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 46');

        await jugar(tester, ancla: 6, destino: (7, 4));

        expect(partida.estado, EstadoPartida.terminada);
        expect(textoDe(tester, puntuacionTotal), 'Puntuación total: 54');
        expect(
          textoDe(tester, find.byKey(const Key('final-score'))),
          'Puntuación final: 54 de 54',
        );
        expect(partida.puntuacionTotal, lessThanOrEqualTo(54));
        for (var id = 0; id < 8; id++) {
          expect(filaDeZona(id), findsOneWidget, reason: 'zona $id');
        }
        expect(filaDeZona(8), findsNothing);
      },
    );

    testWidgets(
      'Un número distinto del que tiene la zona gris no ilumina su celda',
      (tester) async {
        await abrirPartida(
          tester,
          partidaIniciada(mapaTres),
          random: DadosFijos([6, 5]),
        );

        await lanzarDados(tester);
        await elegirAncla(tester, 6);

        expect(destinoIluminado(7, 4), findsNothing);
        expect(destinoIluminado(6, 3), findsOneWidget);
        expect(destinoIluminado(7, 2), findsOneWidget);
      },
    );

    testWidgets(
      'Un tercer número distinto en la morada de abajo no ilumina su celda aunque esté en otro pedazo',
      (tester) async {
        final partida = partidaIniciada(mapaTres);
        partida.tablero.colocarDato(6, 4, 1);
        await abrirPartida(tester, partida, random: DadosFijos([6, 2]));

        await lanzarDados(tester);
        await elegirAncla(tester, 6);

        expect(destinoIluminado(7, 2), findsNothing);
        expect(destinoIluminado(7, 4), findsNothing);
        expect(destinoIluminado(6, 3), findsOneWidget);
      },
    );
  });
}
