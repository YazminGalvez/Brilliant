import 'color_zona.dart';
import 'tablero.dart';
import 'tipo.dart';
import 'zona.dart';

/// Arma un [Tablero] con sus zonas a partir del color de cada celda.
///
/// Las celdas vecinas (arriba, abajo, izquierda, derecha) del mismo color forman
/// una zona. Las celdas de un color de [coloresUnidos] forman una sola zona
/// aunque estén separadas. Los ids van desde 0 en el orden en que se encuentra
/// la primera celda de cada zona, recorriendo fila por fila.
class ConstructorTablero {
  final List<List<ColorZona>> colores;
  final Set<ColorZona> coloresUnidos;
  final List<(int, int)>? celdasIniciales;

  ConstructorTablero({
    required this.colores,
    this.coloresUnidos = const {},
    this.celdasIniciales,
  }) {
    if (colores.length != Tablero.cantidadFilas ||
        colores.any((fila) => fila.length != Tablero.cantidadColumnas)) {
      throw ArgumentError(
        'El dibujo del mapa debe medir '
        '${Tablero.cantidadFilas}x${Tablero.cantidadColumnas}.',
      );
    }
  }

  Tablero construir() {
    final tablero = Tablero(celdasIniciales: celdasIniciales);
    final asignadas = List.generate(
      Tablero.cantidadFilas,
      (_) => List.filled(Tablero.cantidadColumnas, false),
    );
    var siguienteId = 0;

    for (var fila = 0; fila < Tablero.cantidadFilas; fila++) {
      for (var columna = 0; columna < Tablero.cantidadColumnas; columna++) {
        if (asignadas[fila][columna]) continue;

        final color = colores[fila][columna];
        final posiciones = coloresUnidos.contains(color)
            ? _celdasDelColor(color)
            : _celdasVecinas(fila, columna);
        posiciones.sort(
          (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
        );

        for (final (filaZona, columnaZona) in posiciones) {
          asignadas[filaZona][columnaZona] = true;
        }
        tablero.agregarRegion(
          Zona(
            id: siguienteId++,
            tipo: Tipo.deColor(color),
            coordenadas: [
              for (final (filaZona, columnaZona) in posiciones)
                tablero.obtenerCelda(filaZona, columnaZona),
            ],
          ),
        );
      }
    }

    return tablero;
  }

  List<(int, int)> _celdasDelColor(ColorZona color) => [
    for (var fila = 0; fila < Tablero.cantidadFilas; fila++)
      for (var columna = 0; columna < Tablero.cantidadColumnas; columna++)
        if (colores[fila][columna] == color) (fila, columna),
  ];

  List<(int, int)> _celdasVecinas(int fila, int columna) {
    final color = colores[fila][columna];
    final encontradas = <(int, int)>{(fila, columna)};
    final pendientes = [(fila, columna)];

    while (pendientes.isNotEmpty) {
      final (filaActual, columnaActual) = pendientes.removeLast();
      for (final (filaVecina, columnaVecina) in [
        (filaActual - 1, columnaActual),
        (filaActual + 1, columnaActual),
        (filaActual, columnaActual - 1),
        (filaActual, columnaActual + 1),
      ]) {
        if (filaVecina < 0 ||
            filaVecina >= Tablero.cantidadFilas ||
            columnaVecina < 0 ||
            columnaVecina >= Tablero.cantidadColumnas ||
            colores[filaVecina][columnaVecina] != color) {
          continue;
        }
        if (encontradas.add((filaVecina, columnaVecina))) {
          pendientes.add((filaVecina, columnaVecina));
        }
      }
    }

    return encontradas.toList();
  }
}
