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
  FutureOr<SalaPartida> Function(AvisoTurno aviso) alTerminarTurno = (aviso) =>
      salaConJugadores([
        jugador('ana', jugoRonda: true),
        jugador('luis'),
      ], ronda: aviso.ronda);
  final tablerosEnviados = <List<int>>[];
  final turnosAvisados = <AvisoTurno>[];

  @override
  Future<SalaPartida> consultar(String codigo) async => alConsultar(codigo);

  @override
  Future<SalaPartida> enviarTablero(String codigo, List<int> numeros) async {
    tablerosEnviados.add(numeros);
    return alEnviarTablero(numeros);
  }

  @override
  Future<SalaPartida> terminarTurno(
    String codigo,
    int ronda, {
    required bool tableroLleno,
    int? zona,
  }) async {
    final aviso = AvisoTurno(
      ronda: ronda,
      tableroLleno: tableroLleno,
      zona: zona,
    );
    turnosAvisados.add(aviso);
    return alTerminarTurno(aviso);
  }
}

Map<String, Object?> jugador(
  String nombre, {
  bool tableroListo = false,
  bool concedio = false,
  bool jugoRonda = false,
}) => {
  'nombre': nombre,
  'listo': true,
  'tableroListo': tableroListo,
  'conectado': true,
  'concedio': concedio,
  'jugoRonda': jugoRonda,
};

SalaPartida salaConJugadores(
  List<Map<String, Object?>> jugadores, {
  List<int> miTablero = const [],
  int ronda = 0,
  bool terminada = false,
}) => SalaPartida.desdeJson(
  salaJson(
    comenzada: true,
    ronda: ronda,
    cambios: {
      'jugadores': jugadores,
      'miTablero': miTablero,
      'terminada': terminada,
    },
  ),
);

SalaPartida rondaDeAnaYLuis(int ronda, {bool anaJugo = false}) =>
    salaConJugadores([
      jugador('ana', tableroListo: true, jugoRonda: anaJugo),
      jugador('luis', tableroListo: true),
    ], ronda: ronda);

