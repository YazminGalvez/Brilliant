import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/validador_anclas.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/cliente_autenticacion.dart';
import 'package:frontend/direccion_servidor.dart';
import 'package:frontend/inicio_sesion.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:frontend/panel_historial_lanzamientos.dart';
import 'package:frontend/panel_historial_movimientos.dart';
import 'package:frontend/partida_compartida.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/seleccion_mapa.dart';
import 'package:frontend/vigilante_sesion.dart';

Color colorDeZona(ColorZona color) => switch (color) {
  ColorZona.amarillo => const Color(0xFFFEF3C7),
  ColorZona.verde => const Color(0xFFDCFCE7),
  ColorZona.azul => const Color(0xFFDBEAFE),
  ColorZona.morado => const Color(0xFFF3E8FF),
  ColorZona.rojo => const Color(0xFFFEE2E2),
  ColorZona.gris => const Color(0xFFE5E7EB),
  ColorZona.naranja => const Color(0xFFFFEDD5),
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final servidor = await DireccionServidor.elegir();
  runApp(MainApp(servicio: ClienteAutenticacion(servidor: servidor)));
}

class MainApp extends StatelessWidget {
  const MainApp({this.partida, this.random, this.servicio, super.key});

  final Partida? partida;
  final Random? random;
  final ServicioAutenticacion? servicio;

  Widget _menuVigilado(ServicioAutenticacion servicio) => VigilanteSesion(
    servicio: servicio,
    alPerderSesion: (context) => _volverAlInicio(
      Navigator.of(context),
      servicio,
      aviso: VigilanteSesion.avisoSesionPerdida,
    ),
    child: SeleccionMapaPage(random: random),
  );

  InicioSesionPage _inicioSesion(
    ServicioAutenticacion servicio, {
    String? aviso,
  }) => InicioSesionPage(
    servicio: servicio,
    siguiente: (_) => _menuVigilado(servicio),
    aviso: aviso,
  );

  void _volverAlInicio(
    NavigatorState navegador,
    ServicioAutenticacion servicio, {
    String? aviso,
  }) {
    navegador.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => _inicioSesion(servicio, aviso: aviso),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicio = this.servicio;
    final aplicacion = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5F1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D6657)),
      ),
      home: servicio != null
          ? _inicioSesion(servicio)
          : partida == null
          ? SeleccionMapaPage(random: random)
          : TableroPage(partida: partida, random: random),
    );
    if (servicio == null) return aplicacion;

    return ProveedorAutenticacion(
      servicio: servicio,
      volverAlInicio: (navegador, {aviso}) =>
          _volverAlInicio(navegador, servicio, aviso: aviso),
      child: aplicacion,
    );
  }
}

class TableroPage extends StatefulWidget {
  const TableroPage({this.partida, this.random, this.compartida, super.key});

  final Partida? partida;
  final Random? random;
  final PartidaCompartida? compartida;

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  late final Partida _partida;
  OpcionAncla? _opcionAnclaSeleccionada;
  int _rondaRegistrada = 0;

  @override
  void initState() {
    super.initState();
    final compartida = widget.compartida;
    _partida =
        widget.partida ??
        (compartida == null
            ? Partida(mapa: mapaUno)
            : Partida(
                mapa: mapaDeLaSala(compartida.sala) ?? mapaUno,
                permitirRelanzar: false,
              ));
    if (compartida != null) {
      _colocarTableroEnviado(compartida.sala.miTablero);
      _sincronizarRonda(compartida);
      compartida
        ..addListener(_alCambiarCompartida)
        ..iniciar();
    }
  }

  @override
  void dispose() {
    widget.compartida
      ?..removeListener(_alCambiarCompartida)
      ..detener();
    super.dispose();
  }

  void _alCambiarCompartida() {
    final compartida = widget.compartida;
    if (!mounted || compartida == null) return;
    setState(() {
      if (!_partida.inicializado) {
        _colocarTableroEnviado(compartida.sala.miTablero);
      }
      _sincronizarRonda(compartida);
    });
  }

