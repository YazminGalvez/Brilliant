import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:juego_brilliant/dados.dart';

void main() {
  const coordenadasIniciales = [(1, 3), (2, 6), (4, 2), (4, 5), (6, 3), (7, 5)];

  Future<void> ingresarNumero(
    WidgetTester tester,
    (int, int) coordenada,
    int numero,
  ) async {
    final casilla = find.byKey(Key('cell-${coordenada.$1}-${coordenada.$2}'));
    await tester.ensureVisible(casilla);
    await tester.pumpAndSettle();
    await tester.tap(casilla);
    await tester.pumpAndSettle();
    await tester.tap(find.text('$numero').last);
    await tester.pumpAndSettle();
  }

  testWidgets('Los números iniciales fueron agregados', (tester) async {
    await tester.pumpWidget(const MainApp());

    for (var index = 0; index < coordenadasIniciales.length; index++) {
      await ingresarNumero(tester, coordenadasIniciales[index], index + 1);
    }

    for (var index = 0; index < coordenadasIniciales.length; index++) {
      final coordenada = coordenadasIniciales[index];
      expect(
        find.descendant(
          of: find.byKey(Key('cell-${coordenada.$1}-${coordenada.$2}')),
          matching: find.text('${index + 1}'),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('Los números iniciales no se repitieron', (tester) async {
    await tester.pumpWidget(const MainApp());
    await ingresarNumero(tester, coordenadasIniciales.first, 1);

    final siguienteCasilla = coordenadasIniciales[1];
    await tester.tap(
      find.byKey(Key('cell-${siguienteCasilla.$1}-${siguienteCasilla.$2}')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(SimpleDialog), matching: find.text('1')),
      findsNothing,
    );
  });

  testWidgets('Los números iniciales están en las coordenadas correctas', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());

    for (var fila = 1; fila <= 7; fila++) {
      for (var columna = 1; columna <= 7; columna++) {
        final coordenada = (fila, columna);
        final esCasillaInicial = coordenadasIniciales.contains(coordenada);
        final casilla = tester.widget<InkWell>(
          find.byKey(Key('cell-$fila-$columna')),
        );

        expect(
          casilla.onTap != null,
          esCasillaInicial,
          reason: 'Casilla ($fila, $columna)',
        );
      }
    }

    expect(find.text('+'), findsNWidgets(coordenadasIniciales.length));
  });

  testWidgets(
    'Inicio se habilita al completar los valores y cambia a jugando',
    (tester) async {
      await tester.pumpWidget(const MainApp());

      FilledButton botonInicio() =>
          tester.widget<FilledButton>(find.byKey(const Key('start-game')));

      expect(botonInicio().onPressed, isNull);
      expect(
        find.text('Faltan números iniciales: ingresa del 1 al 6 sin repetir.'),
        findsOneWidget,
      );

      for (var index = 0; index < coordenadasIniciales.length; index++) {
        await ingresarNumero(tester, coordenadasIniciales[index], index + 1);
      }

      expect(botonInicio().onPressed, isNotNull);
      await tester.ensureVisible(find.byKey(const Key('start-game')));
      await tester.tap(find.byKey(const Key('start-game')));
      await tester.pumpAndSettle();

      expect(find.text('Partida en curso'), findsOneWidget);
      expect(find.byKey(const Key('start-game')), findsNothing);
      expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);
      expect(
        tester.widget<InkWell>(find.byKey(const Key('cell-1-1'))).onTap,
        isNotNull,
      );
      expect(
        tester.widget<InkWell>(find.byKey(const Key('cell-1-3'))).onTap,
        isNull,
      );
    },
  );

  testWidgets('seleccionar ancla marca y permite colocar en destinos válidos', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: TableroPage(random: Random(42))));

    for (var index = 0; index < coordenadasIniciales.length; index++) {
      await ingresarNumero(tester, coordenadasIniciales[index], index + 1);
    }

    final inicio = find.byKey(const Key('start-game'));
    await tester.ensureVisible(inicio);
    await tester.tap(inicio);
    await tester.pumpAndSettle();

    final botonLanzar = find.byKey(const Key('roll-dice-button'));
    await tester.ensureVisible(botonLanzar);
    await tester.tap(botonLanzar);
    await tester.pumpAndSettle();

    final opciones = tester
        .widgetList<OutlinedButton>(find.byType(OutlinedButton))
        .where((opcion) => opcion.onPressed != null)
        .map((opcion) => opcion.key! as ValueKey<String>)
        .toList();
    expect(opciones, isNotEmpty);

    Finder marcadoresValidos() => find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'valid-move-marker-',
          ),
    );

    ValueKey<String>? opcionConDestino;
    for (final opcion in opciones) {
      final botonOpcion = find.byKey(opcion);
      await tester.ensureVisible(botonOpcion);
      await tester.tap(botonOpcion);
      await tester.pumpAndSettle();
      if (marcadoresValidos().evaluate().isNotEmpty) {
        opcionConDestino = opcion;
        break;
      }
    }

    expect(opcionConDestino, isNotNull);
    final marker = tester.widget<Icon>(marcadoresValidos().first);
    final markerKey = marker.key! as ValueKey<String>;
    final partesCoordenada = markerKey.value.split('-');
    final fila = partesCoordenada[3];
    final columna = partesCoordenada[4];
    final celdaDestino = find.byKey(Key('cell-$fila-$columna'));
    final textoOpcion = tester.widget<Text>(
      find.descendant(
        of: find.byKey(opcionConDestino!),
        matching: find.byType(Text),
      ),
    );
    final numeroAColocar = RegExp(
      r'colocar (\d+)',
    ).firstMatch(textoOpcion.data!)!.group(1)!;

    await tester.ensureVisible(celdaDestino);
    await tester.tap(celdaDestino);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: celdaDestino, matching: find.text(numeroAColocar)),
      findsOneWidget,
    );
    expect(marcadoresValidos(), findsNothing);
  });

  testWidgets('confirma una celda y bloquea el ancla hasta lanzar de nuevo', (
    tester,
  ) async {
    final seed = _buscarSemillaParaTirada([4, 6]);
    await tester.pumpWidget(
      MaterialApp(home: TableroPage(random: Random(seed))),
    );

    for (var index = 0; index < coordenadasIniciales.length; index++) {
      await ingresarNumero(tester, coordenadasIniciales[index], index + 1);
    }

    final inicio = find.byKey(const Key('start-game'));
    await tester.ensureVisible(inicio);
    await tester.tap(inicio);
    await tester.pumpAndSettle();

    final botonLanzar = find.byKey(const Key('roll-dice-button'));
    await tester.ensureVisible(botonLanzar);
    await tester.tap(botonLanzar);
    await tester.pumpAndSettle();

    final opcionAnclaCuatro = find.byKey(const Key('anchor-option-4'));
    expect(
      tester.widget<OutlinedButton>(opcionAnclaCuatro).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(opcionAnclaCuatro);
    await tester.tap(opcionAnclaCuatro);
    await tester.pumpAndSettle();

    final destino = find.byKey(const Key('cell-4-4'));
    expect(find.byKey(const Key('valid-move-marker-4-4')), findsOneWidget);
    await tester.ensureVisible(destino);
    await tester.tap(destino);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: destino, matching: find.text('6')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('valid-move-marker-4-4')), findsNothing);
    expect(find.text('Puntuación total: 0'), findsOneWidget);
    expect(find.byKey(const Key('zone-score-0')), findsNothing);
    expect(
      tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .every((opcion) => opcion.onPressed == null),
      isTrue,
    );

    await tester.ensureVisible(botonLanzar);
    await tester.tap(botonLanzar);
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .any((opcion) => opcion.onPressed != null),
      isTrue,
    );
  });
}

int _buscarSemillaParaTirada(List<int> objetivo) {
  for (var semilla = 0; semilla < 10000; semilla++) {
    final tirada = Dados(cantidad: 2, random: Random(semilla)).lanzar();
    if (tirada[0] == objetivo[0] && tirada[1] == objetivo[1]) {
      return semilla;
    }
  }
  throw StateError('No se encontró semilla para la tirada solicitada.');
}
