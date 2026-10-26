import 'tablero.dart';
import 'zona.dart';

class OpcionAncla {
  const OpcionAncla({
    required this.ancla,
    required this.numeroAColocar,
    required this.puedeSeleccionarse,
  });

  final int ancla;
  final int numeroAColocar;
  final bool puedeSeleccionarse;
}

class ValidadorAnclas {
  ValidadorAnclas(this.tablero);

  final Tablero tablero;

  List<int> obtenerAnclasPosibles(int dadoA, int dadoB) {
    _validarNumero(dadoA, 'dadoA');
    _validarNumero(dadoB, 'dadoB');

    final valoresPresentes = tablero.valoresColocados;
    return {dadoA, dadoB}
        .where(valoresPresentes.contains)
        .toList(growable: false);
  }

  List<OpcionAncla> obtenerOpciones(int dadoA, int dadoB) {
    _validarNumero(dadoA, 'dadoA');
    _validarNumero(dadoB, 'dadoB');

    final anclasPresentes = tablero.valoresColocados;
    final opciones = <OpcionAncla>[
      OpcionAncla(
        ancla: dadoA,
        numeroAColocar: dadoB,
        puedeSeleccionarse: anclasPresentes.contains(dadoA),
      ),
    ];

    if (dadoA != dadoB) {
      opciones.add(
        OpcionAncla(
          ancla: dadoB,
          numeroAColocar: dadoA,
          puedeSeleccionarse: anclasPresentes.contains(dadoB),
        ),
      );
    }

    return opciones;
  }

  List<Coordenada> buscarDestinosValidos({
    required int numeroAncla,
    required int numeroDelOtroDado,
  }) {
    _validarNumero(numeroAncla, 'numeroAncla');
    _validarNumero(numeroDelOtroDado, 'numeroDelOtroDado');

    final anclas = tablero.celdas
        .where((celda) => celda.valor == numeroAncla)
        .toList(growable: false);
    if (anclas.isEmpty) return const [];

    final destinos = <(int, int)>{};
    for (final ancla in anclas) {
      for (final (deltaFila, deltaColumna) in _direccionesOrtogonales) {
        final filaDestino = ancla.fila + deltaFila;
        final columnaDestino = ancla.columna + deltaColumna;

        if (!_dentroDelTablero(filaDestino, columnaDestino)) continue;

        final destino = tablero.obtenerCelda(filaDestino, columnaDestino);
        if (destino.valor != null ||
            !_cumpleReglaDeZona(
              filaDestino,
              columnaDestino,
              numeroDelOtroDado,
            )) {
          continue;
        }

        destinos.add((filaDestino, columnaDestino));
      }
    }

    final coordenadasOrdenadas = destinos.toList()
      ..sort((a, b) {
        final porFila = a.$1.compareTo(b.$1);
        return porFila != 0 ? porFila : a.$2.compareTo(b.$2);
      });
    return coordenadasOrdenadas
        .map((coordenada) => tablero.obtenerCelda(coordenada.$1, coordenada.$2))
        .toList(growable: false);
  }

  bool hayMovimientosPosibles(int dadoA, int dadoB) =>
      obtenerOpciones(dadoA, dadoB).any(
        (opcion) =>
            opcion.puedeSeleccionarse &&
            buscarDestinosValidos(
              numeroAncla: opcion.ancla,
              numeroDelOtroDado: opcion.numeroAColocar,
            ).isNotEmpty,
      );

  bool _cumpleReglaDeZona(int fila, int columna, int numero) =>
      tablero.zonaEn(fila, columna)?.validarNuevoMovimiento(numero) ?? false;

  bool _dentroDelTablero(int fila, int columna) =>
      fila >= 0 &&
      fila < Tablero.cantidadFilas &&
      columna >= 0 &&
      columna < Tablero.cantidadColumnas;

  void _validarNumero(int numero, String nombreParametro) {
    if (numero < 1 || numero > 6) {
      throw ArgumentError.value(
        numero,
        nombreParametro,
        'Debe estar entre 1 y 6.',
      );
    }
  }

  static const List<(int, int)> _direccionesOrtogonales = [
    (-1, 0),
    (0, 1),
    (1, 0),
    (0, -1),
  ];
}
