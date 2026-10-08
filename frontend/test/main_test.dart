import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

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
}
