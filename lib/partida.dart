import 'historial_lanzamientos.dart';
import 'historial_movimientos.dart';
import 'mapa.dart';
import 'tablero.dart';
import 'validador_anclas.dart';
import 'zona.dart';

enum EstadoPartida { preparando, jugando, terminada }

class Partida {
  Partida({required this.mapa, this.permitirRelanzar = true})
    : _tablero = mapa.crearTablero();

  final Mapa mapa;
  final bool permitirRelanzar;
  final HistorialLanzamientos historialLanzamientos = HistorialLanzamientos();
  final HistorialMovimientos historialMovimientos = HistorialMovimientos();

  Tablero _tablero;
  EstadoPartida _estado = EstadoPartida.preparando;
  TiradaDados? _tiradaActual;

  Tablero get tablero => _tablero;
  EstadoPartida get estado => _estado;
  TiradaDados? get tiradaActual => _tiradaActual;

  bool get terminada => _estado == EstadoPartida.terminada;

  List<int?> get valoresIniciales => _tablero.valoresIniciales;
  bool get inicializado => _tablero.inicializado;
  bool get puedeIniciar => _estado == EstadoPartida.preparando && inicializado;

  int get puntuacionTotal => _tablero.puntuacionTotal;
  int get puntuacionMaxima => _tablero.puntuacionMaxima;
  Map<int, int> get puntuacionPorZona => _tablero.puntuacionPorZona;

  void colocarValorInicial(int fila, int columna, int? valor) {
    _exigirEstado(EstadoPartida.preparando);
    if (!_tablero.celdasIniciales.contains((fila + 1, columna + 1))) {
      throw ArgumentError(
        'La celda ($fila, $columna) no es una celda inicial del mapa.',
      );
    }
    if (valor != null && (valor < 1 || valor > 6)) {
      throw ArgumentError.value(valor, 'valor', 'Debe estar entre 1 y 6.');
    }
    _tablero.colocarDato(fila, columna, valor);
  }

  void iniciar() {
    if (!puedeIniciar) {
      throw StateError(
        'La partida no puede iniciar hasta que las celdas iniciales '
        'contengan los números del 1 al 6 sin repetir.',
      );
    }
    _estado = EstadoPartida.jugando;
  }

  bool get puedeLanzar {
    if (_estado != EstadoPartida.jugando) return false;
    if (_tiradaActual == null) return true;
    return permitirRelanzar && hayMovimientosPosibles;
  }

  TiradaDados registrarTirada(List<int> valores) {
    _exigirEstado(EstadoPartida.jugando);
    if (!puedeLanzar) {
      throw StateError('Hay que resolver la tirada actual antes de lanzar.');
    }
    return _tiradaActual = historialLanzamientos.registrar(valores);
  }

  List<OpcionAncla> get opcionesAncla {
    final tirada = _tiradaActual;
    if (tirada == null) return const [];
    return ValidadorAnclas(
      _tablero,
    ).obtenerOpciones(tirada.primerDado, tirada.segundoDado);
  }

  List<Coordenada> destinosValidos(OpcionAncla opcion) {
    if (!opcion.puedeSeleccionarse) return const [];
    return ValidadorAnclas(_tablero).buscarDestinosValidos(
      numeroAncla: opcion.ancla,
      numeroDelOtroDado: opcion.numeroAColocar,
    );
  }

  bool get hayMovimientosPosibles {
    final tirada = _tiradaActual;
    if (tirada == null) return false;
    return ValidadorAnclas(
      _tablero,
    ).hayMovimientosPosibles(tirada.primerDado, tirada.segundoDado);
  }

  bool get puedeSaltarTurno =>
      _estado == EstadoPartida.jugando &&
      _tiradaActual != null &&
      !hayMovimientosPosibles;

  void saltarTurno() {
    _exigirEstado(EstadoPartida.jugando);
    if (!puedeSaltarTurno) {
      throw StateError('Solo se puede saltar el turno si no hay movimientos.');
    }
    historialMovimientos.registrarSaltoTurno(
      numeroTirada: _tiradaActual!.numeroTirada,
    );
    _tiradaActual = null;
  }

  void colocar(OpcionAncla opcion, int fila, int columna) {
    _exigirEstado(EstadoPartida.jugando);
    final tirada = _tiradaActual;
    if (tirada == null) {
      throw StateError('No hay una tirada pendiente para colocar.');
    }

    final opcionDeTirada = opcionesAncla
        .where(
          (actual) =>
              actual.ancla == opcion.ancla &&
              actual.numeroAColocar == opcion.numeroAColocar,
        )
        .firstOrNull;
    if (opcionDeTirada == null) {
      throw ArgumentError('La opción no corresponde a la tirada actual.');
    }
    if (!opcionDeTirada.puedeSeleccionarse) {
      throw ArgumentError('El ancla ${opcion.ancla} no está en el tablero.');
    }
    final esDestinoValido = destinosValidos(
      opcionDeTirada,
    ).any((celda) => celda.fila == fila && celda.columna == columna);
    if (!esDestinoValido) {
      throw ArgumentError(
        'La celda ($fila, $columna) no es un destino válido para esta opción.',
      );
    }

    _tablero.colocarDato(fila, columna, opcionDeTirada.numeroAColocar);
    final zona = _tablero.zonaEn(fila, columna);
    final zonaCompletada = zona != null && zona.verificarCompletado()
        ? zona
        : null;
    historialMovimientos.registrarJugada(
      numeroTirada: tirada.numeroTirada,
      ancla: opcionDeTirada.ancla,
      numeroColocado: opcionDeTirada.numeroAColocar,
      fila: fila,
      columna: columna,
      zonaCompletada: zonaCompletada,
      puntosGanados: zonaCompletada?.puntosObtenidos ?? 0,
    );
    _tiradaActual = null;

    if (_tablero.estaLleno) {
      _estado = EstadoPartida.terminada;
    }
  }

  void reiniciar() {
    _tablero = mapa.crearTablero();
    historialLanzamientos.limpiar();
    historialMovimientos.limpiar();
    _tiradaActual = null;
    _estado = EstadoPartida.preparando;
  }

  void _exigirEstado(EstadoPartida esperado) {
    if (_estado != esperado) {
      throw StateError(
        'La acción requiere la partida en estado ${esperado.name}, '
        'pero está en ${_estado.name}.',
      );
    }
  }
}
