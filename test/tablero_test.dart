import 'package:test/test.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  Tipo crearTipoVerde() {
    return TipoVerde();
  }

  group('Pruebas del Tablero', () {
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
    test('Extrae en orden de derecha a izquierda y arriba hacia abajo', () {
      final tablero = Tablero();
      final region = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [tablero.obtenerCelda(0, 0)],
      );

      tablero.establecerValoresIniciales([region]);
      tablero.colocarDato(0, 6, 1);
      tablero.colocarDato(0, 5, 2);
      tablero.colocarDato(1, 6, 3);

      final resultado = tablero.extraerDatos();

      expect(resultado[0], equals(1));
      expect(resultado[1], equals(2));
      expect(resultado[7], equals(3));
    });

    test('Bloquea la extracción si no se han proporcionado los valores iniciales', () {
      final tablero = Tablero();

      expect(
        () => tablero.extraerDatos(),
        throwsA(isA<StateError>()),
      );
    });

    test('Permite guardar una región sin asignarla a cada celda individualmente', () {
      final tablero = Tablero();
      final region = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [
          tablero.obtenerCelda(0, 0),
          tablero.obtenerCelda(0, 1),
        ],
      );

      tablero.agregarRegion(region);

      expect(tablero.regiones, contains(region));
      expect(tablero.obtenerCeldasDeRegion(region), hasLength(2));
    });

    test('No permite regiones con ids duplicados', () {
      final tablero = Tablero();
      final primera = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [tablero.obtenerCelda(0, 0)],
      );
      final segunda = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [tablero.obtenerCelda(1, 0)],
      );

      tablero.agregarRegion(primera);

      expect(
        () => tablero.agregarRegion(segunda),
        throwsArgumentError,
      );
    });
  });
}