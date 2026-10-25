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

      expect(tipoConfig.descripcion, equals('Todos los números deben ser iguales'));
    });
  });

  group('Puntuaciones', () {
    test('Rojo da 6/4/2', () {
      expect(TipoRojo().puntuaciones, {1: 6, 2: 4, 3: 2});
    });

    test('Azul da 7/5/3', () {
      expect(TipoAzul().puntuaciones, {1: 7, 2: 5, 3: 3});
    });

    test('Verde da 4/3/2', () {
      expect(TipoVerde().puntuaciones, {1: 4, 2: 3, 3: 2});
    });

    test('Amarillo da 8/6/4', () {
      expect(TipoAmarillo().puntuaciones, {1: 8, 2: 6, 3: 4});
    });

    test('Morado da 6/4/2', () {
      expect(TipoMorado().puntuaciones, {1: 6, 2: 4, 3: 2});
    });

    test('calcularPuntuacion sin argumento da los puntos del 1er lugar', () {
      for (final tipo in [
        TipoAmarillo(),
        TipoVerde(),
        TipoAzul(),
        TipoMorado(),
        TipoRojo(),
      ]) {
        expect(tipo.calcularPuntuacion(), tipo.puntuaciones[1]);
      }
    });

    test('calcularPuntuacion rechaza posiciones fuera de 1 a 3', () {
      final tipo = TipoVerde();

      expect(() => tipo.calcularPuntuacion(0), throwsArgumentError);
      expect(() => tipo.calcularPuntuacion(4), throwsArgumentError);
    });

    test('La puntuación máxima del Mapa 1 es 54', () {
      final maxima = 2 *
              (TipoRojo().calcularPuntuacion() +
                  TipoAzul().calcularPuntuacion() +
                  TipoVerde().calcularPuntuacion() +
                  TipoMorado().calcularPuntuacion()) +
          TipoAmarillo().calcularPuntuacion();

      expect(maxima, 54);
    });
  });

  group('Nombres y descripciones', () {
    test('Amarillo', () {
      expect(TipoAmarillo().nombre, 'Amarilla');
      expect(
        TipoAmarillo().descripcion,
        'Todos los números deben ser distintos',
      );
    });

    test('Verde', () {
      expect(TipoVerde().nombre, 'Verde');
      expect(TipoVerde().descripcion, 'Se puede colocar cualquier número');
    });

    test('Azul', () {
      expect(TipoAzul().nombre, 'Azul');
      expect(TipoAzul().descripcion, 'Todos los números deben ser iguales');
    });

    test('Morado', () {
      expect(TipoMorado().nombre, 'Morada');
      expect(
        TipoMorado().descripcion,
        'Máximo dos números diferentes por zona',
      );
    });

    test('Rojo', () {
      expect(TipoRojo().nombre, 'Roja');
      expect(TipoRojo().descripcion, 'Todos los números deben ser distintos');
    });
  });
}