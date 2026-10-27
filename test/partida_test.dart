import 'dart:math';

import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/dados.dart';
import 'package:juego_brilliant/historial_movimientos.dart';
import 'package:juego_brilliant/mapa.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/validador_anclas.dart';

class MapaTodoVerde extends Mapa {
  const MapaTodoVerde();

  @override
  int get numero => 0;

  @override
  List<List<ColorZona>> get colores =>
      List.generate(7, (_) => List.filled(7, ColorZona.verde));

  @override
  List<(int, int)> get celdasIniciales => const [
    (1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (1, 6),
  ];

  @override
  Set<ColorZona> get coloresUnidos => const {};
}

void main() {
  void prepararIniciales(
    Partida partida, [
    List<int> valores = const [1, 2, 3, 4, 5, 6],
  ]) {
    final celdas = partida.mapa.celdasIniciales;
    for (var index = 0; index < celdas.length; index++) {
      final (fila, columna) = celdas[index];
      partida.colocarValorInicial(fila - 1, columna - 1, valores[index]);
    }
  }

  Partida partidaIniciada(Mapa mapa, {bool permitirRelanzar = true}) {
    final partida = Partida(mapa: mapa, permitirRelanzar: permitirRelanzar);
    prepararIniciales(partida);
    partida.iniciar();
    return partida;
  }

  OpcionAncla opcionConAncla(Partida partida, int ancla) =>
      partida.opcionesAncla.firstWhere((opcion) => opcion.ancla == ancla);

  group('Preparación', () {
    test('empieza preparando y bloqueada', () {
      final partida = Partida(mapa: mapaUno);

      expect(partida.estado, EstadoPartida.preparando);
      expect(partida.inicializado, isFalse);
      expect(partida.puedeIniciar, isFalse);
      expect(partida.valoresIniciales, everyElement(isNull));
      expect(partida.iniciar, throwsStateError);
    });

    test('no puede iniciar con 5 de 6 valores', () {
      final partida = Partida(mapa: mapaUno);
      prepararIniciales(partida);
      final (fila, columna) = mapaUno.celdasIniciales.last;
      partida.colocarValorInicial(fila - 1, columna - 1, null);

      expect(partida.puedeIniciar, isFalse);
      expect(partida.iniciar, throwsStateError);
    });

    test('no puede iniciar con valores duplicados', () {
      final partida = Partida(mapa: mapaUno);
      prepararIniciales(partida, [1, 1, 2, 3, 4, 5]);

      expect(partida.puedeIniciar, isFalse);
    });

    test('rechaza valores fuera de 1 a 6', () {
      final partida = Partida(mapa: mapaUno);
      final (fila, columna) = mapaUno.celdasIniciales.first;

      expect(
        () => partida.colocarValorInicial(fila - 1, columna - 1, 0),
        throwsArgumentError,
      );
      expect(
        () => partida.colocarValorInicial(fila - 1, columna - 1, 7),
        throwsArgumentError,
      );
    });

    test('rechaza celdas que no son iniciales del mapa', () {
      final partida = Partida(mapa: mapaUno);

      expect(() => partida.colocarValorInicial(0, 0, 1), throwsArgumentError);
    });

    test('con 1 a 6 puede iniciar y pasa a jugando', () {
      final partida = Partida(mapa: mapaUno);
      prepararIniciales(partida, [6, 5, 4, 3, 2, 1]);

      expect(partida.puedeIniciar, isTrue);
      expect(partida.valoresIniciales, [6, 5, 4, 3, 2, 1]);
      partida.iniciar();
      expect(partida.estado, EstadoPartida.jugando);
      expect(partida.puedeIniciar, isFalse);
    });

    test('vaciar una celda inicial antes de iniciar bloquea otra vez', () {
      final partida = Partida(mapa: mapaUno);
      prepararIniciales(partida);
      expect(partida.puedeIniciar, isTrue);

      final (fila, columna) = mapaUno.celdasIniciales.first;
      partida.colocarValorInicial(fila - 1, columna - 1, null);

      expect(partida.puedeIniciar, isFalse);
    });

    test('no deja colocar valores iniciales ya jugando', () {
      final partida = partidaIniciada(mapaUno);
      final (fila, columna) = mapaUno.celdasIniciales.first;

      expect(
        () => partida.colocarValorInicial(fila - 1, columna - 1, 2),
        throwsStateError,
      );
    });

    test('usa las celdas iniciales del mapa', () {
      final partida = Partida(mapa: const MapaTodoVerde());
      prepararIniciales(partida);

      expect(partida.tablero.obtenerCelda(0, 5).valor, 6);
      expect(partida.puedeIniciar, isTrue);
    });
  });

  group('Turno', () {
    test('no deja lanzar antes de iniciar', () {
      final partida = Partida(mapa: mapaUno);

      expect(partida.puedeLanzar, isFalse);
      expect(() => partida.registrarTirada([1, 2]), throwsStateError);
    });

    test('registrarTirada registra y deja la tirada pendiente', () {
      final partida = partidaIniciada(const MapaTodoVerde());

      final tirada = partida.registrarTirada([1, 5]);

      expect(partida.tiradaActual, same(tirada));
      expect(partida.historialLanzamientos.cantidad, 1);
      expect(partida.opcionesAncla, hasLength(2));
      expect(partida.hayMovimientosPosibles, isTrue);
      expect(partida.puedeSaltarTurno, isFalse);
    });

    test('con permitirRelanzar se puede lanzar sin resolver', () {
      final partida = partidaIniciada(const MapaTodoVerde());
      partida.registrarTirada([1, 5]);

      expect(partida.puedeLanzar, isTrue);
      partida.registrarTirada([2, 3]);
      expect(partida.historialLanzamientos.cantidad, 2);
      expect(partida.tiradaActual!.numeroTirada, 2);
    });

    test('sin permitirRelanzar hay que resolver la tirada', () {
      final partida = partidaIniciada(
        const MapaTodoVerde(),
        permitirRelanzar: false,
      );
      partida.registrarTirada([1, 5]);

      expect(partida.puedeLanzar, isFalse);
      expect(() => partida.registrarTirada([2, 3]), throwsStateError);
    });

    test('sin movimientos no se puede lanzar hasta saltar el turno', () {
      final partida = partidaIniciada(mapaUno);
      partida.registrarTirada([6, 1]);
      partida.colocar(opcionConAncla(partida, 6), 6, 5);

      partida.registrarTirada([6, 6]);

      expect(partida.hayMovimientosPosibles, isFalse);
      expect(partida.puedeSaltarTurno, isTrue);
      expect(partida.puedeLanzar, isFalse);
      expect(() => partida.registrarTirada([1, 2]), throwsStateError);

      partida.saltarTurno();

      expect(partida.tiradaActual, isNull);
      expect(partida.puedeLanzar, isTrue);
    });
  });

  group('Colocar', () {
    test('coloca el número del otro dado junto a la ancla', () {
      final partida = partidaIniciada(const MapaTodoVerde());
      partida.registrarTirada([1, 5]);
      final opcion = opcionConAncla(partida, 1);

      expect(partida.destinosValidos(opcion).map((c) => (c.fila, c.columna)), [
        (1, 0),
      ]);
      partida.colocar(opcion, 1, 0);

      expect(partida.tablero.obtenerCelda(1, 0).valor, 5);
      expect(partida.tiradaActual, isNull);
      final registro = partida.historialMovimientos.ultimo!;
      expect(registro.tipo, TipoMovimiento.colocacion);
      expect(
        (registro.numeroTirada, registro.ancla, registro.numeroColocado),
        (1, 1, 5),
      );
      expect((registro.fila, registro.columna), (1, 0));
    });

    test('rechaza un destino no válido', () {
      final partida = partidaIniciada(const MapaTodoVerde());
      partida.registrarTirada([1, 5]);

      expect(
        () => partida.colocar(opcionConAncla(partida, 1), 3, 3),
        throwsArgumentError,
      );
      expect(partida.tablero.obtenerCelda(3, 3).valor, isNull);
    });

    test('rechaza una opción que no es de la tirada actual', () {
      final partida = partidaIniciada(const MapaTodoVerde());
      partida.registrarTirada([1, 5]);

      expect(
        () => partida.colocar(
          const OpcionAncla(
            ancla: 3,
            numeroAColocar: 4,
            puedeSeleccionarse: true,
          ),
          1,
          2,
        ),
        throwsArgumentError,
      );
    });

    test('solo permite una colocación por tirada', () {
      final partida = partidaIniciada(const MapaTodoVerde());
      partida.registrarTirada([1, 5]);
      final opcion = opcionConAncla(partida, 1);
      partida.colocar(opcion, 1, 0);

      expect(() => partida.colocar(opcion, 2, 0), throwsStateError);
    });

    test('no deja saltar el turno si hay movimientos', () {
      final partida = partidaIniciada(const MapaTodoVerde());

      expect(partida.saltarTurno, throwsStateError);
      partida.registrarTirada([1, 5]);
      expect(partida.saltarTurno, throwsStateError);
    });
  });

  group('Saltar turno', () {
    test('no cambia el tablero ni los puntos y queda registrado', () {
      final partida = partidaIniciada(mapaUno);
      partida.registrarTirada([6, 1]);
      partida.colocar(opcionConAncla(partida, 6), 6, 5);
      partida.registrarTirada([6, 6]);
      final antes = partida.tablero.celdas.map((c) => c.valor).toList();
      final puntosAntes = partida.puntuacionTotal;

      partida.saltarTurno();

      expect(partida.tablero.celdas.map((c) => c.valor).toList(), antes);
      expect(partida.puntuacionTotal, puntosAntes);
      final salto = partida.historialMovimientos.ultimo!;
      expect(salto.tipo, TipoMovimiento.saltoTurno);
      expect(salto.numeroTirada, 2);
    });
  });

  group('Fin de partida', () {
    test('termina al llenar el tablero y suma los puntos de la zona', () {
      final partida = partidaIniciada(const MapaTodoVerde());
      for (final celda in partida.tablero.celdas) {
        if (celda.valor == null && !(celda.fila == 6 && celda.columna == 6)) {
          celda.valor = 1;
        }
      }
      expect(partida.puntuacionTotal, 0);

      partida.registrarTirada([1, 2]);
      partida.colocar(opcionConAncla(partida, 1), 6, 6);

      expect(partida.estado, EstadoPartida.terminada);
      expect(partida.terminada, isTrue);
      expect(partida.puntuacionTotal, 4);
      expect(partida.puntuacionMaxima, 4);
      expect(partida.puntuacionPorZona, {0: 4});
      expect(partida.historialMovimientos.movimientos.map((m) => m.tipo), [
        TipoMovimiento.colocacion,
        TipoMovimiento.zonaCompletada,
        TipoMovimiento.puntosGanados,
      ]);
      expect(partida.historialMovimientos.ultimo!.puntos, 4);

      expect(partida.puedeLanzar, isFalse);
      expect(() => partida.registrarTirada([1, 2]), throwsStateError);
      expect(partida.saltarTurno, throwsStateError);
    });
  });

  test('reiniciar vuelve a preparando con todo vacío', () {
    final partida = partidaIniciada(const MapaTodoVerde());
    partida.registrarTirada([1, 5]);
    partida.colocar(opcionConAncla(partida, 1), 1, 0);

    partida.reiniciar();

    expect(partida.estado, EstadoPartida.preparando);
    expect(partida.tablero.celdas.every((c) => c.valor == null), isTrue);
    expect(partida.historialLanzamientos.cantidad, 0);
    expect(partida.historialMovimientos.cantidad, 0);
    expect(partida.tiradaActual, isNull);
    expect(partida.tablero.regiones, hasLength(1));
  });

  test('simulación con dados fijos mantiene los invariantes', () {
    final partida = partidaIniciada(mapaUno);
    final dados = Dados(cantidad: 2, random: Random(7));

    for (var tirada = 0; tirada < 500 && !partida.terminada; tirada++) {
      partida.registrarTirada(dados.lanzar());
      if (partida.puedeSaltarTurno) {
        partida.saltarTurno();
        continue;
      }
      final opcion = partida.opcionesAncla.firstWhere(
        (opcion) => partida.destinosValidos(opcion).isNotEmpty,
      );
      final destino = partida.destinosValidos(opcion).first;
      partida.colocar(opcion, destino.fila, destino.columna);
    }

    final movimientos = partida.historialMovimientos.movimientos;
    final colocaciones = movimientos
        .where((m) => m.tipo == TipoMovimiento.colocacion)
        .length;
    final saltos = movimientos
        .where((m) => m.tipo == TipoMovimiento.saltoTurno)
        .length;

    expect(
      partida.puntuacionTotal,
      lessThanOrEqualTo(partida.puntuacionMaxima),
    );
    for (final celda in partida.tablero.celdas) {
      if (celda.valor != null) expect(celda.valor, inInclusiveRange(1, 6));
    }
    expect(
      partida.historialLanzamientos.cantidad,
      greaterThanOrEqualTo(colocaciones + saltos),
    );
    expect(colocaciones, greaterThan(0));
  });
}