  void _sincronizarRonda(PartidaCompartida compartida) {
    final ronda = compartida.sala.ronda;
    if (ronda > 0 && _partida.puedeIniciar) _partida.iniciar();

    final dados = compartida.resultado;
    if (dados == null ||
        !compartida.puedoJugarRonda ||
        ronda <= _rondaRegistrada ||
        !_partida.puedeLanzar) {
      return;
    }
    _partida.registrarTirada(dados);
    _rondaRegistrada = ronda;
    _opcionAnclaSeleccionada = null;
  }

  Future<void> _confirmarConceder() async {
    final compartida = widget.compartida;
    if (compartida == null || !compartida.puedoConceder) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Conceder la partida?'),
        content: const Text(
          'Si concedes, pierdes la partida y no podrás ganarla.',
        ),
        actions: [
          TextButton(
            key: const Key('conceder-cancelar'),
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('conceder-confirmar'),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Conceder'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    await compartida.conceder();
  }

  bool get _concedi => widget.compartida?.concedi ?? false;

  int? _zonaCompletadaEn(int fila, int columna) {
    final zona = _partida.tablero.zonaEn(fila, columna);
    if (zona == null || !zona.verificarCompletado()) return null;
    return zona.id + 1;
  }

  void _colocarTableroEnviado(List<int> numeros) {
    final celdas = _partida.mapa.celdasIniciales;
    if (numeros.length != celdas.length) return;
    try {
      for (var indice = 0; indice < celdas.length; indice++) {
        final (fila, columna) = celdas[indice];
        _partida.colocarValorInicial(fila - 1, columna - 1, numeros[indice]);
      }
    } on Object {
      return;
    }
  }

  bool get _bloqueadoPorCompartida {
    final compartida = widget.compartida;
    return compartida != null &&
        (compartida.yaFinalice || compartida.enviando || compartida.cerrada);
  }

  Future<void> _finalizarTablero() async {
    final compartida = widget.compartida;
    if (compartida == null || !_partida.inicializado) return;
    await compartida.enviarTablero([
      for (final valor in _partida.valoresIniciales) valor!,
    ]);
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

  void _cambiarDeMapa() {
    final navegador = Navigator.of(context);
    if (navegador.canPop()) {
      navegador.pop();
      return;
    }
    navegador.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SeleccionMapaPage(random: widget.random),
      ),
    );
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
    if (!_partida.puedeSaltarTurno || _concedi) return;

    setState(() {
      _partida.saltarTurno();
      _opcionAnclaSeleccionada = null;
    });
    widget.compartida?.terminarTurno(tableroLleno: false);
  }

  void _confirmarMovimiento(int fila, int columna) {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || !_destinosValidos.contains((fila, columna))) return;

    setState(() {
      _partida.colocar(opcion, fila, columna);
      _opcionAnclaSeleccionada = null;
    });
    widget.compartida?.terminarTurno(
      tableroLleno: _partida.tablero.estaLleno,
      zona: _zonaCompletadaEn(fila, columna),
    );
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
            if ((!numerosUsados.contains(numero) || numero == valorActual) &&
                _partida.zonaAceptaValorInicial(fila, columna, numero))
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
      if (_bloqueadoPorCompartida) return null;
      return esCeldaInicial ? () => _editarCeldaInicial(fila, columna) : null;
    }
    if (_jugando && !esCeldaInicial && !_concedi) {
      return () => _confirmarMovimiento(fila, columna);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final compartida = widget.compartida;
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
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Brilliant',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (compartida == null)
                        TextButton.icon(
                          key: const Key('change-map-button'),
                          onPressed: _cambiarDeMapa,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Cambiar de mapa'),
                        )
                      else if (compartida.puedoConceder ||
                          compartida.concediendo)
                        TextButton.icon(
                          key: const Key('multi-conceder'),
                          onPressed: compartida.concediendo
                              ? null
                              : _confirmarConceder,
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          icon: compartida.concediendo
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.flag_outlined),
                          label: const Text('Conceder partida'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (compartida != null)
                    Text(
                      'Partida ${compartida.sala.codigo} · '
                      'Mapa ${_partida.mapa.numero}',
                      key: const Key('multi-encabezado'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  Text(
                    switch (_partida.estado) {
                      EstadoPartida.preparando =>
                        'Ingresa los números iniciales del 1 al 6',
                      _ when compartida != null =>
                        'Ronda ${compartida.sala.ronda}',
                      EstadoPartida.jugando => 'Partida en curso',
                      EstadoPartida.terminada => 'Fin del juego',
                    },
                    key: compartida != null && enCurso
                        ? const Key('multi-ronda')
                        : null,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (compartida != null && compartida.sinConexion) ...[
                    const SizedBox(height: 12),
                    const _FranjaSinConexion(),
                  ],
                  if (enCurso) ...[
                    const SizedBox(height: 12),
                    _construirMarcador(),
                  ],
                  if (enCurso && compartida != null) ...[
                    const SizedBox(height: 12),
                    _PanelRondaCompartida(
                      compartida: compartida,
                      tableroLleno: _partida.terminada,
                    ),
                  ] else if (_partida.terminada) ...[
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
                                final esCeldaInicial = celdasIniciales.contains(
                                  (fila, columna),
                                );

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
                      final panelDados = enCurso && !_concedi
                          ? LanzamientoDados(
                              opciones: _opcionesVisibles,
                              puedeLanzar:
                                  compartida == null && _partida.puedeLanzar,
                              opcionSeleccionada: _opcionAnclaSeleccionada,
                              onAnclaSeleccionada: _seleccionarOpcionAncla,
                              onTirada: compartida == null
                                  ? _registrarTirada
                                  : null,
                              puedeSaltarTurno: _partida.puedeSaltarTurno,
                              onSaltarTurno: _saltarTurno,
                              random: widget.random,
                              dadosDelServidor: compartida?.resultado,
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
                  if (_preparando && compartida != null) ...[
                    const SizedBox(height: 16),
                    _PanelTableroCompartido(
                      compartida: compartida,
                      tableroCompleto: _partida.inicializado,
                      onFinalizar: _finalizarTablero,
                    ),
                  ] else if (_preparando) ...[
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

class _PanelTableroCompartido extends StatelessWidget {
  const _PanelTableroCompartido({
    required this.compartida,
    required this.tableroCompleto,
    required this.onFinalizar,
  });

  final PartidaCompartida compartida;
  final bool tableroCompleto;
  final VoidCallback onFinalizar;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final error = compartida.error;

    if (compartida.cerrada) {
      return _PartidaNoDisponible(compartida: compartida);
    }

    if (!compartida.yaFinalice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            SelectableText(
              error.mensaje,
              key: const Key('multi-error'),
              style: TextStyle(color: colores.error),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            key: const Key('multi-finalizar'),
            onPressed: tableroCompleto && !compartida.enviando
                ? onFinalizar
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: compartida.enviando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Finalizar tablero'),
          ),
          if (!tableroCompleto)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Faltan números iniciales: ingresa del 1 al 6 sin repetir.',
              ),
            ),
        ],
      );
    }

    return Card(
      key: const Key('multi-esperando'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compartida.todosTerminaron)
              Text(
                'Todos los jugadores finalizaron su tablero.',
                key: const Key('multi-todos-listos'),
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              Row(
                children: [
                  Icon(Icons.hourglass_top, size: 20, color: colores.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esperando a los demás jugadores...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            for (final jugador in compartida.jugadoresEnJuego)
              Padding(
                key: Key('multi-jugador-${jugador.nombre}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Opacity(
                  opacity: _seDesconecto(compartida, jugador.nombre) ? 0.5 : 1,
                  child: Row(
                    children: [
                      Icon(
                        jugador.tableroListo
                            ? Icons.check_circle_outline
                            : Icons.hourglass_empty,
                        size: 20,
                        color: jugador.tableroListo
                            ? const Color(0xFF15803D)
                            : colores.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          jugador.nombre == compartida.miNombre
                              ? '${jugador.nombre} (tú)'
                              : jugador.nombre,
                        ),
                      ),
                      if (_seDesconecto(compartida, jugador.nombre))
                        _SinConexion(nombre: jugador.nombre)
                      else
                        Text(
                          jugador.tableroListo
                              ? 'Tablero listo'
                              : 'Colocando números',
                          style: TextStyle(color: colores.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FranjaSinConexion extends StatelessWidget {
  const _FranjaSinConexion();

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      key: const Key('multi-sin-conexion'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colores.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 20, color: colores.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin conexión con el servidor. Reintentando...',
              style: TextStyle(color: colores.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinConexion extends StatelessWidget {
  const _SinConexion({required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sin conexión',
      key: Key('jugador-sin-conexion-$nombre'),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

bool _seDesconecto(PartidaCompartida compartida, String nombre) {
  if (nombre == compartida.miNombre) return false;
  for (final jugador in compartida.sala.jugadores) {
    if (jugador.nombre == nombre) {
      return !jugador.conectado && !jugador.concedio;
    }
  }
  return false;
}

void _volverAlMenu(BuildContext context, PartidaCompartida compartida) {
  compartida.salir();
  Navigator.of(context).popUntil((ruta) => ruta.isFirst);
}

class _PartidaNoDisponible extends StatelessWidget {
  const _PartidaNoDisponible({required this.compartida});

  final PartidaCompartida compartida;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('multi-no-disponible'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'La partida ya no está disponible.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('multi-volver-menu'),
              onPressed: () => _volverAlMenu(context, compartida),
              child: const Text('Volver al menú'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaDePuntos extends StatelessWidget {
  const _ListaDePuntos({
    required this.compartida,
    required this.estadoDe,
    this.mostrarConexion = false,
  });

  final PartidaCompartida compartida;
  final String? Function(String nombre) estadoDe;
  final bool mostrarConexion;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final clasificacion = compartida.clasificacion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var posicion = 0; posicion < clasificacion.length; posicion++)
          _FilaDePuntos(
            posicion: posicion + 1,
            nombre: clasificacion[posicion].key,
            puntos: clasificacion[posicion].value,
            esYo: clasificacion[posicion].key == compartida.miNombre,
            estado: estadoDe(clasificacion[posicion].key),
            sinConexion:
                mostrarConexion &&
                _seDesconecto(compartida, clasificacion[posicion].key),
            colores: colores,
          ),
      ],
    );
  }
}

class _FilaDePuntos extends StatelessWidget {
  const _FilaDePuntos({
    required this.posicion,
    required this.nombre,
    required this.puntos,
    required this.esYo,
    required this.estado,
    required this.sinConexion,
    required this.colores,
  });

  final int posicion;
  final String nombre;
  final int puntos;
  final bool esYo;
  final String? estado;
  final bool sinConexion;
  final ColorScheme colores;

  @override
  Widget build(BuildContext context) {
    final estado = this.estado;
    final fila = Container(
      key: Key('multi-jugador-$nombre'),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: esYo ? colores.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$posicion.')),
          Expanded(
            child: Text(
              esYo ? '$nombre (tú)' : nombre,
              style: TextStyle(fontWeight: esYo ? FontWeight.w700 : null),
            ),
          ),
          if (sinConexion) ...[
            _SinConexion(nombre: nombre),
            const SizedBox(width: 12),
          ] else if (estado != null) ...[
            Text(
              estado,
              key: Key('multi-estado-$nombre'),
              style: TextStyle(color: colores.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            '$puntos pts',
            key: Key('multi-puntos-$nombre'),
            style: TextStyle(
              fontWeight: esYo ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return sinConexion ? Opacity(opacity: 0.5, child: fila) : fila;
  }
}

class _PanelRondaCompartida extends StatelessWidget {
  const _PanelRondaCompartida({
    required this.compartida,
    required this.tableroLleno,
  });

  final PartidaCompartida compartida;
  final bool tableroLleno;

  String _estadoDe(String nombre) {
    final jugador = compartida.sala.jugadores
        .where((jugador) => jugador.nombre == nombre)
        .firstOrNull;
    if (jugador == null) return 'Salió';
    if (jugador.concedio) return 'Concedió';
    final esYo = nombre == compartida.miNombre;
    if (jugador.jugoRonda || (esYo && !compartida.puedoJugarRonda)) {
      return 'Jugó';
    }
    return 'Pensando';
  }

  @override
  Widget build(BuildContext context) {
    if (compartida.cerrada) return _PartidaNoDisponible(compartida: compartida);
    if (compartida.terminada || compartida.concedi) {
      return _PanelFinPartida(compartida: compartida);
    }

    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final sala = compartida.sala;
    final errorTurno = compartida.errorTurno;
    final errorConceder = compartida.errorConceder;
    final (titulo, clave) = compartida.puedoJugarRonda
        ? (
            'Tu turno: elige un ancla y un destino, o salta el turno.',
            'multi-tu-turno',
          )
        : ('Esperando a los demás...', 'multi-esperando-ronda');

    return Card(
      key: const Key('multi-jugadores'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, key: Key(clave), style: tema.textTheme.titleMedium),
            if (tableroLleno) ...[
              const SizedBox(height: 4),
              const Text('Llenaste tu tablero.'),
            ],
            if (errorTurno != null && compartida.avisoPendiente != null) ...[
              const SizedBox(height: 8),
              Text(
                'No se pudo avisar tu turno: ${errorTurno.mensaje}',
                key: const Key('multi-error-turno'),
                style: TextStyle(color: colores.error),
              ),
            ],
            if (errorConceder != null) ...[
              const SizedBox(height: 8),
              Text(
                errorConceder.mensaje,
                key: const Key('multi-error-conceder'),
                style: TextStyle(color: colores.error),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Meta: ${sala.meta} puntos',
              key: const Key('multi-meta'),
              style: TextStyle(color: colores.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            _ListaDePuntos(
              compartida: compartida,
              estadoDe: _estadoDe,
              mostrarConexion: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelFinPartida extends StatelessWidget {
  const _PanelFinPartida({required this.compartida});

  final PartidaCompartida compartida;

  static String motivoDeFin(String? motivo) => switch (motivo) {
    SalaPartida.motivoMeta => 'Alguien llegó a la meta.',
    SalaPartida.motivoSinTableros => 'Nadie puede seguir jugando.',
    SalaPartida.motivoAbandono => 'Los demás jugadores concedieron.',
    _ => 'La partida terminó.',
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sala = compartida.sala;
    final ganadores = sala.terminada ? sala.ganadores : const <String>[];
    final ganePorAbandono =
        compartida.gane && sala.motivoFin == SalaPartida.motivoAbandono;
    final titulo = switch (compartida) {
      PartidaCompartida(salioPorInactividad: true) =>
        'Saliste de la partida por inactividad.',
      PartidaCompartida(concedi: true) => 'Concediste la partida.',
      _ when ganePorAbandono => 'Ganaste: los demás concedieron.',
      PartidaCompartida(gane: true) => '¡Ganaste!',
      _ => 'Partida terminada',
    };
    final mostrarMotivo =
        sala.terminada && !ganePorAbandono && !compartida.concedi;

    return Card(
      key: const Key('multi-fin'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              key: const Key('multi-resultado'),
              style: tema.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (mostrarMotivo) ...[
              const SizedBox(height: 4),
              Text(
                motivoDeFin(sala.motivoFin),
                key: const Key('multi-motivo'),
                style: TextStyle(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
            if (ganadores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                ganadores.length == 1
                    ? 'Ganó ${ganadores.single}'
                    : 'Empate: ${ganadores.join(', ')}',
                key: const Key('multi-ganadores'),
                style: tema.textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text('Clasificación', style: tema.textTheme.titleSmall),
            const SizedBox(height: 4),
            _ListaDePuntos(compartida: compartida, estadoDe: (_) => null),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('multi-volver-menu'),
              onPressed: () => _volverAlMenu(context, compartida),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Volver al menú'),
            ),
          ],
        ),
      ),
    );
  }
}
