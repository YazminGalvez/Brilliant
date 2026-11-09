import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/crear_partida.dart';
import 'package:frontend/inicio_sesion.dart';
import 'package:frontend/main.dart';
import 'package:frontend/partida_compartida.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/sala_espera.dart';
import 'package:frontend/unirse_partida.dart';

class PantallaClara extends StatelessWidget {
  const PantallaClara({
    required this.titulo,
    required this.children,
    super.key,
  });

  final String titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final margen = max(24.0, (restricciones.maxWidth - 420) / 2);
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: margen, vertical: 24),
              children: children,
            );
          },
        ),
      ),
    );
  }
}

class MultijugadorPage extends StatefulWidget {
  const MultijugadorPage({
    required this.partidas,
    this.intervalo = const Duration(seconds: 2),
    super.key,
  });

  final ServicioPartidas partidas;
  final Duration intervalo;

  @override
  State<MultijugadorPage> createState() => _MultijugadorPageState();
}

class _MultijugadorPageState extends State<MultijugadorPage> {
  SalaPartida? _salaActual;

  ServicioPartidas get partidas => widget.partidas;

  @override
  void initState() {
    super.initState();
    _buscarPartidaActual();
  }

  Future<void> _buscarPartidaActual() async {
    SalaPartida? sala;
    try {
      sala = await partidas.actual();
    } on Object {
      sala = null;
    }
    if (!mounted) return;
    setState(
      () => _salaActual = sala != null && _sePuedeVolver(sala) ? sala : null,
    );
  }

  bool _sePuedeVolver(SalaPartida sala) {
    if (!sala.comenzada) return true;
    if (sala.terminada) return false;
    final nombre = partidas.autenticacion.sesion?.nombre;
    return sala.jugadores.any(
      (jugador) => jugador.nombre == nombre && !jugador.concedio,
    );
  }

  Future<void> _abrir(WidgetBuilder pagina) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: pagina));
    if (mounted) await _buscarPartidaActual();
  }

  void _volverAPartida(SalaPartida sala) {
    _abrir(
      (_) => sala.comenzada
          ? TableroPage(
              compartida: PartidaCompartida(
                partidas: partidas,
                salaInicial: sala,
                intervalo: widget.intervalo,
              ),
            )
          : SalaEsperaPage(
              partidas: partidas,
              salaInicial: sala,
              intervalo: widget.intervalo,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final salaActual = _salaActual;

    return PantallaClara(
      titulo: 'Jugar con amigos',
      children: [
        if (salaActual != null) ...[
          FilledButton.tonalIcon(
            key: const Key('multi-volver'),
            onPressed: () => _volverAPartida(salaActual),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Volver a tu partida'),
          ),
          const SizedBox(height: 24),
        ],
        const MarcaDelJuego(),
        const SizedBox(height: 24),
        Text(
          'Partida con amigos',
          style: tema.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cada quien juega su propio tablero con los mismos dados. Gana '
          'quien complete primero las zonas.',
          style: TextStyle(
            fontSize: 15,
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('multi-crear'),
          onPressed: () => _abrir((_) => CrearPartidaPage(partidas: partidas)),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.add),
          label: const Text('Crear partida'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('multi-unirse'),
          onPressed: () =>
              _abrir((_) => UnirseConCodigoPage(partidas: partidas)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.login),
          label: const Text('Unirse con código'),
        ),
      ],
    );
  }
}
