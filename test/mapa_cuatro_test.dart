import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  group('Mapa 4: zonas', () {
    const a = ColorZona.amarillo;
    const v = ColorZona.verde;
    const z = ColorZona.azul;
    const m = ColorZona.morado;
    const r = ColorZona.rojo;
    const o = ColorZona.naranja;

    late Tablero tablero;

    setUp(() {
      tablero = mapaCuatro.crearTablero();
    });

    List<(int, int)> celdasDe(Zona zona) => [
      for (final coordenada in zona.coordenadas)
        (coordenada.fila, coordenada.columna),
    ];

    int zonasDe(ColorZona color) =>
        tablero.regiones.where((zona) => zona.tipo.colorZona == color).length;

    test('Es el mapa número 4', () {
      expect(mapaCuatro.numero, 4);
    });

    test('El dibujo mide 7x7', () {
      expect(mapaCuatro.colores, hasLength(7));
      for (final fila in mapaCuatro.colores) {
        expect(fila, hasLength(7));
      }
    });

    test('El dibujo coincide con el del papel', () {
      expect(mapaCuatro.colores, [
        [o, o, o, o, o, o, o],
        [a, r, z, v, z, r, a],
        [r, r, m, m, m, r, r],
        [a, v, z, m, z, v, a],
        [r, r, m, m, m, r, r],
        [a, r, z, v, z, r, a],
        [o, o, o, o, o, o, o],
      ]);
    });

    test('Arma 8 zonas con ids consecutivos desde 0', () {
      expect(
        tablero.regiones.map((zona) => zona.id),
        List.generate(8, (i) => i),
      );
    });

    test(
      'Tiene 2 zonas naranjas, 2 rojas, 1 morada, 1 amarilla, 1 azul y 1 verde',
      () {
        expect(zonasDe(ColorZona.naranja), 2);
        expect(zonasDe(ColorZona.rojo), 2);
        expect(zonasDe(ColorZona.morado), 1);
        expect(zonasDe(ColorZona.amarillo), 1);
        expect(zonasDe(ColorZona.azul), 1);
        expect(zonasDe(ColorZona.verde), 1);
        expect(zonasDe(ColorZona.gris), 0);
      },
    );

    test('Las zonas en orden de id tienen el color y el tamaño esperados', () {
      expect(tablero.regiones.map((zona) => zona.tipo.colorZona), [
        o,
        a,
        r,
        z,
        v,
        r,
        m,
        o,
      ]);
      expect(tablero.regiones.map((zona) => zona.tamanoZona), [
        7,
        6,
        6,
        6,
        4,
        6,
        7,
        7,
      ]);
    });

    test('Cada celda está en una sola zona del mismo color', () {
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          final zonas = tablero.regiones
              .where((zona) => zona.contieneCoordenada(fila, columna))
              .toList();
          expect(zonas, hasLength(1), reason: 'Celda ($fila, $columna)');
          expect(
            zonas.single.tipo.colorZona,
            mapaCuatro.colorEn(fila, columna),
          );
        }
      }
      expect(
        tablero.regiones.fold(0, (total, zona) => total + zona.tamanoZona),
        49,
      );
    });

    test('El amarillo, el azul y el verde son colores unidos', () {
      expect(mapaCuatro.coloresUnidos, {
        ColorZona.amarillo,
        ColorZona.azul,
        ColorZona.verde,
      });
    });

    test('Las 6 celdas amarillas separadas forman una sola zona', () {
      final amarilla = tablero.zonaEn(1, 0)!;

      expect(amarilla.tipo.colorZona, ColorZona.amarillo);
      expect(celdasDe(amarilla), [
        (1, 0),
        (1, 6),
        (3, 0),
        (3, 6),
        (5, 0),
        (5, 6),
      ]);
    });

    test('Las 6 celdas azules separadas forman una sola zona', () {
      final azul = tablero.zonaEn(1, 2)!;

      expect(azul.tipo.colorZona, ColorZona.azul);
      expect(celdasDe(azul), [(1, 2), (1, 4), (3, 2), (3, 4), (5, 2), (5, 4)]);
    });

    test('Las 4 celdas verdes separadas forman una sola zona', () {
      final verde = tablero.zonaEn(1, 3)!;

      expect(verde.tipo.colorZona, ColorZona.verde);
      expect(celdasDe(verde), [(1, 3), (3, 1), (3, 5), (5, 3)]);
    });

    test(
      'Los rojos de la izquierda están unidos por partes en una sola zona',
      () {
        final izquierda = tablero.zonaEn(2, 0)!;

        expect(tablero.zonaEn(4, 0), same(izquierda));
        expect(celdasDe(izquierda), [
          (1, 1),
          (2, 0),
          (2, 1),
          (4, 0),
          (4, 1),
          (5, 1),
        ]);
      },
    );

    test('Los rojos de la derecha están unidos por partes en otra zona', () {
      final derecha = tablero.zonaEn(2, 6)!;

      expect(tablero.zonaEn(4, 6), same(derecha));
      expect(derecha, isNot(same(tablero.zonaEn(2, 0))));
      expect(celdasDe(derecha), [
        (1, 5),
        (2, 5),
        (2, 6),
        (4, 5),
        (4, 6),
        (5, 5),
      ]);
    });

    test('Las partes unidas son los rojos de cada lado', () {
      expect(mapaCuatro.partesUnidas, [
        [(3, 1), (5, 1)],
        [(3, 7), (5, 7)],
      ]);
    });

    test('Las dos filas naranjas no se unen', () {
      final arriba = tablero.zonaEn(0, 0)!;
      final abajo = tablero.zonaEn(6, 0)!;

      expect(arriba, isNot(same(abajo)));
      expect(celdasDe(arriba), [for (var c = 0; c < 7; c++) (0, c)]);
      expect(celdasDe(abajo), [for (var c = 0; c < 7; c++) (6, c)]);
    });

    test('El morado del centro forma una sola zona de 7 celdas', () {
      final morada = tablero.zonaEn(3, 3)!;

      expect(celdasDe(morada), [
        (2, 2),
        (2, 3),
        (2, 4),
        (3, 3),
        (4, 2),
        (4, 3),
        (4, 4),
      ]);
    });
  });
}
