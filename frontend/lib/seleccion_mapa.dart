import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:juego_brilliant/mapas.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:frontend/main.dart';
import 'package:frontend/menu_cuenta.dart';
import 'package:frontend/proveedor_autenticacion.dart';

const List<Mapa?> mapasDelMenu = mapasDisponibles;

class SeleccionMapaPage extends StatelessWidget {
  const SeleccionMapaPage({this.random, this.mapas = mapasDelMenu, super.key});

  final Random? random;
  final List<Mapa?> mapas;

  void _abrirMapa(BuildContext context, Mapa mapa) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TableroPage(
          partida: Partida(mapa: mapa),
          random: random,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proveedor = ProveedorAutenticacion.buscar(context);

    return Scaffold(
      appBar: proveedor == null
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                BotonCuenta(proveedor: proveedor),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Brilliant',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elige tu mapa',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var index = 0; index < mapas.length; index++) ...[
                    if (index > 0) const SizedBox(height: 12),
                    _TarjetaMapa(
                      numero: index + 1,
                      mapa: mapas[index],
                      onAbrir: (mapa) => _abrirMapa(context, mapa),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const _ComoSeJuega(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaMapa extends StatelessWidget {
  const _TarjetaMapa({
    required this.numero,
    required this.mapa,
    required this.onAbrir,
  });

  final int numero;
  final Mapa? mapa;
  final ValueChanged<Mapa> onAbrir;

  @override
  Widget build(BuildContext context) {
    final mapa = this.mapa;
    final disponible = mapa != null;
    final colores = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      button: disponible,
      enabled: disponible,
      label: 'Mapa $numero, ${disponible ? 'disponible' : 'bloqueado'}',
      onTap: disponible ? () => onAbrir(mapa) : null,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        color: disponible ? Colors.white : const Color(0xFFEDEEEA),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x663D5147), width: 0.7),
        ),
        child: InkWell(
          key: Key('map-option-$numero'),
          onTap: disponible ? () => onAbrir(mapa) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                disponible
                    ? _VistaPreviaMapa(mapa: mapa)
                    : Container(
                        width: _VistaPreviaMapa.lado,
                        height: _VistaPreviaMapa.lado,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E4DF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: colores.onSurfaceVariant,
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa $numero',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      _Etiqueta(disponible: disponible),
                      if (!disponible) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Muy pronto podrás jugarlo.',
                          style: TextStyle(color: colores.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (disponible)
                  const Icon(Icons.arrow_forward, color: Color(0xFF3D5147)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VistaPreviaMapa extends StatelessWidget {
  const _VistaPreviaMapa({required this.mapa});

  static const double lado = 84;

  final Mapa mapa;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: lado,
      height: lado,
      child: Column(
        children: [
          for (var fila = 0; fila < 7; fila++)
            Expanded(
              child: Row(
                children: [
                  for (var columna = 0; columna < 7; columna++)
                    Expanded(
                      child: Container(
                        key: Key('map-preview-cell-${fila * 7 + columna}'),
                        margin: const EdgeInsets.all(0.5),
                        decoration: BoxDecoration(
                          color: colorDeZona(mapa.colorEn(fila, columna)),
                          border: Border.all(
                            color: const Color(0x663D5147),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.disponible});

  final bool disponible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: disponible ? const Color(0xFFDCFCE7) : const Color(0xFFE2E4DF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        disponible ? 'Disponible' : 'Próximamente',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: disponible ? const Color(0xFF15803D) : const Color(0xFF3D5147),
        ),
      ),
    );
  }
}

class _ComoSeJuega extends StatelessWidget {
  const _ComoSeJuega();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cómo se juega',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Coloca los números del 1 al 6 en las celdas iniciales.',
            ),
            const Text('2. Lanza los dos dados.'),
            const Text(
              '3. Usa un dado como ancla y coloca el otro número junto a ella.',
            ),
            const Text(
              '4. Completa zonas respetando su regla para sumar puntos.',
            ),
          ],
        ),
      ),
    );
  }
}
