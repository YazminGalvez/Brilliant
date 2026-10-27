import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/validador_anclas.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:frontend/panel_historial_lanzamientos.dart';
import 'package:frontend/panel_historial_movimientos.dart';

Color colorDeZona(ColorZona color) => switch (color) {
  ColorZona.amarillo => const Color(0xFFFEF3C7),
  ColorZona.verde => const Color(0xFFDCFCE7),
  ColorZona.azul => const Color(0xFFDBEAFE),
  ColorZona.morado => const Color(0xFFF3E8FF),
  ColorZona.rojo => const Color(0xFFFEE2E2),
};

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({this.partida, this.random, super.key});

  final Partida? partida;
  final Random? random;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5F1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6657)),
      ),
      home: TableroPage(partida: partida, random: random),
    );
  }
}

class TableroPage extends StatefulWidget {
  const TableroPage({this.partida, this.random, super.key});

  final Partida? partida;
  final Random? random;

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  late final Partida _partida;
  OpcionAncla? _opcionAnclaSeleccionada;

  @override
  void initState() {
    super.initState();
    _partida = widget.partida ?? Partida(mapa: mapaUno);
  }

  bool get _preparando => _partida.estado == EstadoPartida.preparando;
  bool get _jugando => _partida.estado == EstadoPartida.jugando;

  List<(int, int)> get _celdasIniciales => [
    for (final (fila, columna) in _partida.mapa.celdasIniciales)
      (fila - 1, columna - 1),
  ];

  List<OpcionAncla> get _opcionesVisibles {
    if (_partida.tiradaActual != null) return _partida.opcionesAncla;

    final ultima = _partida.historialLanzamientos.ultima;
    if (ultima == null || !_jugando) return const [];
    return [
      OpcionAncla(
        ancla: ultima.primerDado,
        numeroAColocar: ultima.segundoDado,
        puedeSeleccionarse: false,
      ),
      if (ultima.primerDado != ultima.segundoDado)
        OpcionAncla(
          ancla: ultima.segundoDado,
          numeroAColocar: ultima.primerDado,
          puedeSeleccionarse: false,
        ),
    ];
  }

