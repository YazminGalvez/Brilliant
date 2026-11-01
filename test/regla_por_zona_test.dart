import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/constructor_tablero.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:juego_brilliant/tipo.dart';

const _v = ColorZona.verde;
const _o = ColorZona.naranja;

List<List<ColorZona>> _dibujoConDosNaranjas() => [
  for (var fila = 0; fila < 7; fila++)
    [
      for (var columna = 0; columna < 7; columna++)
        fila == 0 || fila == 6 ? _o : _v,
    ],
];

class _MapaDeDosNaranjas extends Mapa {
  _MapaDeDosNaranjas();

  final List<List<(int, int)>> celdasRecibidas = [];

  @override
  int get numero => 0;

  @override
  List<List<ColorZona>> get colores => _dibujoConDosNaranjas();

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
  Tipo crearTipoDeZona(ColorZona color, List<(int, int)> celdas) {
    celdasRecibidas.add(celdas);
    if (color != ColorZona.naranja) return crearTipo(color);
    return celdas.first.$1 == 1
        ? TipoNaranja(minimo: 4, maximo: 6)
        : TipoNaranja(minimo: 1, maximo: 3);
  }
}

void main() {
  group('Regla por zona', () {
    test('Dos zonas del mismo color pueden tener reglas distintas', () {
      final tablero = _MapaDeDosNaranjas().crearTablero();
      final arriba = tablero.zonaEn(0, 0)!;
      final abajo = tablero.zonaEn(6, 0)!;

      expect(arriba.tipo.colorZona, ColorZona.naranja);
      expect(abajo.tipo.colorZona, ColorZona.naranja);
      expect(arriba.validarNuevoMovimiento(5), isTrue);
      expect(arriba.validarNuevoMovimiento(2), isFalse);
      expect(abajo.validarNuevoMovimiento(2), isTrue);
      expect(abajo.validarNuevoMovimiento(5), isFalse);
    });

    test('El mapa recibe las celdas de cada zona contando desde 1', () {
      final mapa = _MapaDeDosNaranjas();
      mapa.crearTablero();

      expect(mapa.celdasRecibidas, hasLength(3));
      expect(mapa.celdasRecibidas.first, [
        for (var columna = 1; columna <= 7; columna++) (1, columna),
      ]);
      expect(mapa.celdasRecibidas.last, [
        for (var columna = 1; columna <= 7; columna++) (7, columna),
      ]);
    });

    test('El constructor entrega las celdas de cada zona contando desde 0', () {
      final recibidas = <List<(int, int)>>[];
      ConstructorTablero(
        colores: _dibujoConDosNaranjas(),
        crearTipoDeZona: (color, celdas) {
          recibidas.add(celdas);
          return Tipo.deColor(color);
        },
      ).construir();

      expect(recibidas.first, [
        for (var columna = 0; columna < 7; columna++) (0, columna),
      ]);
    });

    test('Sin regla por zona el mapa usa la regla de su color', () {
      final tablero = ConstructorTablero(
        colores: _dibujoConDosNaranjas(),
      ).construir();
      final arriba = tablero.zonaEn(0, 0)!.tipo as TipoNaranja;

      expect(arriba.minimo, 1);
      expect(arriba.maximo, 6);
    });
  });
}
