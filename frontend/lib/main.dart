import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/historial_lanzamientos.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/validador_anclas.dart';
import 'package:juego_brilliant/validador_inicio.dart';
import 'package:juego_brilliant/zona.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:frontend/panel_historial_lanzamientos.dart';

Color colorDe(ColorZona color) => switch (color) {
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
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5F1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6657)),
      ),
      home: const TableroPage(),
    );
  }
}

class TableroPage extends StatefulWidget {
  const TableroPage({this.random, super.key});

  final Random? random;

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  final ValidadorInicio _validadorInicio = ValidadorInicio();
  final HistorialLanzamientos _historialLanzamientos =
      HistorialLanzamientos();
  final Map<(int, int), int> _valores = {};
  OpcionAncla? _opcionAnclaSeleccionada;
  Set<(int, int)> _destinosValidos = {};
  bool _tiradaConsumida = false;

  List<int?> get _valoresIniciales => [
    for (final coordenada in ValidadorInicio.celdasIniciales)
      _valores[coordenada],
  ];

  void _actualizarEstadoInicial() {
    _validadorInicio.actualizarValoresIniciales(_valoresIniciales);
  }

  void _iniciarPartida() {
    if (!_validadorInicio.puedeIniciar) return;
    setState(_validadorInicio.iniciarPartida);
  }

  Tablero _crearTableroParaValidarAnclas() {
    final tablero = mapaUno.crearTablero();

    for (var fila = 0; fila < Tablero.cantidadFilas; fila++) {
      for (var columna = 0; columna < Tablero.cantidadColumnas; columna++) {
        tablero.colocarDato(fila, columna, _valores[(fila + 1, columna + 1)]);
      }
    }

    return tablero;
  }

  Zona _zonaDe(Tablero tablero, int fila, int columna) => tablero.regiones
      .firstWhere((zona) => zona.contieneCoordenada(fila, columna));

  void _seleccionarOpcionAncla(OpcionAncla? opcion) {
    if (opcion == null || !opcion.puedeSeleccionarse) {
      setState(() {
        _opcionAnclaSeleccionada = null;
        _destinosValidos = {};
        _tiradaConsumida = false;
      });
      return;
    }

    final validador = ValidadorAnclas(_crearTableroParaValidarAnclas());
    final destinos = validador.buscarDestinosValidos(
      numeroAncla: opcion.ancla,
      numeroDelOtroDado: opcion.numeroAColocar,
    );

    setState(() {
      _opcionAnclaSeleccionada = opcion;
      _destinosValidos = {
        for (final destino in destinos) (destino.fila, destino.columna),
      };
    });
  }

  void _confirmarMovimiento(int fila, int columna) {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || !_destinosValidos.contains((fila, columna))) return;

