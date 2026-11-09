import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/partida_compartida.dart';
import 'package:frontend/partidas.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/mapa_dos.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';

import '../helpers.dart';
import '../partidas_de_prueba.dart';

typedef TurnoAvisado = ({int ronda, bool tableroLleno, int? zona});

Map<String, Object?> jugadorEnPartida(
  String nombre, {
  bool tableroListo = true,
  bool jugoRonda = false,
  bool concedio = false,
}) => {
  'nombre': nombre,
  'listo': true,
  'tableroListo': tableroListo,
  'conectado': true,
  'concedio': concedio,
  'jugoRonda': jugoRonda,
};

class ServicioPartidasFalso extends ServicioPartidas {
  ServicioPartidasFalso({
    int mapa = 2,
    int ronda = 0,
    List<int> dados = const [],
    List<Map<String, Object?>>? jugadores,
    List<int> miTablero = const [],
    Map<String, int> puntos = const {},
  }) : datos = salaJson(
         comenzada: true,
         ronda: ronda,
         cambios: {
           'mapa': mapa,
           'dados': dados,
           'jugadores':
               jugadores ??
               [
                 jugadorEnPartida('ana', tableroListo: ronda > 0),
                 jugadorEnPartida('luis', tableroListo: ronda > 0),
               ],
           'miTablero': miTablero,
           'puntos': puntos,
         },
       ),
       super(AutenticacionFalsa('ana'));

  Map<String, Object?> datos;

  final tablerosEnviados = <List<int>>[];
  final turnosAvisados = <TurnoAvisado>[];

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

  void nuevaRonda(int ronda, List<int> dados) {
    datos = {...datos, 'ronda': ronda, 'dados': dados};
    for (final jugador in listaDeJugadores) {
      cambiarJugador(jugador['nombre']! as String, {'jugoRonda': false});
    }
  }

  void cambiarSala(Map<String, Object?> cambios) {
    datos = {...datos, ...cambios};
  }

  @override
  Future<SalaPartida> consultar(String codigo) async => sala;

  @override
  Future<SalaPartida> enviarTablero(String codigo, List<int> numeros) async {
    tablerosEnviados.add(numeros);
    cambiarJugador('ana', {'tableroListo': true});
    cambiarSala({'miTablero': numeros});
    return sala;
  }

  @override
  Future<SalaPartida> terminarTurno(
    String codigo,
    int ronda, {
    required bool tableroLleno,
    int? zona,
  }) async {
    turnosAvisados.add((ronda: ronda, tableroLleno: tableroLleno, zona: zona));
    cambiarJugador('ana', {'jugoRonda': true});
    return sala;
  }

  @override
  Future<void> salir(String codigo) async {}
}

