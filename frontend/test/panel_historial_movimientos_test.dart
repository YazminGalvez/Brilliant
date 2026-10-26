import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/panel_historial_movimientos.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/historial_movimientos.dart';

void main() {
  String nombreDeZona(int idZona) => idZona == 4 ? 'Verde' : 'Amarilla';

  group('describirMovimiento', () {
    test('describe una colocación con fila y columna desde 1', () {
      final colocacion = RegistroMovimiento.colocacion(
        numero: 1,
        numeroTirada: 3,
        ancla: 1,
        numeroColocado: 4,
        fila: 1,
        columna: 4,
      );

      expect(
        describirMovimiento(colocacion, nombreDeZona),
        'Tirada 3: colocaste el 4 en fila 2, columna 5 (ancla 1)',
      );
    });

    test('describe un salto de turno', () {
      expect(
        describirMovimiento(
          RegistroMovimiento.saltoTurno(numero: 1, numeroTirada: 3),
          nombreDeZona,
        ),
        'Tirada 3: saltaste el turno',
      );
    });

    test('describe una zona completada con su nombre', () {
      expect(
        describirMovimiento(
          RegistroMovimiento.zonaCompletada(
            numero: 1,
            numeroTirada: 3,
            idZona: 4,
            color: ColorZona.verde,
          ),
          nombreDeZona,
        ),
        'Tirada 3: completaste la zona verde',
      );
    });

    test('describe los puntos en plural y en singular', () {
      expect(
        describirMovimiento(
          RegistroMovimiento.puntosGanados(
            numero: 1,
            numeroTirada: 3,
            puntos: 4,
          ),
          nombreDeZona,
        ),
        'Tirada 3: ganaste 4 puntos',
      );
      expect(
        describirMovimiento(
          RegistroMovimiento.puntosGanados(
            numero: 1,
            numeroTirada: 3,
            puntos: 1,
          ),
          nombreDeZona,
        ),
        'Tirada 3: ganaste 1 punto',
      );
    });
  });

  group('PanelHistorialMovimientos', () {
    Future<void> mostrarPanel(
      WidgetTester tester,
      HistorialMovimientos historial,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelHistorialMovimientos(
            historial: historial,
            nombreDeZona: nombreDeZona,
          ),
        ),
      ),
    );

    testWidgets('muestra un aviso cuando está vacío', (tester) async {
      await mostrarPanel(tester, HistorialMovimientos());

      expect(find.byKey(const Key('movement-history-panel')), findsOneWidget);
      expect(find.text('Historial de movimientos'), findsOneWidget);
      expect(find.byKey(const Key('movement-history-empty')), findsOneWidget);
      expect(find.text('Aún no hay movimientos.'), findsOneWidget);
      expect(find.byKey(const Key('movement-history-list')), findsNothing);
    });

    testWidgets('muestra los movimientos con el más reciente arriba', (
      tester,
    ) async {
      final historial = HistorialMovimientos()
        ..registrarJugada(
          numeroTirada: 1,
          ancla: 2,
          numeroColocado: 3,
          fila: 0,
          columna: 1,
        )
        ..registrarSaltoTurno(numeroTirada: 2)
        ..registrarPuntosGanados(numeroTirada: 3, puntos: 7);

      await mostrarPanel(tester, historial);

      expect(find.byKey(const Key('movement-history-empty')), findsNothing);
      final items = find.descendant(
        of: find.byKey(const Key('movement-history-list')),
        matching: find.byType(ListTile),
      );
      expect(items, findsNWidgets(3));
      expect(
        tester
            .widgetList<ListTile>(items)
            .map((item) => (item.key! as ValueKey<String>).value),
        [
          'movement-history-item-3',
          'movement-history-item-2',
          'movement-history-item-1',
        ],
      );
      expect(find.text('Tirada 3: ganaste 7 puntos'), findsOneWidget);
      expect(find.text('Tirada 2: saltaste el turno'), findsOneWidget);
      expect(
        find.text('Tirada 1: colocaste el 3 en fila 1, columna 2 (ancla 2)'),
        findsOneWidget,
      );
    });
  });
}
