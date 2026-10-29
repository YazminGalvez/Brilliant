import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/zona.dart';

import '../helpers.dart';

typedef Jugada = ({List<int> dados, int ancla, (int, int) destino});

void main() {
  group('Widgets: puntuación en pantalla', () {
    Zona zonaEn(Partida partida, (int, int) celda) =>
        partida.tablero.zonaEn(celda.$1 - 1, celda.$2 - 1)!;

    void llenar(Partida partida, Map<(int, int), int> valores) {
      for (final MapEntry(key: (fila, columna), :value) in valores.entries) {
        partida.tablero.colocarDato(fila - 1, columna - 1, value);
      }
    }

    Future<void> jugar(
      WidgetTester tester,
      Partida partida,
      Jugada jugada,
    ) async {
      await abrirPartida(tester, partida, random: DadosFijos(jugada.dados));
      await lanzarDados(tester);
      await elegirAncla(tester, jugada.ancla);
      await tocarDestino(tester, jugada.destino.$1, jugada.destino.$2);
    }

    Finder filaDeZona(int id) => find.byKey(Key('zone-score-$id'));

    Finder filasDeZonas() => find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('zone-score-'),
    );

    String textoDe(WidgetTester tester, Finder finder) =>
        tester.widget<Text>(finder).data!;

    String totalMostrado(WidgetTester tester) =>
        textoDe(tester, find.byKey(const Key('total-score')));

    final completarZona =
        <
          ({
            ColorZona color,
            String nombre,
            int puntos,
            Map<(int, int), int> valores,
            Jugada jugada,
          })
        >[
          (
            color: ColorZona.rojo,
            nombre: 'roja',
            puntos: 6,
            valores: {(3, 2): 1, (3, 3): 2, (5, 2): 4, (6, 2): 5},
            jugada: (dados: [5, 6], ancla: 5, destino: (6, 1)),
          ),
          (
            color: ColorZona.azul,
            nombre: 'azul',
            puntos: 7,
            valores: {(2, 3): 1, (2, 4): 1},
            jugada: (dados: [1, 1], ancla: 1, destino: (3, 4)),
          ),
          (
            color: ColorZona.verde,
            nombre: 'verde',
            puntos: 4,
            valores: {(1, 2): 1, (2, 1): 1, (2, 2): 1, (3, 1): 1, (4, 1): 1},
            jugada: (dados: [1, 1], ancla: 1, destino: (5, 1)),
          ),
          (
            color: ColorZona.amarillo,
            nombre: 'amarilla',
            puntos: 8,
            valores: {(1, 1): 1, (1, 7): 2, (7, 1): 3, (7, 7): 5},
            jugada: (dados: [4, 6], ancla: 4, destino: (4, 4)),
          ),
          (
            color: ColorZona.morado,
            nombre: 'morada',
            puntos: 6,
            valores: {(1, 4): 2, (1, 5): 2, (1, 6): 2, (2, 5): 2},
            jugada: (dados: [4, 2], ancla: 4, destino: (3, 5)),
          ),
        ];

    testWidgets(
      'Una partida recién iniciada muestra total 0 y ninguna fila de zona',
      (tester) async {
        await abrirPartida(tester, partidaEnJuego());

        expect(totalMostrado(tester), 'Puntuación total: 0');
        expect(filasDeZonas(), findsNothing);
      },
    );

    for (final caso in completarZona) {
      testWidgets(
        'Completar una zona ${caso.nombre} muestra sus ${caso.puntos} puntos y el total los suma',
        (tester) async {
          final partida = partidaEnJuego();
          llenar(partida, caso.valores);
          final zona = zonaEn(partida, caso.jugada.destino);
          expect(zona.tipo.colorZona, caso.color);
          expect(zona.verificarCompletado(), isFalse);

          await jugar(tester, partida, caso.jugada);

          expect(zona.verificarCompletado(), isTrue);
          expect(filasDeZonas(), findsOneWidget);
          expect(
            textoDe(tester, filaDeZona(zona.id)),
            endsWith('${zona.id + 1}: ${caso.puntos} puntos'),
          );
          expect(totalMostrado(tester), 'Puntuación total: ${caso.puntos}');
        },
      );
    }

    testWidgets('Dos zonas verdes completas puntúan cada una por separado', (
      tester,
    ) async {
      final partida = partidaEnJuego();
      llenar(partida, {
        (1, 2): 1,
        (2, 1): 1,
        (2, 2): 1,
        (3, 1): 1,
        (4, 1): 1,
        (5, 1): 1,
        (2, 7): 4,
        (3, 6): 4,
        (3, 7): 4,
        (4, 7): 4,
      });
      final verdeIzquierda = zonaEn(partida, (5, 1));
      final verdeDerecha = zonaEn(partida, (4, 6));
      expect(verdeIzquierda.tipo.colorZona, ColorZona.verde);
      expect(verdeDerecha.tipo.colorZona, ColorZona.verde);
      expect(verdeIzquierda.id, isNot(verdeDerecha.id));

      await abrirPartida(tester, partida, random: DadosFijos([4, 4]));
      expect(filaDeZona(verdeIzquierda.id), findsOneWidget);
      expect(filaDeZona(verdeDerecha.id), findsNothing);
      expect(totalMostrado(tester), 'Puntuación total: 4');

      await lanzarDados(tester);
      await elegirAncla(tester, 4);
      await tocarDestino(tester, 4, 6);

      expect(filasDeZonas(), findsNWidgets(2));
      expect(
        textoDe(tester, filaDeZona(verdeIzquierda.id)),
        endsWith(': 4 puntos'),
      );
      expect(
        textoDe(tester, filaDeZona(verdeDerecha.id)),
        endsWith(': 4 puntos'),
      );
      expect(totalMostrado(tester), 'Puntuación total: 8');
    });

    testWidgets('Las filas del marcador aparecen ordenadas por id de zona', (
      tester,
    ) async {
      final partida = partidaEnJuego();
      llenar(partida, {
        (5, 7): 3,
        (6, 6): 3,
        (6, 7): 3,
        (7, 6): 3,
        (1, 1): 1,
        (1, 7): 2,
        (4, 4): 3,
        (7, 1): 5,
        (7, 7): 6,
        (3, 2): 1,
        (3, 3): 2,
        (5, 2): 4,
        (6, 1): 6,
        (6, 2): 5,
        (2, 3): 1,
        (2, 4): 1,
      });

      await jugar(tester, partida, (dados: [1, 1], ancla: 1, destino: (3, 4)));

      final ids = [
        zonaEn(partida, (5, 7)).id,
        zonaEn(partida, (1, 1)).id,
        zonaEn(partida, (3, 2)).id,
        zonaEn(partida, (3, 4)).id,
      ]..sort();
      expect(filasDeZonas(), findsNWidgets(ids.length));
      final alturas = [
        for (final id in ids) tester.getTopLeft(filaDeZona(id)).dy,
      ];
      for (var index = 1; index < alturas.length; index++) {
        expect(alturas[index], greaterThan(alturas[index - 1]));
      }
    });

    testWidgets('Una zona incompleta no suma puntos', (tester) async {
      final partida = partidaEnJuego();
      llenar(partida, {(1, 2): 1, (2, 1): 1, (2, 2): 1, (3, 1): 1});
      final verde = zonaEn(partida, (4, 1));

      await jugar(tester, partida, (dados: [1, 1], ancla: 1, destino: (4, 1)));

      expect(partida.tablero.obtenerCelda(3, 0).valor, 1);
      expect(verde.verificarCompletado(), isFalse);
      expect(filaDeZona(verde.id), findsNothing);
      expect(totalMostrado(tester), 'Puntuación total: 0');
    });

    testWidgets(
      'Con el tablero lleno la puntuación mostrada es la máxima del mapa y no la supera',
      (tester) async {
        final partida = partidaEnJuego();
        llenar(partida, {
          (1, 1): 1,
          (1, 7): 2,
          (4, 4): 3,
          (7, 1): 5,
          (1, 2): 1,
          (2, 1): 1,
          (2, 2): 1,
          (3, 1): 1,
          (4, 1): 1,
          (5, 1): 1,
          (2, 3): 1,
          (2, 4): 1,
          (3, 4): 1,
          (1, 4): 2,
          (1, 5): 2,
          (1, 6): 2,
          (2, 5): 2,
          (3, 5): 2,
          (2, 7): 4,
          (3, 6): 4,
          (3, 7): 4,
          (4, 6): 4,
          (4, 7): 4,
          (3, 2): 1,
          (3, 3): 2,
          (5, 2): 4,
          (6, 1): 6,
          (6, 2): 5,
          (4, 3): 5,
          (5, 3): 5,
          (5, 4): 5,
          (7, 2): 5,
          (7, 3): 5,
          (5, 5): 1,
          (5, 6): 2,
          (6, 4): 3,
          (6, 5): 4,
          (7, 4): 5,
          (5, 7): 3,
          (6, 6): 3,
          (6, 7): 3,
          (7, 6): 3,
        });
        expect(partida.puntuacionMaxima, 54);

        await jugar(tester, partida, (
          dados: [3, 6],
          ancla: 3,
          destino: (7, 7),
        ));

        expect(partida.estado, EstadoPartida.terminada);
        expect(filasDeZonas(), findsNWidgets(partida.tablero.regiones.length));
        expect(totalMostrado(tester), 'Puntuación total: 54');
        expect(partida.puntuacionTotal, lessThanOrEqualTo(54));
      },
    );
  });
}
