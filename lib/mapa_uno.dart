import 'color_zona.dart';
import 'mapa.dart';
import 'validador_inicio.dart';

const mapaUno = MapaUno();

class MapaUno extends Mapa {
  const MapaUno();

  static const _a = ColorZona.amarillo;
  static const _v = ColorZona.verde;
  static const _z = ColorZona.azul;
  static const _m = ColorZona.morado;
  static const _r = ColorZona.rojo;

  @override
  int get numero => 1;

  @override
  List<List<ColorZona>> get colores => const [
    [_a, _v, _z, _m, _m, _m, _a],
    [_v, _v, _z, _z, _m, _m, _v],
    [_v, _r, _r, _z, _m, _v, _v],
    [_v, _r, _m, _a, _v, _v, _v],
    [_v, _r, _m, _m, _r, _r, _z],
    [_r, _r, _m, _r, _r, _z, _z],
    [_a, _m, _m, _r, _r, _z, _a],
  ];

  @override
  List<(int, int)> get celdasIniciales => ValidadorInicio.celdasIniciales;

  @override
  Set<ColorZona> get coloresUnidos => const {ColorZona.amarillo};
}
