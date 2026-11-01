import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_cuatro.dart';
import 'package:juego_brilliant/partida.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  group('Mapa 4: zonas', () {
    const a = ColorZona.amarillo;
    const v = ColorZona.verde;
    const z = ColorZona.azul;
    const m = ColorZona.morado;
    const r = ColorZona.rojo;
    const o = ColorZona.naranja;

    late Tablero tablero;

    setUp(() {
      tablero = mapaCuatro.crearTablero();
    });

    List<(int, int)> celdasDe(Zona zona) => [
      for (final coordenada in zona.coordenadas)
        (coordenada.fila, coordenada.columna),
    ];

    int zonasDe(ColorZona color) =>
        tablero.regiones.where((zona) => zona.tipo.colorZona == color).length;

    test('Es el mapa número 4', () {
      expect(mapaCuatro.numero, 4);
    });

    test('El dibujo mide 7x7', () {
      expect(mapaCuatro.colores, hasLength(7));
      for (final fila in mapaCuatro.colores) {
        expect(fila, hasLength(7));
      }
    });

    test('El dibujo coincide con el del papel', () {
      expect(mapaCuatro.colores, [
        [o, o, o, o, o, o, o],
        [a, r, z, v, z, r, a],
        [r, r, m, m, m, r, r],
        [a, v, z, m, z, v, a],
        [r, r, m, m, m, r, r],
        [a, r, z, v, z, r, a],
        [o, o, o, o, o, o, o],
      ]);
    });

    test('Arma 8 zonas con ids consecutivos desde 0', () {
      expect(
        tablero.regiones.map((zona) => zona.id),
        List.generate(8, (i) => i),
      );
    });

    test(
      'Tiene 2 zonas naranjas, 2 rojas, 1 morada, 1 amarilla, 1 azul y 1 verde',
      () {
        expect(zonasDe(ColorZona.naranja), 2);
        expect(zonasDe(ColorZona.rojo), 2);
        expect(zonasDe(ColorZona.morado), 1);
        expect(zonasDe(ColorZona.amarillo), 1);
        expect(zonasDe(ColorZona.azul), 1);
        expect(zonasDe(ColorZona.verde), 1);
        expect(zonasDe(ColorZona.gris), 0);
      },
    );

    test('Las zonas en orden de id tienen el color y el tamaño esperados', () {
      expect(tablero.regiones.map((zona) => zona.tipo.colorZona), [
        o,
        a,
        r,
        z,
        v,
        r,
        m,
        o,
      ]);
      expect(tablero.regiones.map((zona) => zona.tamanoZona), [
        7,
        6,
        6,
        6,
        4,
        6,
        7,
        7,
      ]);
    });

    test('Cada celda está en una sola zona del mismo color', () {
      for (var fila = 0; fila < 7; fila++) {
        for (var columna = 0; columna < 7; columna++) {
          final zonas = tablero.regiones
              .where((zona) => zona.contieneCoordenada(fila, columna))
              .toList();
          expect(zonas, hasLength(1), reason: 'Celda ($fila, $columna)');
          expect(
            zonas.single.tipo.colorZona,
            mapaCuatro.colorEn(fila, columna),
          );
        }
      }
      expect(
        tablero.regiones.fold(0, (total, zona) => total + zona.tamanoZona),
        49,
      );
    });

    test('El amarillo, el azul y el verde son colores unidos', () {
      expect(mapaCuatro.coloresUnidos, {
        ColorZona.amarillo,
        ColorZona.azul,
        ColorZona.verde,
      });
    });

    test('Las 6 celdas amarillas separadas forman una sola zona', () {
      final amarilla = tablero.zonaEn(1, 0)!;

      expect(amarilla.tipo.colorZona, ColorZona.amarillo);
      expect(celdasDe(amarilla), [
        (1, 0),
        (1, 6),
        (3, 0),
        (3, 6),
        (5, 0),
        (5, 6),
      ]);
    });

    test('Las 6 celdas azules separadas forman una sola zona', () {
      final azul = tablero.zonaEn(1, 2)!;

      expect(azul.tipo.colorZona, ColorZona.azul);
      expect(celdasDe(azul), [(1, 2), (1, 4), (3, 2), (3, 4), (5, 2), (5, 4)]);
    });

    test('Las 4 celdas verdes separadas forman una sola zona', () {
      final verde = tablero.zonaEn(1, 3)!;

      expect(verde.tipo.colorZona, ColorZona.verde);
      expect(celdasDe(verde), [(1, 3), (3, 1), (3, 5), (5, 3)]);
    });

    test(
      'Los rojos de la izquierda están unidos por partes en una sola zona',
      () {
        final izquierda = tablero.zonaEn(2, 0)!;

        expect(tablero.zonaEn(4, 0), same(izquierda));
        expect(celdasDe(izquierda), [
          (1, 1),
          (2, 0),
          (2, 1),
          (4, 0),
          (4, 1),
          (5, 1),
        ]);
      },
    );

    test('Los rojos de la derecha están unidos por partes en otra zona', () {
      final derecha = tablero.zonaEn(2, 6)!;

      expect(tablero.zonaEn(4, 6), same(derecha));
      expect(derecha, isNot(same(tablero.zonaEn(2, 0))));
      expect(celdasDe(derecha), [
        (1, 5),
        (2, 5),
        (2, 6),
        (4, 5),
        (4, 6),
        (5, 5),
      ]);
    });

    test('Las partes unidas son los rojos de cada lado', () {
      expect(mapaCuatro.partesUnidas, [
        [(3, 1), (5, 1)],
        [(3, 7), (5, 7)],
      ]);
    });

    test('Las dos filas naranjas no se unen', () {
      final arriba = tablero.zonaEn(0, 0)!;
      final abajo = tablero.zonaEn(6, 0)!;

      expect(arriba, isNot(same(abajo)));
      expect(celdasDe(arriba), [for (var c = 0; c < 7; c++) (0, c)]);
      expect(celdasDe(abajo), [for (var c = 0; c < 7; c++) (6, c)]);
    });

    test('El morado del centro forma una sola zona de 7 celdas', () {
      final morada = tablero.zonaEn(3, 3)!;

      expect(celdasDe(morada), [
        (2, 2),
        (2, 3),
        (2, 4),
        (3, 3),
        (4, 2),
        (4, 3),
        (4, 4),
      ]);
    });
  });

  group('Mapa 4: reglas y puntos', () {
    late Tablero tablero;

    setUp(() {
      tablero = mapaCuatro.crearTablero();
    });

    int primerLugarDe(ColorZona color) => tablero.regiones
        .firstWhere((zona) => zona.tipo.colorZona == color)
        .tipo
        .calcularPuntuacion(1);

    test('Cada color da los puntos del primer lugar del Mapa 4', () {
      expect(primerLugarDe(ColorZona.amarillo), 8);
      expect(primerLugarDe(ColorZona.rojo), 6);
      expect(primerLugarDe(ColorZona.azul), 8);
      expect(primerLugarDe(ColorZona.verde), 3);
      expect(primerLugarDe(ColorZona.morado), 7);
      expect(primerLugarDe(ColorZona.naranja), 6);
    });

    test('Las dos zonas naranjas dan 6 puntos cada una', () {
      expect(tablero.zonaEn(0, 0)!.tipo.calcularPuntuacion(1), 6);
      expect(tablero.zonaEn(6, 0)!.tipo.calcularPuntuacion(1), 6);
    });

    test('La puntuación máxima del Mapa 4 es 50', () {
      expect(tablero.puntuacionMaxima, 50);
    });

    test('El naranja de la fila 1 acepta números del 4 al 6', () {
      tablero.colocarDato(0, 0, 5);

      expect(tablero.zonaEn(0, 6)!.validarNuevoMovimiento(5), isTrue);
      expect(tablero.zonaEn(0, 6)!.validarNuevoMovimiento(4), isTrue);
    });

    test('El naranja de la fila 1 rechaza números del 1 al 3', () {
      expect(tablero.zonaEn(0, 3)!.validarNuevoMovimiento(3), isFalse);
    });

    test('El naranja de la fila 7 acepta números del 1 al 3', () {
      tablero.colocarDato(6, 0, 2);

      expect(tablero.zonaEn(6, 6)!.validarNuevoMovimiento(2), isTrue);
      expect(tablero.zonaEn(6, 6)!.validarNuevoMovimiento(3), isTrue);
    });

    test('El naranja de la fila 7 rechaza números del 4 al 6', () {
      expect(tablero.zonaEn(6, 3)!.validarNuevoMovimiento(4), isFalse);
    });

    test('La zona amarilla acepta en otra celda separada un número nuevo', () {
      tablero.colocarDato(1, 0, 4);

      expect(tablero.zonaEn(5, 6)!.validarNuevoMovimiento(3), isTrue);
    });

    test(
      'La zona amarilla rechaza en otra celda separada un número repetido',
      () {
        tablero.colocarDato(1, 0, 4);

        expect(tablero.zonaEn(5, 6)!.validarNuevoMovimiento(4), isFalse);
      },
    );

    test('La zona azul acepta en otra celda separada el mismo número', () {
      tablero.colocarDato(1, 2, 6);

      expect(tablero.zonaEn(5, 4)!.validarNuevoMovimiento(6), isTrue);
    });

    test('La zona azul rechaza en otra celda separada un número distinto', () {
      tablero.colocarDato(1, 2, 6);

      expect(tablero.zonaEn(5, 4)!.validarNuevoMovimiento(1), isFalse);
    });

    test(
      'La zona verde unida acepta cualquier número en sus celdas separadas',
      () {
        tablero.colocarDato(1, 3, 2);

        expect(tablero.zonaEn(5, 3)!.validarNuevoMovimiento(2), isTrue);
        expect(tablero.zonaEn(5, 3)!.validarNuevoMovimiento(6), isTrue);
      },
    );

    test(
      'El rojo de la izquierda acepta en un pedazo un número que no está en el otro',
      () {
        tablero.colocarDato(1, 1, 3);

        expect(tablero.zonaEn(5, 1)!.validarNuevoMovimiento(4), isTrue);
      },
    );

    test(
      'El rojo de la izquierda rechaza en un pedazo un número que está en el otro',
      () {
        tablero.colocarDato(1, 1, 3);

        expect(tablero.zonaEn(5, 1)!.validarNuevoMovimiento(3), isFalse);
      },
    );

    test(
      'El rojo de la derecha no se ve afectado por los números del de la izquierda',
      () {
        tablero.colocarDato(1, 1, 3);

        expect(tablero.zonaEn(1, 5)!.validarNuevoMovimiento(3), isTrue);
      },
    );
  });

  group('Mapa 4: números iniciales', () {
    const celdasEsperadas = [(1, 5), (3, 3), (3, 6), (4, 1), (6, 5), (7, 2)];
    const numerosValidos = [6, 2, 3, 4, 5, 1];

    Partida partidaConNumerosIniciales() {
      final partida = Partida(mapa: mapaCuatro);
      final celdas = mapaCuatro.celdasIniciales;
      for (var indice = 0; indice < celdas.length; indice++) {
        final (fila, columna) = celdas[indice];
        partida.colocarValorInicial(
          fila - 1,
          columna - 1,
          numerosValidos[indice],
        );
      }
      return partida;
    }

    test('Tiene 6 celdas iniciales distintas dentro del tablero', () {
      final celdas = mapaCuatro.celdasIniciales;

      expect(celdas, celdasEsperadas);
      expect(celdas.toSet(), hasLength(6));
      for (final (fila, columna) in celdas) {
        expect(fila, inInclusiveRange(1, 7), reason: '($fila, $columna)');
        expect(columna, inInclusiveRange(1, 7), reason: '($fila, $columna)');
      }
      expect(mapaCuatro.crearTablero().celdasIniciales, celdasEsperadas);
    });

    test('Las celdas iniciales caen en las zonas esperadas', () {
      final tablero = mapaCuatro.crearTablero();

      Zona zonaDe((int, int) celda) =>
          tablero.zonaEn(celda.$1 - 1, celda.$2 - 1)!;

      expect(celdasEsperadas.map((celda) => zonaDe(celda).tipo.colorZona), [
        ColorZona.naranja,
        ColorZona.morado,
        ColorZona.rojo,
        ColorZona.amarillo,
        ColorZona.azul,
        ColorZona.naranja,
      ]);
      expect(celdasEsperadas.map((celda) => zonaDe(celda).id), [
        0,
        6,
        5,
        1,
        3,
        7,
      ]);
    });

    test(
      'Los números del 1 al 6 en orden no caben porque el naranja de arriba no acepta el 1',
      () {
        final partida = Partida(mapa: mapaCuatro);

        expect(partida.zonaAceptaValorInicial(0, 4, 1), isFalse);
        expect(() => partida.colocarValorInicial(0, 4, 1), throwsArgumentError);
      },
    );

    test('Hay un reparto del 1 al 6 que cada zona acepta', () {
      final partida = Partida(mapa: mapaCuatro);
      final celdas = mapaCuatro.celdasIniciales;

      expect(numerosValidos.toSet(), {1, 2, 3, 4, 5, 6});
      for (var indice = 0; indice < celdas.length; indice++) {
        final (fila, columna) = celdas[indice];
        final numero = numerosValidos[indice];

        expect(
          partida.zonaAceptaValorInicial(fila - 1, columna - 1, numero),
          isTrue,
          reason: 'celda ($fila, $columna) con $numero',
        );
        partida.colocarValorInicial(fila - 1, columna - 1, numero);
      }
      expect(partida.inicializado, isTrue);
    });

    test('Con ese reparto la partida puede iniciar', () {
      final partida = partidaConNumerosIniciales();

      expect(partida.puedeIniciar, isTrue);
      partida.iniciar();
      expect(partida.estado, EstadoPartida.jugando);
    });

    test('Con dados fijos se coloca un número en un destino válido', () {
      final partida = partidaConNumerosIniciales()..iniciar();

      partida.registrarTirada([6, 5]);
      final opcion = partida.opcionesAncla.firstWhere(
        (opcion) => opcion.ancla == 6,
      );
      final destinos = partida.destinosValidos(opcion);

      expect(opcion.puedeSeleccionarse, isTrue);
      expect(destinos.map((celda) => (celda.fila, celda.columna)), [
        (0, 3),
        (0, 5),
        (1, 4),
      ]);

      partida.colocar(opcion, 1, 4);

      expect(partida.tablero.obtenerCelda(1, 4).valor, 5);
      expect(partida.historialMovimientos.cantidad, 1);
      expect(partida.tiradaActual, isNull);
    });
  });
}
