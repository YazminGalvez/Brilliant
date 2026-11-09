import 'dart:async';

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

class AvisoTurno {
  const AvisoTurno({
    required this.ronda,
    required this.tableroLleno,
    required this.zona,
  });

  final int ronda;
  final bool tableroLleno;
  final int? zona;
}

class PartidaCompartida extends ChangeNotifier {
  PartidaCompartida({
    required this.partidas,
    required SalaPartida salaInicial,
    Duration intervalo = const Duration(seconds: 2),
    this.esperaReintento = const Duration(seconds: 2),
  }) : _sala = salaInicial {
    _vigilante = VigilanteSala(
      partidas: partidas,
      codigo: salaInicial.codigo,
      salaInicial: salaInicial,
      intervalo: intervalo,
      alCambiar: _recibirSala,
      alCerrar: () {
        _cerrada = true;
        detener();
        notifyListeners();
      },
    );
  }

  static const errorGeneral =
      'No se pudo enviar el tablero. Inténtalo de nuevo.';

  final ServicioPartidas partidas;
  final Duration esperaReintento;
  late final VigilanteSala _vigilante;

  SalaPartida _sala;
  bool _cerrada = false;
  bool _enviando = false;
  ErrorAutenticacion? _error;

  int _rondaAvisada = 0;
  AvisoTurno? _avisoPendiente;
  bool _avisando = false;
  bool _miTableroLleno = false;
  Timer? _reintento;
  ErrorAutenticacion? _errorTurno;

  SalaPartida get sala => _sala;
  bool get cerrada => _cerrada;
  bool get enviando => _enviando;
  ErrorAutenticacion? get error => _error;
  bool get activa => _vigilante.activo;
  AvisoTurno? get avisoPendiente => _avisoPendiente;
  ErrorAutenticacion? get errorTurno => _errorTurno;

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

  List<int>? get resultado =>
      _sala.ronda > 0 && _sala.dados.length == 2 ? _sala.dados : null;

  bool get puedoJugarRonda {
    final jugador = yo;
    final ronda = _sala.ronda;
    return !_cerrada &&
        _sala.comenzada &&
        !_sala.terminada &&
        resultado != null &&
        jugador != null &&
        !jugador.concedio &&
        !jugador.jugoRonda &&
        !_miTableroLleno &&
        _rondaAvisada < ronda &&
        _avisoPendiente?.ronda != ronda;
  }

  bool get esperandoALosDemas =>
      !_cerrada &&
      _sala.comenzada &&
      !_sala.terminada &&
      _sala.ronda > 0 &&
      !puedoJugarRonda;

  void iniciar() {
    if (!_cerrada) _vigilante.iniciar();
  }

  void detener() {
    _vigilante.detener();
    _reintento?.cancel();
    _reintento = null;
  }

  Future<bool> enviarTablero(List<int> numeros) async {
    if (_enviando || _cerrada) return false;

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      final sala = await partidas.enviarTablero(_sala.codigo, numeros);
      _enviando = false;
      _recibirSala(sala);
      return true;
    } on ErrorAutenticacion catch (error) {
      _enviando = false;
      _error = error;
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        _cerrada = true;
        detener();
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

  void terminarTurno({required bool tableroLleno, int? zona}) {
    if (!puedoJugarRonda) return;

    _avisoPendiente = AvisoTurno(
      ronda: _sala.ronda,
      tableroLleno: tableroLleno,
      zona: zona,
    );
    _miTableroLleno = _miTableroLleno || tableroLleno;
    notifyListeners();
    _enviarAviso();
  }

  Future<void> _enviarAviso() async {
    final aviso = _avisoPendiente;
    if (aviso == null || _avisando || _cerrada) return;

    _avisando = true;
    _reintento?.cancel();
    _reintento = null;
    try {
      final sala = await partidas.terminarTurno(
        _sala.codigo,
        aviso.ronda,
        tableroLleno: aviso.tableroLleno,
        zona: aviso.zona,
      );
      _avisando = false;
      if (identical(_avisoPendiente, aviso)) _confirmarAviso();
      _recibirSala(sala);
    } on ErrorAutenticacion catch (error) {
      _avisando = false;
      _errorTurno = error;
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        _cerrada = true;
        detener();
      } else if (_convieneReintentar(error)) {
        _programarReintento();
      }
      notifyListeners();
    } catch (_) {
      _avisando = false;
      _programarReintento();
    }
  }

  static bool _convieneReintentar(ErrorAutenticacion error) {
    final estado = error.codigo;
    return estado == null || estado == 429 || estado >= 500;
  }

  void _programarReintento() {
    if (_cerrada || _avisoPendiente == null) return;
    _reintento?.cancel();
    _reintento = Timer(esperaReintento, _enviarAviso);
  }

  void _confirmarAviso() {
    final aviso = _avisoPendiente;
    if (aviso == null) return;
    if (aviso.ronda > _rondaAvisada) _rondaAvisada = aviso.ronda;
    _avisoPendiente = null;
    _errorTurno = null;
    _reintento?.cancel();
    _reintento = null;
  }

  void _recibirSala(SalaPartida sala) {
    _sala = sala;
    final aviso = _avisoPendiente;
    if (aviso != null &&
        (sala.terminada ||
            sala.ronda > aviso.ronda ||
            (sala.ronda == aviso.ronda && (yo?.jugoRonda ?? false)))) {
      _confirmarAviso();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    detener();
    super.dispose();
  }
}
