import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/main.dart';
import 'package:frontend/menu_cuenta.dart';
import 'package:frontend/multijugador.dart';
import 'package:frontend/partida_compartida.dart';
import 'package:frontend/partidas.dart';
import 'package:frontend/proveedor_autenticacion.dart';
import 'package:frontend/seleccion_mapa.dart';
import 'package:juego_brilliant/mapa_dos.dart';

import '../helpers.dart';
import '../partidas_de_prueba.dart';

const errorDeRed = ErrorAutenticacion('No se pudo conectar con el servidor.');

Map<String, Object?> jugadorEnJuego(
  String nombre, {
  bool conectado = true,
  bool concedio = false,
  bool jugoRonda = false,
}) => {
  'nombre': nombre,
  'listo': true,
  'tableroListo': true,
  'conectado': conectado,
  'concedio': concedio,
  'jugoRonda': jugoRonda,
};

class SesionEnPartida extends AutenticacionFalsa {
  SesionEnPartida() : super('ana');

  late final ServicioPartidasFalso partidas;
  final eventos = <String>[];
  bool _cerrada = false;

  @override
  SesionUsuario? get sesion => _cerrada ? null : super.sesion;

  @override
  Future<void> cerrarSesion() async {
    eventos.add('cerrar sesión');
    _cerrada = true;
  }

  @override
  Future<Map<String, Object?>?> enviarConSesion(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
  }) async {
    if (ruta == '/partidas/actual') {
      return (await partidas.actual()) == null ? null : partidas.datos;
    }
    if (ruta.endsWith('/conceder')) {
      await partidas.conceder(ruta.split('/')[2]);
      return partidas.datos;
    }
    return null;
  }
}

class ServicioPartidasFalso extends ServicioPartidas {
  ServicioPartidasFalso({
    int ronda = 1,
    List<int> dados = const [1, 3],
    List<Map<String, Object?>>? jugadores,
  }) : datos = salaJson(
         comenzada: true,
         ronda: ronda,
         cambios: {
           'dados': dados,
           'jugadores':
               jugadores ?? [jugadorEnJuego('ana'), jugadorEnJuego('luis')],
           'miTablero': [1, 2, 3, 4, 5, 6],
           'puntos': {'ana': 4, 'luis': 7},
         },
       ),
       super(SesionEnPartida()) {
    sesionDePrueba.partidas = this;
  }

  Map<String, Object?> datos;
  bool enPartida = true;
  bool hayRed = true;
  bool existe = true;

  final turnosAvisados = <int>[];
  final concesiones = <String>[];
  var consultas = 0;

  SesionEnPartida get sesionDePrueba => autenticacion as SesionEnPartida;

  SalaPartida get sala => SalaPartida.desdeJson(datos);

  List<Map<String, Object?>> get listaDeJugadores =>
      (datos['jugadores']! as List<Object?>).cast<Map<String, Object?>>();

  void cambiarJugador(String nombre, Map<String, Object?> cambios) {
    datos = {
      ...datos,
      'jugadores': [
        for (final jugador in listaDeJugadores)
          jugador['nombre'] == nombre ? {...jugador, ...cambios} : jugador,
      ],
    };
  }

  void cambiarSala(Map<String, Object?> cambios) {
    datos = {...datos, ...cambios};
  }

  void _comprobarServidor() {
    if (!hayRed) throw errorDeRed;
    if (!existe) {
      throw const ErrorAutenticacion(
        'Esa partida ya no existe.',
        codigo: 404,
        codigoServidor: 'PARTIDA_NO_ENCONTRADA',
      );
    }
  }

  @override
  Future<SalaPartida?> actual() async => enPartida ? sala : null;

  @override
  Future<SalaPartida> consultar(String codigo) async {
    consultas++;
    _comprobarServidor();
    return sala;
  }

  @override
  Future<SalaPartida> terminarTurno(
    String codigo,
    int ronda, {
    required bool tableroLleno,
    int? zona,
  }) async {
    turnosAvisados.add(ronda);
    _comprobarServidor();
    cambiarJugador('ana', {'jugoRonda': true});
    return sala;
  }

  @override
  Future<SalaPartida> conceder(String codigo) async {
    concesiones.add(codigo);
    sesionDePrueba.eventos.add('conceder');
    _comprobarServidor();
    cambiarJugador('ana', {'concedio': true});
    return sala;
  }

  @override
  Future<void> salir(String codigo) async {}
}

Future<void> abrirPartidaEnCurso(
  WidgetTester tester,
  ServicioPartidasFalso partidas, {
  Duration esperaReintento = const Duration(seconds: 2),
}) async {
  usarTamanoDePantalla(tester, const Size(1000, 2400));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          key: const Key('abrir-partida'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TableroPage(
                compartida: PartidaCompartida(
                  partidas: partidas,
                  salaInicial: partidas.sala,
                  esperaReintento: esperaReintento,
                ),
              ),
            ),
          ),
          child: const Text('Menú'),
        ),
      ),
    ),
  );
  await tocar(tester, find.byKey(const Key('abrir-partida')));
}

