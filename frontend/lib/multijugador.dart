import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/crear_partida.dart';
import 'package:frontend/inicio_sesion.dart';
import 'package:frontend/partidas.dart';
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

class MultijugadorPage extends StatelessWidget {
  const MultijugadorPage({required this.partidas, super.key});

  final ServicioPartidas partidas;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return PantallaClara(
      titulo: 'Jugar con amigos',
      children: [
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
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CrearPartidaPage(partidas: partidas),
            ),
          ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.add),
          label: const Text('Crear partida'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('multi-unirse'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => UnirseConCodigoPage(partidas: partidas),
            ),
          ),
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
