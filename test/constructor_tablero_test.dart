import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/constructor_tablero.dart';

const _v = ColorZona.verde;
const _r = ColorZona.rojo;
const _a = ColorZona.amarillo;

/// Dibujo todo verde con celdas sueltas de otro color.
List<List<ColorZona>> dibujoCon(Map<(int, int), ColorZona> celdas) => [
  for (var fila = 0; fila < 7; fila++)
    [
      for (var columna = 0; columna < 7; columna++)
        celdas[(fila, columna)] ?? _v,
    ],
];

void main() {
  test('Dos regiones separadas del mismo color forman 2 zonas', () {
    final tablero = ConstructorTablero(
      colores: dibujoCon({(0, 0): _r, (6, 6): _r}),
    ).construir();

    final rojas = tablero.regiones
        .where((zona) => zona.tipo.colorZona == ColorZona.rojo)
        .toList();
    expect(rojas, hasLength(2));
    expect(rojas.map((zona) => zona.tamanoZona), [1, 1]);
  });

  test('Un color unido forma 1 zona aunque esté separado', () {
    final tablero = ConstructorTablero(
      colores: dibujoCon({(0, 0): _a, (3, 3): _a, (6, 6): _a}),
      coloresUnidos: {ColorZona.amarillo},
    ).construir();

    final amarillas = tablero.regiones
        .where((zona) => zona.tipo.colorZona == ColorZona.amarillo)
        .toList();
    expect(amarillas, hasLength(1));
    expect(amarillas.single.tamanoZona, 3);
  });

  test('Los ids son consecutivos desde 0 en orden de recorrido', () {
    final tablero = ConstructorTablero(
      colores: dibujoCon({(0, 0): _a, (0, 1): _r, (6, 6): _a, (6, 5): _r}),
      coloresUnidos: {ColorZona.amarillo},
    ).construir();

    expect(tablero.regiones.map((zona) => zona.id), [0, 1, 2, 3]);
    expect(
      tablero.regiones.map((zona) => zona.tipo.colorZona),
      [ColorZona.amarillo, ColorZona.rojo, ColorZona.verde, ColorZona.rojo],
    );
  });

  test('Un dibujo de 6x7 lanza ArgumentError', () {
    expect(
      () => ConstructorTablero(colores: dibujoCon({}).sublist(1)),
      throwsArgumentError,
    );
  });
}
