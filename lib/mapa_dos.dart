import 'color_zona.dart';
import 'mapa.dart';
import 'tipo.dart';

const mapaDos = MapaDos();

class MapaDos extends Mapa {
  const MapaDos();

  static const List<String> dibujo = [
    'MMMGVVV',
    'MAZZZAV',
    'MRRZZRV',
    'RRRARRR',
    'VRZZRRM',
    'VAZZZAM',
    'VVVGMMM',
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
    _ => throw ArgumentError.value(letra, 'letra', 'No es un color del mapa.'),
  };

  @override
  int get numero => 2;

  @override
  List<List<ColorZona>> get colores => _colores;

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 5),
    (3, 1),
    (4, 3),
    (5, 6),
    (6, 2),
    (7, 5),
  ];

  @override
  Set<ColorZona> get coloresUnidos => const {
    ColorZona.amarillo,
    ColorZona.gris,
  };

  @override
  Map<ColorZona, PuntosPorLugar> get puntosPorColor => const {
    ColorZona.amarillo: (6, 4, 2),
    ColorZona.morado: (6, 4, 2),
    ColorZona.rojo: (6, 4, 2),
    ColorZona.azul: (7, 5, 3),
    ColorZona.verde: (4, 3, 2),
    ColorZona.gris: (3, 2, 1),
  };
}
