import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/seleccion_mapa.dart';
import 'package:juego_brilliant/mapa_dos.dart';
import 'package:juego_brilliant/mapa_uno.dart';

import '../helpers.dart';

void main() {
  group('Widgets: selección de mapa', () {
    final textoMenu = find.text('Elige tu mapa');
    final botonInicio = find.byKey(const Key('start-game'));

    Finder opcion(int numero) => find.byKey(Key('map-option-$numero'));

    Finder celdaDeVista(int indice, [int mapa = 1]) => find.descendant(
      of: opcion(mapa),
      matching: find.byKey(Key('map-preview-cell-$indice')),
    );

    Finder celdasDeVistaEn(Finder tarjeta) => find.descendant(
      of: tarjeta,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'map-preview-cell-',
            ),
      ),
    );

    Color? colorDeCeldaDeVista(
      WidgetTester tester,
      int indice, [
      int mapa = 1,
    ]) =>
        (tester.widget<Container>(celdaDeVista(indice, mapa)).decoration
                as BoxDecoration)
            .color;

    void comprobarMapaBloqueado(WidgetTester tester, int numero) {
      expect(
        find.descendant(
          of: opcion(numero),
          matching: find.text('Próximamente'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: opcion(numero),
          matching: find.text('Muy pronto podrás jugarlo.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: opcion(numero),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(celdasDeVistaEn(opcion(numero)), findsNothing);
      expect(tester.widget<InkWell>(opcion(numero)).onTap, isNull);
    }

    Future<void> abrirAplicacion(WidgetTester tester) async {
      await tester.pumpWidget(const MainApp());
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Al abrir la app se ve el menú con las cuatro tarjetas de mapa',
      (tester) async {
        await abrirAplicacion(tester);

        expect(find.byType(SeleccionMapaPage), findsOneWidget);
        expect(find.byType(TableroPage), findsNothing);
        expect(textoMenu, findsOneWidget);
        expect(opcion(1), findsOneWidget);
        expect(opcion(2), findsOneWidget);
        expect(opcion(3), findsOneWidget);
        expect(opcion(4), findsOneWidget);
        expect(opcion(5), findsNothing);
        expect(find.text('Mapa 1'), findsOneWidget);
        expect(find.text('Mapa 2'), findsOneWidget);
        expect(find.text('Mapa 3'), findsOneWidget);
        expect(find.text('Mapa 4'), findsOneWidget);
      },
    );

    testWidgets(
      'El menú muestra el título, la indicación y la explicación del juego',
      (tester) async {
        await abrirMenuDeMapas(tester);

        expect(find.text('Brilliant'), findsOneWidget);
        expect(textoMenu, findsOneWidget);
        expect(find.text('Cómo se juega'), findsOneWidget);
      },
    );

    testWidgets(
      'El Mapa 1 aparece disponible con una vista previa de 49 celdas con sus colores',
      (tester) async {
        await abrirMenuDeMapas(tester);

        expect(
          find.descendant(of: opcion(1), matching: find.text('Disponible')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: opcion(1),
            matching: find.byIcon(Icons.arrow_forward),
          ),
          findsOneWidget,
        );
        expect(celdasDeVistaEn(opcion(1)), findsNWidgets(49));
        expect(celdaDeVista(48), findsOneWidget);
        expect(celdaDeVista(49), findsNothing);
        for (var indice = 0; indice < 49; indice++) {
          expect(
            colorDeCeldaDeVista(tester, indice),
            colorDeZona(mapaUno.colorEn(indice ~/ 7, indice % 7)),
            reason: 'celda $indice',
          );
        }
      },
    );

    testWidgets(
      'El Mapa 2 aparece disponible con una vista previa de 49 celdas con sus colores',
      (tester) async {
        await abrirMenuDeMapas(tester);

        expect(
          find.descendant(of: opcion(2), matching: find.text('Disponible')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: opcion(2), matching: find.text('Próximamente')),
          findsNothing,
        );
        expect(tester.widget<InkWell>(opcion(2)).onTap, isNotNull);
        expect(celdasDeVistaEn(opcion(2)), findsNWidgets(49));
        for (var indice = 0; indice < 49; indice++) {
          expect(
            colorDeCeldaDeVista(tester, indice, 2),
            colorDeZona(mapaDos.colorEn(indice ~/ 7, indice % 7)),
            reason: 'celda $indice',
          );
        }
      },
    );

    testWidgets(
      'El Mapa 3 aparece próximamente con candado y sin vista previa',
      (tester) async {
        await abrirMenuDeMapas(tester);

        comprobarMapaBloqueado(tester, 3);
      },
    );

    testWidgets(
      'El Mapa 4 aparece próximamente con candado y sin vista previa',
      (tester) async {
        await abrirMenuDeMapas(tester);

        comprobarMapaBloqueado(tester, 4);
      },
    );

    testWidgets(
      'La lista del menú tiene cuatro mapas y solo los dos primeros están habilitados',
      (tester) async {
        expect(mapasDelMenu, hasLength(4));
        expect(mapasDelMenu.first, same(mapaUno));
        expect(mapasDelMenu[1], same(mapaDos));
        expect(mapasDelMenu.skip(2), everyElement(isNull));
      },
    );

    testWidgets(
      'Tocar el Mapa 1 abre el tablero con una partida nueva en preparación',
      (tester) async {
        await abrirAplicacion(tester);

        await tocar(tester, opcion(1));

        expect(find.byType(TableroPage), findsOneWidget);
        expect(botonInicio, findsOneWidget);
        expect(find.text('Inicio'), findsOneWidget);
        expect(textoMenu, findsNothing);
        expect(
          find.text('Ingresa los números iniciales del 1 al 6'),
          findsOneWidget,
        );
        expect(find.text('+'), findsNWidgets(6));
      },
    );

    testWidgets(
      'Tocar el Mapa 2 abre el tablero con las celdas iniciales del Mapa 2',
      (tester) async {
        await abrirAplicacion(tester);

        await tocar(tester, opcion(2));

        expect(find.byType(TableroPage), findsOneWidget);
        expect(botonInicio, findsOneWidget);
        expect(textoMenu, findsNothing);
        expect(find.text('+'), findsNWidgets(6));
        for (final (fila, columna) in mapaDos.celdasIniciales) {
          expect(
            find.descendant(
              of: find.byKey(Key('cell-$fila-$columna')),
              matching: find.text('+'),
            ),
            findsOneWidget,
            reason: 'celda ($fila, $columna)',
          );
        }
      },
    );

    testWidgets('Tocar un mapa bloqueado no abre nada', (tester) async {
      await abrirAplicacion(tester);

      await tocar(tester, opcion(3));

      expect(find.byType(SeleccionMapaPage), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);
      expect(textoMenu, findsOneWidget);
      expect(botonInicio, findsNothing);
    });

    testWidgets(
      'Las tarjetas anuncian si el mapa está disponible o bloqueado',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await abrirMenuDeMapas(tester);

        expect(find.bySemanticsLabel('Mapa 1, disponible'), findsOneWidget);
        expect(find.bySemanticsLabel('Mapa 2, disponible'), findsOneWidget);
        expect(find.bySemanticsLabel('Mapa 3, bloqueado'), findsOneWidget);
        expect(find.bySemanticsLabel('Mapa 4, bloqueado'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets(
      'En pantalla angosta de 360 px el menú y el tablero no se desbordan',
      (tester) async {
        usarTamanoDePantalla(tester, const Size(360, 800));

        await abrirAplicacion(tester);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(opcion(1)).width, lessThanOrEqualTo(360));

        await tocar(tester, opcion(1));
        expect(tester.takeException(), isNull);
        expect(botonInicio, findsOneWidget);
      },
    );

    testWidgets(
      'En pantalla ancha el menú queda centrado de 560 px como máximo y el tablero no se desborda',
      (tester) async {
        usarTamanoDePantalla(tester, const Size(1400, 1000));

        await abrirAplicacion(tester);
        expect(tester.takeException(), isNull);
        final tarjeta = tester.getRect(opcion(1));
        expect(tarjeta.width, lessThanOrEqualTo(560));
        expect(tarjeta.center.dx, moreOrLessEquals(700, epsilon: 1));

        await tocar(tester, opcion(1));
        expect(tester.takeException(), isNull);
        expect(botonInicio, findsOneWidget);
      },
    );
  });
}