Future<void> abrirPartidaCompartida(
  WidgetTester tester,
  ServicioPartidasFalso partidas, {
  Partida? partida,
}) async {
  usarTamanoDePantalla(tester, const Size(1000, 2400));
  await tester.pumpWidget(
    MaterialApp(
      home: TableroPage(
        partida: partida,
        compartida: PartidaCompartida(
          partidas: partidas,
          salaInicial: partidas.sala,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> esperarConsulta(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> mover(
  WidgetTester tester,
  int ancla,
  int fila,
  int columna,
) async {
  await elegirAncla(tester, ancla);
  await tocarDestino(tester, fila, columna);
}

String textoDe(WidgetTester tester, String clave) =>
    tester.widget<Text>(find.byKey(Key(clave))).data!;

Partida tableroDelMapaUnoConUnaCeldaLibre() {
  final partida = Partida(mapa: mapaUno, permitirRelanzar: false);
  final celdas = mapaUno.celdasIniciales;
  for (var indice = 0; indice < celdas.length; indice++) {
    final (fila, columna) = celdas[indice];
    partida.colocarValorInicial(fila - 1, columna - 1, indice + 1);
  }
  partida.iniciar();
  for (final celda in partida.tablero.celdas) {
    if (celda.valor == null && !(celda.fila == 0 && celda.columna == 0)) {
      celda.valor = 1;
    }
  }
  return partida;
}

void main() {
  group('Widgets: partida multijugador', () {
    final botonFinalizar = find.byKey(const Key('multi-finalizar'));
    final botonLanzar = find.byKey(const Key('roll-dice-button'));
    final botonSaltar = find.byKey(const Key('skip-turn-button'));
    final miTurno = find.byKey(const Key('multi-tu-turno'));
    final esperandoRonda = find.byKey(const Key('multi-esperando-ronda'));
    final primerDestinoValido = find
        .byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'valid-move-cell-',
              ),
        )
        .first;

    testWidgets(
      'Finalizar tablero envía los números en el orden del mapa y espera a los demás',
      (tester) async {
        final partidas = ServicioPartidasFalso();
        await abrirPartidaCompartida(tester, partidas);
        final celdas = mapaDos.celdasIniciales;

        for (var indice = celdas.length - 1; indice > 0; indice--) {
          await ingresarNumeroInicial(tester, celdas[indice], indice + 1);
        }
        expect(tester.widget<FilledButton>(botonFinalizar).onPressed, isNull);
        await ingresarNumeroInicial(tester, celdas.first, 1);

        await tocar(tester, botonFinalizar);

        expect(partidas.tablerosEnviados, [
          [1, 2, 3, 4, 5, 6],
        ]);
        expect(botonFinalizar, findsNothing);
        expect(find.byKey(const Key('multi-esperando')), findsOneWidget);
        expect(find.text('Esperando a los demás jugadores...'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('multi-jugador-luis')),
            matching: find.text('Colocando números'),
          ),
          findsOneWidget,
        );

        partidas.cambiarJugador('luis', {'tableroListo': true});
        await esperarConsulta(tester);

        expect(find.byKey(const Key('multi-todos-listos')), findsOneWidget);
      },
    );

    testWidgets(
      'Los dados llegan del servidor y mover avisa la zona completada',
      (tester) async {
        final partidas = ServicioPartidasFalso(
          ronda: 1,
          dados: [1, 3],
          miTablero: [1, 2, 3, 4, 5, 6],
        );
        await abrirPartidaCompartida(tester, partidas);

        expect(textoDe(tester, 'multi-ronda'), 'Ronda 1');
        expect(find.text('Dado 1: 1'), findsOneWidget);
        expect(find.text('Dado 2: 3'), findsOneWidget);
        expect(botonLanzar, findsNothing);
        expect(miTurno, findsOneWidget);

        await mover(tester, 1, 1, 4);

        expect(partidas.turnosAvisados, [
          (ronda: 1, tableroLleno: false, zona: null),
        ]);
        expect(esperandoRonda, findsOneWidget);
        expect(find.text('Esperando a los demás...'), findsOneWidget);

        partidas.nuevaRonda(2, [3, 6]);
        await esperarConsulta(tester);

        expect(textoDe(tester, 'multi-ronda'), 'Ronda 2');
        expect(find.text('Dado 1: 3'), findsOneWidget);
        expect(find.text('Dado 2: 6'), findsOneWidget);
        expect(miTurno, findsOneWidget);

        await mover(tester, 6, 7, 4);

        expect(partidas.turnosAvisados.last, (
          ronda: 2,
          tableroLleno: false,
          zona: 2,
        ));
        expect(esperandoRonda, findsOneWidget);
      },
    );

    testWidgets(
      'Sin movimientos se salta el turno y la última celda avisa el tablero lleno',
      (tester) async {
        final partidas = ServicioPartidasFalso(
          mapa: 1,
          ronda: 1,
          dados: [2, 3],
        );
        await abrirPartidaCompartida(
          tester,
          partidas,
          partida: tableroDelMapaUnoConUnaCeldaLibre(),
        );

        expect(botonLanzar, findsNothing);
        expect(
          find.text(
            'No hay movimientos posibles con esta tirada. '
            'Salta el turno.',
          ),
          findsOneWidget,
        );

        await tocar(tester, botonSaltar);

        expect(partidas.turnosAvisados, [
          (ronda: 1, tableroLleno: false, zona: null),
        ]);
        expect(esperandoRonda, findsOneWidget);
        expect(botonSaltar, findsNothing);

        partidas.nuevaRonda(2, [1, 4]);
        await esperarConsulta(tester);
        expect(miTurno, findsOneWidget);

        await mover(tester, 1, 1, 1);

        expect(partidas.turnosAvisados.last, (
          ronda: 2,
          tableroLleno: true,
          zona: 1,
        ));
        expect(find.text('Llenaste tu tablero.'), findsOneWidget);
        expect(esperandoRonda, findsOneWidget);
      },
    );

    testWidgets(
      'El panel muestra estado y puntos de cada jugador, resalta los propios y la meta',
      (tester) async {
        final partidas = ServicioPartidasFalso(
          mapa: 4,
          ronda: 3,
          dados: [2, 5],
          miTablero: numerosInicialesMapaCuatro,
          jugadores: [
            jugadorEnPartida('ana'),
            jugadorEnPartida('luis', jugoRonda: true),
            jugadorEnPartida('eva', concedio: true),
          ],
          puntos: {'ana': 12, 'luis': 18, 'eva': 3},
        );
        await abrirPartidaCompartida(tester, partidas);

        expect(textoDe(tester, 'multi-encabezado'), 'Partida K7M2QX · Mapa 4');
        expect(textoDe(tester, 'multi-meta'), 'Meta: 26 puntos');
        expect(textoDe(tester, 'multi-estado-ana'), 'Pensando');
        expect(textoDe(tester, 'multi-estado-luis'), 'Jugó');
        expect(textoDe(tester, 'multi-estado-eva'), 'Concedió');
        expect(textoDe(tester, 'multi-puntos-luis'), '18 pts');
        expect(textoDe(tester, 'multi-puntos-ana'), '12 pts');
        expect(textoDe(tester, 'multi-puntos-eva'), '3 pts');
        expect(find.text('ana (tú)'), findsOneWidget);

        final colores = Theme.of(tester.element(miTurno)).colorScheme;
        Color? fondoDe(String nombre) =>
            (tester
                        .widget<Container>(
                          find.byKey(Key('multi-jugador-$nombre')),
                        )
                        .decoration!
                    as BoxDecoration)
                .color;
        expect(fondoDe('ana'), colores.primaryContainer);
        expect(fondoDe('luis'), isNull);
        expect(fondoDe('eva'), isNull);

        await elegirAncla(tester, 2);
        await tocar(tester, primerDestinoValido);
        expect(partidas.turnosAvisados, hasLength(1));
        partidas.cambiarJugador('luis', {'jugoRonda': false});
        await esperarConsulta(tester);
        expect(textoDe(tester, 'multi-estado-ana'), 'Jugó');
        expect(textoDe(tester, 'multi-estado-luis'), 'Pensando');
      },
    );

    testWidgets(
      'Al terminar muestra la clasificación, quién ganó y el motivo',
      (tester) async {
        final partidas = ServicioPartidasFalso(
          ronda: 6,
          dados: [1, 3],
          miTablero: [1, 2, 3, 4, 5, 6],
          jugadores: [
            jugadorEnPartida('ana'),
            jugadorEnPartida('luis'),
            jugadorEnPartida('eva'),
          ],
          puntos: {'ana': 14, 'luis': 27, 'eva': 9},
        );
        await abrirPartidaCompartida(tester, partidas);
        expect(find.byKey(const Key('multi-fin')), findsNothing);

        partidas.cambiarSala({
          'terminada': true,
          'ganadores': ['luis'],
          'motivoFin': 'meta',
        });
        await esperarConsulta(tester);

        expect(find.byKey(const Key('multi-fin')), findsOneWidget);
        expect(textoDe(tester, 'multi-resultado'), 'Partida terminada');
        expect(textoDe(tester, 'multi-motivo'), 'Alguien llegó a la meta.');
        expect(textoDe(tester, 'multi-ganadores'), 'Ganó luis');
        final filas = [
          for (final nombre in ['luis', 'ana', 'eva'])
            tester.getTopLeft(find.byKey(Key('multi-jugador-$nombre'))).dy,
        ];
        expect(filas[0], lessThan(filas[1]));
        expect(filas[1], lessThan(filas[2]));
        expect(
          find.descendant(
            of: find.byKey(const Key('multi-jugador-luis')),
            matching: find.text('1.'),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('multi-volver-menu')), findsOneWidget);
      },
    );

    testWidgets('Un empate muestra a todos los ganadores y el motivo', (
      tester,
    ) async {
      final partidas = ServicioPartidasFalso(
        ronda: 9,
        dados: [2, 2],
        miTablero: [1, 2, 3, 4, 5, 6],
        jugadores: [
          jugadorEnPartida('ana'),
          jugadorEnPartida('luis'),
          jugadorEnPartida('eva'),
        ],
        puntos: {'ana': 20, 'luis': 20, 'eva': 11},
      );
      partidas.cambiarSala({
        'terminada': true,
        'ganadores': ['ana', 'luis'],
        'motivoFin': 'sin_tableros',
      });
      await abrirPartidaCompartida(tester, partidas);

      expect(textoDe(tester, 'multi-resultado'), '¡Ganaste!');
      expect(textoDe(tester, 'multi-ganadores'), 'Empate: ana, luis');
      expect(textoDe(tester, 'multi-motivo'), 'Nadie puede seguir jugando.');
      expect(textoDe(tester, 'multi-puntos-ana'), '20 pts');
      expect(textoDe(tester, 'multi-puntos-luis'), '20 pts');
      expect(textoDe(tester, 'multi-puntos-eva'), '11 pts');
      expect(miTurno, findsNothing);
      expect(esperandoRonda, findsNothing);
    });

    testWidgets('Cada mapa del menú arma su propio tablero compartido', (
      tester,
    ) async {
      for (final (mapa, numeros) in [
        (mapaUno, [1, 2, 3, 4, 5, 6]),
        (mapaCuatro, numerosInicialesMapaCuatro),
      ]) {
        final partidas = ServicioPartidasFalso(
          mapa: mapa.numero,
          ronda: 1,
          dados: [3, 4],
          miTablero: numeros,
        );
        await tester.pumpWidget(const SizedBox());
        await abrirPartidaCompartida(tester, partidas);

        expect(
          textoDe(tester, 'multi-encabezado'),
          'Partida K7M2QX · Mapa ${mapa.numero}',
        );
        expect(miTurno, findsOneWidget);
        for (var indice = 0; indice < mapa.celdasIniciales.length; indice++) {
          final (fila, columna) = mapa.celdasIniciales[indice];
          expect(
            find.descendant(
              of: find.byKey(Key('cell-$fila-$columna')),
              matching: find.text('${numeros[indice]}'),
            ),
            findsOneWidget,
          );
        }
      }
    });
  });
}
