import 'package:test/test.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';

void main() {
  group('Valores iniciales según la zona', () {
    test(
      'El naranja de arriba del Mapa 4 rechaza un valor inicial fuera de 4 a 6',
      () {
        final partida = Partida(mapa: mapaCuatro);

        expect(() => partida.colocarValorInicial(0, 4, 2), throwsArgumentError);
        expect(partida.tablero.obtenerCelda(0, 4).valor, isNull);
      },
    );

    test(
      'El naranja de arriba del Mapa 4 acepta un valor inicial de 4 a 6',
      () {
        final partida = Partida(mapa: mapaCuatro);

        partida.colocarValorInicial(0, 4, 5);

        expect(partida.tablero.obtenerCelda(0, 4).valor, 5);
      },
    );

    test('El naranja de abajo del Mapa 4 rechaza 4 a 6 y acepta 1 a 3', () {
      final partida = Partida(mapa: mapaCuatro);

      expect(() => partida.colocarValorInicial(6, 1, 5), throwsArgumentError);
      partida.colocarValorInicial(6, 1, 2);
      expect(partida.tablero.obtenerCelda(6, 1).valor, 2);
    });

    test(
      'Una zona con otros números rechaza un valor inicial que rompe su regla',
      () {
        final partida = Partida(mapa: mapaCuatro);
        partida.tablero.colocarDato(1, 2, 2);

        expect(() => partida.colocarValorInicial(5, 4, 3), throwsArgumentError);
        partida.colocarValorInicial(5, 4, 2);
        expect(partida.tablero.obtenerCelda(5, 4).valor, 2);
      },
    );

    test(
      'Al cambiar el valor de una celda no cuenta el valor que ya tenía',
      () {
        final partida = Partida(mapa: mapaCuatro);
        partida.colocarValorInicial(5, 4, 3);

        partida.colocarValorInicial(5, 4, 4);

        expect(partida.tablero.obtenerCelda(5, 4).valor, 4);
      },
    );

    test('Revisar si la zona acepta un valor no cambia la celda', () {
      final partida = Partida(mapa: mapaCuatro);
      partida.colocarValorInicial(5, 4, 3);

      expect(partida.zonaAceptaValorInicial(5, 4, 4), isTrue);
      expect(partida.zonaAceptaValorInicial(0, 4, 1), isFalse);
      expect(partida.tablero.obtenerCelda(5, 4).valor, 3);
      expect(partida.tablero.obtenerCelda(0, 4).valor, isNull);
    });

    test('Vaciar una celda inicial sigue permitido', () {
      final partida = Partida(mapa: mapaCuatro);
      partida.colocarValorInicial(0, 4, 6);

      partida.colocarValorInicial(0, 4, null);

      expect(partida.tablero.obtenerCelda(0, 4).valor, isNull);
    });

    test(
      'El Mapa 1 sigue aceptando los números del 1 al 6 en sus celdas iniciales',
      () {
        final partida = Partida(mapa: mapaUno);
        final celdas = mapaUno.celdasIniciales;

        for (var indice = 0; indice < celdas.length; indice++) {
          final (fila, columna) = celdas[indice];
          partida.colocarValorInicial(fila - 1, columna - 1, indice + 1);
        }

        expect(partida.puedeIniciar, isTrue);
      },
    );
  });
}
