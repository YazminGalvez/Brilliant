import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/tipo.dart';

void main() {
  test('El enum tiene exactamente los 5 colores de zona', () {
    expect(
      ColorZona.values.map((color) => color.name),
      ['amarillo', 'verde', 'azul', 'morado', 'rojo'],
    );
  });

  test('Cada tipo devuelve su color de zona', () {
    expect(TipoAmarillo().colorZona, ColorZona.amarillo);
    expect(TipoVerde().colorZona, ColorZona.verde);
    expect(TipoAzul().colorZona, ColorZona.azul);
    expect(TipoMorado().colorZona, ColorZona.morado);
    expect(TipoRojo().colorZona, ColorZona.rojo);
  });

  test('Tipo.deColor devuelve el tipo de cada color', () {
    expect(Tipo.deColor(ColorZona.amarillo), isA<TipoAmarillo>());
    expect(Tipo.deColor(ColorZona.verde), isA<TipoVerde>());
    expect(Tipo.deColor(ColorZona.azul), isA<TipoAzul>());
    expect(Tipo.deColor(ColorZona.morado), isA<TipoMorado>());
    expect(Tipo.deColor(ColorZona.rojo), isA<TipoRojo>());

    for (final color in ColorZona.values) {
      expect(Tipo.deColor(color).colorZona, color);
    }
  });
}
