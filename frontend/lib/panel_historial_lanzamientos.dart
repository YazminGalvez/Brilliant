import 'package:flutter/material.dart';
import 'package:juego_brilliant/historial_lanzamientos.dart';

class PanelHistorialLanzamientos extends StatelessWidget {
  const PanelHistorialLanzamientos({required this.historial, super.key});

  final HistorialLanzamientos historial;

  @override
  Widget build(BuildContext context) {
    final tiradas = historial.tiradas;

    return Card(
      key: const Key('dice-roll-history-panel'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de lanzamientos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: tiradas.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no hay lanzamientos.',
                        key: Key('dice-roll-history-empty'),
                      ),
                    )
                  : ListView.builder(
                      key: const Key('dice-roll-history-list'),
                      itemCount: tiradas.length,
                      itemBuilder: (context, index) {
                        final tirada = tiradas[tiradas.length - index - 1];
                        return ListTile(
                          key: Key(
                            'dice-roll-history-item-${tirada.numeroTirada}',
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Tirada ${tirada.numeroTirada}: '
                            '${tirada.primerDado} y ${tirada.segundoDado}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
