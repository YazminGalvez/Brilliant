import 'package:flutter/material.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/sala_espera.dart';
import 'package:frontend/seleccion_mapa.dart';

class CrearPartidaPage extends StatefulWidget {
  const CrearPartidaPage({
    required this.partidas,
    this.mapas = mapasDelMenu,
    super.key,
  });

  static const errorGeneral =
      'No se pudo crear la partida. Inténtalo de nuevo.';
  static const minimoJugadores = 2;
  static const maximoJugadores = 6;

  final ServicioPartidas partidas;
  final List<Mapa?> mapas;

  @override
  State<CrearPartidaPage> createState() => _CrearPartidaPageState();
}

class _CrearPartidaPageState extends State<CrearPartidaPage> {
  late int? _mapa = widget.mapas.nonNulls.firstOrNull?.numero;
  int _jugadores = CrearPartidaPage.minimoJugadores;
  bool _enviando = false;
  String? _error;

  Future<void> _crear() async {
    final mapa = _mapa;
    if (_enviando || mapa == null) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final sala = await widget.partidas.crear(
        mapa: mapa,
        jugadores: _jugadores,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              SalaEsperaPage(partidas: widget.partidas, salaInicial: sala),
        ),
      );
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      final proveedor = ProveedorAutenticacion.buscar(context);
      if (error.codigoServidor == 'NO_AUTORIZADO' && proveedor != null) {
        proveedor.volverAlInicio(Navigator.of(context), aviso: error.mensaje);
        return;
      }
      _mostrarFallo(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarFallo(CrearPartidaPage.errorGeneral);
    }
  }

  void _mostrarFallo(String mensaje) {
    setState(() {
      _error = mensaje;
      _enviando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final error = _error;

    return PantallaClara(
      titulo: 'Crear partida',
      children: [
        Text('Mapa', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mapa in widget.mapas.nonNulls)
              ChoiceChip(
                key: Key('crear-mapa-${mapa.numero}'),
                label: Text('Mapa ${mapa.numero}'),
                selected: _mapa == mapa.numero,
                onSelected: _enviando
                    ? null
                    : (_) => setState(() => _mapa = mapa.numero),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Jugadores', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (
              var cantidad = CrearPartidaPage.minimoJugadores;
              cantidad <= CrearPartidaPage.maximoJugadores;
              cantidad++
            )
              ChoiceChip(
                key: Key('crear-jugadores-$cantidad'),
                label: Text('$cantidad'),
                selected: _jugadores == cantidad,
                onSelected: _enviando
                    ? null
                    : (_) => setState(() => _jugadores = cantidad),
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          SelectableText(
            error,
            key: const Key('crear-error'),
            style: TextStyle(color: colores.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('crear-confirmar'),
          onPressed: _enviando || _mapa == null ? null : _crear,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _enviando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
