import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_tres.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  group('Mapa 3: zonas', () {
    const a = ColorZona.amarillo;
    const v = ColorZona.verde;
    const z = ColorZona.azul;
    const m = ColorZona.morado;
    const r = ColorZona.rojo;
    const g = ColorZona.gris;

    late Tablero tablero;

    setUp(() {
      tablero = mapaTres.crearTablero();
    });

    List<(int, int)> celdasDe(Zona zona) => [
      for (final coordenada in zona.coordenadas)
        (coordenada.fila, coordenada.columna),
    ];

    int zonasDe(ColorZona color) =>
        tablero.regiones.where((zona) => zona.tipo.colorZona == color).length;

    test('Es el mapa número 3', () {
      expect(mapaTres.numero, 3);
    });

    test('El dibujo mide 7x7', () {
      expect(mapaTres.colores, hasLength(7));
      for (final fila in mapaTres.colores) {
        expect(fila, hasLength(7));
      }
    });

    test('El dibujo coincide con el del papel', () {
      expect(mapaTres.colores, [
        [a, a, m, g, m, a, a],
        [g, a, m, m, m, a, g],
        [r, r, r, m, r, r, r],
        [r, r, r, g, r, r, r],
        [v, z, z, z, z, z, v],
        [v, v, v, v, v, v, v],
        [m, m, m, g, m, m, m],
      ]);
    });

    test('Arma 8 zonas con ids consecutivos desde 0', () {
      expect(
        tablero.regiones.map((zona) => zona.id),
        List.generate(8, (i) => i),
      );
    });

    test(
      'Tiene 1 zona amarilla, 1 gris, 2 moradas, 2 rojas, 1 azul y 1 verde',
      () {
        expect(zonasDe(ColorZona.amarillo), 1);
        expect(zonasDe(ColorZona.gris), 1);
        expect(zonasDe(ColorZona.morado), 2);
        expect(zonasDe(ColorZona.rojo), 2);
        expect(zonasDe(ColorZona.azul), 1);
        expect(zonasDe(ColorZona.verde), 1);
      },
    );

    test('Las zonas en orden de id tienen el color y el tamaño esperados', () {
      expect(tablero.regiones.map((zona) => zona.tipo.colorZona), [
        a,
        m,
        g,
        r,
        r,
        v,
        z,
        m,
      ]);
      expect(tablero.regiones.map((zona) => zona.tamanoZona), [
        6,
        6,
        5,
        6,
        6,
        9,
        5,
        6,
      ]);
    });

    test('Cada celda está en una sola zona del mismo color', () {
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          final zonas = tablero.regiones
              .where((zona) => zona.contieneCoordenada(fila, columna))
              .toList();
          expect(zonas, hasLength(1), reason: 'Celda ($fila, $columna)');
          expect(zonas.single.tipo.colorZona, mapaTres.colorEn(fila, columna));
        }
      }
      expect(
        tablero.regiones.fold(0, (total, zona) => total + zona.tamanoZona),
        49,
      );
    });

    test('El amarillo y el gris son colores unidos', () {
      expect(mapaTres.coloresUnidos, {ColorZona.amarillo, ColorZona.gris});
    });

    test('Las 6 celdas amarillas de las dos esquinas forman una sola zona', () {
      final amarilla = tablero.zonaEn(0, 0)!;

      expect(amarilla.tipo.colorZona, ColorZona.amarillo);
      expect(celdasDe(amarilla), [
        (0, 0),
        (0, 1),
        (0, 5),
        (0, 6),
        (1, 1),
        (1, 5),
      ]);
    });

    test('Las 5 celdas grises separadas forman una sola zona', () {
      final gris = tablero.zonaEn(0, 3)!;

      expect(gris.tipo.colorZona, ColorZona.gris);
      expect(celdasDe(gris), [(0, 3), (1, 0), (1, 6), (3, 3), (6, 3)]);
    });

    test('Los dos pedazos morados de abajo están unidos en una sola zona', () {
      expect(mapaTres.partesUnidas, [
        [(7, 1), (7, 5)],
      ]);
      final abajo = tablero.zonaEn(6, 0)!;

      expect(abajo.tipo.colorZona, ColorZona.morado);
      expect(tablero.zonaEn(6, 4), same(abajo));
      expect(celdasDe(abajo), [(6, 0), (6, 1), (6, 2), (6, 4), (6, 5), (6, 6)]);
    });

    test('El morado de arriba es una zona distinta del de abajo', () {
      final arriba = tablero.zonaEn(0, 2)!;

      expect(arriba, isNot(same(tablero.zonaEn(6, 0))));
      expect(celdasDe(arriba), [
        (0, 2),
        (0, 4),
        (1, 2),
        (1, 3),
        (1, 4),
        (2, 3),
      ]);
    });

    test('Las dos zonas rojas no se unen', () {
      final izquierda = tablero.zonaEn(2, 0)!;
      final derecha = tablero.zonaEn(2, 6)!;

      expect(izquierda, isNot(same(derecha)));
      expect(celdasDe(izquierda), [
        (2, 0),
        (2, 1),
        (2, 2),
        (3, 0),
        (3, 1),
        (3, 2),
      ]);
      expect(celdasDe(derecha), [
        (2, 4),
        (2, 5),
        (2, 6),
        (3, 4),
        (3, 5),
        (3, 6),
      ]);
    });

    test('El verde forma una sola zona de 9 celdas', () {
      final verde = tablero.zonaEn(4, 0)!;

      expect(tablero.zonaEn(4, 6), same(verde));
      expect(verde.tamanoZona, 9);
    });
  });

  group('Mapa 3: reglas y puntos', () {
    late Tablero tablero;

    setUp(() {
      tablero = mapaTres.crearTablero();
    });

    int primerLugarDe(ColorZona color) => tablero.regiones
        .firstWhere((zona) => zona.tipo.colorZona == color)
        .tipo
        .calcularPuntuacion(1);

    test('Cada color da los puntos del primer lugar del Mapa 3', () {
      expect(primerLugarDe(ColorZona.amarillo), 7);
      expect(primerLugarDe(ColorZona.morado), 7);
      expect(primerLugarDe(ColorZona.rojo), 6);
      expect(primerLugarDe(ColorZona.azul), 7);
      expect(primerLugarDe(ColorZona.gris), 8);
      expect(primerLugarDe(ColorZona.verde), 6);
    });

    test('Las dos zonas del mismo color dan los mismos puntos', () {
      for (final zona in tablero.regiones) {
        expect(
          zona.tipo.calcularPuntuacion(1),
          mapaTres.crearTipo(zona.tipo.colorZona).calcularPuntuacion(1),
          reason: 'zona ${zona.id}',
        );
      }
    });

    test('La puntuación máxima del Mapa 3 es 54', () {
      expect(tablero.puntuacionMaxima, 54);
    });

    test('La zona gris acepta en otra celda separada el mismo número', () {
      tablero.colocarDato(0, 3, 2);

      expect(tablero.zonaEn(6, 3)!.validarNuevoMovimiento(2), isTrue);
    });

    test('La zona gris rechaza en otra celda separada un número distinto', () {
      tablero.colocarDato(0, 3, 2);

      expect(tablero.zonaEn(6, 3)!.validarNuevoMovimiento(5), isFalse);
    });

    test('La zona amarilla acepta en la otra esquina un número nuevo', () {
      tablero.colocarDato(0, 0, 3);

      expect(tablero.zonaEn(1, 5)!.validarNuevoMovimiento(4), isTrue);
    });

    test('La zona amarilla rechaza en la otra esquina un número repetido', () {
      tablero.colocarDato(0, 0, 3);

      expect(tablero.zonaEn(1, 5)!.validarNuevoMovimiento(3), isFalse);
    });

    test(
      'El morado de abajo acepta en un pedazo un número del otro pedazo',
      () {
        tablero.colocarDato(6, 0, 1);
        tablero.colocarDato(6, 1, 2);

        expect(tablero.zonaEn(6, 6)!.validarNuevoMovimiento(1), isTrue);
      },
    );

    test(
      'El morado de abajo rechaza un tercer número aunque esté en el otro pedazo',
      () {
        tablero.colocarDato(6, 0, 1);
        tablero.colocarDato(6, 1, 2);

        expect(tablero.zonaEn(6, 6)!.validarNuevoMovimiento(3), isFalse);
      },
    );

    test(
      'El morado de arriba no se ve afectado por los números del de abajo',
      () {
        tablero.colocarDato(6, 0, 1);
        tablero.colocarDato(6, 1, 2);

        expect(tablero.zonaEn(1, 3)!.validarNuevoMovimiento(3), isTrue);
      },
    );
  });
}
