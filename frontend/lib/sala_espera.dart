import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/main.dart';
import 'package:frontend/partida_compartida.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/vigilante_sala.dart';

class SalaEsperaPage extends StatefulWidget {
  const SalaEsperaPage({
    required this.partidas,
    required this.salaInicial,
    this.intervalo = const Duration(seconds: 2),
    super.key,
  });

  static const avisoSalaCerrada = 'La sala se cerró.';
  static const avisoCodigoCopiado = 'Código copiado';
  static const avisoFaltanJugadores =
      'Hacen falta al menos 2 jugadores para empezar.';
  static const errorGeneral =
      'No se pudo cambiar tu estado. Inténtalo de nuevo.';
  static const errorAlSalir =
      'No se pudo salir de la sala. Inténtalo de nuevo.';
  static const avisoCierreParaTodos = 'Si sales, la sala se cierra para todos.';

  final ServicioPartidas partidas;
  final SalaPartida salaInicial;
  final Duration intervalo;

  @override
  State<SalaEsperaPage> createState() => _SalaEsperaPageState();
}

class _SalaEsperaPageState extends State<SalaEsperaPage> {
  late SalaPartida _sala = widget.salaInicial;
  late final VigilanteSala _vigilante;
  bool _cerrada = false;
  bool _salio = false;
  bool _enviandoListo = false;
  bool _saliendo = false;
  String? _error;

  String? get _miNombre => widget.partidas.autenticacion.sesion?.nombre;

