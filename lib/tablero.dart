import 'zona.dart';

class Tablero {
  static const int cantidadFilas = 7;
  static const int cantidadColumnas = 7;

  final List<List<Coordenada>> _matrizCeldas;

  Tablero()
      : _matrizCeldas = List.generate(
          cantidadFilas,
          (f) => List.generate(
            cantidadColumnas,
            (c) => Coordenada.xy(f, c),
          ),
        );

  List<Coordenada> get celdas {
    final listaPlana = <Coordenada>[];
    for (var fila in _matrizCeldas) {
      listaPlana.addAll(fila);
    }
    return listaPlana;
  }
}