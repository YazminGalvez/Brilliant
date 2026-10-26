import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/historial_movimientos.dart';
import 'package:juego_brilliant/mapa_uno.dart';

void main() {
  RegistroMovimiento colocacion({
    int numeroTirada = 1,
    int ancla = 1,
    int numeroColocado = 2,
    int fila = 0,
    int columna = 0,
  }) => RegistroMovimiento.colocacion(
    numero: 1,
    numeroTirada: numeroTirada,
    ancla: ancla,
    numeroColocado: numeroColocado,
    fila: fila,
    columna: columna,
  );

  group('Registro de movimiento', () {
    test('La colocación guarda sus datos y deja los demás en null', () {
      final registro = colocacion(ancla: 3, numeroColocado: 5, fila: 2, columna: 6);

      expect(registro.tipo, TipoMovimiento.colocacion);
      expect(
        (registro.ancla, registro.numeroColocado, registro.fila, registro.columna),
        (3, 5, 2, 6),
      );
      expect(registro.idZona, isNull);
      expect(registro.color, isNull);
      expect(registro.puntos, isNull);
    });

    test('La colocación valida ancla, número, fila y columna', () {
      for (final valor in [0, 7]) {
        expect(() => colocacion(ancla: valor), throwsArgumentError);
        expect(() => colocacion(numeroColocado: valor), throwsArgumentError);
      }
      for (final valor in [-1, 7]) {
        expect(() => colocacion(fila: valor), throwsArgumentError);
        expect(() => colocacion(columna: valor), throwsArgumentError);
      }
    });

    test('Todos los tipos rechazan numeroTirada 0', () {
      expect(() => colocacion(numeroTirada: 0), throwsArgumentError);
      expect(
        () => RegistroMovimiento.saltoTurno(numero: 1, numeroTirada: 0),
        throwsArgumentError,
      );
      expect(
        () => RegistroMovimiento.zonaCompletada(
          numero: 1,
          numeroTirada: 0,
          idZona: 0,
          color: ColorZona.verde,
        ),
        throwsArgumentError,
      );
      expect(
        () => RegistroMovimiento.puntosGanados(
          numero: 1,
          numeroTirada: 0,
          puntos: 4,
        ),
        throwsArgumentError,
      );
    });

    test('Zona completada valida el id', () {
      expect(
        () => RegistroMovimiento.zonaCompletada(
          numero: 1,
          numeroTirada: 1,
          idZona: -1,
          color: ColorZona.verde,
        ),
        throwsArgumentError,
      );
    });

    test('Puntos ganados rechaza 0', () {
      expect(
        () => RegistroMovimiento.puntosGanados(
          numero: 1,
          numeroTirada: 1,
          puntos: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Historial de movimientos', () {
    test('Empieza vacío', () {
      final historial = HistorialMovimientos();

      expect(historial.movimientos, isEmpty);
      expect(historial.cantidad, 0);
      expect(historial.ultimo, isNull);
    });

    test('Numera los registros desde 1 y expone el último', () {
      final historial = HistorialMovimientos();

      historial.registrarColocacion(
        numeroTirada: 1,
        ancla: 1,
        numeroColocado: 2,
        fila: 0,
        columna: 1,
      );
      historial.registrarSaltoTurno(numeroTirada: 2);
      historial.registrarZonaCompletada(
        numeroTirada: 3,
        idZona: 4,
        color: ColorZona.verde,
      );
      final ultimo = historial.registrarPuntosGanados(
        numeroTirada: 3,
        puntos: 4,
      );

      expect(historial.movimientos.map((m) => m.numero), [1, 2, 3, 4]);
      expect(historial.cantidad, 4);
      expect(historial.ultimo, same(ultimo));
    });

    test('registrarJugada sin zona completada deja 1 registro', () {
      final historial = HistorialMovimientos();

      historial.registrarJugada(
        numeroTirada: 2,
        ancla: 3,
        numeroColocado: 4,
        fila: 1,
        columna: 1,
      );

      expect(historial.cantidad, 1);
      expect(historial.ultimo!.tipo, TipoMovimiento.colocacion);
    });

    test('registrarJugada con zona y puntos deja 3 registros en orden', () {
      final historial = HistorialMovimientos()..registrarSaltoTurno(numeroTirada: 1);
      final zona = mapaUno.crearTablero().zonaEn(0, 1)!;

      historial.registrarJugada(
        numeroTirada: 2,
        ancla: 3,
        numeroColocado: 4,
        fila: 0,
        columna: 1,
        zonaCompletada: zona,
        puntosGanados: 4,
      );

      final jugada = historial.movimientos.skip(1).toList();
      expect(jugada.map((m) => m.tipo), [
        TipoMovimiento.colocacion,
        TipoMovimiento.zonaCompletada,
        TipoMovimiento.puntosGanados,
      ]);
      expect(jugada.map((m) => m.numero), [2, 3, 4]);
      expect(jugada.map((m) => m.numeroTirada), [2, 2, 2]);
      expect(jugada[1].idZona, zona.id);
      expect(jugada[1].color, ColorZona.verde);
      expect(jugada[2].puntos, 4);
    });

    test('Un salto de turno no tiene datos de jugada ni puntos', () {
      final historial = HistorialMovimientos();

      final salto = historial.registrarSaltoTurno(numeroTirada: 5);

      expect(salto.tipo, TipoMovimiento.saltoTurno);
      expect(salto.numeroTirada, 5);
      expect(salto.puntos, isNull);
      expect(salto.ancla, isNull);
      expect(salto.numeroColocado, isNull);
      expect(historial.cantidad, 1);
    });

    test('La lista no se puede modificar y limpiar la vacía', () {
      final historial = HistorialMovimientos()..registrarSaltoTurno(numeroTirada: 1);

      expect(
        () => historial.movimientos.add(
          RegistroMovimiento.saltoTurno(numero: 2, numeroTirada: 2),
        ),
        throwsUnsupportedError,
      );

      historial.limpiar();
      expect(historial.movimientos, isEmpty);
      expect(historial.ultimo, isNull);
    });
  });
}
