import 'package:flutter/material.dart';

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
  const TableroPage({super.key});

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  static const List<(int, int)> _celdasIniciales = [
    (1, 3),
    (2, 6),
    (4, 2),
    (4, 5),
    (6, 3),
    (7, 5),
  ];
  final Map<(int, int), int> _valores = {};

  Future<void> _editarCelda(int fila, int columna) async {
    final coordenada = (fila + 1, columna + 1);
    final esCeldaInicial = _celdasIniciales.contains(coordenada);

    if (!esCeldaInicial) return;

    final valorActual = _valores[coordenada];
    final numerosDisponibles = {
      for (final entrada in _valores.entries)
        if (_celdasIniciales.contains(entrada.key) && entrada.key != coordenada)
          entrada.value,
    };

    final valor = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          esCeldaInicial
              ? 'Número inicial ${_celdasIniciales.indexOf(coordenada) + 1}'
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
      setState(() => _valores.remove(coordenada));
      return;
    }

    final color = mapaColores[fila][columna];
    final valoresZona = <int>[
      for (var filaZona = 0; filaZona < mapaColores.length; filaZona++)
        for (
          var columnaZona = 0;
          columnaZona < mapaColores[filaZona].length;
          columnaZona++
        )
          if (mapaColores[filaZona][columnaZona] == color &&
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
      return;
    }

    setState(() => _valores[coordenada] = valor);
  }

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
                    'Ingresa los números iniciales del 1 al 6',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
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
                            final esCeldaInicial = _celdasIniciales.contains(
                              coordenada,
                            );

                            return Padding(
                              padding: const EdgeInsets.all(2),
                              child: Material(
                                color: _colorDeZona(color),
                                borderRadius: BorderRadius.circular(4),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: Key('cell-${fila + 1}-${columna + 1}'),
                                  onTap: esCeldaInicial
                                      ? () => _editarCelda(fila, columna)
                                      : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: esCeldaInicial
                                            ? const Color(0xFF2563EB)
                                            : const Color(0x663D5147),
                                        width: esCeldaInicial ? 2 : 0.7,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: valor == null
                                        ? esCeldaInicial
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
