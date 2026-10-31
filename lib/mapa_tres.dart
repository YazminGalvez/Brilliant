import 'color_zona.dart';
import 'mapa.dart';
import 'validador_inicio.dart';

const mapaTres = MapaTres();

class MapaTres extends Mapa {
  const MapaTres();

  static const List<String> dibujo = [
    'AAMGMAA',
    'GAMMMAG',
    'RRRMRRR',
    'RRRGRRR',
    'VZZZZZV',
    'VVVVVVV',
    'MMMGMMM',
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
  int get numero => 3;

  @override
  List<List<ColorZona>> get colores => _colores;

  @override
  List<(int, int)> get celdasIniciales => ValidadorInicio.celdasIniciales;

  @override
  Set<ColorZona> get coloresUnidos => const {
    ColorZona.amarillo,
    ColorZona.gris,
  };

  @override
  List<List<(int, int)>> get partesUnidas => const [
    [(7, 1), (7, 5)],
  ];
}
