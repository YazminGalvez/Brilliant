class TiradaDados {
  TiradaDados({required this.numeroTirada, required List<int> valores})
    : valores = List<int>.unmodifiable(valores) {
    if (numeroTirada <= 0) {
      throw ArgumentError.value(
        numeroTirada,
        'numeroTirada',
        'Debe ser mayor que cero.',
      );
    }
    if (this.valores.length != 2) {
      throw ArgumentError.value(
        valores,
        'valores',
        'Cada tirada debe contener exactamente dos dados.',
      );
    }
    for (final valor in this.valores) {
      if (valor < 1 || valor > 6) {
        throw ArgumentError.value(
          valores,
          'valores',
          'Cada dado debe tener un valor entre 1 y 6.',
        );
      }
    }
  }

  final int numeroTirada;
  final List<int> valores;

  int get primerDado => valores[0];
  int get segundoDado => valores[1];
}

class HistorialLanzamientos {
  final List<TiradaDados> _tiradas = [];

  List<TiradaDados> get tiradas => List.unmodifiable(_tiradas);
  int get cantidad => _tiradas.length;
  TiradaDados? get ultima => _tiradas.isEmpty ? null : _tiradas.last;

  TiradaDados registrar(List<int> valores) {
    final tirada = TiradaDados(
      numeroTirada: _tiradas.length + 1,
      valores: valores,
    );
    _tiradas.add(tirada);
    return tirada;
  }

  void limpiar() => _tiradas.clear();
}
