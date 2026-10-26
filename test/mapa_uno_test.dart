import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_uno.dart';

void main() {
  test('El dibujo mide 7x7', () {
    expect(mapaUno.colores, hasLength(7));
    for (final fila in mapaUno.colores) {
      expect(fila, hasLength(7));
    }
  });

  test('Tiene 9 zonas con ids 0..8 y los tamaños esperados', () {
    final tablero = mapaUno.crearTablero();

    expect(tablero.regiones.map((zona) => zona.id), List.generate(9, (i) => i));
    expect(
      tablero.regiones.map((zona) => zona.tamanoZona),
      [5, 6, 4, 6, 6, 6, 6, 6, 4],
    );
  });

  test('Cada celda está en una sola zona del mismo color', () {
    final tablero = mapaUno.crearTablero();

    for (var fila = 0; fila < 7; fila++) {
      for (var columna = 0; columna < 7; columna++) {
        final zonas = tablero.regiones
            .where((zona) => zona.contieneCoordenada(fila, columna))
            .toList();
        expect(zonas, hasLength(1), reason: 'Celda ($fila, $columna)');
        expect(zonas.single.tipo.colorZona, mapaUno.colorEn(fila, columna));
      }
    }
    expect(
      tablero.regiones.fold(0, (total, zona) => total + zona.tamanoZona),
      49,
    );
  });

  test('1 zona amarilla de 5 celdas no contiguas y 2 de cada otro color', () {
    final tablero = mapaUno.crearTablero();

    int zonasDe(ColorZona color) =>
        tablero.regiones.where((zona) => zona.tipo.colorZona == color).length;

    expect(zonasDe(ColorZona.amarillo), 1);
    for (final color in [
      ColorZona.verde,
      ColorZona.azul,
      ColorZona.morado,
      ColorZona.rojo,
    ]) {
      expect(zonasDe(color), 2, reason: color.name);
    }

    final amarilla = tablero.regiones.firstWhere(
      (zona) => zona.tipo.colorZona == ColorZona.amarillo,
    );
    expect(amarilla.tamanoZona, 5);
    for (final celda in amarilla.coordenadas) {
      final vecinasAmarillas = amarilla.coordenadas.where(
        (otra) =>
            (otra.fila - celda.fila).abs() + (otra.columna - celda.columna).abs() ==
            1,
      );
      expect(vecinasAmarillas, isEmpty);
    }
  });

  test('La puntuación máxima es 54', () {
    expect(mapaUno.crearTablero().puntuacionMaxima, 54);
  });

  test('Las celdas iniciales son 6 distintas dentro del tablero (base 1)', () {
    final celdas = mapaUno.celdasIniciales;

    expect(celdas, hasLength(6));
    expect(celdas.toSet(), hasLength(6));
    for (final (fila, columna) in celdas) {
      expect(fila, inInclusiveRange(1, 7));
      expect(columna, inInclusiveRange(1, 7));
    }
  });

  test('Los valores iniciales quedan en celdas de zonas del mapa', () {
    final tablero = mapaUno.crearTablero();

    tablero.establecerValoresIniciales([1, 2, 3, 4, 5, 6]);

    expect(tablero.inicializado, isTrue);
    for (final (fila, columna) in mapaUno.celdasIniciales) {
      final celda = tablero.obtenerCelda(fila - 1, columna - 1);
      expect(celda.valor, isNotNull);
      expect(
        tablero.regiones.where(
          (zona) => zona.coordenadas.contains(celda),
        ),
        hasLength(1),
      );
    }
  });
}
