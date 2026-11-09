import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/crear_partida.dart';
import 'package:frontend/main.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/sala_espera.dart';
import 'package:frontend/seleccion_mapa.dart';
import 'package:frontend/unirse_partida.dart';

import '../helpers.dart';
import '../partidas_de_prueba.dart';

class AutenticacionFalsa implements ServicioAutenticacion {
  AutenticacionFalsa(String nombre)
    : sesion = SesionUsuario(token: 'token', idUsuario: '1', nombre: nombre);

  @override
  String servidor = servidorDePrueba;

  @override
  final SesionUsuario? sesion;

  @override
  Future<Map<String, Object?>?> enviarConSesion(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object?> jugadorEnSala(
  String nombre, {
  bool listo = false,
  bool conectado = true,
}) => {
  'nombre': nombre,
  'listo': listo,
  'tableroListo': false,
  'conectado': conectado,
  'concedio': false,
  'jugoRonda': false,
};

class ServicioPartidasFalso extends ServicioPartidas {
  ServicioPartidasFalso({String nombre = 'ana'})
    : super(AutenticacionFalsa(nombre));

  Map<String, Object?> datos = salaJson(
    cambios: {
      'jugadores': [jugadorEnSala('ana')],
    },
  );
  ErrorAutenticacion? errorAlCrear;
  ErrorAutenticacion? errorAlUnirse;
  Object? errorAlConsultar;
  Completer<void>? esperaAlUnirse;

  final partidasCreadas = <(int, int)>[];
  final codigosEnviados = <String>[];
  final cambiosDeListo = <bool>[];
  var consultas = 0;
  var salidas = 0;

  String get miNombre => autenticacion.sesion!.nombre;

  List<Map<String, Object?>> get listaDeJugadores =>
      (datos['jugadores']! as List<Object?>).cast<Map<String, Object?>>();

  void llegaJugador(String nombre, {bool listo = false}) {
    datos = {
      ...datos,
      'jugadores': [...listaDeJugadores, jugadorEnSala(nombre, listo: listo)],
    };
  }

  void cambiarListo(String nombre, {required bool listo}) {
    datos = {
      ...datos,
      'jugadores': [
        for (final jugador in listaDeJugadores)
          jugador['nombre'] == nombre ? {...jugador, 'listo': listo} : jugador,
      ],
    };
  }

  SalaPartida get sala {
    final todosListos =
        listaDeJugadores.length >= 2 &&
        listaDeJugadores.every((jugador) => jugador['listo'] == true);
    return SalaPartida.desdeJson({
      ...datos,
      if (todosListos) 'comenzada': true,
      if (todosListos) 'meta': 26,
    });
  }

  @override
  Future<SalaPartida> crear({required int mapa, required int jugadores}) async {
    partidasCreadas.add((mapa, jugadores));
    final error = errorAlCrear;
    if (error != null) throw error;
    datos = {...datos, 'mapa': mapa, 'capacidad': jugadores};
    return sala;
  }

  @override
  Future<SalaPartida> unirse(String codigo) async {
    codigosEnviados.add(codigo);
    await esperaAlUnirse?.future;
    final error = errorAlUnirse;
    if (error != null) throw error;
    return sala;
  }

  @override
  Future<SalaPartida?> actual() async => null;

  @override
  Future<SalaPartida> consultar(String codigo) async {
    consultas++;
    final error = errorAlConsultar;
    if (error != null) throw error;
    return sala;
  }

  @override
  Future<SalaPartida> marcarListo(String codigo, {required bool listo}) async {
    cambiosDeListo.add(listo);
    cambiarListo(miNombre, listo: listo);
    return sala;
  }

  @override
  Future<void> salir(String codigo) async {
    salidas++;
  }
}

ServicioPartidasFalso salaDeAnaConLuis({
  String nombre = 'ana',
  bool luisListo = false,
}) => ServicioPartidasFalso(nombre: nombre)
  ..datos = salaJson(
    cambios: {
      'jugadores': [
        jugadorEnSala('ana'),
        jugadorEnSala('luis', listo: luisListo),
      ],
    },
  );

Future<void> abrirMultijugador(
  WidgetTester tester,
  ServicioPartidasFalso partidas,
) async {
  usarTamanoDePantalla(tester, const Size(900, 1800));
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: MultijugadorPage(partidas: partidas),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> abrirSala(
  WidgetTester tester,
  ServicioPartidasFalso partidas,
) async {
  await abrirMultijugador(tester, partidas);
  Navigator.of(tester.element(find.byType(MultijugadorPage))).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          SalaEsperaPage(partidas: partidas, salaInicial: partidas.sala),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> esperarConsulta(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

String textoDe(WidgetTester tester, String clave) =>
    tester.widget<Text>(find.byKey(Key(clave))).data!;

void main() {
  group('Widgets: lobby', () {
    final botonListo = find.byKey(const Key('sala-listo'));
    final campoCodigo = find.byKey(const Key('unirse-codigo'));
    final botonUnirse = find.byKey(const Key('unirse-confirmar'));
    final botonSalir = find.byKey(const Key('sala-salir'));

    testWidgets('Sin sesión el menú de mapas no ofrece jugar con amigos', (
      tester,
    ) async {
      await abrirMenuDeMapas(tester);

      expect(find.text('Jugar con amigos'), findsNothing);
      expect(find.byKey(const Key('menu-multijugador')), findsNothing);
    });

    testWidgets(
      'Con sesión aparece Jugar con amigos y abre el menú multijugador',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ProveedorAutenticacion(
              servicio: AutenticacionFalsa('ana'),
              volverAlInicio: (navegador, {aviso}) {},
              child: const SeleccionMapaPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Jugar con amigos'), findsOneWidget);
        await tocar(tester, find.byKey(const Key('menu-multijugador')));

        expect(find.byType(MultijugadorPage), findsOneWidget);
        expect(find.byKey(const Key('multi-crear')), findsOneWidget);
        expect(find.byKey(const Key('multi-unirse')), findsOneWidget);
      },
    );

    testWidgets('Crear partida ofrece solo de 2 a 6 jugadores', (tester) async {
      await abrirMultijugador(tester, ServicioPartidasFalso());
      await tocar(tester, find.byKey(const Key('multi-crear')));

      expect(find.byKey(const Key('crear-jugadores-1')), findsNothing);
      for (var cantidad = 2; cantidad <= 6; cantidad++) {
        expect(find.byKey(Key('crear-jugadores-$cantidad')), findsOneWidget);
      }
      expect(find.byKey(const Key('crear-jugadores-7')), findsNothing);
    });

    testWidgets(
      'Crear envía el mapa y la cantidad elegidos y abre la sala de espera',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        await abrirMultijugador(tester, partidas);
        await tocar(tester, find.byKey(const Key('multi-crear')));

        await tocar(tester, find.byKey(const Key('crear-mapa-3')));
        await tocar(tester, find.byKey(const Key('crear-jugadores-4')));
        await tocar(tester, find.byKey(const Key('crear-confirmar')));

        expect(partidas.partidasCreadas, [(3, 4)]);
        expect(find.byType(SalaEsperaPage), findsOneWidget);
        expect(textoDe(tester, 'sala-mapa'), 'Mapa 3');
        expect(textoDe(tester, 'sala-ocupacion'), '1 de 4 jugadores');
      },
    );

    testWidgets('Si el servidor rechaza la partida se muestra su error', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso()
        ..errorAlCrear = const ErrorAutenticacion(
          'Ese mapa no está disponible.',
          codigo: 400,
          codigoServidor: 'MAPA_NO_DISPONIBLE',
        );
      await abrirMultijugador(tester, partidas);
      await tocar(tester, find.byKey(const Key('multi-crear')));

      await tocar(tester, find.byKey(const Key('crear-confirmar')));

      expect(find.byType(CrearPartidaPage), findsOneWidget);
      expect(find.byType(SalaEsperaPage), findsNothing);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('crear-error')))
            .data,
        'Ese mapa no está disponible.',
      );
    });

    testWidgets(
      'La sala muestra el código, el mapa, el anfitrión y los espacios',
      (tester) async {
        await abrirSala(tester, salaDeAnaConLuis());

        expect(
          tester
              .widget<SelectableText>(find.byKey(const Key('sala-codigo')))
              .data,
          'K7M2QX',
        );
        expect(textoDe(tester, 'sala-mapa'), 'Mapa 2');
        expect(textoDe(tester, 'sala-anfitrion'), 'Anfitrión: ana');
        expect(textoDe(tester, 'sala-ocupacion'), '2 de 4 jugadores');
        expect(find.text('ana (tú)'), findsOneWidget);
        expect(find.byKey(const Key('sala-faltan-jugadores')), findsNothing);
      },
    );

    testWidgets('Los jugadores que llegan aparecen en la sala', (tester) async {
      final partidas = ServicioPartidasFalso();
      await abrirSala(tester, partidas);
      expect(find.byKey(const Key('sala-faltan-jugadores')), findsOneWidget);
      expect(find.byKey(const Key('sala-jugador-luis')), findsNothing);

      partidas
        ..llegaJugador('luis')
        ..llegaJugador('eva', listo: true);
      await esperarConsulta(tester);

      expect(find.byKey(const Key('sala-jugador-luis')), findsOneWidget);
      expect(find.byKey(const Key('sala-jugador-eva')), findsOneWidget);
      expect(textoDe(tester, 'sala-estado-luis'), 'Esperando');
      expect(textoDe(tester, 'sala-estado-eva'), 'Listo');
      expect(textoDe(tester, 'sala-ocupacion'), '3 de 4 jugadores');
      expect(find.byKey(const Key('sala-faltan-jugadores')), findsNothing);
    });

    testWidgets('Copiar código lo copia al portapapeles y avisa', (
      tester,
    ) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'Clipboard.setData') {
            copiado =
                (llamada.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await abrirSala(tester, ServicioPartidasFalso());

      await tocar(tester, find.byKey(const Key('sala-copiar')));

      expect(copiado, 'K7M2QX');
      expect(find.text('Código copiado'), findsOneWidget);
    });

    testWidgets('Un código incompleto o con símbolos no llega al servidor', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso(nombre: 'luis');
      await abrirMultijugador(tester, partidas);
      await tocar(tester, find.byKey(const Key('multi-unirse')));

      await tester.enterText(campoCodigo, 'K7M');
      await tocar(tester, botonUnirse);
      expect(find.text('El código tiene 6 caracteres.'), findsOneWidget);

      await tester.enterText(campoCodigo, 'K7-2QX');
      await tocar(tester, botonUnirse);
      expect(
        find.text('El código solo lleva letras y números.'),
        findsOneWidget,
      );

      expect(partidas.codigosEnviados, isEmpty);
      expect(find.byType(UnirseConCodigoPage), findsOneWidget);
    });

    testWidgets('El código se escribe en mayúsculas y así se envía', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis(nombre: 'luis');
      await abrirMultijugador(tester, partidas);
      await tocar(tester, find.byKey(const Key('multi-unirse')));

      await tester.enterText(campoCodigo, 'k7m2qx');
      await tester.pump();
      expect(tester.widget<TextField>(campoCodigo).controller!.text, 'K7M2QX');

      await tocar(tester, botonUnirse);

      expect(partidas.codigosEnviados, ['K7M2QX']);
      expect(find.byType(SalaEsperaPage), findsOneWidget);
      expect(find.text('luis (tú)'), findsOneWidget);
    });

