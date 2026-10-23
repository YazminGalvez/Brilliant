enum EstadoInicialPartida { bloqueado, inicializado, jugando }

class ValidadorInicio {
  // Posiciones dadas por el profesor como (fila, columna), contando desde 1.
  static const List<(int, int)> celdasIniciales = [
    (1, 3),
    (2, 6),
    (4, 2),
    (4, 5),
    (6, 3),
    (7, 5),
  ];

  EstadoInicialPartida _estado = EstadoInicialPartida.bloqueado;

  EstadoInicialPartida get estado => _estado;
  bool get bloqueado => _estado == EstadoInicialPartida.bloqueado;
  bool get puedeIniciar => _estado == EstadoInicialPartida.inicializado;
  bool get jugando => _estado == EstadoInicialPartida.jugando;

  void actualizarValoresIniciales(List<int?> valores) {
    if (!sonValoresInicialesValidos(valores)) {
      _estado = EstadoInicialPartida.bloqueado;
      return;
    }

    if (_estado != EstadoInicialPartida.jugando) {
      _estado = EstadoInicialPartida.inicializado;
    }
  }

  void iniciarPartida() {
    if (_estado != EstadoInicialPartida.inicializado) {
      throw StateError(
        'La partida no puede iniciar hasta que las celdas iniciales sean válidas.',
      );
    }
    _estado = EstadoInicialPartida.jugando;
  }

  void reiniciar() {
    _estado = EstadoInicialPartida.bloqueado;
  }

  void validarAntesDeIniciar() {
    if (_estado != EstadoInicialPartida.inicializado) {
      throw StateError(
        'Debes completar los valores iniciales antes de iniciar la partida.',
      );
    }
  }

  static bool sonValoresInicialesValidos(List<int?> valores) {
    if (valores.length != celdasIniciales.length ||
        valores.any((valor) => valor == null)) {
      return false;
    }

    final numeros = valores.cast<int>().toSet();
    return numeros.length == celdasIniciales.length &&
        numeros.containsAll(List<int>.generate(6, (index) => index + 1));
  }
}
