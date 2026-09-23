import 'package:test/test.dart';
import 'package:juego_brilliant/tablero.dart';

void main() {
  group('Pruebas de Tablero', () {
    test('Verifica que el tablero mida 7x7 casillas', () {
      final tablero = Tablero();
      expect(Tablero.cantidadFilas, equals(7));
      expect(Tablero.cantidadColumnas, equals(7));
      expect(tablero.celdas, hasLength(49));
    });
    test('Guarda y lee correctamente un dato en las celdas', () {
      final tablero = Tablero();

      tablero.colocarDato(0, 6, 9);
      tablero.colocarDato(6, 0, 4);

      expect(tablero.obtenerCelda(0, 6).valor, equals(9));
      expect(tablero.obtenerCelda(6, 0).valor, equals(4));
    });

    test('Rechaza coordenadas fuera del tablero', () {
      final tablero = Tablero();

      expect(
        () => tablero.obtenerCelda(7, 0),
        throwsRangeError,
      );
    });
  });
}