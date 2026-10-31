import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/tipo.dart';

void main() {
  group('Pruebas de Tipo Naranja', () {
    test('El rango 4 a 6 acepta 4, 5 y 6', () {
      final naranja = TipoNaranja(minimo: 4, maximo: 6);

      expect(naranja.esPosibleAgregar([], 4), isTrue);
      expect(naranja.esPosibleAgregar([], 5), isTrue);
      expect(naranja.esPosibleAgregar([], 6), isTrue);
    });

    test('El rango 4 a 6 acepta números repetidos', () {
      final naranja = TipoNaranja(minimo: 4, maximo: 6);

      expect(naranja.esPosibleAgregar([5, 5], 5), isTrue);
      expect(naranja.esPosibleAgregar([4, 6, 4], 6), isTrue);
    });

    test('El rango 4 a 6 rechaza 1, 2 y 3', () {
      final naranja = TipoNaranja(minimo: 4, maximo: 6);

      expect(naranja.esPosibleAgregar([], 1), isFalse);
      expect(naranja.esPosibleAgregar([4], 2), isFalse);
      expect(naranja.esPosibleAgregar([5, 6], 3), isFalse);
    });

    test('El rango 1 a 3 acepta 1, 2, 3 y repetidos', () {
      final naranja = TipoNaranja(minimo: 1, maximo: 3);

      expect(naranja.esPosibleAgregar([], 1), isTrue);
      expect(naranja.esPosibleAgregar([1], 2), isTrue);
      expect(naranja.esPosibleAgregar([3, 3], 3), isTrue);
    });

    test('El rango 1 a 3 rechaza 4, 5 y 6', () {
      final naranja = TipoNaranja(minimo: 1, maximo: 3);

      expect(naranja.esPosibleAgregar([], 4), isFalse);
      expect(naranja.esPosibleAgregar([1], 5), isFalse);
      expect(naranja.esPosibleAgregar([2, 3], 6), isFalse);
    });

    test('Un rango fuera de 1 a 6 o al revés lanza un error', () {
      expect(() => TipoNaranja(minimo: 0, maximo: 3), throwsArgumentError);
      expect(() => TipoNaranja(minimo: 4, maximo: 7), throwsArgumentError);
      expect(() => TipoNaranja(minimo: 5, maximo: 2), throwsArgumentError);
    });

    test('Un rango de un solo número es válido', () {
      final naranja = TipoNaranja(minimo: 3, maximo: 3);

      expect(naranja.esPosibleAgregar([3], 3), isTrue);
      expect(naranja.esPosibleAgregar([], 4), isFalse);
    });

    test('Da 6/4/3 puntos', () {
      final naranja = TipoNaranja();

      expect(naranja.puntuaciones, {1: 6, 2: 4, 3: 3});
      expect(naranja.calcularPuntuacion(), 6);
    });

    test('Tiene su nombre, descripción y color de zona', () {
      final naranja = TipoNaranja(minimo: 2, maximo: 5);

      expect(naranja.nombre, 'Naranja');
      expect(naranja.descripcion, 'Solo números del 2 al 5; pueden repetirse');
      expect(naranja.colorZona, ColorZona.naranja);
    });

    test('Tipo.deColor usa el rango completo de 1 a 6', () {
      final tipo = Tipo.deColor(ColorZona.naranja);

      expect(tipo, isA<TipoNaranja>());
      final naranja = tipo as TipoNaranja;
      expect(naranja.minimo, 1);
      expect(naranja.maximo, 6);
      for (var numero = 1; numero <= 6; numero++) {
        expect(naranja.esPosibleAgregar([], numero), isTrue, reason: '$numero');
      }
    });
  });
}
