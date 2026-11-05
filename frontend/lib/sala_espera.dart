import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/vigilante_sala.dart';

class SalaEsperaPage extends StatefulWidget {
  const SalaEsperaPage({
    required this.partidas,
    required this.salaInicial,
    this.intervalo = const Duration(seconds: 2),
    super.key,
  });

  static const avisoSalaCerrada = 'La sala se cerró.';

  final ServicioPartidas partidas;
  final SalaPartida salaInicial;
  final Duration intervalo;

  @override
  State<SalaEsperaPage> createState() => _SalaEsperaPageState();
}

class _SalaEsperaPageState extends State<SalaEsperaPage> {
  late SalaPartida _sala = widget.salaInicial;
  bool _cerrada = false;
  late final VigilanteSala _vigilante;

  @override
  void initState() {
    super.initState();
    _vigilante = VigilanteSala(
      partidas: widget.partidas,
      codigo: widget.salaInicial.codigo,
      salaInicial: widget.salaInicial,
      intervalo: widget.intervalo,
      alCambiar: (sala) {
        if (mounted) setState(() => _sala = sala);
      },
      alCerrar: () {
        if (mounted) setState(() => _cerrada = true);
      },
    )..iniciar();
  }

  @override
  void dispose() {
    _vigilante.detener();
    super.dispose();
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: _sala.codigo));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_cerrada) return _salaCerrada(context);

    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final sala = _sala;

    return PantallaClara(
      titulo: 'Sala de espera',
      children: [
        Text(
          'Comparte este código',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: colores.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: SelectableText(
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
            ),
            IconButton(
              key: const Key('sala-copiar-codigo'),
              tooltip: 'Copiar código',
              icon: const Icon(Icons.copy_outlined),
              onPressed: _copiarCodigo,
            ),
          ],
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
          ListTile(
            key: Key('sala-jugador-${jugador.nombre}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.person_outline,
              color: jugador.conectado ? colores.primary : colores.outline,
            ),
            title: Text(jugador.nombre),
            subtitle: Text(
              [
                if (jugador.nombre == sala.anfitrion) 'Anfitrión',
                jugador.conectado ? 'Conectado' : 'Desconectado',
              ].join(' · '),
            ),
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
