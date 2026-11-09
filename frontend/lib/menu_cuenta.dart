import 'package:flutter/material.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/vigilante_sesion.dart';

enum _AccionCuenta { cerrarSesion, borrarCuenta }

class BotonCuenta extends StatelessWidget {
  const BotonCuenta({required this.proveedor, super.key});

  static const avisoPartidaEnJuego =
      'Estás en una partida; se concederá si cierras sesión.';

  final ProveedorAutenticacion proveedor;

  Future<SalaPartida?> _partidaEnJuego() async {
    final nombre = proveedor.servicio.sesion?.nombre;
    try {
      final sala = await ServicioPartidas(proveedor.servicio).actual();
      if (sala == null || !sala.comenzada || sala.terminada) return null;
      final sigoJugando = sala.jugadores.any(
        (jugador) => jugador.nombre == nombre && !jugador.concedio,
      );
      return sigoJugando ? sala : null;
    } on Object {
      return null;
    }
  }

  Future<void> _cerrarSesion(BuildContext context, String nombre) async {
    final partida = _partidaEnJuego();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Quieres cerrar la sesión de $nombre?'),
            _AvisoPartidaEnJuego(partida: partida),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('cerrar-confirmar'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    await _concederSiHaceFalta(proveedor.servicio, partida);
    try {
      await proveedor.servicio.cerrarSesion();
    } catch (_) {}
    if (!context.mounted) return;
    proveedor.volverAlInicio(Navigator.of(context), aviso: 'Sesión cerrada.');
  }

  Future<void> _borrarCuenta(BuildContext context) async {
    final partida = _partidaEnJuego();
    final borrada = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _DialogoBorrarCuenta(servicio: proveedor.servicio, partida: partida),
    );
    if (!context.mounted) return;

    if (borrada == true) {
      proveedor.volverAlInicio(
        Navigator.of(context),
        aviso: 'Cuenta eliminada.',
      );
    } else if (proveedor.servicio.sesion == null) {
      proveedor.volverAlInicio(
        Navigator.of(context),
        aviso: VigilanteSesion.avisoSesionPerdida,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = proveedor.servicio.sesion?.nombre ?? '';

    return PopupMenuButton<_AccionCuenta>(
      key: const Key('menu-cuenta'),
      tooltip: 'Cuenta',
      icon: const Icon(Icons.person_outline),
      onSelected: (accion) => switch (accion) {
        _AccionCuenta.cerrarSesion => _cerrarSesion(context, nombre),
        _AccionCuenta.borrarCuenta => _borrarCuenta(context),
      },
      itemBuilder: (contexto) => [
        PopupMenuItem<_AccionCuenta>(
          enabled: false,
          child: Text('Sesión: $nombre'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          key: Key('cuenta-cerrar-sesion'),
          value: _AccionCuenta.cerrarSesion,
          child: Text('Cerrar sesión'),
        ),
        PopupMenuItem(
          key: const Key('cuenta-borrar'),
          value: _AccionCuenta.borrarCuenta,
          child: Text(
            'Borrar cuenta',
            style: TextStyle(color: Theme.of(contexto).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

class _DialogoBorrarCuenta extends StatefulWidget {
  const _DialogoBorrarCuenta({required this.servicio, required this.partida});

  final ServicioAutenticacion servicio;
  final Future<SalaPartida?> partida;

  @override
  State<_DialogoBorrarCuenta> createState() => _DialogoBorrarCuentaState();
}

class _DialogoBorrarCuentaState extends State<_DialogoBorrarCuenta> {
  final _contrasena = TextEditingController();

  bool _enviando = false;
  bool _concedida = false;
  String? _error;

  @override
  void dispose() {
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _borrar() async {
    if (_enviando) return;
    if (_contrasena.text.isEmpty) {
      setState(() => _error = 'Escribe tu contraseña.');
      return;
    }

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      if (!_concedida) {
        _concedida = true;
        await _concederSiHaceFalta(widget.servicio, widget.partida);
      }
      await widget.servicio.borrarCuenta(_contrasena.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      _mostrarFallo(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarFallo('No se pudo borrar la cuenta. Inténtalo de nuevo.');
    }
  }

  void _mostrarFallo(String mensaje) {
    if (widget.servicio.sesion == null) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      _error = mensaje;
      _enviando = false;
      _contrasena.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final error = _error;

    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: const Text('Borrar cuenta'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tu cuenta se eliminará de forma permanente y no se podrá '
              'recuperar. Escribe tu contraseña para confirmar.',
            ),
            _AvisoPartidaEnJuego(partida: widget.partida),
            const SizedBox(height: 16),
            TextField(
              key: const Key('borrar-contrasena'),
              controller: _contrasena,
              readOnly: _enviando,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _borrar(),
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                error,
                key: const Key('borrar-error'),
                style: TextStyle(color: colores.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _enviando
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('borrar-confirmar'),
            onPressed: _enviando ? null : _borrar,
            style: FilledButton.styleFrom(
              backgroundColor: colores.error,
              foregroundColor: colores.onError,
              disabledBackgroundColor: colores.error.withValues(alpha: 0.5),
              disabledForegroundColor: colores.onError,
            ),
            child: _enviando
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colores.onError,
                    ),
                  )
                : const Text('Borrar cuenta'),
          ),
        ],
      ),
    );
  }
}

Future<void> _concederSiHaceFalta(
  ServicioAutenticacion servicio,
  Future<SalaPartida?> partida,
) async {
  try {
    final sala = await partida;
    if (sala != null) await ServicioPartidas(servicio).conceder(sala.codigo);
  } on Object {
    return;
  }
}

class _AvisoPartidaEnJuego extends StatelessWidget {
  const _AvisoPartidaEnJuego({required this.partida});

  final Future<SalaPartida?> partida;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalaPartida?>(
      future: partida,
      builder: (context, estado) {
        if (estado.data == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            BotonCuenta.avisoPartidaEnJuego,
            key: const Key('cuenta-aviso-partida'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