  JugadorSala? get _yo {
    for (final jugador in _sala.jugadores) {
      if (jugador.nombre == _miNombre) return jugador;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _vigilante = VigilanteSala(
      partidas: widget.partidas,
      codigo: widget.salaInicial.codigo,
      salaInicial: widget.salaInicial,
      intervalo: widget.intervalo,
      alCambiar: _recibirSala,
      alCerrar: () {
        if (mounted) setState(() => _cerrada = true);
      },
    );
    if (widget.salaInicial.comenzada) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _irAPartida());
    } else {
      _vigilante.iniciar();
    }
  }

  @override
  void dispose() {
    _vigilante.detener();
    super.dispose();
  }

  void _recibirSala(SalaPartida sala) {
    if (!mounted || _salio) return;
    setState(() => _sala = sala);
    if (sala.comenzada) _irAPartida();
  }

  void _irAPartida() {
    if (!mounted || _salio) return;
    _salio = true;
    _vigilante.detener();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TableroPage(
          compartida: PartidaCompartida(
            partidas: widget.partidas,
            salaInicial: _sala,
            intervalo: widget.intervalo,
          ),
        ),
      ),
    );
  }

  Future<void> _cambiarListo() async {
    if (_enviandoListo) return;

    final listo = !(_yo?.listo ?? false);
    setState(() {
      _enviandoListo = true;
      _error = null;
    });

    try {
      final sala = await widget.partidas.marcarListo(
        _sala.codigo,
        listo: listo,
      );
      if (!mounted) return;
      setState(() => _enviandoListo = false);
      _recibirSala(sala);
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      final proveedor = ProveedorAutenticacion.buscar(context);
      if (error.codigoServidor == 'NO_AUTORIZADO' && proveedor != null) {
        proveedor.volverAlInicio(Navigator.of(context), aviso: error.mensaje);
        return;
      }
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        _vigilante.detener();
        setState(() {
          _enviandoListo = false;
          _cerrada = true;
        });
        return;
      }
      _mostrarFallo(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarFallo(SalaEsperaPage.errorGeneral);
    }
  }

  void _mostrarFallo(String mensaje) {
    setState(() {
      _error = mensaje;
      _enviandoListo = false;
      _saliendo = false;
    });
  }

  Future<bool> _confirmarCierre() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Salir de la sala?'),
        content: const Text(SalaEsperaPage.avisoCierreParaTodos),
        actions: [
          TextButton(
            key: const Key('sala-cerrar-cancelar'),
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('sala-cerrar-confirmar'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Salir y cerrar'),
          ),
        ],
      ),
    );
    return confirmado ?? false;
  }

  Future<void> _salir() async {
    if (_saliendo || _salio) return;
    if (_sala.anfitrion == _miNombre && !await _confirmarCierre()) return;
    if (!mounted || _saliendo || _salio) return;

    _vigilante.detener();
    setState(() {
      _saliendo = true;
      _error = null;
    });

    try {
      await widget.partidas.salir(_sala.codigo);
      _cerrarPantalla();
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      final proveedor = ProveedorAutenticacion.buscar(context);
      if (error.codigoServidor == 'NO_AUTORIZADO' && proveedor != null) {
        proveedor.volverAlInicio(Navigator.of(context), aviso: error.mensaje);
        return;
      }
      if (error.codigoServidor == 'PARTIDA_NO_ENCONTRADA') {
        _cerrarPantalla();
        return;
      }
      _seguirEnLaSala(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _seguirEnLaSala(SalaEsperaPage.errorAlSalir);
    }
  }

  void _cerrarPantalla() {
    if (!mounted) return;
    _salio = true;
    Navigator.of(context).pop();
  }

  void _seguirEnLaSala(String mensaje) {
    _mostrarFallo(mensaje);
    _vigilante.iniciar();
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: _sala.codigo));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(SalaEsperaPage.avisoCodigoCopiado)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _cerrada || _salio,
      onPopInvokedWithResult: (seCerro, _) {
        if (!seCerro) _salir();
      },
      child: _cerrada ? _salaCerrada(context) : _salaAbierta(context),
    );
  }

  Widget _salaAbierta(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final sala = _sala;
    final yoListo = _yo?.listo ?? false;
    final error = _error;

    return PantallaClara(
      titulo: 'Sala de espera',
      children: [
        Text(
          'Comparte este código',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: colores.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SelectableText(
          sala.codigo,
          key: const Key('sala-codigo'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            key: const Key('sala-copiar'),
            onPressed: _copiarCodigo,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar código'),
          ),
        ),
        const SizedBox(height: 24),
        _Dato(
          icono: Icons.map_outlined,
          texto: 'Mapa ${sala.mapa}',
          clave: const Key('sala-mapa'),
        ),
        _Dato(
          icono: Icons.star_outline,
          texto: 'Anfitrión: ${sala.anfitrion}',
          clave: const Key('sala-anfitrion'),
        ),
        _Dato(
          icono: Icons.group_outlined,
          texto: '${sala.jugadores.length} de ${sala.capacidad} jugadores',
          clave: const Key('sala-ocupacion'),
        ),
        const SizedBox(height: 16),
        Text('Jugadores', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final jugador in sala.jugadores)
          _FilaJugador(
            jugador: jugador,
            esAnfitrion: jugador.nombre == sala.anfitrion,
            esYo: jugador.nombre == _miNombre,
          ),
        if (sala.jugadores.length < 2) ...[
          const SizedBox(height: 8),
          Text(
            SalaEsperaPage.avisoFaltanJugadores,
            key: const Key('sala-faltan-jugadores'),
            style: TextStyle(color: colores.onSurfaceVariant),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          SelectableText(
            error,
            key: const Key('sala-error'),
            style: TextStyle(color: colores.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('sala-listo'),
          onPressed: _enviandoListo || _saliendo ? null : _cambiarListo,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _enviandoListo
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(yoListo ? 'Ya no estoy listo' : 'Estoy listo'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('sala-salir'),
          onPressed: _saliendo ? null : _salir,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: colores.error,
          ),
          icon: _saliendo
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: const Text('Salir de la sala'),
        ),
      ],
    );
  }

  Widget _salaCerrada(BuildContext context) {
    return PantallaClara(
      titulo: 'Sala de espera',
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.meeting_room_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        const Text(
          SalaEsperaPage.avisoSalaCerrada,
          key: Key('sala-cerrada'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('sala-volver'),
          onPressed: () => Navigator.of(context).maybePop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}

class _FilaJugador extends StatelessWidget {
  const _FilaJugador({
    required this.jugador,
    required this.esAnfitrion,
    required this.esYo,
  });

  final JugadorSala jugador;
  final bool esAnfitrion;
  final bool esYo;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final (estado, color, icono) = switch (jugador) {
      JugadorSala(conectado: false) => (
        'Sin conexión',
        colores.outline,
        Icons.wifi_off,
      ),
      JugadorSala(listo: true) => (
        'Listo',
        const Color(0xFF15803D),
        Icons.check_circle_outline,
      ),
      _ => ('Esperando', colores.onSurfaceVariant, Icons.hourglass_empty),
    };

    return ListTile(
      key: Key('sala-jugador-${jugador.nombre}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icono, color: color),
      title: Text(esYo ? '${jugador.nombre} (tú)' : jugador.nombre),
      subtitle: esAnfitrion ? const Text('Anfitrión') : null,
      trailing: Text(
        estado,
        key: Key('sala-estado-${jugador.nombre}'),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto, required this.clave});

  final IconData icono;
  final String texto;
  final Key clave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icono, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, key: clave)),
        ],
      ),
    );
  }
}
