import 'color_zona.dart';
import 'constructor_tablero.dart';
import 'tablero.dart';

/// Describe un mapa del juego: el color de cada celda y las celdas iniciales.
/// El tablero con sus zonas lo arma [ConstructorTablero].
abstract class Mapa {
  const Mapa();

  int get numero;

  /// Color de cada celda: 7 filas x 7 columnas.
  List<List<ColorZona>> get colores;

  /// Posiciones (fila, columna) de las celdas iniciales, contando desde 1.
  List<(int, int)> get celdasIniciales;

  /// Colores cuyas celdas forman una sola zona aunque estén separadas.
  Set<ColorZona> get coloresUnidos;

  /// Color de la celda en (fila, columna), contando desde 0.
  ColorZona colorEn(int fila, int columna) => colores[fila][columna];

  Tablero crearTablero() => ConstructorTablero(
    colores: colores,
    coloresUnidos: coloresUnidos,
  ).construir();
}
