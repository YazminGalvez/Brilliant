import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_dos.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  group('Mapa 2: zonas', () {
    const a = ColorZona.amarillo;
    const v = ColorZona.verde;
    const z = ColorZona.azul;
    const m = ColorZona.morado;
    const r = ColorZona.rojo;
    const g = ColorZona.gris;

    late Tablero tablero;

    setUp(() {
      tablero = mapaDos.crearTablero();
    });

    List<(int, int)> celdasDe(Zona zona) => [
      for (final coordenada in zona.coordenadas)
        (coordenada.fila, coordenada.columna),
    ];

    int zonasDe(ColorZona color) =>
        tablero.regiones.where((zona) => zona.tipo.colorZona == color).length;

    test('Es el mapa número 2', () {
      expect(mapaDos.numero, 2);
    });

    test('El dibujo mide 7x7', () {
      expect(mapaDos.colores, hasLength(7));
      for (final fila in mapaDos.colores) {
        expect(fila, hasLength(7));
      }
    });

    test('El dibujo coincide con el del papel', () {
      expect(mapaDos.colores, [
        [m, m, m, g, v, v, v],
        [m, a, z, z, z, a, v],
        [m, r, r, z, z, r, v],
        [r, r, r, a, r, r, r],
        [v, r, z, z, r, r, m],
        [v, a, z, z, z, a, m],
        [v, v, v, g, m, m, m],
      ]);
    });

    test('Arma 10 zonas con ids consecutivos desde 0', () {
      expect(
        tablero.regiones.map((zona) => zona.id),
        List.generate(10, (i) => i),
      );
    });

    test(
      'Tiene 2 zonas moradas, rojas, azules y verdes, y 1 amarilla y 1 gris',
      () {
        expect(zonasDe(ColorZona.morado), 2);
        expect(zonasDe(ColorZona.rojo), 2);
        expect(zonasDe(ColorZona.azul), 2);
        expect(zonasDe(ColorZona.verde), 2);
        expect(zonasDe(ColorZona.amarillo), 1);
        expect(zonasDe(ColorZona.gris), 1);
      },
    );

    test('Las zonas en orden de id tienen el color y el tamaño esperados', () {
      expect(tablero.regiones.map((zona) => zona.tipo.colorZona), [
        m,
        g,
        v,
        a,
        z,
        r,
        r,
        v,
        z,
        m,
      ]);
      expect(tablero.regiones.map((zona) => zona.tamanoZona), [
        5,
        2,
        5,
        5,
        5,
        6,
        6,
        5,
        5,
        5,
      ]);
    });

    test('Cada celda está en una sola zona del mismo color', () {
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          final zonas = tablero.regiones
              .where((zona) => zona.contieneCoordenada(fila, columna))
              .toList();
          expect(zonas, hasLength(1), reason: 'Celda ($fila, $columna)');
          expect(zonas.single.tipo.colorZona, mapaDos.colorEn(fila, columna));
        }
      }
      expect(
        tablero.regiones.fold(0, (total, zona) => total + zona.tamanoZona),
        49,
      );
    });

    test('El amarillo y el gris son colores unidos', () {
      expect(mapaDos.coloresUnidos, {ColorZona.amarillo, ColorZona.gris});
    });

    test('Las 5 celdas amarillas separadas forman una sola zona', () {
      final amarilla = tablero.zonaEn(1, 1)!;

      expect(amarilla.tipo.colorZona, ColorZona.amarillo);
      expect(celdasDe(amarilla), [(1, 1), (1, 5), (3, 3), (5, 1), (5, 5)]);
      expect(tablero.zonaEn(5, 5), same(amarilla));
    });

    test('Las 2 celdas grises separadas forman una sola zona', () {
      final gris = tablero.zonaEn(0, 3)!;

      expect(gris.tipo.colorZona, ColorZona.gris);
      expect(celdasDe(gris), [(0, 3), (6, 3)]);
      expect(tablero.zonaEn(6, 3), same(gris));
    });

    test('Las dos zonas moradas no se unen', () {
      final arriba = tablero.zonaEn(0, 0)!;
      final abajo = tablero.zonaEn(6, 6)!;

      expect(arriba, isNot(same(abajo)));
      expect(celdasDe(arriba), [(0, 0), (0, 1), (0, 2), (1, 0), (2, 0)]);
      expect(celdasDe(abajo), [(4, 6), (5, 6), (6, 4), (6, 5), (6, 6)]);
    });

    test('Las dos zonas verdes no se unen', () {
      final arriba = tablero.zonaEn(0, 6)!;
      final abajo = tablero.zonaEn(6, 0)!;

      expect(arriba, isNot(same(abajo)));
      expect(celdasDe(arriba), [(0, 4), (0, 5), (0, 6), (1, 6), (2, 6)]);
      expect(celdasDe(abajo), [(4, 0), (5, 0), (6, 0), (6, 1), (6, 2)]);
    });

    test('Las dos zonas azules no se unen', () {
      final arriba = tablero.zonaEn(1, 3)!;
      final abajo = tablero.zonaEn(5, 3)!;

      expect(arriba, isNot(same(abajo)));
      expect(celdasDe(arriba), [(1, 2), (1, 3), (1, 4), (2, 3), (2, 4)]);
      expect(celdasDe(abajo), [(4, 2), (4, 3), (5, 2), (5, 3), (5, 4)]);
    });

    test('Las dos zonas rojas no se unen aunque estén en la misma fila', () {
      final izquierda = tablero.zonaEn(3, 0)!;
      final derecha = tablero.zonaEn(3, 6)!;

      expect(izquierda, isNot(same(derecha)));
      expect(celdasDe(izquierda), [
        (2, 1),
        (2, 2),
        (3, 0),
        (3, 1),
        (3, 2),
        (4, 1),
      ]);
      expect(celdasDe(derecha), [
        (2, 5),
        (3, 4),
        (3, 5),
        (3, 6),
        (4, 4),
        (4, 5),
      ]);
    });
  });

  group('Mapa 2: reglas y puntos', () {
    late Tablero tablero;

    setUp(() {
      tablero = mapaDos.crearTablero();
    });

    int primerLugarDe(ColorZona color) => tablero.regiones
        .firstWhere((zona) => zona.tipo.colorZona == color)
        .tipo
        .calcularPuntuacion(1);

    test('Cada color da los puntos del primer lugar del Mapa 2', () {
      expect(primerLugarDe(ColorZona.amarillo), 6);
      expect(primerLugarDe(ColorZona.morado), 6);
      expect(primerLugarDe(ColorZona.rojo), 6);
      expect(primerLugarDe(ColorZona.azul), 7);
      expect(primerLugarDe(ColorZona.verde), 4);
      expect(primerLugarDe(ColorZona.gris), 3);
    });

    test('Las dos zonas del mismo color dan los mismos puntos', () {
      for (final zona in tablero.regiones) {
        expect(
          zona.tipo.calcularPuntuacion(1),
          mapaDos.crearTipo(zona.tipo.colorZona).calcularPuntuacion(1),
          reason: 'zona ${zona.id}',
        );
      }
    });

    test('El amarillo del Mapa 2 conserva los puntos de 2.º y 3.er lugar', () {
      final amarilla = tablero.zonaEn(1, 1)!.tipo;

      expect(amarilla.puntuaciones, {1: 6, 2: 6, 3: 4});
    });

    test('La puntuación máxima del Mapa 2 es 55', () {
      expect(tablero.puntuacionMaxima, 55);
    });

    test('La zona gris acepta en su otra celda el mismo número', () {
      tablero.colocarDato(0, 3, 2);

      expect(tablero.zonaEn(6, 3)!.validarNuevoMovimiento(2), isTrue);
    });

    test('La zona gris rechaza en su otra celda un número distinto', () {
      tablero.colocarDato(0, 3, 2);

      expect(tablero.zonaEn(6, 3)!.validarNuevoMovimiento(5), isFalse);
    });

    test('La zona amarilla acepta en otra celda separada un número nuevo', () {
      tablero.colocarDato(1, 1, 4);

      expect(tablero.zonaEn(5, 5)!.validarNuevoMovimiento(3), isTrue);
    });

    test(
      'La zona amarilla rechaza en otra celda separada un número repetido',
      () {
        tablero.colocarDato(1, 1, 4);

        expect(tablero.zonaEn(5, 5)!.validarNuevoMovimiento(4), isFalse);
      },
    );
  });

  group('Mapa 2: números iniciales', () {
    const celdasEsperadas = [(1, 5), (3, 1), (4, 3), (5, 6), (6, 2), (7, 5)];

    Partida partidaConNumerosIniciales() {
      final partida = Partida(mapa: mapaDos);
      final celdas = mapaDos.celdasIniciales;
      for (var indice = 0; indice < celdas.length; indice++) {
        final (fila, columna) = celdas[indice];
        partida.colocarValorInicial(fila - 1, columna - 1, indice + 1);
      }
      return partida;
    }

    test('Tiene 6 celdas iniciales distintas dentro del tablero', () {
      final celdas = mapaDos.celdasIniciales;

      expect(celdas, celdasEsperadas);
      expect(celdas.toSet(), hasLength(6));
      for (final (fila, columna) in celdas) {
        expect(fila, inInclusiveRange(1, 7), reason: '($fila, $columna)');
        expect(columna, inInclusiveRange(1, 7), reason: '($fila, $columna)');
      }
      expect(mapaDos.crearTablero().celdasIniciales, celdasEsperadas);
    });

    test('Las celdas iniciales caen en las zonas esperadas', () {
      final tablero = mapaDos.crearTablero();

      Zona zonaDe((int, int) celda) =>
          tablero.zonaEn(celda.$1 - 1, celda.$2 - 1)!;

      expect(celdasEsperadas.map((celda) => zonaDe(celda).tipo.colorZona), [
        ColorZona.verde,
        ColorZona.morado,
        ColorZona.rojo,
        ColorZona.rojo,
        ColorZona.amarillo,
        ColorZona.morado,
      ]);
      expect(celdasEsperadas.map((celda) => zonaDe(celda).id), [
        2,
        0,
        5,
        6,
        3,
        9,
      ]);
    });

    test('Cada número del 1 al 6 es aceptado por la zona de su celda', () {
      final tablero = mapaDos.crearTablero();
      final celdas = mapaDos.celdasIniciales;

      for (var indice = 0; indice < celdas.length; indice++) {
        final (fila, columna) = celdas[indice];
        final zona = tablero.zonaEn(fila - 1, columna - 1)!;
        final numero = indice + 1;

        expect(
          zona.validarNuevoMovimiento(numero),
          isTrue,
          reason: 'celda ($fila, $columna) con $numero',
        );
        tablero.colocarDato(fila - 1, columna - 1, numero);
      }
      expect(tablero.inicializado, isTrue);
    });

    test('Con los números del 1 al 6 la partida puede iniciar', () {
      final partida = partidaConNumerosIniciales();

      expect(partida.puedeIniciar, isTrue);
      partida.iniciar();
      expect(partida.estado, EstadoPartida.jugando);
    });

    test('Con dados fijos se coloca un número en un destino válido', () {
      final partida = partidaConNumerosIniciales()..iniciar();

      partida.registrarTirada([1, 2]);
      final opcion = partida.opcionesAncla.firstWhere(
        (opcion) => opcion.ancla == 1,
      );
      final destinos = partida.destinosValidos(opcion);

      expect(opcion.puedeSeleccionarse, isTrue);
      expect(destinos.map((celda) => (celda.fila, celda.columna)), [
        (0, 3),
        (0, 5),
        (1, 4),
      ]);

      partida.colocar(opcion, 0, 3);

      expect(partida.tablero.obtenerCelda(0, 3).valor, 2);
      expect(partida.historialMovimientos.cantidad, 1);
      expect(partida.tiradaActual, isNull);
    });
  });
}
