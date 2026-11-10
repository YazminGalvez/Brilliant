import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/direccion_servidor.dart';
import 'package:frontend/inicio_sesion.dart';
import 'package:frontend/main.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/registro.dart';
import 'package:frontend/seleccion_mapa.dart';
import 'package:frontend/vigilante_sesion.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class ServicioFalso extends ServicioAutenticacion {
  ServicioFalso({SesionUsuario? sesion}) : _sesion = sesion;

  @override
  String servidor = 'http://127.0.0.1:8080';

  SesionUsuario? _sesion;

  final iniciosDeSesion = <(String, String)>[];
  final cuentasCreadas = <(String, String)>[];
  final contrasenasDeBorrado = <String>[];
  int cierresDeSesion = 0;
  int revisionesDeSesion = 0;

  ErrorAutenticacion? errorAlIniciar;
  ErrorAutenticacion? errorAlCrear;
  ErrorAutenticacion? errorAlBorrar;
  ErrorAutenticacion? errorAlRevisar;
  bool sesionSigueActiva = true;
  Completer<void>? esperaAlIniciar;
  bool hayConexion = true;
  Completer<void>? esperaAlProbar;
  final direccionesProbadas = <String>[];

  @override
  Future<bool> probarConexion() async {
    direccionesProbadas.add(servidor);
    await esperaAlProbar?.future;
    return hayConexion;
  }

  @override
  SesionUsuario? get sesion => _sesion;

  SesionUsuario _iniciar(String nombre) => _sesion = SesionUsuario(
    token: 'token-falso',
    idUsuario: '1',
    nombre: nombre,
  );

  @override
  Future<SesionUsuario> iniciarSesion(String nombre, String contrasena) async {
    iniciosDeSesion.add((nombre, contrasena));
    await esperaAlIniciar?.future;
    final error = errorAlIniciar;
    if (error != null) throw error;
    return _iniciar(nombre);
  }

  @override
  Future<SesionUsuario> crearCuenta(String nombre, String contrasena) async {
    cuentasCreadas.add((nombre, contrasena));
    final error = errorAlCrear;
    if (error != null) throw error;
    return _iniciar(nombre);
  }

  @override
  Future<void> cerrarSesion() async {
    cierresDeSesion++;
    _sesion = null;
  }

  @override
  Future<void> borrarCuenta(String contrasena) async {
    contrasenasDeBorrado.add(contrasena);
    final error = errorAlBorrar;
    if (error != null) throw error;
    _sesion = null;
  }

  @override
  Future<bool> sesionActiva() async {
    revisionesDeSesion++;
    final error = errorAlRevisar;
    if (error != null) throw error;
    return sesionSigueActiva;
  }

  @override
  Future<Map<String, Object?>?> enviarConSesion(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
  }) => throw UnsupportedError('Las pruebas de cuenta no usan partidas.');
}

const sesionDeAna = SesionUsuario(
  token: 'token-falso',
  idUsuario: '1',
  nombre: 'ana',
);

final campoUsuario = find.byKey(const Key('login-usuario'));
final campoContrasena = find.byKey(const Key('login-contrasena'));
final campoServidor = find.byKey(const Key('login-servidor'));
final botonEntrar = find.byKey(const Key('login-entrar'));
final errorDeInicio = find.byKey(const Key('login-error'));
final botonCrearCuenta = find.byKey(const Key('login-crear-cuenta'));
final menuDeMapas = find.byType(SeleccionMapaPage);
final pantallaDeInicio = find.byType(InicioSesionPage);
final botonCuenta = find.byKey(const Key('menu-cuenta'));

String textoDe(WidgetTester tester, Finder campo) => tester
    .widget<EditableText>(
      find.descendant(of: campo, matching: find.byType(EditableText)),
    )
    .controller
    .text;

Future<void> abrirJuego(WidgetTester tester, ServicioFalso servicio) async {
  await tester.pumpWidget(MainApp(servicio: servicio));
  await tester.pumpAndSettle();
}

Future<void> entrar(
  WidgetTester tester, {
  String usuario = 'ana',
  String contrasena = 'secreta123',
}) async {
  await tester.enterText(campoUsuario, usuario);
  await tester.enterText(campoContrasena, contrasena);
  await tocar(tester, botonEntrar);
}

