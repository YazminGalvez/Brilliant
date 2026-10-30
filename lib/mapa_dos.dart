import 'color_zona.dart';
import 'mapa.dart';
import 'tipo.dart';
import 'validador_inicio.dart';

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
  List<(int, int)> get celdasIniciales => ValidadorInicio.celdasIniciales;

  @override
  Set<ColorZona> get coloresUnidos => const {
    ColorZona.amarillo,
    ColorZona.gris,
  };

  @override
  Tipo crearTipo(ColorZona color) => Tipo.deColor(
    color,
    primerLugar: switch (color) {
      ColorZona.amarillo => 6,
      ColorZona.morado => 6,
      ColorZona.rojo => 6,
      ColorZona.azul => 7,
      ColorZona.verde => 4,
      ColorZona.gris => 3,
    },
  );
}
