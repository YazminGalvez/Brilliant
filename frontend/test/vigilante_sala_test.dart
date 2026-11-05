import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/vigilante_sala.dart';
import 'package:http/http.dart' as http;

import 'partidas_de_prueba.dart';

class _Avisos {
  final cambios = <SalaPartida>[];
  int cierres = 0;
}

void main() {
  group('Vigilante de la sala', () {
    Future<(VigilanteSala, ServidorDePartidasFalso, _Avisos)> vigilar(
      FutureOr<http.Response> Function(http.Request peticion) responder,
    ) async {
      final servidor = ServidorDePartidasFalso(responder);
      final partidas = ServicioPartidas(await servidor.clienteConSesion());
      final avisos = _Avisos();
      final vigilante = VigilanteSala(
        partidas: partidas,
        codigo: 'K7M2QX',
        alCambiar: avisos.cambios.add,
        alCerrar: () => avisos.cierres++,
      )..iniciar();
      return (vigilante, servidor, avisos);
    }

    testWidgets('Consulta la sala cada 2 segundos y avisa solo cuando cambia', (
      tester,
    ) async {
      var ronda = 0;
      final (vigilante, servidor, avisos) = await vigilar(
        (_) => respuestaJson(salaJson(ronda: ronda), 200),
      );

      await tester.pump(const Duration(milliseconds: 1999));
      expect(servidor.peticiones, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(servidor.peticiones, hasLength(1));
      expect(servidor.peticiones.single.url.path, '/api/v1/partidas/K7M2QX');
      expect(avisos.cambios.map((sala) => sala.ronda), [0]);

      await tester.pump(const Duration(seconds: 2));
      expect(servidor.peticiones, hasLength(2));
      expect(avisos.cambios, hasLength(1));

      ronda = 1;
      await tester.pump(const Duration(seconds: 2));
      expect(servidor.peticiones, hasLength(3));
      expect(avisos.cambios.map((sala) => sala.ronda), [0, 1]);
      vigilante.detener();
    });

    testWidgets(
      'No empieza otra consulta mientras la anterior sigue sin responder',
      (tester) async {
        final respuesta = Completer<http.Response>();
        final (vigilante, servidor, avisos) = await vigilar(
          (_) => respuesta.future,
        );

        await tester.pump(const Duration(seconds: 7));
        expect(servidor.peticiones, hasLength(1));

        respuesta.complete(respuestaJson(salaJson(), 200));
        await tester.pump();
        expect(avisos.cambios, hasLength(1));

        await tester.pump(const Duration(seconds: 1));
        expect(servidor.peticiones, hasLength(2));
        vigilante.detener();
      },
    );

    testWidgets('Ignora los errores de conexión y sigue consultando', (
      tester,
    ) async {
      var fallos = 2;
      final (vigilante, servidor, avisos) = await vigilar((_) {
        if (fallos > 0) {
          fallos--;
          throw http.ClientException('Connection refused');
        }
        return respuestaJson(salaJson(), 200);
      });

      await tester.pump(const Duration(seconds: 4));
      expect(servidor.peticiones, hasLength(2));
      expect(avisos.cambios, isEmpty);
      expect(avisos.cierres, 0);

      await tester.pump(const Duration(seconds: 2));
      expect(avisos.cambios, hasLength(1));
      expect(avisos.cierres, 0);
      vigilante.detener();
    });

    testWidgets(
      'Avisa el cierre cuando la partida ya no existe y deja de consultar',
      (tester) async {
        final (vigilante, servidor, avisos) = await vigilar(
          (_) => errorDelServidor('PARTIDA_NO_ENCONTRADA', 404),
        );

        await tester.pump(const Duration(seconds: 2));
        expect(avisos.cierres, 1);
        expect(vigilante.activo, isFalse);

        await tester.pump(const Duration(seconds: 6));
        expect(servidor.peticiones, hasLength(1));
        expect(avisos.cierres, 1);
      },
    );

    testWidgets('Otros errores del servidor no cierran la sala', (
      tester,
    ) async {
      final (vigilante, _, avisos) = await vigilar(
        (_) => errorDelServidor('DEMASIADOS_INTENTOS', 429),
      );

      await tester.pump(const Duration(seconds: 4));

      expect(avisos.cierres, 0);
      expect(vigilante.activo, isTrue);
      vigilante.detener();
    });

    testWidgets('Detener el vigilante corta las consultas', (tester) async {
      final (vigilante, servidor, _) = await vigilar(
        (_) => respuestaJson(salaJson(), 200),
      );

      await tester.pump(const Duration(seconds: 2));
      vigilante.detener();
      await tester.pump(const Duration(seconds: 6));

      expect(servidor.peticiones, hasLength(1));
    });
  });
}
