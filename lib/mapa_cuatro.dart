import 'color_zona.dart';
import 'mapa.dart';
import 'validador_inicio.dart';

const mapaCuatro = MapaCuatro();

class MapaCuatro extends Mapa {
  const MapaCuatro();

  static const List<String> dibujo = [
    'OOOOOOO',
    'ARZVZRA',
    'RRMMMRR',
    'AVZMZVA',
    'RRMMMRR',
    'ARZVZRA',
    'OOOOOOO',
  ];

  static final List<List<ColorZona>> _colores = List.unmodifiable([
    for (final fila in dibujo)
      List<ColorZona>.unmodifiable([
        for (final letra in fila.split('')) _colorDeLetra(letra),
      ]),
  ]);

  static ColorZona _colorDeLetra(String letra) => switch (letra) {
    'A' => ColorZona.amarillo,
    'V' => ColorZona.verde,
    'Z' => ColorZona.azul,
    'M' => ColorZona.morado,
    'R' => ColorZona.rojo,
    'G' => ColorZona.gris,
    'O' => ColorZona.naranja,
    _ => throw ArgumentError.value(letra, 'letra', 'No es un color del mapa.'),
  };

  @override
  int get numero => 4;

  @override
  List<List<ColorZona>> get colores => _colores;

  @override
  List<(int, int)> get celdasIniciales => ValidadorInicio.celdasIniciales;

  @override
  Set<ColorZona> get coloresUnidos => const {
    ColorZona.amarillo,
    ColorZona.azul,
    ColorZona.verde,
  };

  @override
  List<List<(int, int)>> get partesUnidas => const [
    [(3, 1), (5, 1)],
    [(3, 7), (5, 7)],
  ];
}
