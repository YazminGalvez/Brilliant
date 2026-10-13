import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart' as modelo;
import 'package:juego_brilliant/validador_anclas.dart';
import 'package:juego_brilliant/validador_inicio.dart';
import 'package:juego_brilliant/zona.dart';
import 'package:frontend/lanzamiento_dados.dart';

enum ColorZonaBrilliant { amarillo, verde, azul, morado, rojo }

const List<List<ColorZonaBrilliant>> mapaColores = [
  [
    ColorZonaBrilliant.amarillo,
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.azul,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.amarillo,
  ],
  [
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.azul,
    ColorZonaBrilliant.azul,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.verde,
  ],
  [
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.azul,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.verde,
  ],
  [
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.amarillo,
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.verde,
  ],
  [
    ColorZonaBrilliant.verde,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.azul,
  ],
  [
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.azul,
    ColorZonaBrilliant.azul,
  ],
  [
    ColorZonaBrilliant.amarillo,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.morado,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.rojo,
    ColorZonaBrilliant.azul,
    ColorZonaBrilliant.amarillo,
  ],
];

final List<List<int>> _mapaIdsZonas = _crearMapaIdsZonas();

List<List<int>> _crearMapaIdsZonas() {
  final ids = List.generate(7, (_) => List.filled(7, -1));
  var siguienteId = 0;

  for (var fila = 0; fila < 7; fila++) {
    for (var columna = 0; columna < 7; columna++) {
      if (ids[fila][columna] != -1) continue;

      final color = mapaColores[fila][columna];
      final pendientes = <(int, int)>[(fila, columna)];
      ids[fila][columna] = siguienteId;

      while (pendientes.isNotEmpty) {
        final (filaActual, columnaActual) = pendientes.removeLast();
        for (final (deltaFila, deltaColumna) in [
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final filaVecina = filaActual + deltaFila;
          final columnaVecina = columnaActual + deltaColumna;
          if (filaVecina < 0 ||
              filaVecina >= 7 ||
              columnaVecina < 0 ||
              columnaVecina >= 7 ||
              ids[filaVecina][columnaVecina] != -1 ||
              mapaColores[filaVecina][columnaVecina] != color) {
            continue;
          }

          ids[filaVecina][columnaVecina] = siguienteId;
          pendientes.add((filaVecina, columnaVecina));
        }
      }
      siguienteId++;
    }
  }

  final idZonaAmarilla = ids[0][0];
  for (var fila = 0; fila < 7; fila++) {
    for (var columna = 0; columna < 7; columna++) {
      if (mapaColores[fila][columna] == ColorZonaBrilliant.amarillo) {
        ids[fila][columna] = idZonaAmarilla;
      }
    }
  }

  return ids;
}

String descripcionRegla(ColorZonaBrilliant color) => switch (color) {
  ColorZonaBrilliant.amarillo => 'Todos los números deben ser distintos',
  ColorZonaBrilliant.verde => 'Se puede colocar cualquier número',
  ColorZonaBrilliant.azul => 'Todos los números deben ser iguales',
  ColorZonaBrilliant.morado => 'Máximo dos números diferentes por zona',
  ColorZonaBrilliant.rojo => 'Todos los números deben ser distintos',
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
  final Map<(int, int), int> _valores = {};
  final Map<int, int> _puntajesPorZona = {};
  final Set<int> _zonasPuntuadas = {};
  OpcionAncla? _opcionAnclaSeleccionada;
  Set<(int, int)> _destinosValidos = {};
  bool _tiradaConsumida = false;

  int get _puntajeTotal =>
      _puntajesPorZona.values.fold(0, (total, puntos) => total + puntos);

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
    final tablero = Tablero();
    final coordenadasPorZona = <int, List<Coordenada>>{};

    for (var fila = 0; fila < mapaColores.length; fila++) {
      for (var columna = 0; columna < mapaColores[fila].length; columna++) {
        tablero.colocarDato(fila, columna, _valores[(fila + 1, columna + 1)]);
        coordenadasPorZona
            .putIfAbsent(_mapaIdsZonas[fila][columna], () => [])
            .add(tablero.obtenerCelda(fila, columna));
      }
    }

    for (final entrada in coordenadasPorZona.entries) {
      final primeraCelda = entrada.value.first;
      final tipo =
          switch (mapaColores[primeraCelda.fila][primeraCelda.columna]) {
            ColorZonaBrilliant.amarillo => modelo.TipoAmarillo(),
            ColorZonaBrilliant.verde => modelo.TipoVerde(),
            ColorZonaBrilliant.azul => modelo.TipoAzul(),
            ColorZonaBrilliant.morado => modelo.TipoMorado(),
            ColorZonaBrilliant.rojo => modelo.TipoRojo(),
          };
      tablero.agregarRegion(
        Zona(id: entrada.key, tipo: tipo, coordenadas: entrada.value),
      );
    }

    return tablero;
  }

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
        if (_validadorInicio.jugando) {
          _actualizarEstadoPuntuacion(fila, columna);
        }
        _opcionAnclaSeleccionada = null;
        _destinosValidos = {};
      });
      return;
    }

    _guardarNumero(fila, columna, valor);
  }

  bool _guardarNumero(int fila, int columna, int valor) {
    final color = mapaColores[fila][columna];
    final idZona = _mapaIdsZonas[fila][columna];
    final valoresZona = <int>[
      for (var filaZona = 0; filaZona < mapaColores.length; filaZona++)
        for (
          var columnaZona = 0;
          columnaZona < mapaColores[filaZona].length;
          columnaZona++
        )
          if (_mapaIdsZonas[filaZona][columnaZona] == idZona &&
              (filaZona != fila || columnaZona != columna) &&
              _valores.containsKey((filaZona + 1, columnaZona + 1)))
            _valores[(filaZona + 1, columnaZona + 1)]!,
    ];
    final esValido = switch (color) {
      ColorZonaBrilliant.amarillo ||
      ColorZonaBrilliant.rojo => !valoresZona.contains(valor),
      ColorZonaBrilliant.verde => true,
      ColorZonaBrilliant.azul =>
        valoresZona.isEmpty || valoresZona.every((actual) => actual == valor),
      ColorZonaBrilliant.morado => {...valoresZona, valor}.length <= 2,
    };

    if (!esValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Regla de la zona: ${descripcionRegla(color)}')),
      );
      return false;
    }

    setState(() {
      _valores[(fila + 1, columna + 1)] = valor;
      if (ValidadorInicio.celdasIniciales.contains((fila + 1, columna + 1))) {
        _actualizarEstadoInicial();
      }
      if (_validadorInicio.jugando) {
        _actualizarEstadoPuntuacion(fila, columna);
      }
      _opcionAnclaSeleccionada = null;
      _destinosValidos = {};
    });
    return true;
  }

  void _actualizarEstadoPuntuacion(int fila, int columna) {
    final idZona = _mapaIdsZonas[fila][columna];
    final zonaCompleta = [
      for (var filaZona = 0; filaZona < _mapaIdsZonas.length; filaZona++)
        for (
          var columnaZona = 0;
          columnaZona < _mapaIdsZonas[filaZona].length;
          columnaZona++
        )
          if (_mapaIdsZonas[filaZona][columnaZona] == idZona)
            _valores.containsKey((filaZona + 1, columnaZona + 1)),
    ].every((tieneValor) => tieneValor);

    if (!zonaCompleta || !_zonasPuntuadas.add(idZona)) return;

    final color = mapaColores[fila][columna];
    _puntajesPorZona[idZona] = _puntosPorPrimeraCompletacion(color);
  }

  int _puntosPorPrimeraCompletacion(ColorZonaBrilliant color) =>
      switch (color) {
        ColorZonaBrilliant.amarillo => 8,
        ColorZonaBrilliant.verde => 4,
        ColorZonaBrilliant.azul => 7,
        ColorZonaBrilliant.morado => 6,
        ColorZonaBrilliant.rojo => 6,
      };

  String _nombreZona(ColorZonaBrilliant color) => switch (color) {
    ColorZonaBrilliant.amarillo => 'Amarilla',
    ColorZonaBrilliant.verde => 'Verde',
    ColorZonaBrilliant.azul => 'Azul',
    ColorZonaBrilliant.morado => 'Morada',
    ColorZonaBrilliant.rojo => 'Roja',
  };

  Color _colorDeZona(ColorZonaBrilliant color) => switch (color) {
    ColorZonaBrilliant.amarillo => const Color(0xFFFEF3C7),
    ColorZonaBrilliant.verde => const Color(0xFFDCFCE7),
    ColorZonaBrilliant.azul => const Color(0xFFDBEAFE),
    ColorZonaBrilliant.morado => const Color(0xFFF3E8FF),
    ColorZonaBrilliant.rojo => const Color(0xFFFEE2E2),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
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
                  Center(
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
                            final color = mapaColores[fila][columna];
                            final coordenada = (fila + 1, columna + 1);
                            final valor = _valores[coordenada];
                            final esDestinoValido = _destinosValidos.contains((
                              fila,
                              columna,
                            ));
                            final esCeldaInicial = ValidadorInicio
                                .celdasIniciales
                                .contains(coordenada);

                            return Padding(
                              padding: const EdgeInsets.all(2),
                              child: Material(
                                color: esDestinoValido
                                    ? const Color(0xFFBBF7D0)
                                    : _colorDeZona(color),
                                borderRadius: BorderRadius.circular(4),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: Key('cell-${fila + 1}-${columna + 1}'),
                                  onTap: _validadorInicio.jugando
                                      ? esCeldaInicial
                                            ? null
                                            : () => _editarCelda(fila, columna)
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
                                                    color: Color(0xFF1D4ED8),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                )
                                              : null
                                        : Text(
                                            '$valor',
                                            style: TextStyle(
                                              color: const Color(0xFF26332D),
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
                  ),
                  const SizedBox(height: 16),
                  if (_validadorInicio.jugando)
                    LanzamientoDados(
                      valoresPresentes: _valores.values.toSet(),
                      opcionSeleccionada: _opcionAnclaSeleccionada,
                      tiradaConsumida: _tiradaConsumida,
                      onAnclaSeleccionada: _seleccionarOpcionAncla,
                      random: widget.random,
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

  Widget _construirMarcador() {
    final zonasConPuntos = _puntajesPorZona.keys.toList()..sort();
    return Card(
      key: const Key('scoreboard'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puntuación total: $_puntajeTotal',
              key: const Key('total-score'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (zonasConPuntos.isNotEmpty) ...[
              const SizedBox(height: 4),
              for (final idZona in zonasConPuntos)
                Text(
                  'Zona ${_nombreZona(_colorDeIdZona(idZona))} ${idZona + 1}: '
                  '${_puntajesPorZona[idZona]} puntos',
                  key: Key('zone-score-$idZona'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  ColorZonaBrilliant _colorDeIdZona(int idZona) {
    for (var fila = 0; fila < _mapaIdsZonas.length; fila++) {
      for (var columna = 0; columna < _mapaIdsZonas[fila].length; columna++) {
        if (_mapaIdsZonas[fila][columna] == idZona) {
          return mapaColores[fila][columna];
        }
      }
    }
    throw StateError('No se encontró la zona $idZona en el tablero.');
  }
}