const errorDeConexion = ErrorAutenticacion(
  'No se pudo conectar con el servidor.',
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

  group('Puedo jugar la ronda', () {
    test('No se juega antes de la primera ronda', () {
      final compartida = compartidaCon(rondaDeAnaYLuis(0));

      expect(compartida.resultado, isNull);
      expect(compartida.puedoJugarRonda, isFalse);
      expect(compartida.esperandoALosDemas, isFalse);
    });

    test('En una ronda con dados y sin haber jugado se puede jugar', () {
      final compartida = compartidaCon(rondaDeAnaYLuis(1));

      expect(compartida.resultado, [3, 5]);
      expect(compartida.puedoJugarRonda, isTrue);
      expect(compartida.esperandoALosDemas, isFalse);
    });

    test('Si el servidor dice que ya jugué la ronda no se puede jugar', () {
      final compartida = compartidaCon(rondaDeAnaYLuis(1, anaJugo: true));

      expect(compartida.puedoJugarRonda, isFalse);
      expect(compartida.esperandoALosDemas, isTrue);
    });

    test('Una partida terminada no se puede jugar', () {
      final compartida = compartidaCon(
        salaConJugadores([jugador('ana')], ronda: 5, terminada: true),
      );

      expect(compartida.puedoJugarRonda, isFalse);
    });

    test('Quien concedió no puede jugar la ronda', () {
      final compartida = compartidaCon(
        salaConJugadores([jugador('ana', concedio: true)], ronda: 2),
      );

      expect(compartida.puedoJugarRonda, isFalse);
    });
  });

  group('Aviso de turno', () {
    test('Avisa la ronda en curso con la zona y el tablero lleno', () async {
      final compartida = compartidaCon(rondaDeAnaYLuis(2));

      compartida.terminarTurno(tableroLleno: false, zona: 4);
      await pumpEventQueue();

      final aviso = partidas.turnosAvisados.single;
      expect(aviso.ronda, 2);
      expect(aviso.tableroLleno, isFalse);
      expect(aviso.zona, 4);
      expect(compartida.avisoPendiente, isNull);
      expect(compartida.puedoJugarRonda, isFalse);
    });

    test('Mientras se envía el aviso ya no se puede jugar la ronda', () async {
      final espera = Completer<SalaPartida>();
      partidas.alTerminarTurno = (_) => espera.future;
      final compartida = compartidaCon(rondaDeAnaYLuis(1));

      compartida.terminarTurno(tableroLleno: false);

      expect(compartida.avisoPendiente?.ronda, 1);
      expect(compartida.puedoJugarRonda, isFalse);
      expect(compartida.esperandoALosDemas, isTrue);
      espera.complete(rondaDeAnaYLuis(1, anaJugo: true));
      await pumpEventQueue();
      expect(compartida.avisoPendiente, isNull);
    });

    test('No avisa dos veces la misma ronda', () async {
      final compartida = compartidaCon(rondaDeAnaYLuis(3));

      compartida.terminarTurno(tableroLleno: false);
      compartida.terminarTurno(tableroLleno: false, zona: 2);
      await pumpEventQueue();
      compartida.terminarTurno(tableroLleno: true);
      await pumpEventQueue();

      expect(partidas.turnosAvisados, hasLength(1));
      expect(partidas.turnosAvisados.single.zona, isNull);
    });

    test(
      'Aunque la respuesta traiga la misma ronda sin marcar, no repite el aviso',
      () async {
        partidas.alTerminarTurno = (_) => rondaDeAnaYLuis(3);
        final compartida = compartidaCon(rondaDeAnaYLuis(3));

        compartida.terminarTurno(tableroLleno: false);
        await pumpEventQueue();
        compartida.terminarTurno(tableroLleno: false);
        await pumpEventQueue();

        expect(partidas.turnosAvisados, hasLength(1));
        expect(compartida.puedoJugarRonda, isFalse);
      },
    );

    test('En la ronda siguiente se puede volver a jugar y avisar', () async {
      partidas.alTerminarTurno = (aviso) => rondaDeAnaYLuis(aviso.ronda + 1);
      final compartida = compartidaCon(rondaDeAnaYLuis(1));

      compartida.terminarTurno(tableroLleno: false);
      await pumpEventQueue();

      expect(compartida.sala.ronda, 2);
      expect(compartida.puedoJugarRonda, isTrue);
      compartida.terminarTurno(tableroLleno: false);
      await pumpEventQueue();
      expect(partidas.turnosAvisados.map((aviso) => aviso.ronda), [1, 2]);
    });

    test('Con el tablero lleno ya no se juegan más rondas', () async {
      partidas.alTerminarTurno = (aviso) => rondaDeAnaYLuis(aviso.ronda + 1);
      final compartida = compartidaCon(rondaDeAnaYLuis(6));

      compartida.terminarTurno(tableroLleno: true, zona: 1);
      await pumpEventQueue();

      expect(compartida.sala.ronda, 7);
      expect(compartida.puedoJugarRonda, isFalse);
    });

    testWidgets('Si el aviso falla por la red lo reintenta hasta que llega', (
      tester,
    ) async {
      var fallos = 2;
      partidas.alTerminarTurno = (aviso) {
        if (fallos > 0) {
          fallos--;
          throw errorDeConexion;
        }
        return rondaDeAnaYLuis(aviso.ronda + 1);
      };
      final compartida = PartidaCompartida(
        partidas: partidas,
        salaInicial: rondaDeAnaYLuis(1),
      );

      compartida.terminarTurno(tableroLleno: false, zona: 3);
      await tester.pump();

      expect(partidas.turnosAvisados, hasLength(1));
      expect(compartida.avisoPendiente?.ronda, 1);
      expect(compartida.errorTurno, errorDeConexion);
      expect(compartida.puedoJugarRonda, isFalse);

      await tester.pump(const Duration(seconds: 2));
      expect(partidas.turnosAvisados, hasLength(2));
      expect(compartida.avisoPendiente, isNotNull);

      await tester.pump(const Duration(seconds: 2));
      expect(partidas.turnosAvisados, hasLength(3));
      expect(partidas.turnosAvisados.every((aviso) => aviso.zona == 3), isTrue);
      expect(compartida.avisoPendiente, isNull);
      expect(compartida.errorTurno, isNull);
      expect(compartida.sala.ronda, 2);

      await tester.pump(const Duration(seconds: 10));
      expect(partidas.turnosAvisados, hasLength(3));
      compartida.dispose();
    });

    testWidgets('Si la sala ya muestra que jugué, deja de reintentar', (
      tester,
    ) async {
      partidas.alTerminarTurno = (_) => throw errorDeConexion;
      partidas.alConsultar = (_) => rondaDeAnaYLuis(1, anaJugo: true);
      final compartida = PartidaCompartida(
        partidas: partidas,
        salaInicial: rondaDeAnaYLuis(1),
        intervalo: const Duration(seconds: 1),
        esperaReintento: const Duration(seconds: 5),
      )..iniciar();

      compartida.terminarTurno(tableroLleno: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(compartida.avisoPendiente, isNull);
      await tester.pump(const Duration(seconds: 10));
      expect(partidas.turnosAvisados, hasLength(1));
      expect(compartida.puedoJugarRonda, isFalse);
      compartida.dispose();
    });

    testWidgets(
      'Un rechazo del servidor no se da por enviado ni se repite solo',
      (tester) async {
        partidas.alTerminarTurno = (_) => throw const ErrorAutenticacion(
          'Los datos de la partida no son válidos.',
          codigo: 400,
          codigoServidor: 'DATOS_INVALIDOS',
        );
        final compartida = PartidaCompartida(
          partidas: partidas,
          salaInicial: rondaDeAnaYLuis(1),
        );

        compartida.terminarTurno(tableroLleno: false, zona: 99);
        await tester.pump();
        await tester.pump(const Duration(seconds: 10));

        expect(partidas.turnosAvisados, hasLength(1));
        expect(compartida.avisoPendiente?.ronda, 1);
        expect(compartida.errorTurno?.codigoServidor, 'DATOS_INVALIDOS');
        compartida.dispose();
      },
    );

    test('Si la partida ya no existe al avisar queda cerrada', () async {
      partidas.alTerminarTurno = (_) => throw const ErrorAutenticacion(
        'Esa partida ya no existe.',
        codigo: 404,
        codigoServidor: 'PARTIDA_NO_ENCONTRADA',
      );
      final compartida = compartidaCon(rondaDeAnaYLuis(1));

      compartida.terminarTurno(tableroLleno: false);
      await pumpEventQueue();

      expect(compartida.cerrada, isTrue);
      expect(compartida.puedoJugarRonda, isFalse);
    });
  });

  group('Puntos de la partida compartida', () {
    SalaPartida salaConPuntos({
      int ronda = 2,
      Map<String, int> puntos = const {'ana': 0, 'luis': 0},
      Map<String, Object?> zonas = const {},
      bool terminada = false,
      List<String> ganadores = const [],
      String? motivoFin,
    }) => SalaPartida.desdeJson(
      salaJson(
        comenzada: true,
        ronda: ronda,
        cambios: {
          'jugadores': [
            jugador('ana', tableroListo: true),
            jugador('luis', tableroListo: true),
          ],
          'puntos': puntos,
          'zonas': zonas,
          'terminada': terminada,
          'ganadores': ganadores,
          'motivoFin': motivoFin,
        },
      ),
    );

    test('Los puntos vienen de la sala y quien no tiene puntos lleva 0', () {
      final compartida = compartidaCon(
        salaConPuntos(puntos: const {'luis': 7}),
      );

      expect(compartida.puntos, {'ana': 0, 'luis': 7});
    });

    test(
      'Mi zona completada suma puntos antes de que el servidor la registre',
      () async {
        final espera = Completer<SalaPartida>();
        partidas.alTerminarTurno = (_) => espera.future;
        final compartida = compartidaCon(salaConPuntos());

        compartida.terminarTurno(tableroLleno: false, zona: 1);

        expect(compartida.puntos['ana'], 6);
        expect(compartida.puntos['luis'], 0);
        espera.complete(salaConPuntos());
        await pumpEventQueue();
        expect(compartida.puntos['ana'], 6);
      },
    );

    test(
      'Si otro completó antes la misma zona, mis puntos son los del segundo lugar',
      () {
        final compartida = compartidaCon(
          salaConPuntos(
            puntos: const {'ana': 0, 'luis': 6},
            zonas: const {
              '1': {'luis': 1},
            },
          ),
        );
        partidas.alTerminarTurno = (_) => Completer<SalaPartida>().future;

        compartida.terminarTurno(tableroLleno: false, zona: 1);

        expect(compartida.puntos, {'ana': 4, 'luis': 6});
      },
    );

    test('Cuando el servidor registra mi zona se usan sus puntos', () async {
      partidas.alTerminarTurno = (_) => salaConPuntos(
        ronda: 3,
        puntos: const {'ana': 9, 'luis': 0},
        zonas: const {
          '1': {'ana': 2},
        },
      );
      final compartida = compartidaCon(salaConPuntos());

      compartida.terminarTurno(tableroLleno: false, zona: 1);
      await pumpEventQueue();

      expect(compartida.puntos['ana'], 9);
    });

    test('La clasificación ordena de más a menos puntos', () {
      final compartida = compartidaCon(
        salaConPuntos(puntos: const {'ana': 4, 'luis': 11}),
      );

      expect(compartida.clasificacion.map((entrada) => entrada.key), [
        'luis',
        'ana',
      ]);
    });
  });

  group('Fin de la partida compartida', () {
    SalaPartida salaTerminada(List<String> ganadores, String motivo) =>
        SalaPartida.desdeJson(
          salaJson(
            comenzada: true,
            ronda: 8,
            cambios: {
              'jugadores': [jugador('ana'), jugador('luis')],
              'terminada': true,
              'puntos': {'ana': 26, 'luis': 20},
              'ganadores': ganadores,
              'motivoFin': motivo,
            },
          ),
        );

    test('Antes de terminar no se gana', () {
      final compartida = compartidaCon(rondaDeAnaYLuis(3));

      expect(compartida.terminada, isFalse);
      expect(compartida.gane, isFalse);
    });

    test('Si estoy entre los ganadores, gané', () {
      final compartida = compartidaCon(salaTerminada(['ana'], 'meta'));

      expect(compartida.terminada, isTrue);
      expect(compartida.gane, isTrue);
      expect(compartida.puedoJugarRonda, isFalse);
      expect(compartida.esperandoALosDemas, isFalse);
    });

    test('En un empate todos los ganadores ganan', () {
      final compartida = compartidaCon(
        salaTerminada(['luis', 'ana'], 'sin_tableros'),
      );

      expect(compartida.gane, isTrue);
    });

    test('Si gana otro, no gané', () {
      final compartida = compartidaCon(salaTerminada(['luis'], 'meta'));

      expect(compartida.gane, isFalse);
    });

    testWidgets(
      'Al llegar la sala terminada deja de consultar y de reintentar',
      (tester) async {
        partidas.alTerminarTurno = (_) => throw errorDeConexion;
        partidas.alConsultar = (_) => salaTerminada(['ana'], 'meta');
        final compartida = PartidaCompartida(
          partidas: partidas,
          salaInicial: rondaDeAnaYLuis(4),
        )..iniciar();

        compartida.terminarTurno(tableroLleno: false);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));

        expect(compartida.terminada, isTrue);
        expect(compartida.gane, isTrue);
        expect(compartida.activa, isFalse);
        expect(compartida.avisoPendiente, isNull);
        final avisos = partidas.turnosAvisados.length;
        await tester.pump(const Duration(seconds: 10));
        expect(partidas.turnosAvisados, hasLength(avisos));
        compartida.dispose();
      },
    );
  });

  test('El mapa de la sala es el mapa disponible con ese número', () {
    final sala = salaConJugadores([jugador('ana')]);

    expect(mapaDeLaSala(sala), same(mapaDos));
  });
}
