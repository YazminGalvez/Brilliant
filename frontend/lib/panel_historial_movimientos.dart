import 'package:flutter/material.dart';
import 'package:juego_brilliant/historial_movimientos.dart';

String describirMovimiento(
  RegistroMovimiento movimiento,
  String Function(int idZona) nombreDeZona,
) {
  final tirada = 'Tirada ${movimiento.numeroTirada}';
  return switch (movimiento.tipo) {
    TipoMovimiento.colocacion =>
      '$tirada: colocaste el ${movimiento.numeroColocado} '
          'en fila ${movimiento.fila! + 1}, columna ${movimiento.columna! + 1} '
          '(ancla ${movimiento.ancla})',
    TipoMovimiento.saltoTurno => '$tirada: saltaste el turno',
    TipoMovimiento.zonaCompletada =>
      '$tirada: completaste la zona '
          '${nombreDeZona(movimiento.idZona!).toLowerCase()}',
    TipoMovimiento.puntosGanados =>
      '$tirada: ganaste ${movimiento.puntos} '
          '${movimiento.puntos == 1 ? 'punto' : 'puntos'}',
  };
}

class PanelHistorialMovimientos extends StatelessWidget {
  const PanelHistorialMovimientos({
    required this.historial,
    required this.nombreDeZona,
    super.key,
  });

  final HistorialMovimientos historial;
  final String Function(int idZona) nombreDeZona;

  @override
  Widget build(BuildContext context) {
    final movimientos = historial.movimientos;

    return Card(
      key: const Key('movement-history-panel'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de movimientos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: movimientos.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no hay movimientos.',
                        key: Key('movement-history-empty'),
                      ),
                    )
                  : ListView.builder(
                      key: const Key('movement-history-list'),
                      itemCount: movimientos.length,
                      itemBuilder: (context, index) {
                        final movimiento =
                            movimientos[movimientos.length - index - 1];
                        return ListTile(
                          key: Key(
                            'movement-history-item-${movimiento.numero}',
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            describirMovimiento(movimiento, nombreDeZona),
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
