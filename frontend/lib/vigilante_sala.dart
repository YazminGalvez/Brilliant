import 'dart:async';

import 'package:frontend/autenticacion.dart';
import 'package:frontend/partidas.dart';

class VigilanteSala {
  VigilanteSala({
    required this.partidas,
    required this.codigo,
    required this.alCambiar,
    required this.alCerrar,
    this.alResponder,
    this.alFallar,
    this.intervalo = const Duration(seconds: 2),
    SalaPartida? salaInicial,
  }) : _ultimaSala = salaInicial;

  final ServicioPartidas partidas;
  final String codigo;
  final void Function(SalaPartida sala) alCambiar;
  final void Function() alCerrar;
  final void Function()? alResponder;
  final void Function(Object error)? alFallar;
  final Duration intervalo;

  Timer? _temporizador;
  bool _consultando = false;
  SalaPartida? _ultimaSala;

  bool get activo => _temporizador != null;

  SalaPartida? get ultimaSala => _ultimaSala;

  void iniciar() {
    _temporizador ??= Timer.periodic(intervalo, (_) => _consultar());
  }

  void detener() {
    _temporizador?.cancel();
    _temporizador = null;
  }

  Future<void> _consultar() async {
    if (_consultando) return;

    _consultando = true;
    try {
      final sala = await partidas.consultar(codigo);
      if (!activo) return;
      if (sala != _ultimaSala) {
        _ultimaSala = sala;
        alCambiar(sala);
      }
      if (activo) alResponder?.call();
    } on ErrorAutenticacion catch (error) {
      if (!activo) return;
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        detener();
        alCerrar();
      } else {
        alFallar?.call(error);
      }
    } on Object catch (error) {
      if (activo) alFallar?.call(error);
    } finally {
      _consultando = false;
    }
  }
}
