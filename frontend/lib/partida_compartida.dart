import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:juego_brilliant/mapas.dart';
import 'package:juego_brilliant/puntos_multijugador.dart';
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
  static const errorAlConceder =
      'No se pudo conceder la partida. Inténtalo de nuevo.';

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
  final Map<int, int> _misZonas = {};
  Timer? _reintento;
  ErrorAutenticacion? _errorTurno;

  bool _concedi = false;
  bool _concediendo = false;
  ErrorAutenticacion? _errorConceder;

  bool get concedi => _concedi || (yo?.concedio ?? false);
  bool get concediendo => _concediendo;
  ErrorAutenticacion? get errorConceder => _errorConceder;

  bool get puedoConceder =>
      _sala.comenzada &&
      !_sala.terminada &&
      !_cerrada &&
      !concedi &&
      !_concediendo;

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

  bool get terminada => _sala.terminada;

  bool get gane => terminada && _sala.ganadores.contains(miNombre);

  Map<String, int> get puntos {
    final puntos = {
      for (final jugador in _sala.jugadores) jugador.nombre: 0,
      ..._sala.puntos,
    };
    final nombre = miNombre;
    final mapa = mapaDeLaSala(_sala);
    if (nombre == null || mapa == null || terminada) return puntos;

    final pendientes = {
      for (final MapEntry(key: zona, value: ronda) in _misZonas.entries)
        if (!(_sala.zonas[zona]?.containsKey(nombre) ?? false)) zona: ronda,
    };
    if (pendientes.isEmpty) return puntos;

    final zonas = {
      for (final MapEntry(:key, :value) in _sala.zonas.entries) key: {...value},
    };
    pendientes.forEach((zona, ronda) {
      (zonas[zona] ??= {})[nombre] = ronda;
    });
    try {
      puntos[nombre] =
          PuntosMultijugador.puntosTotales(mapa, zonas)[nombre] ?? 0;
    } on ArgumentError {
      return puntos;
    }
    return puntos;
  }

  List<MapEntry<String, int>> get clasificacion {
    final puntos = this.puntos;
    final orden = [
      for (final jugador in _sala.jugadores)
        MapEntry(jugador.nombre, puntos[jugador.nombre] ?? 0),
    ];
    for (final MapEntry(:key, :value) in puntos.entries) {
      if (!orden.any((entrada) => entrada.key == key)) {
        orden.add(MapEntry(key, value));
      }
    }
    return orden..sort((a, b) => b.value.compareTo(a.value));
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
        !_concedi &&
        !jugador.jugoRonda &&
        !_miTableroLleno &&
        _rondaAvisada < ronda &&
        _avisoPendiente?.ronda != ronda;
  }

  bool get esperandoALosDemas =>
      !_cerrada &&
      !concedi &&
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

  Future<bool> conceder() async {
    if (!puedoConceder) return false;

    _concediendo = true;
    _errorConceder = null;
    notifyListeners();

    try {
      final sala = await partidas.conceder(_sala.codigo);
      _concediendo = false;
      _concedi = true;
      _avisoPendiente = null;
      detener();
      _sala = sala;
      notifyListeners();
      return true;
    } on ErrorAutenticacion catch (error) {
      _concediendo = false;
      _errorConceder = error;
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        _cerrada = true;
        detener();
      }
      notifyListeners();
      return false;
    } catch (_) {
      _concediendo = false;
      _errorConceder = const ErrorAutenticacion(errorAlConceder);
      notifyListeners();
      return false;
    }
  }

  Future<void> salir() async {
    detener();
    if (_cerrada) return;
    try {
      await partidas.salir(_sala.codigo);
    } on Object {
      return;
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
    if (zona != null) _misZonas.putIfAbsent(zona, () => _sala.ronda);
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
    if (sala.terminada) detener();
    notifyListeners();
  }

  @override
  void dispose() {
    detener();
    super.dispose();
  }
}
