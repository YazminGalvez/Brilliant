class ValidadorInicio {
  bool _valoresInicialesConfigurados = false;

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
}