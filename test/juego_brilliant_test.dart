import 'package:test/test.dart';
import 'package:juego_brilliant/tipo.dart';

void main() {
  group('Pruebas de colores', () {
    test('Azul acepta si todos son iguales', () {
      final zonaAzul = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 10,
      );

      expect(zonaAzul.validarMovimiento([]), isTrue);
      expect(zonaAzul.validarMovimiento([4, 4, 4]), isTrue);
      expect(zonaAzul.validarMovimiento([4, 5, 4]), isFalse);
    });

    test('Rojo no deja repetir números', () {
      final zonaRoja = Tipo(
        tipo: TipoZona.rojo,
        color: 'Rojo',
        regla: 'Todos diferentes',
        puntuacion: 10,
      );

      expect(zonaRoja.validarMovimiento([1, 2, 3, 4]), isTrue);
      expect(zonaRoja.validarMovimiento([1, 2, 3, 1]), isFalse);
    });

    test('Verde acepta cualquier cosa', () {
      final zonaVerde = Tipo(
        tipo: TipoZona.verde,
        color: 'Verde',
        regla: 'Libre',
        puntuacion: 10,
      );

      expect(zonaVerde.validarMovimiento([5, 5, 9, 1]), isTrue);
      expect(zonaVerde.validarMovimiento([7, 7, 7, 7]), isTrue);
    });

    test('Morado solo deja dos números distintos', () {
      final zonaMorada = Tipo(
        tipo: TipoZona.morado,
        color: 'Morado',
        regla: 'Dos números máximo',
        puntuacion: 10,
      );

      expect(zonaMorada.validarMovimiento([2, 8, 2, 8]), isTrue);
      expect(zonaMorada.validarMovimiento([2, 8, 5]), isFalse);
    });

    test('Amarillo revisa que no se repita número', () {
      final zonaAmarilla = Tipo(
        tipo: TipoZona.amarillo,
        color: 'Amarillo',
        regla: 'Sin repetir',
        puntuacion: 10,
      );

      expect(zonaAmarilla.validarAmarillo([10, 20, 30]), isTrue);
      expect(zonaAmarilla.validarAmarillo([10, 20, 10]), isFalse);
    });
  });

  group('Otras pruebas', () {
    test('Devuelve bien los puntos', () {
      final tipoConfig = Tipo(
        tipo: TipoZona.verde,
        color: 'Verde',
        regla: 'Libre',
        puntuacion: 25,
      );

      expect(tipoConfig.calcularPuntuacion(), equals(25));
    });

    test('Muestra la info correcta', () {
      final tipoConfig = Tipo(
        tipo: TipoZona.azul,
        color: 'Azul',
        regla: 'Todos iguales',
        puntuacion: 15,
      );

      final info = tipoConfig.obtenerInformacion();
      expect(info, contains('Azul'));
      expect(info, contains('15'));
      expect(info, contains('Todos iguales'));
    });
  });
}