    testWidgets('Un rechazo al unirse se muestra y se puede reintentar', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis(nombre: 'luis');
      await abrirMultijugador(tester, partidas);
      await tocar(tester, find.byKey(const Key('multi-unirse')));
      await tester.enterText(campoCodigo, 'K7M2QX');

      const rechazos = [
        ErrorAutenticacion(
          'Esa partida no existe.',
          codigo: 404,
          codigoServidor: 'PARTIDA_NO_ENCONTRADA',
        ),
        ErrorAutenticacion(
          'La partida ya está llena.',
          codigo: 409,
          codigoServidor: 'PARTIDA_LLENA',
        ),
        ErrorAutenticacion(
          'La partida ya comenzó.',
          codigo: 409,
          codigoServidor: 'PARTIDA_COMENZADA',
        ),
      ];
      for (final rechazo in rechazos) {
        partidas.errorAlUnirse = rechazo;
        await tocar(tester, botonUnirse);

        expect(
          tester
              .widget<SelectableText>(find.byKey(const Key('unirse-error')))
              .data,
          rechazo.mensaje,
        );
        expect(find.byType(UnirseConCodigoPage), findsOneWidget);
      }

      partidas.errorAlUnirse = null;
      await tocar(tester, botonUnirse);

      expect(partidas.codigosEnviados, hasLength(4));
      expect(find.byType(SalaEsperaPage), findsOneWidget);
    });

    testWidgets('Tocar dos veces Unirse envía una sola petición', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis(nombre: 'luis')
        ..esperaAlUnirse = Completer<void>();
      await abrirMultijugador(tester, partidas);
      await tocar(tester, find.byKey(const Key('multi-unirse')));
      await tester.enterText(campoCodigo, 'K7M2QX');

      await tester.tap(botonUnirse);
      await tester.pump();
      await tester.tap(botonUnirse, warnIfMissed: false);
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();

      expect(partidas.codigosEnviados, ['K7M2QX']);

      partidas.esperaAlUnirse!.complete();
      await tester.pumpAndSettle();
      expect(partidas.codigosEnviados, hasLength(1));
      expect(find.byType(SalaEsperaPage), findsOneWidget);
    });

    testWidgets('El anfitrión y los invitados tienen botón de listo', (
      tester,
    ) async {
      await abrirSala(tester, salaDeAnaConLuis());
      expect(botonListo, findsOneWidget);
      expect(find.text('Estoy listo'), findsOneWidget);

      await abrirSala(tester, salaDeAnaConLuis(nombre: 'luis'));
      expect(find.text('luis (tú)'), findsOneWidget);
      expect(botonListo, findsOneWidget);
      expect(find.text('Estoy listo'), findsOneWidget);
    });

    testWidgets('Confirmar y deshacer listo avisan al servidor', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis();
      await abrirSala(tester, partidas);

      await tocar(tester, botonListo);
      expect(partidas.cambiosDeListo, [true]);
      expect(textoDe(tester, 'sala-estado-ana'), 'Listo');
      expect(find.text('Ya no estoy listo'), findsOneWidget);

      await tocar(tester, botonListo);
      expect(partidas.cambiosDeListo, [true, false]);
      expect(textoDe(tester, 'sala-estado-ana'), 'Esperando');
      expect(find.text('Estoy listo'), findsOneWidget);
    });

    testWidgets('Mientras falte alguien por confirmar la partida no empieza', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis();
      await abrirSala(tester, partidas);

      await tocar(tester, botonListo);
      await esperarConsulta(tester);
      await esperarConsulta(tester);

      expect(textoDe(tester, 'sala-estado-luis'), 'Esperando');
      expect(find.byType(SalaEsperaPage), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);
    });

    testWidgets('Cuando el último confirma se pasa al tablero', (tester) async {
      final partidas = salaDeAnaConLuis();
      await abrirSala(tester, partidas);
      await tocar(tester, botonListo);

      partidas.cambiarListo('luis', listo: true);
      await esperarConsulta(tester);

      expect(find.byType(SalaEsperaPage), findsNothing);
      expect(find.byType(TableroPage), findsOneWidget);
      expect(textoDe(tester, 'multi-encabezado'), 'Partida K7M2QX · Mapa 2');
    });

    testWidgets('Si yo soy el último en confirmar también se pasa al tablero', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis(luisListo: true);
      await abrirSala(tester, partidas);

      await tocar(tester, botonListo);

      expect(partidas.cambiosDeListo, [true]);
      expect(find.byType(TableroPage), findsOneWidget);
    });

    testWidgets('El anfitrión confirma antes de cerrar la sala', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis();
      await abrirSala(tester, partidas);

      await tocar(tester, botonSalir);
      expect(find.text(SalaEsperaPage.avisoCierreParaTodos), findsOneWidget);
      await tocar(tester, find.byKey(const Key('sala-cerrar-cancelar')));
      expect(partidas.salidas, 0);
      expect(find.byType(SalaEsperaPage), findsOneWidget);

      await tocar(tester, botonSalir);
      await tocar(tester, find.byKey(const Key('sala-cerrar-confirmar')));

      expect(partidas.salidas, 1);
      expect(find.byType(SalaEsperaPage), findsNothing);
      expect(find.byType(MultijugadorPage), findsOneWidget);
    });

    testWidgets('Un invitado sale de la sala sin confirmar', (tester) async {
      final partidas = salaDeAnaConLuis(nombre: 'luis');
      await abrirSala(tester, partidas);

      await tocar(tester, botonSalir);

      expect(find.text(SalaEsperaPage.avisoCierreParaTodos), findsNothing);
      expect(partidas.salidas, 1);
      expect(find.byType(MultijugadorPage), findsOneWidget);
    });

    testWidgets('Si la sala se cierra se avisa y se puede volver', (
      tester,
    ) async {
      final partidas = salaDeAnaConLuis(nombre: 'luis');
      await abrirSala(tester, partidas);

      partidas.errorAlConsultar = const ErrorAutenticacion(
        'Esa partida ya no existe.',
        codigo: 404,
        codigoServidor: 'PARTIDA_NO_ENCONTRADA',
      );
      await esperarConsulta(tester);

      expect(textoDe(tester, 'sala-cerrada'), 'La sala se cerró.');
      expect(botonListo, findsNothing);

      final consultas = partidas.consultas;
      await esperarConsulta(tester);
      expect(partidas.consultas, consultas);

      await tocar(tester, find.byKey(const Key('sala-volver')));
      expect(find.byType(SalaEsperaPage), findsNothing);
      expect(find.byType(MultijugadorPage), findsOneWidget);
    });

    testWidgets('Un fallo pasajero al consultar no saca a nadie de la sala', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso()
        ..errorAlConsultar = const ErrorAutenticacion(
          'No se pudo conectar con el servidor.',
        );
      await abrirSala(tester, partidas);

      await esperarConsulta(tester);
      await esperarConsulta(tester);
      expect(partidas.consultas, 2);
      expect(find.byKey(const Key('sala-cerrada')), findsNothing);
      expect(find.byKey(const Key('sala-error')), findsNothing);
      expect(botonListo, findsOneWidget);

      partidas
        ..errorAlConsultar = null
        ..llegaJugador('luis');
      await esperarConsulta(tester);

      expect(find.byKey(const Key('sala-jugador-luis')), findsOneWidget);
      expect(find.byType(SalaEsperaPage), findsOneWidget);
    });
  });
}
