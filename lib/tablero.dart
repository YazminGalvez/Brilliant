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
            (c) => Coordenada(fila: f, columna: c),
          ),
        );

  List<Coordenada> get celdas {
    final listaPlana = <Coordenada>[];
    for (var fila in _matrizCeldas) {
      listaPlana.addAll(fila);
    }
    return listaPlana;
  }

  Coordenada obtenerCelda(int fila, int columna) {
    if (fila < 0 || fila >= cantidadFilas || columna < 0 || columna >= cantidadColumnas) {
      throw RangeError('Coordenada fuera de los límites del tablero.');
    }
    return _matrizCeldas[fila][columna];
  }

  void colocarDato(int fila, int columna, int? valor) {
    obtenerCelda(fila, columna).valor = valor;
  }
}