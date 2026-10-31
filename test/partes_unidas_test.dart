import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/constructor_tablero.dart';
import 'package:juego_brilliant/mapa.dart';

const _v = ColorZona.verde;
const _r = ColorZona.rojo;

class _MapaDePrueba extends Mapa {
  const _MapaDePrueba({this.grupos = const []});

  final List<List<(int, int)>> grupos;

  @override
  int get numero => 0;

  @override
  List<List<ColorZona>> get colores => [
    for (var fila = 0; fila < 7; fila++)
      [
        for (var columna = 0; columna < 7; columna++)
          fila == 0 && (columna == 0 || columna == 6) ? _r : _v,
      ],
  ];

  @override
  List<(int, int)> get celdasIniciales => const [
    (2, 1),
    (2, 2),
    (2, 3),
    (2, 4),
    (2, 5),
    (2, 6),
  ];

  @override
  Set<ColorZona> get coloresUnidos => const {};

  @override
  List<List<(int, int)>> get partesUnidas => grupos;
}

void main() {
  group('Partes unidas', () {
    List<int> tamanosRojos(Mapa mapa) => [
      for (final zona in mapa.crearTablero().regiones)
        if (zona.tipo.colorZona == ColorZona.rojo) zona.tamanoZona,
    ];

    test('Sin la unión los dos pedazos rojos forman 2 zonas', () {
      expect(tamanosRojos(const _MapaDePrueba()), [1, 1]);
    });

    test('Con la unión los dos pedazos rojos forman 1 zona', () {
      const mapa = _MapaDePrueba(
        grupos: [
          [(1, 1), (1, 7)],
        ],
      );
      final tablero = mapa.crearTablero();

      expect(tamanosRojos(mapa), [2]);
      expect(tablero.zonaEn(0, 0), same(tablero.zonaEn(0, 6)));
    });

    test('Los ids siguen consecutivos desde 0 con la unión', () {
      const mapa = _MapaDePrueba(
        grupos: [
          [(1, 1), (1, 7)],
        ],
      );
      final tablero = mapa.crearTablero();

      expect(tablero.regiones.map((zona) => zona.id), [0, 1]);
      expect(tablero.zonaEn(0, 0)!.id, 0);
      expect(tablero.zonaEn(0, 1)!.id, 1);
    });

    test('El mapa recibe las celdas desde 1 y el tablero las usa desde 0', () {
      const mapa = _MapaDePrueba(
        grupos: [
          [(1, 1), (1, 7)],
        ],
      );
      final roja = mapa.crearTablero().zonaEn(0, 0)!;

      expect(roja.coordenadas.map((celda) => (celda.fila, celda.columna)), [
        (0, 0),
        (0, 6),
      ]);
    });

    test('Un grupo con una sola celda lanza un error', () {
      expect(
        () => ConstructorTablero(
          colores: const _MapaDePrueba().colores,
          partesUnidas: [
            [(0, 0)],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('Un grupo con una celda fuera del tablero lanza un error', () {
      expect(
        () => ConstructorTablero(
          colores: const _MapaDePrueba().colores,
          partesUnidas: [
            [(0, 0), (7, 0)],
          ],
        ),
        throwsArgumentError,
      );
    });

    test('Un grupo con celdas de distinto color lanza un error', () {
      expect(
        () => ConstructorTablero(
          colores: const _MapaDePrueba().colores,
          partesUnidas: [
            [(0, 0), (3, 3)],
          ],
        ),
        throwsArgumentError,
      );
    });

    test(
      'Un mapa con un grupo inválido lanza un error al crear el tablero',
      () {
        const mapa = _MapaDePrueba(
          grupos: [
            [(1, 1), (8, 1)],
          ],
        );

        expect(mapa.crearTablero, throwsArgumentError);
      },
    );
  });
}
