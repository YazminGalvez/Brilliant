enum EstadoInicialPartida { bloqueado, inicializado, jugando }

class ValidadorInicio {
  static const List<(int, int)> celdasIniciales = [
    (1, 3),
    (2, 6),
    (4, 2),
    (4, 5),
    (6, 3),
    (7, 5),
  ];

  bool _valoresInicialesConfigurados = false;
  EstadoInicialPartida _estado = EstadoInicialPartida.bloqueado;

  EstadoInicialPartida get estado => _estado;
  bool get bloqueado => _estado == EstadoInicialPartida.bloqueado;
  bool get puedeIniciar => _estado == EstadoInicialPartida.inicializado;
  bool get jugando => _estado == EstadoInicialPartida.jugando;

  void actualizarValoresIniciales(List<int?> valores) {
    if (!_sonValoresInicialesValidos(valores)) {
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
    _valoresInicialesConfigurados = false;
  }

  void marcarValoresInicialesConfigurados() {
    _valoresInicialesConfigurados = true;
  }

  void validarAvance() {
    if (!_valoresInicialesConfigurados) {
      throw StateError(
        'Bloqueo activo: No se puede avanzar hasta proporcionar los valores iniciales.',
      );
    }
  }

  void validarAntesDeIniciar() {
    if (_estado != EstadoInicialPartida.inicializado) {
      throw StateError(
        'Debes completar los valores iniciales antes de iniciar la partida.',
      );
    }
  }

  bool _sonValoresInicialesValidos(List<int?> valores) {
    if (valores.length != celdasIniciales.length ||
        valores.any((valor) => valor == null)) {
      return false;
    }

    final numeros = valores.cast<int>().toSet();
    return numeros.length == celdasIniciales.length &&
        numeros.containsAll(List<int>.generate(6, (index) => index + 1));
  }
}
