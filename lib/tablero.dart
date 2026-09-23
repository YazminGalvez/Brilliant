import 'zona.dart';

class Tablero {
  static const int cantidadFilas = 7;
  static const int cantidadColumnas = 7;

  final List<List<Coordenada>> _matrizCeldas;
  final List<Zona> _listaRegiones = [];
  bool _valoresInicialesListos = false;

  Tablero()
      : _matrizCeldas = List.generate(
          cantidadFilas,
          (f) => List.generate(
            cantidadColumnas,
            (c) => Coordenada(fila: f, columna: c),
          ),
        );

  List<Zona> get regiones => List.unmodifiable(_listaRegiones);
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

  void establecerValoresIniciales(List<Zona> regionesIniciales) {
    for (var region in regionesIniciales) {
      agregarRegion(region);
    }
    _valoresInicialesListos = true;
  }

  List<int?> extraerDatos() {
    if (!_valoresInicialesListos) {
      throw StateError('Bloqueo activo: No se puede avanzar hasta proporcionar los valores iniciales.');
    }

    final datosExtraidos = <int?>[];
    for (var f = 0; f < cantidadFilas; f++) {
      for (var c = cantidadColumnas - 1; c >= 0; c--) {
        datosExtraidos.add(_matrizCeldas[f][c].valor);
      }
    }
    return datosExtraidos;
  }

  void agregarRegion(Zona region) {
    for (var pos in region.coordenadas) {
      if (pos.fila < 0 || pos.fila >= cantidadFilas || pos.columna < 0 || pos.columna >= cantidadColumnas) {
        throw RangeError('Coordenada de región fuera de los límites.');
      }
    }

    final idExistente = _listaRegiones.any((element) => element.id == region.id);
    if (idExistente) {
      throw ArgumentError('Ya existe una región con el id ${region.id}.');
    }

    _listaRegiones.add(region);
  }

  List<Coordenada> obtenerCeldasDeRegion(Zona region) {
    if (!_listaRegiones.contains(region)) {
      throw ArgumentError('La región no pertenece a este tablero.');
    }

    return region.coordenadas
        .map((coord) => obtenerCelda(coord.fila, coord.columna))
        .toList();
  }
}