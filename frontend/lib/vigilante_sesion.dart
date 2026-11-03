import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:frontend/autenticacion.dart';

class VigilanteSesion extends StatefulWidget {
  const VigilanteSesion({
    required this.servicio,
    required this.alPerderSesion,
    required this.child,
    this.intervalo = const Duration(seconds: 30),
    super.key,
  });

  static const avisoSesionPerdida =
      'Tu sesión ya no está activa, inicia sesión de nuevo.';

  final ServicioAutenticacion servicio;
  final void Function(BuildContext context) alPerderSesion;
  final Widget child;
  final Duration intervalo;

  @override
  State<VigilanteSesion> createState() => _VigilanteSesionState();
}

class _VigilanteSesionState extends State<VigilanteSesion> {
  Timer? _temporizador;
  bool _revisando = false;
  bool _sesionPerdida = false;

  @override
  void initState() {
    super.initState();
    _programarRevisiones();
  }

  @override
  void didUpdateWidget(VigilanteSesion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intervalo != widget.intervalo) _programarRevisiones();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _programarRevisiones() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(widget.intervalo, (_) => _revisar());
  }

  Future<void> _revisar() async {
    if (_revisando || _sesionPerdida) return;

    _revisando = true;
    bool activa;
    try {
      activa = await widget.servicio.sesionActiva();
    } catch (_) {
      return;
    } finally {
      _revisando = false;
    }

    if (!mounted || activa || _sesionPerdida) return;
    _sesionPerdida = true;
    _temporizador?.cancel();
    widget.alPerderSesion(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