Future<void> abrirMenuConSesion(
  WidgetTester tester,
  ServicioPartidasFalso partidas,
) async {
  final sesion = partidas.sesionDePrueba;
  await tester.pumpWidget(
    MaterialApp(
      home: ProveedorAutenticacion(
        servicio: sesion,
        volverAlInicio: (navegador, {aviso}) =>
            sesion.eventos.add('inicio: $aviso'),
        child: const SeleccionMapaPage(),
      ),
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

Future<void> moverAlPrimerDestino(WidgetTester tester) async {
  await elegirAncla(tester, 1);
  await tocarDestino(tester, 1, 4);
}

void main() {
  group('Widgets: conceder y desconexión', () {
    final botonConceder = find.byKey(const Key('multi-conceder'));
    final franja = find.byKey(const Key('multi-sin-conexion'));
    final miTurno = find.byKey(const Key('multi-tu-turno'));

    testWidgets('Conceder pide confirmación y cancelar no llama al servidor', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso();
      await abrirPartidaEnCurso(tester, partidas);

      await tocar(tester, botonConceder);
      expect(
        find.text('Si concedes, pierdes la partida y no podrás ganarla.'),
        findsOneWidget,
      );

      await tocar(tester, find.byKey(const Key('conceder-cancelar')));

      expect(partidas.concesiones, isEmpty);
      expect(botonConceder, findsOneWidget);
      expect(miTurno, findsOneWidget);
    });

    testWidgets(
      'Confirmar concede en el servidor y muestra Concediste la partida.',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        await abrirPartidaEnCurso(tester, partidas);

        await tocar(tester, botonConceder);
        await tocar(tester, find.byKey(const Key('conceder-confirmar')));

        expect(partidas.concesiones, ['K7M2QX']);
        expect(textoDe(tester, 'multi-resultado'), 'Concediste la partida.');
        expect(botonConceder, findsNothing);
        expect(find.text('Dado 1: 1'), findsNothing);
        expect(textoDe(tester, 'multi-puntos-luis'), '7 pts');

        await tocar(tester, find.byKey(const Key('multi-volver-menu')));
        expect(find.byType(TableroPage), findsNothing);
        expect(find.text('Menú'), findsOneWidget);
      },
    );

    testWidgets('Quien concedió aparece como Concedió y el juego sigue', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso(
        jugadores: [
          jugadorEnJuego('ana'),
          jugadorEnJuego('luis'),
          jugadorEnJuego('eva'),
        ],
      );
      await abrirPartidaEnCurso(tester, partidas);

      partidas.cambiarJugador('luis', {'concedio': true});
      await esperarConsulta(tester);

      expect(textoDe(tester, 'multi-estado-luis'), 'Concedió');
      expect(textoDe(tester, 'multi-estado-eva'), 'Pensando');
      expect(miTurno, findsOneWidget);
      expect(find.byKey(const Key('multi-fin')), findsNothing);
    });

    testWidgets(
      'Si los demás conceden y quedo solo se ve Ganaste: los demás concedieron.',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        await abrirPartidaEnCurso(tester, partidas);

        partidas
          ..cambiarJugador('luis', {'concedio': true})
          ..cambiarSala({
            'terminada': true,
            'ganadores': ['ana'],
            'motivoFin': 'abandono',
          });
        await esperarConsulta(tester);

        expect(
          textoDe(tester, 'multi-resultado'),
          'Ganaste: los demás concedieron.',
        );
        expect(find.byKey(const Key('multi-motivo')), findsNothing);
        expect(textoDe(tester, 'multi-ganadores'), 'Ganó ana');
        expect(botonConceder, findsNothing);
      },
    );

    testWidgets(
      'La franja aparece tras 2 fallos seguidos y se va al volver la red',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        await abrirPartidaEnCurso(tester, partidas);

        partidas.hayRed = false;
        await esperarConsulta(tester);
        expect(franja, findsNothing);

        await esperarConsulta(tester);
        expect(franja, findsOneWidget);
        expect(
          find.text('Sin conexión con el servidor. Reintentando...'),
          findsOneWidget,
        );
        expect(miTurno, findsOneWidget);

        partidas.hayRed = true;
        await esperarConsulta(tester);

        expect(franja, findsNothing);
        expect(partidas.consultas, 3);
      },
    );

    testWidgets('Al volver la red se reenvía el turno que quedó pendiente', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso();
      await abrirPartidaEnCurso(
        tester,
        partidas,
        esperaReintento: const Duration(minutes: 1),
      );

      partidas.hayRed = false;
      await moverAlPrimerDestino(tester);
      await esperarConsulta(tester);
      await esperarConsulta(tester);
      expect(franja, findsOneWidget);
      expect(partidas.turnosAvisados, [1]);
      expect(find.byKey(const Key('multi-error-turno')), findsOneWidget);

      partidas.hayRed = true;
      await esperarConsulta(tester);

      expect(partidas.turnosAvisados, [1, 1]);
      expect(franja, findsNothing);
      expect(find.byKey(const Key('multi-error-turno')), findsNothing);
      expect(find.byKey(const Key('multi-esperando-ronda')), findsOneWidget);
    });

    testWidgets('Un jugador sin conexión se ve atenuado y el juego sigue', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso();
      await abrirPartidaEnCurso(tester, partidas);

      partidas.cambiarJugador('luis', {'conectado': false});
      await esperarConsulta(tester);

      final sinConexion = find.byKey(const Key('jugador-sin-conexion-luis'));
      expect(sinConexion, findsOneWidget);
      expect(tester.widget<Text>(sinConexion).data, 'Sin conexión');
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: sinConexion, matching: find.byType(Opacity)),
            )
            .opacity,
        0.5,
      );
      expect(find.byKey(const Key('jugador-sin-conexion-ana')), findsNothing);
      expect(franja, findsNothing);
      expect(miTurno, findsOneWidget);

      await moverAlPrimerDestino(tester);
      expect(partidas.turnosAvisados, [1]);
    });

    testWidgets(
      'Volver a tu partida abre la partida en curso con el tablero ya enviado',
      (tester) async {
        final partidas = ServicioPartidasFalso(ronda: 2, dados: [4, 5]);
        usarTamanoDePantalla(tester, const Size(1000, 2400));
        await tester.pumpWidget(
          MaterialApp(home: MultijugadorPage(partidas: partidas)),
        );
        await tester.pumpAndSettle();

        await tocar(tester, find.byKey(const Key('multi-volver')));

        expect(find.byType(TableroPage), findsOneWidget);
        expect(textoDe(tester, 'multi-ronda'), 'Ronda 2');
        expect(find.text('Dado 1: 4'), findsOneWidget);
        expect(miTurno, findsOneWidget);
        final celdas = mapaDos.celdasIniciales;
        for (var indice = 0; indice < celdas.length; indice++) {
          final (fila, columna) = celdas[indice];
          expect(
            find.descendant(
              of: find.byKey(Key('cell-$fila-$columna')),
              matching: find.text('${indice + 1}'),
            ),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets('Sin partida en juego no aparece Volver a tu partida', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso()..enPartida = false;
      await tester.pumpWidget(
        MaterialApp(home: MultijugadorPage(partidas: partidas)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('multi-volver')), findsNothing);
      expect(find.byKey(const Key('multi-crear')), findsOneWidget);
    });

    testWidgets(
      'Si el servidor cierra la partida se ve La partida ya no está disponible.',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        await abrirPartidaEnCurso(tester, partidas);

        partidas.existe = false;
        await esperarConsulta(tester);

        expect(find.byKey(const Key('multi-no-disponible')), findsOneWidget);
        expect(find.text('La partida ya no está disponible.'), findsOneWidget);
        expect(franja, findsNothing);
        expect(botonConceder, findsNothing);

        await tocar(tester, find.byKey(const Key('multi-volver-menu')));
        expect(find.text('Menú'), findsOneWidget);
      },
    );

    testWidgets(
      'Cerrar sesión en plena partida avisa y concede antes de salir',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        final sesion = partidas.sesionDePrueba;
        await abrirMenuConSesion(tester, partidas);

        await tocar(tester, find.byKey(const Key('menu-cuenta')));
        await tocar(tester, find.byKey(const Key('cuenta-cerrar-sesion')));

        expect(find.text(BotonCuenta.avisoPartidaEnJuego), findsOneWidget);
        expect(sesion.eventos, isEmpty);

        await tocar(tester, find.byKey(const Key('cerrar-confirmar')));

        expect(sesion.eventos, [
          'conceder',
          'cerrar sesión',
          'inicio: Sesión cerrada.',
        ]);
        expect(partidas.concesiones, ['K7M2QX']);
      },
    );

    testWidgets('Si la red falla al conceder la sesión se cierra igual', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso();
      final sesion = partidas.sesionDePrueba;
      await abrirMenuConSesion(tester, partidas);
      await tocar(tester, find.byKey(const Key('menu-cuenta')));
      await tocar(tester, find.byKey(const Key('cuenta-cerrar-sesion')));
      expect(find.text(BotonCuenta.avisoPartidaEnJuego), findsOneWidget);
      partidas.hayRed = false;

      await tocar(tester, find.byKey(const Key('cerrar-confirmar')));

      expect(sesion.eventos, [
        'conceder',
        'cerrar sesión',
        'inicio: Sesión cerrada.',
      ]);
      expect(sesion.sesion, isNull);
    });

    testWidgets('Sin partida en juego cerrar sesión no avisa ni concede', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso()..enPartida = false;
      final sesion = partidas.sesionDePrueba;
      await abrirMenuConSesion(tester, partidas);

      await tocar(tester, find.byKey(const Key('menu-cuenta')));
      await tocar(tester, find.byKey(const Key('cuenta-cerrar-sesion')));
      expect(find.text(BotonCuenta.avisoPartidaEnJuego), findsNothing);
      await tocar(tester, find.byKey(const Key('cerrar-confirmar')));

      expect(sesion.eventos, ['cerrar sesión', 'inicio: Sesión cerrada.']);
      expect(partidas.concesiones, isEmpty);
    });
  });
}
