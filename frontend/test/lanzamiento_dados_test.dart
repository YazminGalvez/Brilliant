import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:juego_brilliant/validador_anclas.dart';

void main() {
  testWidgets('muestra las opciones deshabilitadas si no hay anclas', (
    tester,
  ) async {
    await tester.pumpWidget(const _Anfitrion(valoresPresentes: {}));

    expect(find.byKey(const Key('anchor-options-panel')), findsNothing);

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('anchor-options-panel')), findsOneWidget);
    final opciones = tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(opciones, isNotEmpty);
    expect(opciones.every((opcion) => opcion.onPressed == null), isTrue);
  });

  testWidgets('permite seleccionar una opción de ancla disponible', (
    tester,
  ) async {
    OpcionAncla? seleccionada;

    await tester.pumpWidget(
      _Anfitrion(onAnclaSeleccionada: (opcion) => seleccionada = opcion),
    );

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    final primeraOpcion = tester
        .widgetList<OutlinedButton>(find.byType(OutlinedButton))
        .first;
    expect(primeraOpcion.onPressed, isNotNull);
    await tester.tap(find.byWidget(primeraOpcion));

    expect(seleccionada, isNotNull);
    expect(seleccionada!.puedeSeleccionarse, isTrue);
  });

  testWidgets('no ofrece saltar turno si hay movimientos posibles', (
    tester,
  ) async {
    await tester.pumpWidget(const _Anfitrion());

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skip-turn-button')), findsNothing);
    expect(find.byKey(const Key('no-moves-message')), findsNothing);
  });

  testWidgets('ofrece saltar turno con los dados quietos y avisa al tocarlo', (
    tester,
  ) async {
    var saltos = 0;

    await tester.pumpWidget(
      _Anfitrion(sinJugadas: true, onSaltarTurno: () => saltos++),
    );

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('skip-turn-button')), findsNothing);
    expect(find.byKey(const Key('no-moves-message')), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('skip-turn-button')), findsOneWidget);
    expect(
      find.text(
        'No hay movimientos posibles con esta tirada. '
        'Salta el turno para volver a lanzar.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('skip-turn-button')));
    await tester.pump();

    expect(saltos, 1);
    expect(tester.takeException(), isNull);
  });

  FilledButton botonLanzar(WidgetTester tester) => tester.widget<FilledButton>(
    find.byKey(const Key('roll-dice-button')),
  );

  testWidgets('deshabilita lanzar mientras se puede saltar el turno', (
    tester,
  ) async {
    var tiradas = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanzamientoDados(
            puedeLanzar: false,
            puedeSaltarTurno: true,
            onTirada: (_) => tiradas++,
          ),
        ),
      ),
    );

    expect(botonLanzar(tester).onPressed, isNull);
    await tester.tap(
      find.byKey(const Key('roll-dice-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(tiradas, 0);
    expect(
      find.textContaining('Salta el turno para volver a lanzar'),
      findsOneWidget,
    );
  });

  testWidgets('lanza una vez si no se puede saltar el turno', (tester) async {
    var tiradas = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LanzamientoDados(onTirada: (_) => tiradas++),
        ),
      ),
    );

    expect(botonLanzar(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pumpAndSettle();

    expect(tiradas, 1);
  });

  testWidgets('vuelve a habilitar lanzar después de saltar el turno', (
    tester,
  ) async {
    var tiradas = 0;

    await tester.pumpWidget(
      _Anfitrion(sinJugadas: true, onTirada: () => tiradas++),
    );

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pump();
    expect(botonLanzar(tester).onPressed, isNull);

    await tester.pumpAndSettle();
    expect(botonLanzar(tester).onPressed, isNull);
    await tester.tap(
      find.byKey(const Key('roll-dice-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(tiradas, 1);

    await tester.tap(find.byKey(const Key('skip-turn-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skip-turn-button')), findsNothing);
    expect(botonLanzar(tester).onPressed, isNotNull);
  });

  testWidgets('deshabilita lanzar si el padre no lo permite', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LanzamientoDados(puedeLanzar: false)),
      ),
    );

    expect(botonLanzar(tester).onPressed, isNull);
    expect(find.byKey(const Key('skip-turn-button')), findsNothing);
  });
}

class _Anfitrion extends StatefulWidget {
  const _Anfitrion({
    this.valoresPresentes = const {1, 2, 3, 4, 5, 6},
    this.sinJugadas = false,
    this.onTirada,
    this.onSaltarTurno,
    this.onAnclaSeleccionada,
  });

  final Set<int> valoresPresentes;
  final bool sinJugadas;
  final VoidCallback? onTirada;
  final VoidCallback? onSaltarTurno;
  final ValueChanged<OpcionAncla?>? onAnclaSeleccionada;

  @override
  State<_Anfitrion> createState() => _AnfitrionState();
}

class _AnfitrionState extends State<_Anfitrion> {
  List<OpcionAncla> _opciones = const [];
  bool _puedeSaltarTurno = false;

  List<OpcionAncla> _opcionesDe(List<int> valores) => [
    for (final (ancla, otro) in [
      (valores[0], valores[1]),
      if (valores[0] != valores[1]) (valores[1], valores[0]),
    ])
      OpcionAncla(
        ancla: ancla,
        numeroAColocar: otro,
        puedeSeleccionarse: widget.valoresPresentes.contains(ancla),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 330,
          child: LanzamientoDados(
            opciones: _opciones,
            puedeLanzar: !_puedeSaltarTurno,
            puedeSaltarTurno: _puedeSaltarTurno,
            onAnclaSeleccionada: widget.onAnclaSeleccionada,
            onTirada: (valores) {
              widget.onTirada?.call();
              setState(() {
                _opciones = _opcionesDe(valores);
                _puedeSaltarTurno = widget.sinJugadas;
              });
            },
            onSaltarTurno: () {
              widget.onSaltarTurno?.call();
              setState(() => _puedeSaltarTurno = false);
            },
          ),
        ),
      ),
    );
  }
}
