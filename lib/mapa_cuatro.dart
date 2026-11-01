import 'color_zona.dart';
import 'mapa.dart';
import 'tipo.dart';
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

  @override
  Tipo crearTipo(ColorZona color) => Tipo.deColor(
    color,
    primerLugar: switch (color) {
      ColorZona.amarillo => 8,
      ColorZona.rojo => 6,
      ColorZona.azul => 8,
      ColorZona.verde => 3,
      ColorZona.morado => 7,
      ColorZona.naranja => 6,
      ColorZona.gris => null,
    },
  );

  @override
  Tipo crearTipoDeZona(ColorZona color, List<(int, int)> celdas) {
    if (color != ColorZona.naranja) return crearTipo(color);
    final (minimo, maximo) = switch (celdas.first.$1) {
      1 => (4, 6),
      7 => (1, 3),
      final fila => throw StateError('No hay naranja en la fila $fila.'),
    };
    return TipoNaranja(minimo: minimo, maximo: maximo, primerLugar: 6);
  }
}
