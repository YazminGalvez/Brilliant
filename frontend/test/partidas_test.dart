import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/cliente_autenticacion.dart';
import 'package:frontend/partidas.dart';
import 'package:http/http.dart' as http;

import 'partidas_de_prueba.dart';

Matcher errorDePartida(String mensaje, {String? codigoServidor}) =>
    isA<ErrorAutenticacion>()
        .having((error) => error.mensaje, 'mensaje', mensaje)
        .having(
          (error) => error.codigoServidor,
          'codigoServidor',
          codigoServidor,
        );

void main() {
  Future<ServicioPartidas> partidasQueResponden(
    http.Response Function(http.Request peticion) responder, {
    List<http.Request>? peticiones,
  }) async {
    final servidor = ServidorDePartidasFalso((peticion) {
      peticiones?.add(peticion);
      return responder(peticion);
    });
    return ServicioPartidas(await servidor.clienteConSesion());
  }

  group('Servicio de partidas', () {
    test(
      'Crear una partida manda el mapa y los jugadores con el token',
      () async {
        final peticiones = <http.Request>[];
        final partidas = await partidasQueResponden(
          (_) => respuestaJson(salaJson(), 201),
          peticiones: peticiones,
        );

        final sala = await partidas.crear(mapa: 2, jugadores: 4);

        final peticion = peticiones.single;
        expect(peticion.method, 'POST');
        expect(peticion.url.toString(), '$servidorDePrueba/api/v1/partidas');
        expect(peticion.headers['Authorization'], 'Bearer token-de-prueba');
        expect(cuerpoDe(peticion), {'mapa': 2, 'jugadores': 4});
        expect(sala.codigo, 'K7M2QX');
      },
    );

    test('Unirse manda el código recortado', () async {
      final peticiones = <http.Request>[];
      final partidas = await partidasQueResponden(
        (_) => respuestaJson(salaJson(), 200),
        peticiones: peticiones,
      );

      await partidas.unirse('  k7m2qx \n');

      final peticion = peticiones.single;
      expect(peticion.method, 'POST');
      expect(peticion.url.path, '/api/v1/partidas/unirse');
      expect(cuerpoDe(peticion), {'codigo': 'k7m2qx'});
    });

    test('Consultar una sala pide su código con GET', () async {
      final peticiones = <http.Request>[];
      final partidas = await partidasQueResponden(
        (_) => respuestaJson(salaJson(), 200),
        peticiones: peticiones,
      );

      await partidas.consultar('K7M2QX');

      expect(peticiones.single.method, 'GET');
      expect(peticiones.single.url.path, '/api/v1/partidas/K7M2QX');
    });

    test('La partida actual es null cuando el servidor responde 204', () async {
      final partidas = await partidasQueResponden(
        (_) => http.Response('', 204),
      );

      expect(await partidas.actual(), isNull);
    });

    test(
      'La partida actual devuelve la sala cuando el usuario está en una',
      () async {
        final peticiones = <http.Request>[];
        final partidas = await partidasQueResponden(
          (_) => respuestaJson(salaJson(ronda: 3, comenzada: true), 200),
          peticiones: peticiones,
        );

        final sala = await partidas.actual();

        expect(peticiones.single.url.path, '/api/v1/partidas/actual');
        expect(sala?.ronda, 3);
        expect(sala?.comenzada, isTrue);
      },
    );
  });

  group('Sala de partida desde JSON', () {
    test('Lee una sala válida y tolera campos nuevos', () {
      final sala = SalaPartida.desdeJson(
        salaJson(
          ronda: 4,
          comenzada: true,
          cambios: {
            'zonas': {
              '3': {'ana': 2, 'luis': 4},
            },
            'puntos': {'ana': 12, 'luis': 6},
            'miTablero': [1, 2, 3, 4, 5, 6],
            'ganadores': ['ana'],
            'terminada': true,
            'motivoFin': 'meta',
            'campoNuevo': 'se ignora',
          },
        ),
      );

      expect(sala.codigo, 'K7M2QX');
      expect(sala.mapa, 2);
      expect(sala.capacidad, 4);
      expect(sala.anfitrion, 'ana');
      expect(sala.jugadores.map((jugador) => jugador.nombre), ['ana', 'luis']);
      expect(sala.jugadores.first.listo, isTrue);
      expect(sala.ronda, 4);
      expect(sala.dados, [3, 5]);
      expect(sala.miTablero, [1, 2, 3, 4, 5, 6]);
      expect(sala.zonas, {
        3: {'ana': 2, 'luis': 4},
      });
      expect(sala.puntos, {'ana': 12, 'luis': 6});
      expect(sala.meta, 26);
      expect(sala.ganadores, ['ana']);
      expect(sala.motivoFin, 'meta');
    });

    test('Dos salas con los mismos datos son iguales', () {
      expect(
        SalaPartida.desdeJson(salaJson()),
        SalaPartida.desdeJson(salaJson()),
      );
      expect(
        SalaPartida.desdeJson(salaJson()),
        isNot(SalaPartida.desdeJson(salaJson(ronda: 1))),
      );
    });

    test('Un campo con el tipo equivocado da respuesta inesperada', () {
      expect(
        () => SalaPartida.desdeJson(salaJson(cambios: {'ronda': 'uno'})),
        throwsA(errorDePartida('Respuesta inesperada del servidor.')),
      );
    });

    test('Un campo que falta da respuesta inesperada', () {
      final incompleta = salaJson()..remove('jugadores');

      expect(
        () => SalaPartida.desdeJson(incompleta),
        throwsA(errorDePartida('Respuesta inesperada del servidor.')),
      );
    });

    test('Un jugador incompleto da respuesta inesperada', () {
      expect(
        () => SalaPartida.desdeJson(
          salaJson(
            cambios: {
              'jugadores': [
                {'nombre': 'ana'},
              ],
            },
          ),
        ),
        throwsA(errorDePartida('Respuesta inesperada del servidor.')),
      );
    });

    test('Una zona con un número de zona inválido da respuesta inesperada', () {
      expect(
        () => SalaPartida.desdeJson(
          salaJson(
            cambios: {
              'zonas': {
                'tres': {'ana': 2},
              },
            },
          ),
        ),
        throwsA(errorDePartida('Respuesta inesperada del servidor.')),
      );
    });

    test(
      'Una respuesta del servidor que no es JSON da respuesta inesperada',
      () async {
        final partidas = await partidasQueResponden(
          (_) => http.Response('<html>error</html>', 200),
        );

        await expectLater(
          partidas.consultar('K7M2QX'),
          throwsA(errorDePartida('Respuesta inesperada del servidor.')),
        );
      },
    );
  });

  group('Errores del servidor de partidas', () {
    Future<void> esperarError(
      http.Response respuesta,
      String mensaje,
      String? codigoServidor,
    ) async {
      final partidas = await partidasQueResponden((_) => respuesta);

      await expectLater(
        partidas.unirse('K7M2QX'),
        throwsA(errorDePartida(mensaje, codigoServidor: codigoServidor)),
      );
    }

    test('PARTIDA_NO_ENCONTRADA dice que la partida ya no existe', () async {
      await esperarError(
        errorDelServidor('PARTIDA_NO_ENCONTRADA', 404),
        'Esa partida ya no existe.',
        'PARTIDA_NO_ENCONTRADA',
      );
    });

    test('PARTIDA_LLENA dice que la partida ya está llena', () async {
      await esperarError(
        errorDelServidor('PARTIDA_LLENA', 409),
        'La partida ya está llena.',
        'PARTIDA_LLENA',
      );
    });

    test('PARTIDA_COMENZADA dice que la partida ya comenzó', () async {
      await esperarError(
        errorDelServidor('PARTIDA_COMENZADA', 409),
        'La partida ya comenzó.',
        'PARTIDA_COMENZADA',
      );
    });

    test('YA_EN_PARTIDA dice que ya estás en una partida en juego', () async {
      await esperarError(
        errorDelServidor('YA_EN_PARTIDA', 409),
        'Ya estás en una partida en juego.',
        'YA_EN_PARTIDA',
      );
    });

    test('MAPA_NO_DISPONIBLE dice que ese mapa no está disponible', () async {
      await esperarError(
        errorDelServidor('MAPA_NO_DISPONIBLE', 400),
        'Ese mapa no está disponible.',
        'MAPA_NO_DISPONIBLE',
      );
    });

    test(
      'DATOS_INVALIDOS dice que los datos de la partida no son válidos',
      () async {
        await esperarError(
          errorDelServidor('DATOS_INVALIDOS', 400),
          'Los datos de la partida no son válidos.',
          'DATOS_INVALIDOS',
        );
      },
    );

    test('DEMASIADOS_INTENTOS usa los segundos de Retry-After', () async {
      await esperarError(
        respuestaJson(
          {'codigo': 'DEMASIADOS_INTENTOS'},
          429,
          cabeceras: {'retry-after': '20'},
        ),
        'Demasiados intentos. Espera 20 segundos e inténtalo de nuevo.',
        'DEMASIADOS_INTENTOS',
      );
    });

    test('Sin conexión usa el mensaje de conexión', () async {
      final partidas = await partidasQueResponden(
        (_) => throw http.ClientException('Connection refused'),
      );

      await expectLater(
        partidas.unirse('K7M2QX'),
        throwsA(errorDePartida(ClienteAutenticacion.mensajeConexion)),
      );
    });

    test(
      'NO_AUTORIZADO dice que la sesión terminó y borra la sesión local',
      () async {
        final servidor = ServidorDePartidasFalso(
          (_) => errorDelServidor('NO_AUTORIZADO', 401),
        );
        final autenticacion = await servidor.clienteConSesion();

        await expectLater(
          ServicioPartidas(autenticacion).consultar('K7M2QX'),
          throwsA(
            errorDePartida(
              'Tu sesión terminó. Inicia sesión de nuevo.',
              codigoServidor: 'NO_AUTORIZADO',
            ),
          ),
        );
        expect(autenticacion.sesion, isNull);
      },
    );

    test(
      'Sin sesión no se llama al servidor y se pide iniciar sesión',
      () async {
        final servidor = ServidorDePartidasFalso(
          (_) => respuestaJson(salaJson(), 200),
        );
        final autenticacion = ClienteAutenticacion(
          servidor: servidorDePrueba,
          cliente: servidor.cliente,
        );

        await expectLater(
          ServicioPartidas(autenticacion).actual(),
          throwsA(
            errorDePartida(
              'Tu sesión terminó. Inicia sesión de nuevo.',
              codigoServidor: 'NO_AUTORIZADO',
            ),
          ),
        );
        expect(servidor.peticiones, isEmpty);
      },
    );
  });

  group('Validación del código de partida', () {
    test('Un código de 6 letras y números es válido aunque tenga espacios', () {
      expect(ServicioPartidas.errorCodigo('K7M2QX'), isNull);
      expect(ServicioPartidas.errorCodigo('  k7m2qx  '), isNull);
    });

    test('Un código de otra longitud dice que tiene 6 caracteres', () {
      expect(
        ServicioPartidas.errorCodigo('K7M2Q'),
        'El código tiene 6 caracteres.',
      );
      expect(
        ServicioPartidas.errorCodigo('K7M2QXY'),
        'El código tiene 6 caracteres.',
      );
      expect(ServicioPartidas.errorCodigo(''), 'El código tiene 6 caracteres.');
    });

    test('Un código con símbolos dice que solo lleva letras y números', () {
      expect(
        ServicioPartidas.errorCodigo('K7-2QX'),
        'El código solo lleva letras y números.',
      );
      expect(
        ServicioPartidas.errorCodigo('K7M2Ñ1'),
        'El código solo lleva letras y números.',
      );
    });
  });
}
