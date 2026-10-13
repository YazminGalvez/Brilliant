import 'package:juego_brilliant/historial_lanzamientos.dart';
import 'package:test/test.dart';

void main() {
  group('HistorialLanzamientos', () {
    test('inicia vacío y no tiene una última tirada', () {
      final historial = HistorialLanzamientos();

      expect(historial.tiradas, isEmpty);
      expect(historial.cantidad, 0);
      expect(historial.ultima, isNull);
    });

    test('registra cada resultado en orden y asigna número consecutivo', () {
      final historial = HistorialLanzamientos();

      final primera = historial.registrar([2, 5]);
      final segunda = historial.registrar([6, 1]);

      expect(historial.cantidad, 2);
      expect(primera.numeroTirada, 1);
      expect(primera.valores, [2, 5]);
      expect(primera.primerDado, 2);
      expect(primera.segundoDado, 5);
      expect(segunda.numeroTirada, 2);
      expect(segunda.valores, [6, 1]);
      expect(historial.tiradas, [primera, segunda]);
      expect(historial.ultima, same(segunda));
    });

    test('expone una colección inmutable', () {
      final historial = HistorialLanzamientos()..registrar([3, 4]);

      expect(
        () => historial.tiradas.add(
          TiradaDados(numeroTirada: 2, valores: [1, 2]),
        ),
        throwsUnsupportedError,
      );
      expect(historial.cantidad, 1);
    });

    test('rechaza tiradas que no contienen dos dados', () {
      final historial = HistorialLanzamientos();

      expect(() => historial.registrar([]), throwsArgumentError);
      expect(() => historial.registrar([1]), throwsArgumentError);
      expect(() => historial.registrar([1, 2, 3]), throwsArgumentError);
      expect(historial.tiradas, isEmpty);
    });

    test('rechaza valores de dado fuera del rango de 1 a 6', () {
      final historial = HistorialLanzamientos();

      expect(() => historial.registrar([0, 3]), throwsArgumentError);
      expect(() => historial.registrar([4, 7]), throwsArgumentError);
      expect(historial.tiradas, isEmpty);
    });

    test('rechaza números de tirada inválidos al crear un registro', () {
      expect(
        () => TiradaDados(numeroTirada: 0, valores: [1, 2]),
        throwsArgumentError,
      );
    });

    test('limpiar elimina el historial y reinicia la numeración', () {
      final historial = HistorialLanzamientos()
        ..registrar([1, 6])
        ..registrar([4, 4]);

      historial.limpiar();

      expect(historial.tiradas, isEmpty);
      expect(historial.ultima, isNull);
      expect(historial.registrar([5, 2]).numeroTirada, 1);
    });
  });
}
