import 'package:test/test.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  late Tablero tablero;

  Zona agregarZona(int id, Tipo tipo, List<(int, int)> posiciones) {
    final zona = Zona(
      id: id,
      tipo: tipo,
      coordenadas: [
        for (final (fila, columna) in posiciones)
          tablero.obtenerCelda(fila, columna),
      ],
    );
    tablero.agregarRegion(zona);
    return zona;
  }

  setUp(() {
    tablero = Tablero();
  });

  group('Puntuación del tablero', () {
    test('Sin zonas todo vale 0', () {
      expect(tablero.puntuacionTotal, 0);
      expect(tablero.puntuacionMaxima, 0);
      expect(tablero.puntuacionPorZona, isEmpty);
    });

    for (final (tipo, valores, puntos) in [
      (TipoRojo(), [1, 2], 6),
      (TipoAzul(), [3, 3], 7),
      (TipoVerde(), [5, 5], 4),
      (TipoAmarillo(), [4, 6], 8),
      (TipoMorado(), [2, 5], 6),
    ]) {
      test('Zona ${tipo.nombre} suma $puntos solo al llenarse', () {
        final zona = agregarZona(1, tipo, [(0, 0), (0, 1)]);

        zona.colocarNumero(0, 0, valores[0]);
        expect(tablero.puntuacionTotal, 0);

        zona.colocarNumero(0, 1, valores[1]);
        expect(tablero.puntuacionTotal, puntos);
      });
    }

    test('Dos zonas del mismo color puntúan por separado', () {
      agregarZona(1, TipoVerde(), [(0, 0)]).colocarNumero(0, 0, 1);
      agregarZona(2, TipoVerde(), [(6, 6)]).colocarNumero(6, 6, 2);

      expect(tablero.puntuacionTotal, 8);
    });

    test('La puntuación máxima del Mapa 1 es 54 aunque esté vacío', () {
      final tipos = [
        TipoRojo(),
        TipoRojo(),
        TipoAzul(),
        TipoAzul(),
        TipoVerde(),
        TipoVerde(),
        TipoMorado(),
        TipoMorado(),
        TipoAmarillo(),
      ];
      for (var index = 0; index < tipos.length; index++) {
        agregarZona(index, tipos[index], [(index ~/ 7, index % 7)]);
      }

      expect(tablero.puntuacionMaxima, 54);
      expect(tablero.puntuacionTotal, 0);
    });

    test('puntuacionPorZona solo incluye las zonas completas', () {
      agregarZona(3, TipoAzul(), [(0, 0)]).colocarNumero(0, 0, 4);
      agregarZona(1, TipoRojo(), [(1, 0)]).colocarNumero(1, 0, 2);
      agregarZona(2, TipoVerde(), [(2, 0), (2, 1)]).colocarNumero(2, 0, 6);

      expect(tablero.puntuacionPorZona, {1: 6, 3: 7});
      expect(tablero.puntuacionPorZona.keys, [1, 3]);
    });

    test('El 2º y 3º lugar no influyen en el total', () {
      final tipo = TipoAmarillo();
      expect(tipo.puntuaciones, hasLength(3));

      agregarZona(1, tipo, [(0, 0)]).colocarNumero(0, 0, 1);

      expect(tablero.puntuacionTotal, tipo.calcularPuntuacion(1));
    });
  });

  group('Puntos de una zona', () {
    test('Una zona incompleta da 0 y completa da el 1er lugar', () {
      final zona = agregarZona(1, TipoAzul(), [(0, 0), (0, 1)]);

      zona.colocarNumero(0, 0, 5);
      expect(zona.puntosObtenidos, 0);

      zona.colocarNumero(0, 1, 5);
      expect(zona.puntosObtenidos, 7);
    });
  });
}