  Set<(int, int)> get _destinosValidos {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || _partida.tiradaActual == null) return const {};
    return {
      for (final destino in _partida.destinosValidos(opcion))
        (destino.fila, destino.columna),
    };
  }

  void _iniciarPartida() {
    if (!_partida.puedeIniciar) return;
    setState(_partida.iniciar);
  }

  void _nuevaPartida() {
    setState(() {
      _partida.reiniciar();
      _opcionAnclaSeleccionada = null;
    });
  }

  void _registrarTirada(List<int> valores) {
    setState(() {
      _partida.registrarTirada(valores);
    });
  }

  void _seleccionarOpcionAncla(OpcionAncla? opcion) {
    setState(() {
      _opcionAnclaSeleccionada = opcion != null && opcion.puedeSeleccionarse
          ? opcion
          : null;
    });
  }

  void _saltarTurno() {
    if (!_partida.puedeSaltarTurno) return;

    setState(() {
      _partida.saltarTurno();
      _opcionAnclaSeleccionada = null;
    });
  }

  void _confirmarMovimiento(int fila, int columna) {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || !_destinosValidos.contains((fila, columna))) return;

    setState(() {
      _partida.colocar(opcion, fila, columna);
      _opcionAnclaSeleccionada = null;
    });
  }

  Future<void> _editarCeldaInicial(int fila, int columna) async {
    final indice = _celdasIniciales.indexOf((fila, columna));
    if (!_preparando || indice < 0) return;

    final valoresIniciales = _partida.valoresIniciales;
    final valorActual = valoresIniciales[indice];
    final numerosUsados = {
      for (var otro = 0; otro < valoresIniciales.length; otro++)
        if (otro != indice && valoresIniciales[otro] != null)
          valoresIniciales[otro]!,
    };

    final valor = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Número inicial ${indice + 1}'),
        children: [
          for (var numero = 1; numero <= 6; numero++)
            if (!numerosUsados.contains(numero) || numero == valorActual)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, numero),
                child: Text('$numero'),
              ),
          if (valorActual != null)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Vaciar celda'),
            ),
        ],
      ),
    );

    if (valor == null || !mounted) return;

    setState(() {
      _partida.colocarValorInicial(fila, columna, valor == 0 ? null : valor);
    });
  }

  VoidCallback? _accionDeCelda(int fila, int columna, bool esCeldaInicial) {
    if (_preparando) {
      return esCeldaInicial ? () => _editarCeldaInicial(fila, columna) : null;
    }
    if (_jugando && !esCeldaInicial) {
      return () => _confirmarMovimiento(fila, columna);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enCurso = !_preparando;
    final celdasIniciales = _celdasIniciales.toSet();
    final destinosValidos = _destinosValidos;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Brilliant',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    switch (_partida.estado) {
                      EstadoPartida.preparando =>
                        'Ingresa los números iniciales del 1 al 6',
                      EstadoPartida.jugando => 'Partida en curso',
                      EstadoPartida.terminada => 'Fin del juego',
                    },
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (enCurso) ...[
                    const SizedBox(height: 12),
                    _construirMarcador(),
                  ],
                  if (_partida.terminada) ...[
                    const SizedBox(height: 12),
                    _construirFinDePartida(),
                  ],
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final tablero = Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 49,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                  ),
                              itemBuilder: (context, index) {
                                final fila = index ~/ 7;
                                final columna = index % 7;
                                final color = _partida.mapa.colorEn(
                                  fila,
                                  columna,
                                );
                                final valor = _partida.tablero
                                    .obtenerCelda(fila, columna)
                                    .valor;
                                final esDestinoValido = destinosValidos
                                    .contains((fila, columna));
                                final esCeldaInicial = celdasIniciales
                                    .contains((fila, columna));

                                return Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Material(
                                    color: esDestinoValido
                                        ? const Color(0xFFBBF7D0)
                                        : colorDeZona(color),
                                    borderRadius: BorderRadius.circular(4),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: Key(
                                        'cell-${fila + 1}-${columna + 1}',
                                      ),
                                      onTap: _accionDeCelda(
                                        fila,
                                        columna,
                                        esCeldaInicial,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: esDestinoValido
                                                ? const Color(0xFF16A34A)
                                                : esCeldaInicial
                                                ? const Color(0xFF2563EB)
                                                : const Color(0x663D5147),
                                            width: esDestinoValido
                                                ? 3
                                                : esCeldaInicial
                                                ? 2
                                                : 0.7,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        key: esDestinoValido
                                            ? Key(
                                                'valid-move-cell-${fila + 1}-${columna + 1}',
                                              )
                                            : null,
                                        child: valor == null
                                            ? esDestinoValido
                                                  ? Icon(
                                                      Icons.add_circle,
                                                      key: Key(
                                                        'valid-move-marker-${fila + 1}-${columna + 1}',
                                                      ),
                                                      color: const Color(
                                                        0xFF15803D,
                                                      ),
                                                      size: 16,
                                                    )
                                                  : esCeldaInicial
                                                  ? const Text(
                                                      '+',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF1D4ED8,
                                                        ),
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    )
                                                  : null
                                            : Text(
                                                '$valor',
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFF26332D,
                                                  ),
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                      final panelDados = enCurso
                          ? LanzamientoDados(
                              opciones: _opcionesVisibles,
                              puedeLanzar: _partida.puedeLanzar,
                              opcionSeleccionada: _opcionAnclaSeleccionada,
                              onAnclaSeleccionada: _seleccionarOpcionAncla,
                              onTirada: _registrarTirada,
                              puedeSaltarTurno: _partida.puedeSaltarTurno,
                              onSaltarTurno: _saltarTurno,
                              random: widget.random,
                            )
                          : null;
                      final panelHistorial = enCurso
                          ? PanelHistorialLanzamientos(
                              historial: _partida.historialLanzamientos,
                            )
                          : null;
                      final panelMovimientos = enCurso
                          ? PanelHistorialMovimientos(
                              historial: _partida.historialMovimientos,
                              nombreDeZona: _nombreDeZona,
                            )
                          : null;

                      if (panelDados != null &&
                          panelHistorial != null &&
                          panelMovimientos != null &&
                          constraints.maxWidth >= 850) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  tablero,
                                  const SizedBox(height: 16),
                                  panelDados,
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 300,
                              child: Column(
                                children: [
                                  panelHistorial,
                                  const SizedBox(height: 16),
                                  panelMovimientos,
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          tablero,
                          if (panelDados != null) ...[
                            const SizedBox(height: 16),
                            panelDados,
                          ],
                          if (panelHistorial != null) ...[
                            const SizedBox(height: 16),
                            panelHistorial,
                          ],
                          if (panelMovimientos != null) ...[
                            const SizedBox(height: 16),
                            panelMovimientos,
                          ],
                        ],
                      );
                    },
                  ),
                  if (_preparando) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('start-game'),
                        onPressed: _partida.puedeIniciar
                            ? _iniciarPartida
                            : null,
                        child: const Text('Inicio'),
                      ),
                    ),
                    if (!_partida.puedeIniciar)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Faltan números iniciales: ingresa del 1 al 6 sin repetir.',
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirMarcador() {
    final puntuacionPorZona = _partida.puntuacionPorZona;
    return Card(
      key: const Key('scoreboard'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puntuación total: ${_partida.puntuacionTotal}',
              key: const Key('total-score'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (puntuacionPorZona.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final MapEntry(key: idZona, value: puntos)
                  in puntuacionPorZona.entries)
                Text(
                  'Zona ${_nombreDeZona(idZona)} ${idZona + 1}: '
                  '$puntos puntos',
                  key: Key('zone-score-$idZona'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirFinDePartida() {
    return Card(
      key: const Key('game-over-panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partida terminada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Puntuación final: ${_partida.puntuacionTotal} de '
              '${_partida.puntuacionMaxima}',
              key: const Key('final-score'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('new-game-button'),
              onPressed: _nuevaPartida,
              child: const Text('Nueva partida'),
            ),
          ],
        ),
      ),
    );
  }

  String _nombreDeZona(int idZona) => _partida.tablero.regiones
      .firstWhere((zona) => zona.id == idZona)
      .tipo
      .nombre;
}
