import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/cliente_autenticacion.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const servidorDePrueba = 'http://127.0.0.1:8080';

http.Response respuestaJson(
  Object cuerpo,
  int estado, {
  Map<String, String> cabeceras = const {},
}) => http.Response.bytes(
  utf8.encode(jsonEncode(cuerpo)),
  estado,
  headers: {'content-type': 'application/json', ...cabeceras},
);

http.Response sesionCorrecta({String nombre = 'ana', Object id = 7}) =>
    respuestaJson({
      'token': 'token-de-prueba',
      'tipo': 'Bearer',
      'expiraEnSegundos': 3600,
      'usuario': {'id': id, 'nombre': nombre},
    }, 200);

class ServidorFalso {
  ServidorFalso(this.responder);

  final http.Response Function(http.Request peticion) responder;
  final peticiones = <http.Request>[];

  late final cliente = MockClient((peticion) async {
    peticiones.add(peticion);
    return responder(peticion);
  });

  ClienteAutenticacion crearCliente({String servidor = servidorDePrueba}) =>
      ClienteAutenticacion(servidor: servidor, cliente: cliente);
}

Future<ClienteAutenticacion> clienteConSesion(ServidorFalso servidor) async {
  final cliente = servidor.crearCliente();
  await cliente.iniciarSesion('ana', 'secreta123');
  servidor.peticiones.clear();
  return cliente;
}

http.Response responderConSesion(
  http.Request peticion,
  http.Response Function(http.Request peticion) resto,
) {
  if (peticion.method == 'POST' && peticion.url.path == '/api/v1/sesiones') {
    return sesionCorrecta();
  }
  return resto(peticion);
}

Matcher errorConMensaje(String mensaje, {int? codigo}) =>
    isA<ErrorAutenticacion>()
        .having((error) => error.mensaje, 'mensaje', mensaje)
        .having((error) => error.codigo, 'codigo', codigo);

