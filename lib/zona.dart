import 'tipo.dart';

class Coordenada {
  final int fila;
  final int columna;
  int? valor;

  Coordenada({
    required this.fila,
    required this.columna,
    this.valor,
  });
  Coordenada.xy(this.fila, this.columna, {this.valor});

  int get x => fila;
  int get y => columna;

}


class Zona {
  final int id;
  final List<Coordenada> coordenadas;
  final Tipo tipo;
  bool completado;

  Zona({
    required this.id,
    required this.coordenadas,
    required this.tipo,
    this.completado = false,
  });

  int get tamanoZona {
    return coordenadas.length;
  }

  List<int> obtenerValores() {
    return coordenadas
        .where((coordenada) => coordenada.valor != null)
        .map((coordenada) => coordenada.valor!)
        .toList();
  }

  void colocarNumero(int fila, int columna, int numero) {
    for (var coordenada in coordenadas) {
      if (coordenada.fila == fila && coordenada.columna == columna) {
        coordenada.valor = numero;
        return;
      }
    }
    throw Exception(
      'La coordenada ($fila, $columna) no pertenece a esta zona.',
    );
  }

  bool contieneCoordenada(int fila, int columna) {
    return coordenadas.any(
      (coordenada) =>
          coordenada.fila == fila && coordenada.columna == columna,
    );
  }

  bool validarNuevoMovimiento(int posible) {
    return tipo.esPosibleAgregar(obtenerValores(), posible);
  }

  bool verificarCompletado() {
    if (coordenadas.any((coordenada) => coordenada.valor == null)) {
      completado = false;
      return false;
    }
    completado = true;
    return true;
  }
}