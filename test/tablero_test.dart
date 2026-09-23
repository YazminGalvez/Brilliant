import 'package:test/test.dart';
import 'package:juego_brilliant/tablero.dart';

void main() {
  group('Pruebas iniciales del Tablero', () {
    test('Verifica que el tablero mida 7x7 casillas', () {
      final tablero = Tablero();
      expect(Tablero.cantidadFilas, equals(7));
      expect(Tablero.cantidadColumnas, equals(7));
      expect(tablero.celdas, hasLength(49));
    });
  });
}