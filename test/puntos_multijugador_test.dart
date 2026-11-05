import 'package:test/test.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/mapas.dart';
import 'package:juego_brilliant/puntos_multijugador.dart';

void main() {
  group('Puntos multijugador por zona', () {
    test('La zona 1 del Mapa 1 da 8, 6 y 4 puntos por lugar', () {
      expect(PuntosMultijugador.puntosDeZona(mapaUno, 1, 1), 8);
      expect(PuntosMultijugador.puntosDeZona(mapaUno, 1, 2), 6);
      expect(PuntosMultijugador.puntosDeZona(mapaUno, 1, 3), 4);
    });

    test('El cuarto lugar y los siguientes dan 0 puntos', () {
      expect(PuntosMultijugador.puntosDeZona(mapaUno, 1, 4), 0);
      expect(PuntosMultijugador.puntosDeZona(mapaUno, 1, 6), 0);
    });

    test(
      'Una zona que no existe o un lugar menor que 1 lanzan ArgumentError',
      () {
        expect(
          () => PuntosMultijugador.puntosDeZona(mapaUno, 0, 1),
          throwsArgumentError,
        );
        expect(
          () => PuntosMultijugador.puntosDeZona(mapaUno, 10, 1),
          throwsArgumentError,
        );
        expect(
          () => PuntosMultijugador.puntosDeZona(mapaUno, 1, 0),
          throwsArgumentError,
        );
      },
    );

    test('Las zonas se numeran desde 1 en el mismo orden que el tablero', () {
      final regiones = mapaCuatro.crearTablero().regiones;

      expect(PuntosMultijugador.zonasDe(mapaCuatro), [
        for (var numero = 1; numero <= regiones.length; numero++) numero,
      ]);
      expect(PuntosMultijugador.puntosDeZona(mapaCuatro, 1, 3), 3);
      expect(PuntosMultijugador.puntosDeZona(mapaCuatro, 5, 1), 3);
    });
  });

  group('Puntos multijugador totales', () {
    test(
      'Quienes completan una zona en la misma ronda empatan en el mismo lugar',
      () {
        final totales = PuntosMultijugador.puntosTotales(mapaUno, {
          1: {'ana': 3, 'luis': 3, 'eva': 5},
        });

        expect(totales, {'ana': 8, 'luis': 8, 'eva': 6});
      },
    );

    test('En rondas distintas cada ronda ocupa el siguiente lugar', () {
      final totales = PuntosMultijugador.puntosTotales(mapaUno, {
        1: {'ana': 2, 'luis': 4, 'eva': 7},
      });

      expect(totales, {'ana': 8, 'luis': 6, 'eva': 4});
    });

    test('Quien completa en el cuarto lugar no suma puntos', () {
      final totales = PuntosMultijugador.puntosTotales(mapaUno, {
        1: {'ana': 1, 'luis': 2, 'eva': 3, 'beto': 4},
      });

      expect(totales['beto'], 0);
      expect(totales, {'ana': 8, 'luis': 6, 'eva': 4, 'beto': 0});
    });

    test('El total de un jugador suma sus puntos de todas las zonas', () {
      final totales = PuntosMultijugador.puntosTotales(mapaUno, {
        1: {'ana': 4, 'luis': 2},
        2: {'ana': 3},
        3: {'ana': 5, 'luis': 5},
      });

      expect(totales['ana'], 6 + 4 + 7);
      expect(totales['luis'], 8 + 7);
    });
  });

  group('Tabla de puntos para el servidor', () {
    final tabla = PuntosMultijugador.tablaParaServidor(mapasDisponibles);
    final entradas = tabla.split(';');

    test('Tiene una entrada por cada mapa disponible', () {
      expect(entradas, hasLength(mapasDisponibles.length));
      expect(entradas.map((entrada) => entrada.split(':').first), [
        '1',
        '2',
        '3',
        '4',
      ]);
    });

    test('Cada mapa tiene una zona por cada zona real con tres puntos', () {
      for (var indice = 0; indice < mapasDisponibles.length; indice++) {
        final mapa = mapasDisponibles[indice];
        final zonas = entradas[indice].split(':').last.split('|');

        expect(
          zonas,
          hasLength(mapa.crearTablero().regiones.length),
          reason: 'mapa ${mapa.numero}',
        );
        for (final zona in zonas) {
          expect(
            zona,
            matches(RegExp(r'^\d+,\d+,\d+$')),
            reason: 'mapa ${mapa.numero}',
          );
        }
      }
    });

    test('La primera zona de cada mapa coincide con sus puntos por lugar', () {
      expect(entradas[0], startsWith('1:8,6,4|'));
      expect(entradas[3], startsWith('4:6,4,3|'));
    });
  });
}
