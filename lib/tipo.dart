enum TipoZona {
  azul,
  rojo,
  verde,
  amarillo,
  morado,
}

class Tipo {
  final TipoZona tipo;
  final String color;
  final String regla;
  final int puntuacion;

  Tipo({
    required this.tipo,
    required this.color,
    required this.regla,
    required this.puntuacion,
  });

  bool validarMovimiento(List<int> valores) {
    switch (tipo) {
      case TipoZona.azul:
        if (valores.isEmpty) {
          return true;
        }
        return valores.every((numero) => numero == valores.first);

      case TipoZona.rojo:
        return valores.toSet().length == valores.length;

      case TipoZona.verde:
        return true;

      case TipoZona.amarillo:
        return true;

      case TipoZona.morado:
        return valores.toSet().length <= 2;
    }
  }

  bool validarAmarillo(List<int> valores) {
    if (tipo != TipoZona.amarillo) {
      return false;
    }
    return valores.toSet().length == valores.length;
  }

  int calcularPuntuacion() {
    return puntuacion;
  }

  String obtenerInformacion() {
    return '''
Tipo: $color
Regla: $regla
Puntuación: $puntuacion
''';
  }
}