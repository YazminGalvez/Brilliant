import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Widgets: dados fijos y ayudas de la pantalla', () {
    testWidgets('Los dos dados de la pantalla muestran la tirada fijada', (
      tester,
    ) async {
      await abrirPartida(
        tester,
        partidaEnJuego(),
        random: DadosFijos([3, 5]),
      );

      await lanzarDados(tester);

      expect(find.text('Dado 1: 3'), findsOneWidget);
      expect(find.text('Dado 2: 5'), findsOneWidget);
      expect(find.byKey(const Key('die-face-3')), findsOneWidget);
      expect(find.byKey(const Key('die-face-5')), findsOneWidget);
    });

    testWidgets('Una pantalla nueva muestra el botón Inicio', (tester) async {
      await abrirPantallaNueva(tester);

      expect(find.byKey(const Key('start-game')), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
    });
  });
}
