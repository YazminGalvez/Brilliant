import 'zona.dart';
import 'validador_inicio.dart';

class Tablero {
  static const int cantidadFilas = 7;
  static const int cantidadColumnas = 7;

  final List<List<Coordenada>> _matrizCeldas;
  final List<Zona> _listaRegiones = [];

  Tablero()
    : _matrizCeldas = List.generate(
        cantidadFilas,
        (f) => List.generate(
          cantidadColumnas,
          (c) => Coordenada(fila: f, columna: c),
        ),
      );

  List<Zona> get regiones => List.unmodifiable(_listaRegiones);

  int get puntuacionTotal => _listaRegiones.fold(
    0,
    (total, region) => total + region.puntosObtenidos,
  );

  int get puntuacionMaxima => _listaRegiones.fold(
    0,
    (total, region) => total + region.tipo.calcularPuntuacion(1),
  );

  Map<int, int> get puntuacionPorZona {
    final zonasCompletas = [
      for (final region in _listaRegiones)
        if (region.verificarCompletado()) region,
    ]..sort((a, b) => a.id.compareTo(b.id));

    return Map.unmodifiable({
      for (final region in zonasCompletas) region.id: region.puntosObtenidos,
    });
  }
  Set<int> get valoresColocados => {
    for (final celda in celdas)
      if (celda.valor != null) celda.valor!,
  };

  List<Coordenada> get celdas {
    final listaPlana = <Coordenada>[];
    for (var fila in _matrizCeldas) {
      listaPlana.addAll(fila);
    }
    return listaPlana;
  }

  Coordenada obtenerCelda(int fila, int columna) {
    if (fila < 0 ||
        fila >= cantidadFilas ||
        columna < 0 ||
        columna >= cantidadColumnas) {
      throw RangeError('Coordenada fuera de los límites del tablero.');
    }
    return _matrizCeldas[fila][columna];
  }

  void colocarDato(int fila, int columna, int? valor) {
    obtenerCelda(fila, columna).valor = valor;
  }

  // Celdas de ValidadorInicio.celdasIniciales (base 1) convertidas a base 0.
  List<Coordenada> get _celdasIniciales => [
    for (final (fila, columna) in ValidadorInicio.celdasIniciales)
      obtenerCelda(fila - 1, columna - 1),
  ];

  List<int?> get valoresIniciales => [
    for (final celda in _celdasIniciales) celda.valor,
  ];

  bool get inicializado =>
      ValidadorInicio.sonValoresInicialesValidos(valoresIniciales);

  void establecerValoresIniciales(List<int> valores) {
    if (!ValidadorInicio.sonValoresInicialesValidos(valores)) {
      throw ArgumentError(
        'Los valores iniciales deben ser exactamente los números del 1 al 6, '
        'sin repetir: $valores',
      );
    }

    final celdasIniciales = _celdasIniciales;
    for (var index = 0; index < valores.length; index++) {
      celdasIniciales[index].valor = valores[index];
    }
  }

  List<int?> extraerDatos() {
    if (!inicializado) {
      throw StateError(
        'Bloqueo activo: No se puede avanzar hasta que las celdas iniciales '
        'contengan los números del 1 al 6.',
      );
    }

    final datosExtraidos = <int?>[];
    for (var f = 0; f < cantidadFilas; f++) {
      for (var c = cantidadColumnas - 1; c >= 0; c--) {
        datosExtraidos.add(_matrizCeldas[f][c].valor);
      }
    }
    return datosExtraidos;
  }

  Zona? zonaEn(int fila, int columna) {
    obtenerCelda(fila, columna);

    final zonas = _listaRegiones
        .where((zona) => zona.contieneCoordenada(fila, columna))
        .toList(growable: false);
    if (zonas.length > 1) {
      throw StateError(
        'La celda ($fila, $columna) pertenece a más de una zona.',
      );
    }
    return zonas.isEmpty ? null : zonas.single;
  }

  void agregarRegion(Zona region) {
    for (var pos in region.coordenadas) {
      if (pos.fila < 0 ||
          pos.fila >= cantidadFilas ||
          pos.columna < 0 ||
          pos.columna >= cantidadColumnas) {
        throw RangeError('Coordenada de región fuera de los límites.');
      }
    }

    final idExistente = _listaRegiones.any(
      (element) => element.id == region.id,
    );
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
