import 'package:test/test.dart';
import 'package:juego_brilliant/tipo.dart';

void main() {
  group('Pruebas de colores', () {
    test('Azul acepta si todos son iguales', () {
      final zonaAzul = TipoAzul();

      expect(zonaAzul.esPosibleAgregar([], 4), isTrue);
      expect(zonaAzul.esPosibleAgregar([4, 4], 4), isTrue);
      expect(zonaAzul.esPosibleAgregar([4, 5], 4), isFalse);
    });

    test('Rojo no deja repetir números', () {
      final zonaRoja = TipoRojo();

      expect(zonaRoja.esPosibleAgregar([1, 2, 3], 4), isTrue);
      expect(zonaRoja.esPosibleAgregar([1, 2, 3], 1), isFalse);
    });

    test('Verde acepta cualquier cosa', () {
      final zonaVerde = TipoVerde();

      expect(zonaVerde.esPosibleAgregar([5, 5, 9], 1), isTrue);
      expect(zonaVerde.esPosibleAgregar([7, 7, 7], 7), isTrue);
    });

    test('Morado solo deja dos números distintos', () {
      final zonaMorada = TipoMorado();

      expect(zonaMorada.esPosibleAgregar([2, 8, 2], 8), isTrue);
      expect(zonaMorada.esPosibleAgregar([2, 8], 5), isFalse);
    });

    test('Amarillo revisa que no se repita número', () {
      final zonaAmarilla = TipoAmarillo();

      expect(zonaAmarilla.esPosibleAgregar([10, 20], 30), isTrue);
      expect(zonaAmarilla.esPosibleAgregar([10, 20], 10), isFalse);
    });
  });

  group('Otras pruebas', () {
    test('Devuelve bien los puntos', () {
      final tipoConfig = TipoVerde();

      expect(tipoConfig.puntuaciones[1], equals(4));
    });

    test('Muestra la info correcta', () {
      final tipoConfig = TipoAzul();

      expect(tipoConfig.descripcion, equals('Todos los números deben de ser iguales'));
    });
  });
}