import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/lanzamiento_dados.dart';
import 'package:juego_brilliant/validador_anclas.dart';

void main() {
  testWidgets('muestra las opciones deshabilitadas si no hay anclas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LanzamientoDados(valoresPresentes: {})),
      ),
    );

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
      MaterialApp(
        home: Scaffold(
          body: LanzamientoDados(
            valoresPresentes: {1, 2, 3, 4, 5, 6},
            onAnclaSeleccionada: (opcion) => seleccionada = opcion,
          ),
        ),
      ),
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
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LanzamientoDados(
            valoresPresentes: {1, 2, 3, 4, 5, 6},
            puedeSaltarTurno: false,
          ),
        ),
      ),
    );

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
      _AnfitrionSinJugadas(onSaltarTurno: () => saltos++),
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
            valoresPresentes: const {1, 2, 3, 4, 5, 6},
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
          body: LanzamientoDados(
            valoresPresentes: const {1, 2, 3, 4, 5, 6},
            onTirada: (_) => tiradas++,
          ),
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
      _AnfitrionSinJugadas(onTirada: () => tiradas++),
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
}

class _AnfitrionSinJugadas extends StatefulWidget {
  const _AnfitrionSinJugadas({this.onTirada, this.onSaltarTurno});

  final VoidCallback? onTirada;
  final VoidCallback? onSaltarTurno;

  @override
  State<_AnfitrionSinJugadas> createState() => _AnfitrionSinJugadasState();
}

class _AnfitrionSinJugadasState extends State<_AnfitrionSinJugadas> {
  bool _puedeSaltarTurno = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 330,
          child: LanzamientoDados(
            valoresPresentes: const {1, 2, 3, 4, 5, 6},
            puedeSaltarTurno: _puedeSaltarTurno,
            onTirada: (_) {
              widget.onTirada?.call();
              setState(() => _puedeSaltarTurno = true);
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