Future<void> abrirRegistro(WidgetTester tester, ServicioFalso servicio) async {
  await abrirJuego(tester, servicio);
  await tocar(tester, botonCrearCuenta);
}

Future<void> abrirMenuConCuenta(
  WidgetTester tester,
  ServicioFalso servicio, {
  Duration intervalo = const Duration(minutes: 5),
}) async {
  void volverAlInicio(NavigatorState navegador, {String? aviso}) {
    navegador.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => InicioSesionPage(
          servicio: servicio,
          siguiente: (_) => const SeleccionMapaPage(),
          aviso: aviso,
        ),
      ),
      (_) => false,
    );
  }

  await tester.pumpWidget(
    ProveedorAutenticacion(
      servicio: servicio,
      volverAlInicio: volverAlInicio,
      child: MaterialApp(
        home: VigilanteSesion(
          servicio: servicio,
          intervalo: intervalo,
          alPerderSesion: (context) => volverAlInicio(
            Navigator.of(context),
            aviso: VigilanteSesion.avisoSesionPerdida,
          ),
          child: const SeleccionMapaPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> elegirEnMenuDeCuenta(WidgetTester tester, String key) async {
  await tocar(tester, botonCuenta);
  await tocar(tester, find.byKey(Key(key)));
}

void main() {
  group('Widgets: inicio de sesión', () {
    testWidgets(
      'Sin sesión el juego abre en el inicio de sesión y no se puede elegir mapa',
      (tester) async {
        await abrirJuego(tester, ServicioFalso());

        expect(pantallaDeInicio, findsOneWidget);
        expect(find.text('Inicia sesión'), findsOneWidget);
        expect(menuDeMapas, findsNothing);
        expect(find.byKey(const Key('map-option-1')), findsNothing);
      },
    );

    testWidgets(
      'Con usuario y contraseña correctos se entra al menú de mapas',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirJuego(tester, servicio);

        await entrar(tester);

        expect(servicio.iniciosDeSesion, [('ana', 'secreta123')]);
        expect(menuDeMapas, findsOneWidget);
        expect(pantallaDeInicio, findsNothing);
        expect(botonCuenta, findsOneWidget);
      },
    );

    testWidgets(
      'Con credenciales incorrectas se muestra el mensaje del servicio y se vacía la contraseña',
      (tester) async {
        final servicio = ServicioFalso()
          ..errorAlIniciar = const ErrorAutenticacion(
            'Usuario o contraseña incorrectos.',
            codigo: 401,
          );
        await abrirJuego(tester, servicio);

        await entrar(tester, contrasena: 'equivocada');

        expect(
          tester.widget<SelectableText>(errorDeInicio).data,
          'Usuario o contraseña incorrectos.',
        );
        expect(textoDe(tester, campoContrasena), isEmpty);
        expect(textoDe(tester, campoUsuario), 'ana');
        expect(menuDeMapas, findsNothing);
      },
    );

    testWidgets('Con los campos vacíos se avisa sin llamar al servicio', (
      tester,
    ) async {
      final servicio = ServicioFalso();
      await abrirJuego(tester, servicio);

      await tocar(tester, botonEntrar);

      expect(find.text('Escribe tu usuario.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);
      expect(servicio.iniciosDeSesion, isEmpty);
    });

    testWidgets(
      'La dirección escrita en el apartado Servidor se guarda en el servicio',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirJuego(tester, servicio);

        await tocar(tester, find.text('Servidor'));
        await tester.enterText(campoServidor, 'http://192.168.1.20:8080');
        await entrar(tester);

        expect(servicio.servidor, 'http://192.168.1.20:8080');
        expect(menuDeMapas, findsOneWidget);
      },
    );

    testWidgets(
      'Una dirección sin http:// ni https:// se rechaza sin llamar al servicio',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirJuego(tester, servicio);

        await tocar(tester, find.text('Servidor'));
        await tester.enterText(campoServidor, '127.0.0.1:8080');
        await entrar(tester);

        expect(
          find.descendant(
            of: campoServidor,
            matching: find.text('Debe empezar por http:// o https://'),
          ),
          findsOneWidget,
        );
        expect(servicio.servidor, 'http://127.0.0.1:8080');
        expect(servicio.iniciosDeSesion, isEmpty);
      },
    );

    testWidgets(
      'Mientras se envía el botón Entrar queda deshabilitado con un indicador',
      (tester) async {
        final espera = Completer<void>();
        final servicio = ServicioFalso()..esperaAlIniciar = espera;
        await abrirJuego(tester, servicio);
        await tester.enterText(campoUsuario, 'ana');
        await tester.enterText(campoContrasena, 'secreta123');

        await tester.tap(botonEntrar);
        await tester.pump();

        expect(tester.widget<FilledButton>(botonEntrar).onPressed, isNull);
        expect(
          find.descendant(
            of: botonEntrar,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );

        espera.complete();
        await tester.pumpAndSettle();

        expect(menuDeMapas, findsOneWidget);
      },
    );

    testWidgets('El botón para crear cuenta abre la pantalla de registro', (
      tester,
    ) async {
      await abrirJuego(tester, ServicioFalso());

      await tocar(tester, botonCrearCuenta);

      expect(find.byType(RegistroPage), findsOneWidget);
      expect(find.text('Crea tu cuenta'), findsOneWidget);
    });
  });

  group('Widgets: registro', () {
    final campoUsuarioNuevo = find.byKey(const Key('registro-usuario'));
    final campoContrasenaNueva = find.byKey(const Key('registro-contrasena'));
    final campoRepetir = find.byKey(const Key('registro-repetir'));
    final botonCrear = find.byKey(const Key('registro-crear'));

    Future<void> llenarRegistro(
      WidgetTester tester, {
      String usuario = 'ana_nueva',
      String contrasena = 'secreta123',
      String? repetida,
    }) async {
      await tester.enterText(campoUsuarioNuevo, usuario);
      await tester.enterText(campoContrasenaNueva, contrasena);
      await tester.enterText(campoRepetir, repetida ?? contrasena);
      await tocar(tester, botonCrear);
    }

    testWidgets('Crear una cuenta válida entra directo al menú de mapas', (
      tester,
    ) async {
      final servicio = ServicioFalso();
      await abrirRegistro(tester, servicio);

      await llenarRegistro(tester);

      expect(servicio.cuentasCreadas, [('ana_nueva', 'secreta123')]);
      expect(menuDeMapas, findsOneWidget);
      expect(Navigator.of(tester.element(menuDeMapas)).canPop(), isFalse);
    });

    testWidgets('Un usuario ocupado muestra el mensaje del servicio', (
      tester,
    ) async {
      final servicio = ServicioFalso()
        ..errorAlCrear = const ErrorAutenticacion(
          'Ese nombre de usuario ya está en uso.',
          codigo: 409,
        );
      await abrirRegistro(tester, servicio);

      await llenarRegistro(tester);

      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('registro-error')))
            .data,
        'Ese nombre de usuario ya está en uso.',
      );
      expect(textoDe(tester, campoContrasenaNueva), isEmpty);
      expect(textoDe(tester, campoRepetir), isEmpty);
      expect(menuDeMapas, findsNothing);
    });

    testWidgets('Un usuario demasiado corto se avisa sin llamar al servicio', (
      tester,
    ) async {
      final servicio = ServicioFalso();
      await abrirRegistro(tester, servicio);

      await llenarRegistro(tester, usuario: 'ab');

      expect(
        find.text('El usuario debe tener de 3 a 32 caracteres.'),
        findsOneWidget,
      );
      expect(servicio.cuentasCreadas, isEmpty);
    });

    testWidgets(
      'Una contraseña demasiado corta se avisa sin llamar al servicio',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirRegistro(tester, servicio);

        await llenarRegistro(tester, contrasena: 'corta');

        expect(
          find.text('La contraseña debe tener de 8 a 128 caracteres.'),
          findsOneWidget,
        );
        expect(servicio.cuentasCreadas, isEmpty);
      },
    );

    testWidgets('Contraseñas distintas se avisan sin llamar al servicio', (
      tester,
    ) async {
      final servicio = ServicioFalso();
      await abrirRegistro(tester, servicio);

      await llenarRegistro(tester, repetida: 'secreta124');

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(servicio.cuentasCreadas, isEmpty);
    });

    testWidgets('La flecha de regreso vuelve al inicio de sesión', (
      tester,
    ) async {
      await abrirRegistro(tester, ServicioFalso());

      await tocar(tester, find.byType(BackButton));

      expect(find.byType(RegistroPage), findsNothing);
      expect(pantallaDeInicio, findsOneWidget);
    });
  });

  group('Widgets: cuenta', () {
    final campoBorrar = find.byKey(const Key('borrar-contrasena'));
    final botonBorrar = find.byKey(const Key('borrar-confirmar'));

    ServicioFalso servicioConSesion() => ServicioFalso(sesion: sesionDeAna);

    testWidgets(
      'El botón de cuenta muestra la sesión, cerrar sesión y borrar cuenta',
      (tester) async {
        await abrirMenuConCuenta(tester, servicioConSesion());

        await tocar(tester, botonCuenta);

        expect(find.text('Sesión: ana'), findsOneWidget);
        expect(find.byKey(const Key('cuenta-cerrar-sesion')), findsOneWidget);
        expect(find.byKey(const Key('cuenta-borrar')), findsOneWidget);
        expect(find.text('Cerrar sesión'), findsOneWidget);
        expect(find.text('Borrar cuenta'), findsOneWidget);
      },
    );

    testWidgets(
      'Cerrar sesión pide confirmación y vuelve al inicio con el aviso de sesión cerrada',
      (tester) async {
        final servicio = servicioConSesion();
        await abrirMenuConCuenta(tester, servicio);

        await elegirEnMenuDeCuenta(tester, 'cuenta-cerrar-sesion');

        expect(find.text('¿Quieres cerrar la sesión de ana?'), findsOneWidget);
        expect(servicio.cierresDeSesion, 0);

        await tocar(tester, find.byKey(const Key('cerrar-confirmar')));

        expect(servicio.cierresDeSesion, 1);
        expect(servicio.sesion, isNull);
        expect(pantallaDeInicio, findsOneWidget);
        expect(find.text('Sesión cerrada.'), findsOneWidget);
        expect(menuDeMapas, findsNothing);
      },
    );

    testWidgets('Cancelar el cierre de sesión mantiene la sesión y el menú', (
      tester,
    ) async {
      final servicio = servicioConSesion();
      await abrirMenuConCuenta(tester, servicio);

      await elegirEnMenuDeCuenta(tester, 'cuenta-cerrar-sesion');
      await tocar(tester, find.text('Cancelar'));

      expect(servicio.cierresDeSesion, 0);
      expect(servicio.sesion, same(sesionDeAna));
      expect(find.byType(AlertDialog), findsNothing);
      expect(menuDeMapas, findsOneWidget);
    });

    testWidgets(
      'Borrar la cuenta con la contraseña correcta vuelve al inicio con el aviso de cuenta eliminada',
      (tester) async {
        final servicio = servicioConSesion();
        await abrirMenuConCuenta(tester, servicio);

        await elegirEnMenuDeCuenta(tester, 'cuenta-borrar');
        await tester.enterText(campoBorrar, 'secreta123');
        await tocar(tester, botonBorrar);

        expect(servicio.contrasenasDeBorrado, ['secreta123']);
        expect(find.byType(AlertDialog), findsNothing);
        expect(pantallaDeInicio, findsOneWidget);
        expect(find.text('Cuenta eliminada.'), findsOneWidget);
      },
    );

    testWidgets(
      'Borrar la cuenta con una contraseña incorrecta muestra el error sin cerrar el diálogo',
      (tester) async {
        final servicio = servicioConSesion()
          ..errorAlBorrar = const ErrorAutenticacion(
            'Contraseña incorrecta.',
            codigo: 401,
          );
        await abrirMenuConCuenta(tester, servicio);

        await elegirEnMenuDeCuenta(tester, 'cuenta-borrar');
        await tester.enterText(campoBorrar, 'equivocada');
        await tocar(tester, botonBorrar);

        expect(servicio.contrasenasDeBorrado, ['equivocada']);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          tester
              .widget<SelectableText>(find.byKey(const Key('borrar-error')))
              .data,
          'Contraseña incorrecta.',
        );
        expect(textoDe(tester, campoBorrar), isEmpty);
        expect(servicio.sesion, same(sesionDeAna));
        expect(pantallaDeInicio, findsNothing);
      },
    );

    testWidgets('Cancelar el borrado de la cuenta no llama al servicio', (
      tester,
    ) async {
      final servicio = servicioConSesion();
      await abrirMenuConCuenta(tester, servicio);

      await elegirEnMenuDeCuenta(tester, 'cuenta-borrar');
      await tester.enterText(campoBorrar, 'secreta123');
      await tocar(tester, find.text('Cancelar'));

      expect(servicio.contrasenasDeBorrado, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(menuDeMapas, findsOneWidget);
    });

    testWidgets(
      'Si la sesión deja de estar activa el vigilante regresa al inicio con su aviso',
      (tester) async {
        final servicio = servicioConSesion();
        await abrirMenuConCuenta(
          tester,
          servicio,
          intervalo: const Duration(seconds: 2),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(servicio.revisionesDeSesion, 1);
        expect(menuDeMapas, findsOneWidget);

        servicio.sesionSigueActiva = false;
        await tester.pump(const Duration(seconds: 1));
        expect(servicio.revisionesDeSesion, 1);

        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(servicio.revisionesDeSesion, 2);
        expect(pantallaDeInicio, findsOneWidget);
        expect(
          find.text('Tu sesión ya no está activa, inicia sesión de nuevo.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Si no se puede revisar la sesión por falta de conexión se sigue en el menú',
      (tester) async {
        final servicio = servicioConSesion()
          ..errorAlRevisar = const ErrorAutenticacion(
            'No se pudo conectar con el servidor.',
          );
        await abrirMenuConCuenta(
          tester,
          servicio,
          intervalo: const Duration(seconds: 2),
        );

        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();

        expect(servicio.revisionesDeSesion, 3);
        expect(menuDeMapas, findsOneWidget);
        expect(pantallaDeInicio, findsNothing);
        expect(find.text('No se pudo conectar con el servidor.'), findsNothing);
      },
    );

    testWidgets(
      'Sin proveedor de autenticación el menú no muestra el botón de cuenta',
      (tester) async {
        await abrirMenuDeMapas(tester);

        expect(menuDeMapas, findsOneWidget);
        expect(botonCuenta, findsNothing);
      },
    );
  });

  group('Widgets: dirección del servidor', () {
    const direccionLaptop = 'http://192.168.1.50:8080';
    final botonProbar = find.byKey(const Key('login-probar-conexion'));
    final estadoServidor = find.byKey(const Key('login-estado-servidor'));

    Future<String?> direccionGuardada() async =>
        (await SharedPreferences.getInstance()).getString(
          DireccionServidor.clave,
        );

    Future<void> escribirServidor(WidgetTester tester, String direccion) async {
      await tocar(tester, find.text('Servidor'));
      await tester.enterText(campoServidor, direccion);
      await tester.pump();
    }

    String mensajeDe(WidgetTester tester) =>
        tester.widget<Text>(estadoServidor).data!;

    String servidorPlegado(WidgetTester tester, Key clave) => tester
        .widget<TextFormField>(find.byKey(clave, skipOffstage: false))
        .controller!
        .text;

    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets(
      'Probar conexión con el servidor encendido dice Conectado y guarda la dirección',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirJuego(tester, servicio);
        await escribirServidor(tester, direccionLaptop);

        await tocar(tester, botonProbar);

        expect(servicio.direccionesProbadas, [direccionLaptop]);
        expect(mensajeDe(tester), 'Conectado al servidor');
        expect(await direccionGuardada(), direccionLaptop);
      },
    );

    testWidgets(
      'Probar conexión sin servidor explica qué revisar y no guarda la dirección',
      (tester) async {
        final servicio = ServicioFalso()..hayConexion = false;
        await abrirJuego(tester, servicio);
        await escribirServidor(tester, direccionLaptop);

        await tocar(tester, botonProbar);

        expect(mensajeDe(tester), EstadoServidor.mensajeSinConexion);
        expect(mensajeDe(tester), contains('misma red'));
        expect(await direccionGuardada(), isNull);
      },
    );

    testWidgets(
      'Probar conexión con una dirección inválida no hace la petición',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirJuego(tester, servicio);
        await escribirServidor(tester, 'http://');

        await tocar(tester, botonProbar);

        expect(servicio.direccionesProbadas, isEmpty);
        expect(mensajeDe(tester), EstadoServidor.mensajeInvalida);
        expect(servicio.servidor, 'http://127.0.0.1:8080');
      },
    );

    testWidgets(
      'Mientras prueba la conexión el botón queda deshabilitado con un indicador',
      (tester) async {
        final espera = Completer<void>();
        final servicio = ServicioFalso()..esperaAlProbar = espera;
        await abrirJuego(tester, servicio);
        await escribirServidor(tester, direccionLaptop);

        await tester.tap(botonProbar);
        await tester.pump();

        expect(tester.widget<ButtonStyleButton>(botonProbar).onPressed, isNull);
        expect(
          find.descendant(
            of: botonProbar,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(botonEntrar).onPressed, isNotNull);

        espera.complete();
        await tester.pumpAndSettle();

        expect(
          tester.widget<ButtonStyleButton>(botonProbar).onPressed,
          isNotNull,
        );
        expect(mensajeDe(tester), 'Conectado al servidor');
      },
    );

    testWidgets('Cambiar la dirección después de probar borra el mensaje', (
      tester,
    ) async {
      await abrirJuego(tester, ServicioFalso());
      await escribirServidor(tester, direccionLaptop);
      await tocar(tester, botonProbar);

      await tester.enterText(campoServidor, 'http://192.168.1.51:8080');
      await tester.pump();

      expect(estadoServidor, findsNothing);
    });

    testWidgets('Iniciar sesión con éxito guarda la dirección del servidor', (
      tester,
    ) async {
      await abrirJuego(tester, ServicioFalso());
      await escribirServidor(tester, direccionLaptop);

      await entrar(tester);

      expect(menuDeMapas, findsOneWidget);
      expect(await direccionGuardada(), direccionLaptop);
    });

    testWidgets('Si el inicio de sesión falla no guarda la dirección', (
      tester,
    ) async {
      final servicio = ServicioFalso()
        ..errorAlIniciar = const ErrorAutenticacion(
          'No se pudo conectar con el servidor.',
        );
      await abrirJuego(tester, servicio);
      await escribirServidor(tester, direccionLaptop);

      await entrar(tester);

      expect(errorDeInicio, findsOneWidget);
      expect(await direccionGuardada(), isNull);
    });

    testWidgets(
      'Registro muestra la misma dirección y al crear la cuenta la guarda',
      (tester) async {
        final servicio = ServicioFalso()..servidor = direccionLaptop;
        await abrirRegistro(tester, servicio);

        expect(
          servidorPlegado(tester, const Key('registro-servidor')),
          direccionLaptop,
        );
        expect(
          find.byKey(
            const Key('registro-probar-conexion'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('registro-usuario')),
          'ana_nueva',
        );
        await tester.enterText(
          find.byKey(const Key('registro-contrasena')),
          'secreta123',
        );
        await tester.enterText(
          find.byKey(const Key('registro-repetir')),
          'secreta123',
        );
        await tocar(tester, find.byKey(const Key('registro-crear')));

        expect(menuDeMapas, findsOneWidget);
        expect(await direccionGuardada(), direccionLaptop);
      },
    );

    testWidgets('Si crear la cuenta falla no guarda la dirección', (
      tester,
    ) async {
      final servicio = ServicioFalso()
        ..servidor = direccionLaptop
        ..errorAlCrear = const ErrorAutenticacion(
          'Ese nombre de usuario ya está en uso.',
        );
      await abrirRegistro(tester, servicio);

      await tester.enterText(
        find.byKey(const Key('registro-usuario')),
        'ana_nueva',
      );
      await tester.enterText(
        find.byKey(const Key('registro-contrasena')),
        'secreta123',
      );
      await tester.enterText(
        find.byKey(const Key('registro-repetir')),
        'secreta123',
      );
      await tocar(tester, find.byKey(const Key('registro-crear')));

      expect(find.byKey(const Key('registro-error')), findsOneWidget);
      expect(await direccionGuardada(), isNull);
    });

    testWidgets(
      'La dirección cambiada en registro aparece al volver al inicio de sesión',
      (tester) async {
        final servicio = ServicioFalso();
        await abrirRegistro(tester, servicio);
        await tocar(tester, find.text('Servidor'));
        await tester.enterText(
          find.byKey(const Key('registro-servidor')),
          direccionLaptop,
        );
        await tocar(tester, find.byKey(const Key('registro-probar-conexion')));

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(
          servidorPlegado(tester, const Key('login-servidor')),
          direccionLaptop,
        );
      },
    );
  });
}
