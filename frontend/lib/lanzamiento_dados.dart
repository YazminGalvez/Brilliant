import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/dados.dart';
import 'package:juego_brilliant/validador_anclas.dart';

class LanzamientoDados extends StatefulWidget {
  const LanzamientoDados({
    this.opciones = const [],
    this.puedeLanzar = true,
    this.opcionSeleccionada,
    this.onAnclaSeleccionada,
    this.onTirada,
    this.puedeSaltarTurno = false,
    this.onSaltarTurno,
    this.random,
    super.key,
  });

  final List<OpcionAncla> opciones;
  final bool puedeLanzar;
  final OpcionAncla? opcionSeleccionada;
  final ValueChanged<OpcionAncla?>? onAnclaSeleccionada;
  final ValueChanged<List<int>>? onTirada;
  final bool puedeSaltarTurno;
  final VoidCallback? onSaltarTurno;
  final Random? random;

  @override
  State<LanzamientoDados> createState() => _LanzamientoDadosState();
}

class _LanzamientoDadosState extends State<LanzamientoDados>
    with SingleTickerProviderStateMixin {
  static const _duracionAnimacion = Duration(milliseconds: 900);

  late final Dados _dados = Dados(cantidad: 2, random: widget.random);
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: _duracionAnimacion,
  );
  late final Animation<double> _rotacion = Tween<double>(
    begin: 0,
    end: pi * 4,
  ).animate(CurvedAnimation(parent: _controlador, curve: Curves.easeOutCubic));
  late final Animation<double> _escala = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0.75,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.12,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 55,
    ),
  ]).animate(_controlador);

  List<int?> _resultados = [null, null];

  @override
  void initState() {
    super.initState();
    _controlador.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {});
      }
    });
  }

  void _lanzarDados() {
    if (_controlador.isAnimating || !widget.puedeLanzar) return;

    final resultados = _dados.lanzar();
    widget.onTirada?.call(resultados);
    widget.onAnclaSeleccionada?.call(null);
    setState(() {
      _resultados = resultados;
    });
    _controlador.forward(from: 0);
  }

  void _seleccionarOpcion(OpcionAncla opcion) {
    if (!opcion.puedeSeleccionarse) return;
    widget.onAnclaSeleccionada?.call(opcion);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthPanelDados = constraints.maxWidth < 330
            ? constraints.maxWidth
            : 330.0;
        final widthPanelAnclas = constraints.maxWidth < 460
            ? constraints.maxWidth
            : 220.0;
        final mostrarSaltarTurno =
            widget.puedeSaltarTurno && !_controlador.isAnimating;
        final contenidoDados = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _resultados.length; index++) ...[
                  if (index > 0) const SizedBox(width: 24),
                  AnimatedBuilder(
                    animation: _controlador,
                    child: _CaraDado(valor: _resultados[index] ?? 1),
                    builder: (context, child) => Transform.rotate(
                      angle: _rotacion.value * (index.isEven ? 1 : -1),
                      child: Transform.scale(
                        scale: _escala.value,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _resultados.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Semantics(
                    label:
                        'Dado ${index + 1}: ${_resultados[index] ?? "sin lanzar"}',
                    child: ExcludeSemantics(
                      child: Text(
                        'Dado ${index + 1}: ${_resultados[index] ?? "—"}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('roll-dice-button'),
                  onPressed:
                      _controlador.isAnimating || !widget.puedeLanzar
                      ? null
                      : _lanzarDados,
                  icon: const Icon(Icons.casino),
                  label: const Text('Lanzar dados'),
                ),
                if (mostrarSaltarTurno)
                  OutlinedButton(
                    key: const Key('skip-turn-button'),
                    onPressed: widget.onSaltarTurno,
                    child: const Text('Saltar turno'),
                  ),
              ],
            ),
            if (mostrarSaltarTurno) ...[
              const SizedBox(height: 8),
              Text(
                'No hay movimientos posibles con esta tirada. '
                'Salta el turno para volver a lanzar.',
                key: const Key('no-moves-message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );

        final opciones = widget.opciones;
        final panelAnclas = opciones.isEmpty
            ? const SizedBox.shrink()
            : _PanelOpcionesAncla(
                opciones: opciones,
                seleccionada: widget.opcionSeleccionada,
                onSeleccionar: _seleccionarOpcion,
              );

        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(width: widthPanelDados, child: contenidoDados),
            if (opciones.isNotEmpty)
              SizedBox(width: widthPanelAnclas, child: panelAnclas),
          ],
        );
      },
    );
  }
}

class _PanelOpcionesAncla extends StatelessWidget {
  const _PanelOpcionesAncla({
    required this.opciones,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final List<OpcionAncla> opciones;
  final OpcionAncla? seleccionada;
  final ValueChanged<OpcionAncla> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('anchor-options-panel'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seleccionada == null &&
                      opciones.every((opcion) => !opcion.puedeSeleccionarse)
                  ? 'Lanza los dados para elegir otra ancla'
                  : 'Elige un ancla',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final opcion in opciones)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: Key('anchor-option-${opcion.ancla}'),
                    onPressed: opcion.puedeSeleccionarse
                        ? () => onSeleccionar(opcion)
                        : null,
                    style: seleccionada?.ancla == opcion.ancla
                        ? OutlinedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                          )
                        : null,
                    child: Text(
                      'Ancla ${opcion.ancla} · colocar ${opcion.numeroAColocar}',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CaraDado extends StatelessWidget {
  const _CaraDado({required this.valor});

  final int valor;

  static const Map<int, Set<int>> _puntosPorCara = {
    1: {4},
    2: {0, 8},
    3: {0, 4, 8},
    4: {0, 2, 6, 8},
    5: {0, 2, 4, 6, 8},
    6: {0, 2, 3, 5, 6, 8},
  };

  @override
  Widget build(BuildContext context) {
    final puntos = _puntosPorCara[valor]!;

    return Container(
      key: Key('die-face-$valor'),
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF3D5147), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: [
          for (var index = 0; index < 9; index++)
            Center(
              child: puntos.contains(index)
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF26332D),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 12, height: 12),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