    if (_guardarNumero(fila, columna, opcion.numeroAColocar)) {
      setState(() {
        _tiradaConsumida = true;
      });
    }
  }

  Future<void> _editarCelda(int fila, int columna) async {
    if (_destinosValidos.contains((fila, columna)) &&
        _opcionAnclaSeleccionada != null) {
      _confirmarMovimiento(fila, columna);
      return;
    }

    if (_validadorInicio.jugando) return;

    final coordenada = (fila + 1, columna + 1);
    final esCeldaInicial = ValidadorInicio.celdasIniciales.contains(coordenada);

    if (_validadorInicio.jugando == esCeldaInicial) return;

    final valorActual = _valores[coordenada];
    final numerosDisponibles = esCeldaInicial
        ? {
            for (final entrada in _valores.entries)
              if (ValidadorInicio.celdasIniciales.contains(entrada.key) &&
                  entrada.key != coordenada)
                entrada.value,
          }
        : <int>{};

    final valor = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          esCeldaInicial
              ? 'Número inicial ${ValidadorInicio.celdasIniciales.indexOf(coordenada) + 1}'
              : 'Fila ${fila + 1}, columna ${columna + 1}',
        ),
        children: [
          for (var numero = 1; numero <= 6; numero++)
            if (!numerosDisponibles.contains(numero) || numero == valorActual)
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

    if (valor == 0) {
      setState(() {
        _valores.remove(coordenada);
        if (esCeldaInicial) _actualizarEstadoInicial();
        _opcionAnclaSeleccionada = null;
        _destinosValidos = {};
      });
      return;
    }

    _guardarNumero(fila, columna, valor);
  }

  bool _guardarNumero(int fila, int columna, int valor) {
    final zona = _zonaDe(_crearTableroParaValidarAnclas(), fila, columna);
    final valoresZona = <int>[
      for (final celda in zona.coordenadas)
        if ((celda.fila != fila || celda.columna != columna) &&
            celda.valor != null)
          celda.valor!,
    ];
    final tipo = zona.tipo;

    if (!tipo.esPosibleAgregar(valoresZona, valor)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Regla de la zona: ${tipo.descripcion}')),
      );
      return false;
    }

    setState(() {
      _valores[(fila + 1, columna + 1)] = valor;
      if (ValidadorInicio.celdasIniciales.contains((fila + 1, columna + 1))) {
        _actualizarEstadoInicial();
      }
      _opcionAnclaSeleccionada = null;
      _destinosValidos = {};
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
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
                    _validadorInicio.jugando
                        ? 'Partida en curso'
                        : 'Ingresa los números iniciales del 1 al 6',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_validadorInicio.jugando) ...[
                    const SizedBox(height: 12),
                    _construirMarcador(),
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
                                final color = mapaUno.colorEn(fila, columna);
                                final coordenada = (fila + 1, columna + 1);
                                final valor = _valores[coordenada];
                                final esDestinoValido = _destinosValidos
                                    .contains((fila, columna));
                                final esCeldaInicial = ValidadorInicio
                                    .celdasIniciales
                                    .contains(coordenada);

                                return Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Material(
                                    color: esDestinoValido
                                        ? const Color(0xFFBBF7D0)
                                        : colorDe(color),
                                    borderRadius: BorderRadius.circular(4),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: Key(
                                        'cell-${fila + 1}-${columna + 1}',
                                      ),
                                      onTap: _validadorInicio.jugando
                                          ? esCeldaInicial
                                                ? null
                                                : () => _editarCelda(
                                                    fila,
                                                    columna,
                                                  )
                                          : esCeldaInicial
                                          ? () => _editarCelda(fila, columna)
                                          : null,
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
                      final panelDados = _validadorInicio.jugando
                          ? LanzamientoDados(
                              valoresPresentes: _valores.values.toSet(),
                              opcionSeleccionada: _opcionAnclaSeleccionada,
                              tiradaConsumida: _tiradaConsumida,
                              onAnclaSeleccionada: _seleccionarOpcionAncla,
                              onTirada: _registrarTirada,
                              random: widget.random,
                            )
                          : null;
                      final panelHistorial = _validadorInicio.jugando
                          ? PanelHistorialLanzamientos(
                              historial: _historialLanzamientos,
                            )
                          : null;

                      if (panelDados != null &&
                          panelHistorial != null &&
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
                            SizedBox(width: 300, child: panelHistorial),
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
                        ],
                      );
                    },
                  ),
                  if (!_validadorInicio.jugando) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('start-game'),
                        onPressed: _validadorInicio.puedeIniciar
                            ? _iniciarPartida
                            : null,
                        child: const Text('Inicio'),
                      ),
                    ),
                    if (!_validadorInicio.puedeIniciar)
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

  void _registrarTirada(List<int> valores) {
    setState(() {
      _historialLanzamientos.registrar(valores);
    });
  }

  Widget _construirMarcador() {
    final tablero = _crearTableroParaValidarAnclas();
    final puntuacionPorZona = tablero.puntuacionPorZona;
    return Card(
      key: const Key('scoreboard'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puntuación total: ${tablero.puntuacionTotal}',
              key: const Key('total-score'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (puntuacionPorZona.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final MapEntry(key: idZona, value: puntos)
                  in puntuacionPorZona.entries)
                Text(
                  'Zona ${_nombreDeZona(tablero, idZona)} ${idZona + 1}: '
                  '$puntos puntos',
                  key: Key('zone-score-$idZona'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _nombreDeZona(Tablero tablero, int idZona) =>
      tablero.regiones.firstWhere((zona) => zona.id == idZona).tipo.nombre;
}
