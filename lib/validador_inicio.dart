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
