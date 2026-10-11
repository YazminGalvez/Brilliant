import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/dados.dart';

class LanzamientoDados extends StatefulWidget {
  const LanzamientoDados({super.key});

  @override
  State<LanzamientoDados> createState() => _LanzamientoDadosState();
}

class _LanzamientoDadosState extends State<LanzamientoDados>
    with SingleTickerProviderStateMixin {
  static const _duracionAnimacion = Duration(milliseconds: 900);

  final Dados _dados = Dados(cantidad: 2);
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

  void _lanzarDados() {
    if (_controlador.isAnimating) return;

    setState(() {
      _resultados = _dados.lanzar();
    });
    _controlador.forward(from: 0);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  child: Transform.scale(scale: _escala.value, child: child),
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
              if (index > 0) const SizedBox(width: 24),
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
        FilledButton.icon(
          key: const Key('roll-dice-button'),
          onPressed: _controlador.isAnimating ? null : _lanzarDados,
          icon: const Icon(Icons.casino),
          label: const Text('Lanzar dados'),
        ),
      ],
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
