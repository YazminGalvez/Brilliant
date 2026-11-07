import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/partida_compartida.dart';
import 'package:frontend/partidas.dart';
import 'package:juego_brilliant/mapa_dos.dart';

import 'partidas_de_prueba.dart';

class AutenticacionDeAna implements ServicioAutenticacion {
  @override
  SesionUsuario? get sesion =>
      const SesionUsuario(token: 't', idUsuario: '1', nombre: 'ana');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PartidasFalsas extends ServicioPartidas {
  PartidasFalsas() : super(AutenticacionDeAna());

  FutureOr<SalaPartida> Function(String codigo) alConsultar = (_) =>
      SalaPartida.desdeJson(salaJson(comenzada: true));
  FutureOr<SalaPartida> Function(List<int> numeros) alEnviarTablero = (_) =>
      SalaPartida.desdeJson(salaJson(comenzada: true));
  final tablerosEnviados = <List<int>>[];

  @override
  Future<SalaPartida> consultar(String codigo) async => alConsultar(codigo);

  @override
  Future<SalaPartida> enviarTablero(String codigo, List<int> numeros) async {
    tablerosEnviados.add(numeros);
    return alEnviarTablero(numeros);
  }
}

Map<String, Object?> jugador(
  String nombre, {
  bool tableroListo = false,
  bool concedio = false,
}) => {
  'nombre': nombre,
  'listo': true,
  'tableroListo': tableroListo,
  'conectado': true,
  'concedio': concedio,
  'jugoRonda': false,
};

SalaPartida salaConJugadores(
  List<Map<String, Object?>> jugadores, {
  List<int> miTablero = const [],
}) => SalaPartida.desdeJson(
  salaJson(
    comenzada: true,
    cambios: {'jugadores': jugadores, 'miTablero': miTablero},
  ),
);

void main() {
  late PartidasFalsas partidas;

  setUp(() => partidas = PartidasFalsas());

  PartidaCompartida compartidaCon(SalaPartida sala) {
    final compartida = PartidaCompartida(partidas: partidas, salaInicial: sala);
    addTearDown(compartida.dispose);
    return compartida;
  }

  group('Estado de la partida compartida', () {
    test('Empieza con la sala inicial y sin haber finalizado el tablero', () {
      final sala = salaConJugadores([jugador('ana'), jugador('luis')]);
      final compartida = compartidaCon(sala);

      expect(compartida.sala, sala);
      expect(compartida.miNombre, 'ana');
      expect(compartida.yaFinalice, isFalse);
      expect(compartida.todosTerminaron, isFalse);
      expect(compartida.cerrada, isFalse);
      expect(compartida.error, isNull);
    });

    test(
      'yaFinalice es verdadero cuando mi jugador tiene el tablero listo',
      () {
        final compartida = compartidaCon(
          salaConJugadores([
            jugador('ana', tableroListo: true),
            jugador('luis'),
          ]),
        );

        expect(compartida.yaFinalice, isTrue);
        expect(compartida.todosTerminaron, isFalse);
      },
    );

    test('yaFinalice es verdadero si la sala ya trae mi tablero', () {
      final compartida = compartidaCon(
        salaConJugadores(
          [jugador('ana'), jugador('luis')],
          miTablero: [1, 2, 3, 4, 5, 6],
        ),
      );

      expect(compartida.yaFinalice, isTrue);
    });

    test('todosTerminaron cuando todos tienen el tablero listo', () {
      final compartida = compartidaCon(
        salaConJugadores([
          jugador('ana', tableroListo: true),
          jugador('luis', tableroListo: true),
        ]),
      );

      expect(compartida.todosTerminaron, isTrue);
    });

    test('Quien concedió no cuenta para que todos terminen', () {
      final compartida = compartidaCon(
        salaConJugadores([
          jugador('ana', tableroListo: true),
          jugador('luis', concedio: true),
        ]),
      );

      expect(compartida.jugadoresEnJuego.map((j) => j.nombre), ['ana']);
      expect(compartida.todosTerminaron, isTrue);
    });
  });

  group('Enviar el tablero', () {
    test(
      'Envía los números y guarda la sala que responde el servidor',
      () async {
        final respuesta = salaConJugadores(
          [jugador('ana', tableroListo: true), jugador('luis')],
          miTablero: [6, 5, 4, 3, 2, 1],
        );
        partidas.alEnviarTablero = (_) => respuesta;
        final compartida = compartidaCon(
          salaConJugadores([jugador('ana'), jugador('luis')]),
        );
        var avisos = 0;
        compartida.addListener(() => avisos++);

        final enviado = await compartida.enviarTablero([6, 5, 4, 3, 2, 1]);

        expect(enviado, isTrue);
        expect(partidas.tablerosEnviados, [
          [6, 5, 4, 3, 2, 1],
        ]);
        expect(compartida.sala, respuesta);
        expect(compartida.yaFinalice, isTrue);
        expect(compartida.enviando, isFalse);
        expect(avisos, 2);
      },
    );

    test(
      'No envía el tablero dos veces mientras espera la respuesta',
      () async {
        final espera = Completer<SalaPartida>();
        partidas.alEnviarTablero = (_) => espera.future;
        final compartida = compartidaCon(
          salaConJugadores([jugador('ana'), jugador('luis')]),
        );

        final primero = compartida.enviarTablero([1, 2, 3, 4, 5, 6]);
        final segundo = await compartida.enviarTablero([1, 2, 3, 4, 5, 6]);

        expect(compartida.enviando, isTrue);
        expect(segundo, isFalse);
        espera.complete(salaConJugadores([jugador('ana', tableroListo: true)]));
        expect(await primero, isTrue);
        expect(partidas.tablerosEnviados, hasLength(1));
      },
    );

    test(
      'Un error del servidor se guarda y se puede volver a intentar',
      () async {
        partidas.alEnviarTablero = (_) => throw const ErrorAutenticacion(
          'Los datos de la partida no son válidos.',
          codigo: 400,
          codigoServidor: 'DATOS_INVALIDOS',
        );
        final compartida = compartidaCon(
          salaConJugadores([jugador('ana'), jugador('luis')]),
        );

        final enviado = await compartida.enviarTablero([1, 1, 1, 1, 1, 1]);

        expect(enviado, isFalse);
        expect(compartida.error?.codigoServidor, 'DATOS_INVALIDOS');
        expect(compartida.enviando, isFalse);
        expect(compartida.cerrada, isFalse);

        partidas.alEnviarTablero = (_) =>
            salaConJugadores([jugador('ana', tableroListo: true)]);
        expect(await compartida.enviarTablero([1, 2, 3, 4, 5, 6]), isTrue);
        expect(compartida.error, isNull);
      },
    );

    test('Si la partida ya no existe queda cerrada', () async {
      partidas.alEnviarTablero = (_) => throw const ErrorAutenticacion(
        'Esa partida ya no existe.',
        codigo: 404,
        codigoServidor: 'PARTIDA_NO_ENCONTRADA',
      );
      final compartida = compartidaCon(
        salaConJugadores([jugador('ana'), jugador('luis')]),
      );

      await compartida.enviarTablero([1, 2, 3, 4, 5, 6]);

      expect(compartida.cerrada, isTrue);
      expect(await compartida.enviarTablero([1, 2, 3, 4, 5, 6]), isFalse);
      expect(partidas.tablerosEnviados, hasLength(1));
    });
  });

  group('Vigilancia de la partida compartida', () {
    testWidgets('Avisa cuando llega una sala nueva y sabe quién finalizó', (
      tester,
    ) async {
      partidas.alConsultar = (_) => salaConJugadores([
        jugador('ana'),
        jugador('luis', tableroListo: true),
      ]);
      final compartida = PartidaCompartida(
        partidas: partidas,
        salaInicial: salaConJugadores([jugador('ana'), jugador('luis')]),
      );
      var avisos = 0;
      compartida
        ..addListener(() => avisos++)
        ..iniciar();

      await tester.pump(const Duration(seconds: 2));

      expect(avisos, 1);
      expect(compartida.sala.jugadores.last.tableroListo, isTrue);
      expect(compartida.yaFinalice, isFalse);
      compartida.dispose();
    });

    testWidgets('Un fallo de conexión no cambia la sala ni la cierra', (
      tester,
    ) async {
      partidas.alConsultar = (_) => throw const ErrorAutenticacion(
        'No se pudo conectar con el servidor.',
      );
      final sala = salaConJugadores([jugador('ana'), jugador('luis')]);
      final compartida = PartidaCompartida(
        partidas: partidas,
        salaInicial: sala,
      )..iniciar();

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(compartida.sala, sala);
      expect(compartida.cerrada, isFalse);
      expect(compartida.activa, isTrue);
      compartida.dispose();
    });

    testWidgets('Si la sala desaparece queda cerrada y deja de consultar', (
      tester,
    ) async {
      partidas.alConsultar = (_) => throw const ErrorAutenticacion(
        'Esa partida ya no existe.',
        codigo: 404,
        codigoServidor: 'PARTIDA_NO_ENCONTRADA',
      );
      final compartida = PartidaCompartida(
        partidas: partidas,
        salaInicial: salaConJugadores([jugador('ana'), jugador('luis')]),
      )..iniciar();

      await tester.pump(const Duration(seconds: 2));

      expect(compartida.cerrada, isTrue);
      expect(compartida.activa, isFalse);
      compartida.dispose();
    });
  });

  test('El mapa de la sala es el mapa disponible con ese número', () {
    final sala = salaConJugadores([jugador('ana')]);

    expect(mapaDeLaSala(sala), same(mapaDos));
  });
}
