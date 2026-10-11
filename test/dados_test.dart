import 'dart:math';

import 'package:juego_brilliant/dados.dart';
import 'package:test/test.dart';

void main() {
  group('Dado', () {
    test('cada lanzamiento devuelve un valor entre 1 y 6', () {
      final dado = Dado(random: Random(42));

      for (var lanzamiento = 0; lanzamiento < 100; lanzamiento++) {
        final valor = dado.lanzar();
        expect(valor, inInclusiveRange(1, 6));
        expect(dado.valor, valor);
      }
    });
  });

  group('Dados', () {
    test('lanza todos los dados de la colección', () {
      final dados = Dados(cantidad: 5, random: Random(42));

      final valores = dados.lanzar();

      expect(valores, hasLength(5));
      expect(valores, everyElement(inInclusiveRange(1, 6)));
      expect(dados.dados, hasLength(5));
    });

    test('produce la misma secuencia con la misma semilla', () {
      final primeraTirada = Dados(cantidad: 6, random: Random(42)).lanzar();
      final segundaTirada = Dados(cantidad: 6, random: Random(42)).lanzar();

      expect(segundaTirada, primeraTirada);
    });

    test('no permite crear una colección sin dados', () {
      expect(() => Dados(cantidad: 0, random: Random(42)), throwsArgumentError);
    });
  });
}
