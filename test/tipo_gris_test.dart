import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/tipo.dart';

void main() {
  group('Tipo gris', () {
    test('Acepta cualquier número en la primera celda', () {
      final zonaGris = TipoGris();

      expect(zonaGris.esPosibleAgregar([], 1), isTrue);
      expect(zonaGris.esPosibleAgregar([], 6), isTrue);
    });

    test('Acepta un número igual a los que ya tiene', () {
      final zonaGris = TipoGris();

      expect(zonaGris.esPosibleAgregar([3], 3), isTrue);
      expect(zonaGris.esPosibleAgregar([3, 3], 3), isTrue);
    });

    test('Rechaza un número distinto de los que ya tiene', () {
      final zonaGris = TipoGris();

      expect(zonaGris.esPosibleAgregar([3], 4), isFalse);
      expect(zonaGris.esPosibleAgregar([3, 3], 1), isFalse);
    });

    test('Da 3/2/1 puntos', () {
      final zonaGris = TipoGris();

      expect(zonaGris.calcularPuntuacion(1), 3);
      expect(zonaGris.calcularPuntuacion(2), 2);
      expect(zonaGris.calcularPuntuacion(3), 1);
      expect(zonaGris.calcularPuntuacion(), 3);
    });

    test('Tiene su nombre, descripción y color de zona', () {
      final zonaGris = TipoGris();

      expect(zonaGris.nombre, 'Gris');
      expect(
        zonaGris.descripcion,
        'Todos los números grises deben ser iguales',
      );
      expect(zonaGris.colorZona, ColorZona.gris);
    });

    test('Tipo.deColor devuelve el tipo gris para el color gris', () {
      final tipo = Tipo.deColor(ColorZona.gris);

      expect(tipo, isA<TipoGris>());
      expect(tipo.colorZona, ColorZona.gris);
    });
  });
}
