import 'package:flutter/material.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/partidas.dart';

class PartidaComenzadaPage extends StatelessWidget {
  const PartidaComenzadaPage({required this.sala, super.key});

  final SalaPartida sala;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return PantallaClara(
      titulo: 'Partida ${sala.codigo}',
      children: [
        const SizedBox(height: 24),
        Icon(Icons.casino_outlined, size: 48, color: colores.primary),
        const SizedBox(height: 16),
        const Text(
          'La partida comenzó',
          key: Key('partida-comenzada'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Mapa ${sala.mapa} · ${sala.jugadores.length} jugadores',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: colores.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('partida-comenzada-volver'),
          onPressed: () => Navigator.of(context).maybePop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}