void main() {
  group('Cliente de autenticación', () {
    test(
      'Iniciar sesión correctamente guarda la sesión y manda el cuerpo JSON esperado',
      () async {
        final servidor = ServidorFalso((_) => sesionCorrecta());
        final cliente = servidor.crearCliente();

        final sesion = await cliente.iniciarSesion('ana', 'secreta123');

        final peticion = servidor.peticiones.single;
        expect(peticion.method, 'POST');
        expect(peticion.url.toString(), '$servidorDePrueba/api/v1/sesiones');
        expect(peticion.headers['Content-Type'], 'application/json');
        expect(jsonDecode(utf8.decode(peticion.bodyBytes)), {
          'nombre': 'ana',
          'contrasena': 'secreta123',
        });
        expect(sesion.token, 'token-de-prueba');
        expect(sesion.idUsuario, '7');
        expect(sesion.nombre, 'ana');
        expect(cliente.sesion, same(sesion));
      },
    );

    test(
      'Con credenciales incorrectas lanza el mensaje de usuario o contraseña incorrectos',
      () async {
        final servidor = ServidorFalso(
          (_) => respuestaJson({'codigo': 'CREDENCIALES_INVALIDAS'}, 401),
        );
        final cliente = servidor.crearCliente();

        await expectLater(
          cliente.iniciarSesion('ana', 'mala'),
          throwsA(
            errorConMensaje('Usuario o contraseña incorrectos.', codigo: 401),
          ),
        );
        expect(cliente.sesion, isNull);
      },
    );

    test(
      'Crear cuenta registra al usuario y después inicia sesión con los mismos datos',
      () async {
        final servidor = ServidorFalso(
          (peticion) => peticion.url.path == '/api/v1/cuentas'
              ? respuestaJson({'id': 7, 'nombre': 'ana'}, 201)
              : sesionCorrecta(),
        );
        final cliente = servidor.crearCliente();

        final sesion = await cliente.crearCuenta('ana', 'secreta123');

        expect(servidor.peticiones.map((peticion) => peticion.url.path), [
          '/api/v1/cuentas',
          '/api/v1/sesiones',
        ]);
        for (final peticion in servidor.peticiones) {
          expect(jsonDecode(utf8.decode(peticion.bodyBytes)), {
            'nombre': 'ana',
            'contrasena': 'secreta123',
          });
        }
        expect(cliente.sesion, same(sesion));
      },
    );

    test(
      'Si la cuenta se crea pero el inicio de sesión falla lo dice con un mensaje claro',
      () async {
        final servidor = ServidorFalso(
          (peticion) => peticion.url.path == '/api/v1/cuentas'
              ? respuestaJson({'id': 7, 'nombre': 'ana'}, 201)
              : respuestaJson({'codigo': 'DEMASIADOS_INTENTOS'}, 429),
        );
        final cliente = servidor.crearCliente();

        await expectLater(
          cliente.crearCuenta('ana', 'secreta123'),
          throwsA(
            errorConMensaje(
              'Cuenta creada, pero no se pudo iniciar sesión. Inicia sesión manualmente.',
              codigo: 429,
            ),
          ),
        );
        expect(cliente.sesion, isNull);
      },
    );

    test(
      'Crear una cuenta con un nombre en uso lanza el mensaje de nombre en uso',
      () async {
        final servidor = ServidorFalso(
          (_) => respuestaJson({'codigo': 'NOMBRE_EN_USO'}, 409),
        );

        await expectLater(
          servidor.crearCliente().crearCuenta('ana', 'secreta123'),
          throwsA(
            errorConMensaje(
              'Ese nombre de usuario ya está en uso.',
              codigo: 409,
            ),
          ),
        );
        expect(servidor.peticiones, hasLength(1));
      },
    );

    test(
      'Crear una cuenta con datos inválidos lanza el mensaje de revisar los datos',
      () async {
        final servidor = ServidorFalso(
          (_) => respuestaJson({'codigo': 'NOMBRE_INVALIDO'}, 400),
        );

        await expectLater(
          servidor.crearCliente().crearCuenta('a', 'corta'),
          throwsA(
            errorConMensaje(
              'Revisa los datos: el usuario debe tener de 3 a 32 caracteres y la contraseña de 8 a 128.',
              codigo: 400,
            ),
          ),
        );
      },
    );

    test(
      'Demasiados intentos usa los segundos de la cabecera Retry-After',
      () async {
        final servidor = ServidorFalso(
          (_) => respuestaJson(
            {'codigo': 'DEMASIADOS_INTENTOS'},
            429,
            cabeceras: {'retry-after': '30'},
          ),
        );

        await expectLater(
          servidor.crearCliente().iniciarSesion('ana', 'secreta123'),
          throwsA(
            errorConMensaje(
              'Demasiados intentos. Espera 30 segundos e inténtalo de nuevo.',
              codigo: 429,
            ),
          ),
        );
      },
    );

    test(
      'Demasiados intentos sin Retry-After pide esperar unos minutos',
      () async {
        final servidor = ServidorFalso(
          (_) => respuestaJson({'codigo': 'DEMASIADOS_INTENTOS'}, 429),
        );

        await expectLater(
          servidor.crearCliente().iniciarSesion('ana', 'secreta123'),
          throwsA(
            errorConMensaje(
              'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.',
              codigo: 429,
            ),
          ),
        );
      },
    );

    test('Cerrar sesión manda el token y borra la sesión local', () async {
      final servidor = ServidorFalso(
        (peticion) =>
            responderConSesion(peticion, (_) => http.Response('', 204)),
      );
      final cliente = await clienteConSesion(servidor);

      await cliente.cerrarSesion();

      final peticion = servidor.peticiones.single;
      expect(peticion.method, 'DELETE');
      expect(peticion.url.path, '/api/v1/sesiones/actual');
      expect(peticion.headers['Authorization'], 'Bearer token-de-prueba');
      expect(cliente.sesion, isNull);
    });

    test(
      'Cerrar una sesión que el servidor ya no reconoce no es un error',
      () async {
        final servidor = ServidorFalso(
          (peticion) => responderConSesion(
            peticion,
            (_) => respuestaJson({'codigo': 'NO_AUTORIZADO'}, 401),
          ),
        );
        final cliente = await clienteConSesion(servidor);

        await cliente.cerrarSesion();

        expect(cliente.sesion, isNull);
      },
    );

    test('Cerrar sesión borra la sesión local aunque falle la red', () async {
      var sinRed = false;
      final servidor = ServidorFalso((peticion) {
        if (sinRed) throw http.ClientException('Connection refused');
        return sesionCorrecta();
      });
      final cliente = await clienteConSesion(servidor);
      sinRed = true;

      await expectLater(
        cliente.cerrarSesion(),
        throwsA(errorConMensaje(ClienteAutenticacion.mensajeConexion)),
      );
      expect(cliente.sesion, isNull);
    });

    test(
      'Borrar la cuenta manda el token y la contraseña y borra la sesión local',
      () async {
        final servidor = ServidorFalso(
          (peticion) =>
              responderConSesion(peticion, (_) => http.Response('', 204)),
        );
        final cliente = await clienteConSesion(servidor);

        await cliente.borrarCuenta('secreta123');

        final peticion = servidor.peticiones.single;
        expect(peticion.method, 'DELETE');
        expect(peticion.url.path, '/api/v1/cuentas/yo');
        expect(peticion.headers['Authorization'], 'Bearer token-de-prueba');
        expect(peticion.headers['Content-Type'], 'application/json');
        expect(jsonDecode(utf8.decode(peticion.bodyBytes)), {
          'contrasena': 'secreta123',
        });
        expect(cliente.sesion, isNull);
      },
    );

    test(
      'Borrar la cuenta con una contraseña incorrecta conserva la sesión',
      () async {
        final servidor = ServidorFalso(
          (peticion) => responderConSesion(
            peticion,
            (_) => respuestaJson({'codigo': 'CREDENCIALES_INVALIDAS'}, 401),
          ),
        );
        final cliente = await clienteConSesion(servidor);
        final sesion = cliente.sesion;

        await expectLater(
          cliente.borrarCuenta('mala'),
          throwsA(errorConMensaje('Contraseña incorrecta.', codigo: 401)),
        );
        expect(cliente.sesion, same(sesion));
      },
    );

    test(
      'Borrar la cuenta con la sesión vencida avisa y borra la sesión local',
      () async {
        final servidor = ServidorFalso(
          (peticion) => responderConSesion(
            peticion,
            (_) => respuestaJson({'codigo': 'NO_AUTORIZADO'}, 401),
          ),
        );
        final cliente = await clienteConSesion(servidor);

        await expectLater(
          cliente.borrarCuenta('secreta123'),
          throwsA(
            errorConMensaje(
              'Tu sesión terminó. Inicia sesión de nuevo.',
              codigo: 401,
            ),
          ),
        );
        expect(cliente.sesion, isNull);
      },
    );

    test('Sin conexión con el servidor lanza el mensaje de conexión', () async {
      final servidor = ServidorFalso(
        (_) =>
            throw http.ClientException('SocketException: Connection refused'),
      );

      await expectLater(
        servidor.crearCliente().iniciarSesion('ana', 'secreta123'),
        throwsA(
          errorConMensaje(
            'No se pudo conectar con el servidor. Revisa que esté encendido y que la dirección sea correcta.',
          ),
        ),
      );
    });

    test(
      'Una dirección de servidor inválida lanza el mensaje de conexión',
      () async {
        final servidor = ServidorFalso((_) => sesionCorrecta());
        final cliente = servidor.crearCliente(servidor: 'http://[no válida');

        await expectLater(
          cliente.iniciarSesion('ana', 'secreta123'),
          throwsA(errorConMensaje(ClienteAutenticacion.mensajeConexion)),
        );
        expect(servidor.peticiones, isEmpty);
      },
    );

    test(
      'Un error del servidor sin código conocido no muestra el texto técnico',
      () async {
        final servidor = ServidorFalso(
          (_) => respuestaJson({
            'codigo': 'ERROR_INTERNO',
            'detalle': 'NullPointerException en ServicioCuentas',
          }, 500),
        );

        await expectLater(
          servidor.crearCliente().iniciarSesion('ana', 'secreta123'),
          throwsA(
            errorConMensaje(
              'Ocurrió un error inesperado. Inténtalo de nuevo.',
              codigo: 500,
            ),
          ),
        );
      },
    );

    test(
      'Sin sesión local sesionActiva devuelve false sin llamar al servidor',
      () async {
        final servidor = ServidorFalso((_) => respuestaJson({}, 200));

        expect(await servidor.crearCliente().sesionActiva(), isFalse);
        expect(servidor.peticiones, isEmpty);
      },
    );

    test(
      'sesionActiva devuelve true cuando el servidor reconoce el token',
      () async {
        final servidor = ServidorFalso(
          (peticion) => responderConSesion(
            peticion,
            (_) => respuestaJson({'id': 7, 'nombre': 'ana'}, 200),
          ),
        );
        final cliente = await clienteConSesion(servidor);

        expect(await cliente.sesionActiva(), isTrue);
        final peticion = servidor.peticiones.single;
        expect(peticion.method, 'GET');
        expect(peticion.url.path, '/api/v1/cuentas/yo');
        expect(peticion.headers['Authorization'], 'Bearer token-de-prueba');
        expect(cliente.sesion, isNotNull);
      },
    );

    test(
      'sesionActiva devuelve false y borra la sesión local cuando el servidor responde 401',
      () async {
        final servidor = ServidorFalso(
          (peticion) => responderConSesion(
            peticion,
            (_) => respuestaJson({'codigo': 'NO_AUTORIZADO'}, 401),
          ),
        );
        final cliente = await clienteConSesion(servidor);

        expect(await cliente.sesionActiva(), isFalse);
        expect(cliente.sesion, isNull);
      },
    );

    test(
      'sesionActiva lanza el mensaje de conexión si falla la red y conserva la sesión',
      () async {
        var sinRed = false;
        final servidor = ServidorFalso((peticion) {
          if (sinRed) throw http.ClientException('Connection refused');
          return sesionCorrecta();
        });
        final cliente = await clienteConSesion(servidor);
        sinRed = true;

        await expectLater(
          cliente.sesionActiva(),
          throwsA(errorConMensaje(ClienteAutenticacion.mensajeConexion)),
        );
        expect(cliente.sesion, isNotNull);
      },
    );

    test('Los acentos y la eñe de las respuestas se leen bien', () async {
      final servidor = ServidorFalso(
        (_) => sesionCorrecta(nombre: 'Yazmín_Ñandú'),
      );

      final sesion = await servidor.crearCliente().iniciarSesion(
        'Yazmín_Ñandú',
        'secreta123',
      );

      expect(sesion.nombre, 'Yazmín_Ñandú');
    });

    test(
      'La barra final y los espacios de la dirección no rompen la ruta',
      () async {
        final servidor = ServidorFalso((_) => sesionCorrecta());
        final cliente = servidor.crearCliente(
          servidor: '  http://127.0.0.1:8080/  ',
        );

        await cliente.iniciarSesion('ana', 'secreta123');

        expect(cliente.servidor, servidorDePrueba);
        expect(
          servidor.peticiones.single.url.toString(),
          '$servidorDePrueba/api/v1/sesiones',
        );
      },
    );

    testWidgets(
      'Si el servidor tarda más de 10 segundos lanza el mensaje de conexión',
      (tester) async {
        final cliente = ClienteAutenticacion(
          servidor: servidorDePrueba,
          cliente: MockClient((_) => Completer<http.Response>().future),
        );

        final resultado = cliente
            .iniciarSesion('ana', 'secreta123')
            .then<Object?>((_) => null, onError: (Object error) => error);
        await tester.pump(const Duration(seconds: 9));
        var terminado = false;
        unawaited(resultado.whenComplete(() => terminado = true));
        await tester.pump();
        expect(terminado, isFalse);

        await tester.pump(const Duration(seconds: 2));

        expect(
          await resultado,
          errorConMensaje(ClienteAutenticacion.mensajeConexion),
        );
        expect(cliente.sesion, isNull);
      },
    );

    test('Sin dirección indicada usa el servidor por defecto', () {
      final cliente = ClienteAutenticacion(
        cliente: MockClient((_) async => http.Response('', 204)),
      );

      expect(cliente.servidor, servidorPorDefecto());
    });
  });
}
