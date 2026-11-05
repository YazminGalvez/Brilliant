import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/mapa_dos.dart';
import 'package:juego_brilliant/mapa_tres.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart';

void main() {
  void comprobarPuntos(
    Tablero tablero,
    ColorZona color,
    PuntosPorLugar esperados,
  ) {
    final zonas = tablero.regiones
        .where((zona) => zona.tipo.colorZona == color)
        .toList();
    final (primero, segundo, tercero) = esperados;

    expect(zonas, isNotEmpty, reason: '$color');
    for (final zona in zonas) {
      expect(
        [
          zona.tipo.calcularPuntuacion(1),
          zona.tipo.calcularPuntuacion(2),
          zona.tipo.calcularPuntuacion(3),
        ],
        [primero, segundo, tercero],
        reason: 'zona ${zona.id} ($color)',
      );
    }
  }

  Set<ColorZona> coloresDe(Tablero tablero) => {
    for (final zona in tablero.regiones) zona.tipo.colorZona,
  };

  int sumaDePrimerosLugares(Tablero tablero) => tablero.regiones.fold(
    0,
    (total, zona) => total + zona.tipo.calcularPuntuacion(1),
  );

  group('Puntos por lugar de cada mapa', () {
    test('Mapa 1: cada color da sus puntos de 1.º, 2.º y 3.er lugar', () {
      final tablero = mapaUno.crearTablero();

      expect(coloresDe(tablero), {
        ColorZona.azul,
        ColorZona.verde,
        ColorZona.rojo,
        ColorZona.morado,
        ColorZona.amarillo,
      });
      comprobarPuntos(tablero, ColorZona.azul, (7, 5, 3));
      comprobarPuntos(tablero, ColorZona.verde, (4, 3, 2));
      comprobarPuntos(tablero, ColorZona.rojo, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.morado, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.amarillo, (8, 6, 4));
    });

    test('Mapa 2: cada color da sus puntos de 1.º, 2.º y 3.er lugar', () {
      final tablero = mapaDos.crearTablero();

      expect(coloresDe(tablero), {
        ColorZona.amarillo,
        ColorZona.morado,
        ColorZona.rojo,
        ColorZona.azul,
        ColorZona.verde,
        ColorZona.gris,
      });
      comprobarPuntos(tablero, ColorZona.amarillo, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.morado, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.rojo, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.azul, (7, 5, 3));
      comprobarPuntos(tablero, ColorZona.verde, (4, 3, 2));
      comprobarPuntos(tablero, ColorZona.gris, (3, 2, 1));
    });

    test('Mapa 3: cada color da sus puntos de 1.º, 2.º y 3.er lugar', () {
      final tablero = mapaTres.crearTablero();

      expect(coloresDe(tablero), {
        ColorZona.amarillo,
        ColorZona.morado,
        ColorZona.rojo,
        ColorZona.azul,
        ColorZona.verde,
        ColorZona.gris,
      });
      comprobarPuntos(tablero, ColorZona.amarillo, (7, 5, 3));
      comprobarPuntos(tablero, ColorZona.morado, (7, 5, 3));
      comprobarPuntos(tablero, ColorZona.rojo, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.azul, (7, 5, 3));
      comprobarPuntos(tablero, ColorZona.verde, (6, 5, 4));
      comprobarPuntos(tablero, ColorZona.gris, (8, 6, 4));
    });

    test('Mapa 4: cada color da sus puntos de 1.º, 2.º y 3.er lugar', () {
      final tablero = mapaCuatro.crearTablero();

      expect(coloresDe(tablero), {
        ColorZona.morado,
        ColorZona.azul,
        ColorZona.rojo,
        ColorZona.amarillo,
        ColorZona.verde,
        ColorZona.naranja,
      });
      comprobarPuntos(tablero, ColorZona.morado, (7, 5, 3));
      comprobarPuntos(tablero, ColorZona.azul, (8, 6, 4));
      comprobarPuntos(tablero, ColorZona.rojo, (6, 4, 2));
      comprobarPuntos(tablero, ColorZona.amarillo, (8, 6, 4));
      comprobarPuntos(tablero, ColorZona.verde, (3, 2, 1));
      comprobarPuntos(tablero, ColorZona.naranja, (6, 4, 3));
    });

    test(
      'Mapa 4: las dos naranjas valen lo mismo aunque tengan rango distinto',
      () {
        final tablero = mapaCuatro.crearTablero();
        final arriba = tablero.zonaEn(0, 0)!.tipo as TipoNaranja;
        final abajo = tablero.zonaEn(6, 0)!.tipo as TipoNaranja;

        expect((arriba.minimo, arriba.maximo), (4, 6));
        expect((abajo.minimo, abajo.maximo), (1, 3));
        expect(arriba.puntuaciones, {1: 6, 2: 4, 3: 3});
        expect(abajo.puntuaciones, arriba.puntuaciones);
      },
    );
  });

  group('Puntuación máxima con los primeros lugares', () {
    test('En el Mapa 1 la suma de los primeros lugares es 54', () {
      final tablero = mapaUno.crearTablero();

      expect(sumaDePrimerosLugares(tablero), 54);
      expect(tablero.puntuacionMaxima, 54);
    });

    test('En el Mapa 2 la suma de los primeros lugares es 55', () {
      final tablero = mapaDos.crearTablero();

      expect(sumaDePrimerosLugares(tablero), 55);
      expect(tablero.puntuacionMaxima, 55);
    });

    test('En el Mapa 3 la suma de los primeros lugares es 54', () {
      final tablero = mapaTres.crearTablero();

      expect(sumaDePrimerosLugares(tablero), 54);
      expect(tablero.puntuacionMaxima, 54);
    });

    test('En el Mapa 4 la suma de los primeros lugares es 50', () {
      final tablero = mapaCuatro.crearTablero();

      expect(sumaDePrimerosLugares(tablero), 50);
      expect(tablero.puntuacionMaxima, 50);
    });
  });

  group('Posiciones fuera de rango', () {
    test(
      'Una posición 4 lanza ArgumentError en todas las zonas de los 4 mapas',
      () {
        final tableros = [
          mapaUno.crearTablero(),
          mapaDos.crearTablero(),
          mapaTres.crearTablero(),
          mapaCuatro.crearTablero(),
        ];

        for (final tablero in tableros) {
          for (final zona in tablero.regiones) {
            expect(
              () => zona.tipo.calcularPuntuacion(4),
              throwsArgumentError,
              reason: 'zona ${zona.id}',
            );
          }
        }
      },
    );
  });
}
