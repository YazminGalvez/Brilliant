import 'package:flutter/foundation.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:juego_brilliant/mapas.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/vigilante_sala.dart';

Mapa? mapaDeLaSala(SalaPartida sala) {
  for (final mapa in mapasDisponibles) {
    if (mapa.numero == sala.mapa) return mapa;
  }
  return null;
}

class PartidaCompartida extends ChangeNotifier {
  PartidaCompartida({
    required this.partidas,
    required SalaPartida salaInicial,
    Duration intervalo = const Duration(seconds: 2),
  }) : _sala = salaInicial {
    _vigilante = VigilanteSala(
      partidas: partidas,
      codigo: salaInicial.codigo,
      salaInicial: salaInicial,
      intervalo: intervalo,
      alCambiar: _recibirSala,
      alCerrar: () {
        _cerrada = true;
        notifyListeners();
      },
    );
  }

  static const errorGeneral =
      'No se pudo enviar el tablero. Inténtalo de nuevo.';

  final ServicioPartidas partidas;
  late final VigilanteSala _vigilante;

  SalaPartida _sala;
  bool _cerrada = false;
  bool _enviando = false;
  ErrorAutenticacion? _error;

  SalaPartida get sala => _sala;
  bool get cerrada => _cerrada;
  bool get enviando => _enviando;
  ErrorAutenticacion? get error => _error;
  bool get activa => _vigilante.activo;

  String? get miNombre => partidas.autenticacion.sesion?.nombre;

  JugadorSala? get yo {
    for (final jugador in _sala.jugadores) {
      if (jugador.nombre == miNombre) return jugador;
    }
    return null;
  }

  bool get yaFinalice =>
      (yo?.tableroListo ?? false) || _sala.miTablero.isNotEmpty;

  List<JugadorSala> get jugadoresEnJuego => [
    for (final jugador in _sala.jugadores)
      if (!jugador.concedio) jugador,
  ];

  bool get todosTerminaron {
    final enJuego = jugadoresEnJuego;
    return enJuego.isNotEmpty &&
        enJuego.every((jugador) => jugador.tableroListo);
  }

  void iniciar() {
    if (!_cerrada) _vigilante.iniciar();
  }

  void detener() => _vigilante.detener();

  Future<bool> enviarTablero(List<int> numeros) async {
    if (_enviando || _cerrada) return false;

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      final sala = await partidas.enviarTablero(_sala.codigo, numeros);
      _enviando = false;
      _sala = sala;
      notifyListeners();
      return true;
    } on ErrorAutenticacion catch (error) {
      _enviando = false;
      _error = error;
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        _cerrada = true;
        _vigilante.detener();
      }
      notifyListeners();
      return false;
    } catch (_) {
      _enviando = false;
      _error = const ErrorAutenticacion(errorGeneral);
      notifyListeners();
      return false;
    }
  }

  void _recibirSala(SalaPartida sala) {
    _sala = sala;
    notifyListeners();
  }

  @override
  void dispose() {
    _vigilante.detener();
    super.dispose();
  }
}
