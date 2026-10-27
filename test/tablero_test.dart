import 'package:test/test.dart';
import 'package:juego_brilliant/color_zona.dart';
import 'package:juego_brilliant/mapa_uno.dart';
import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart';
import 'package:juego_brilliant/validador_inicio.dart';
import 'package:juego_brilliant/zona.dart';

void main() {
  List<int?> leerValoresIniciales(Tablero tablero) => [
    for (final (fila, columna) in ValidadorInicio.celdasIniciales)
      tablero.obtenerCelda(fila - 1, columna - 1).valor,
  ];

  group('Validador de inicio', () {
    test('Valida los valores y el estado de la partida', () {
      final tablero = Tablero();
      final validador = ValidadorInicio();

      expect(validador.estado, EstadoInicialPartida.bloqueado);
      expect(validador.validarAntesDeIniciar, throwsA(isA<StateError>()));

      const valores = [1, 2, 3, 4, 5, 6];
      for (var index = 0;
          index < ValidadorInicio.celdasIniciales.length;
          index++) {
        final (fila, columna) = ValidadorInicio.celdasIniciales[index];
        tablero.colocarDato(fila - 1, columna - 1, valores[index]);
      }

      validador.actualizarValoresIniciales(leerValoresIniciales(tablero));
      expect(validador.estado, EstadoInicialPartida.inicializado);
      expect(validador.puedeIniciar, isTrue);
      expect(validador.validarAntesDeIniciar, returnsNormally);

      final (ultimaFila, ultimaColumna) = ValidadorInicio.celdasIniciales.last;
      tablero.colocarDato(ultimaFila - 1, ultimaColumna - 1, 7);
      validador.actualizarValoresIniciales(leerValoresIniciales(tablero));
      expect(validador.estado, EstadoInicialPartida.bloqueado);

      tablero.colocarDato(ultimaFila - 1, ultimaColumna - 1, valores.last);
      validador.actualizarValoresIniciales(leerValoresIniciales(tablero));
      validador.iniciarPartida();
      expect(validador.estado, EstadoInicialPartida.jugando);
      expect(validador.jugando, isTrue);
    });

    test('Rechaza números repetidos en las celdas iniciales', () {
      final tablero = Tablero();
      final validador = ValidadorInicio();

      for (final (fila, columna) in ValidadorInicio.celdasIniciales) {
        tablero.colocarDato(fila - 1, columna - 1, 1);
      }

      validador.actualizarValoresIniciales(leerValoresIniciales(tablero));
      expect(validador.estado, EstadoInicialPartida.bloqueado);
      expect(validador.iniciarPartida, throwsA(isA<StateError>()));
    });

    test('Conserva las coordenadas iniciales establecidas', () {
      expect(ValidadorInicio.celdasIniciales, [
        (1, 3),
        (2, 6),
        (4, 2),
        (4, 5),
        (6, 3),
        (7, 5),
      ]);
    });

    test('No acepta valores iniciales con un null', () {
      expect(
        ValidadorInicio.sonValoresInicialesValidos([1, 2, 3, 4, 5, null]),
        isFalse,
      );
    });
  });

  group('Bloqueo de valores iniciales del tablero', () {
    test('Un tablero nuevo está bloqueado', () {
      final tablero = Tablero();

      expect(tablero.inicializado, isFalse);
      expect(() => tablero.extraerDatos(), throwsA(isA<StateError>()));
    });

    test('Sigue bloqueado con 5 de 6 celdas iniciales llenas', () {
      final tablero = Tablero();

      for (var index = 0; index < 5; index++) {
        final (fila, columna) = ValidadorInicio.celdasIniciales[index];
        tablero.colocarDato(fila - 1, columna - 1, index + 1);
      }

      expect(tablero.inicializado, isFalse);
      expect(() => tablero.extraerDatos(), throwsA(isA<StateError>()));
    });

    test('Rechaza valores repetidos y sigue bloqueado', () {
      final tablero = Tablero();

      expect(
        () => tablero.establecerValoresIniciales([1, 1, 2, 3, 4, 5]),
        throwsArgumentError,
      );
      expect(tablero.inicializado, isFalse);
    });

    test('Rechaza valores fuera del rango 1 a 6', () {
      final tablero = Tablero();

      expect(
        () => tablero.establecerValoresIniciales([0, 1, 2, 3, 4, 5]),
        throwsArgumentError,
      );
      expect(
        () => tablero.establecerValoresIniciales([1, 2, 3, 4, 5, 7]),
        throwsArgumentError,
      );
    });

    test('Rechaza listas con 5 o 7 valores', () {
      final tablero = Tablero();

      expect(
        () => tablero.establecerValoresIniciales([1, 2, 3, 4, 5]),
        throwsArgumentError,
      );
      expect(
        () => tablero.establecerValoresIniciales([1, 2, 3, 4, 5, 6, 7]),
        throwsArgumentError,
      );
    });

    test('Un intento inválido no deja ninguna celda inicial con valor', () {
      final tablero = Tablero();

      for (final valores in [
        [1, 1, 2, 3, 4, 5],
        [0, 1, 2, 3, 4, 5],
        [1, 2, 3, 4, 5, 7],
        [1, 2, 3, 4, 5],
        [1, 2, 3, 4, 5, 6, 7],
      ]) {
        expect(
          () => tablero.establecerValoresIniciales(valores),
          throwsArgumentError,
        );
      }

      expect(tablero.valoresIniciales, everyElement(isNull));
    });

    test('Acepta los valores en cualquier orden y desbloquea', () {
      final tablero = Tablero();
      const valores = [6, 5, 4, 3, 2, 1];

      tablero.establecerValoresIniciales(valores);

      expect(tablero.inicializado, isTrue);
      expect(leerValoresIniciales(tablero), valores);
      expect(tablero.valoresIniciales, valores);
      expect(() => tablero.extraerDatos(), returnsNormally);
    });

    test('Vuelve a bloquearse si se borra una celda inicial', () {
      final tablero = Tablero();
      tablero.establecerValoresIniciales([1, 2, 3, 4, 5, 6]);

      final (fila, columna) = ValidadorInicio.celdasIniciales.first;
      tablero.colocarDato(fila - 1, columna - 1, null);

      expect(tablero.inicializado, isFalse);
      expect(() => tablero.extraerDatos(), throwsA(isA<StateError>()));
    });
  });

  Tipo crearTipoVerde() {
    return TipoVerde();
  }

  group('Pruebas del Tablero', () {
    test('Verifica que el tablero mida 7x7 casillas', () {
      final tablero = Tablero();
      expect(Tablero.cantidadFilas, equals(7));
      expect(Tablero.cantidadColumnas, equals(7));
      expect(tablero.celdas, hasLength(49));
    });

    test('Guarda y lee correctamente un dato en las celdas', () {
      final tablero = Tablero();

      tablero.colocarDato(0, 6, 9);
      tablero.colocarDato(6, 0, 4);

      expect(tablero.obtenerCelda(0, 6).valor, equals(9));
      expect(tablero.obtenerCelda(6, 0).valor, equals(4));
    });

    test('Rechaza coordenadas fuera del tablero', () {
      final tablero = Tablero();

      expect(
        () => tablero.obtenerCelda(7, 0),
        throwsRangeError,
      );
    });
    test('Extrae en orden de derecha a izquierda y arriba hacia abajo', () {
      final tablero = Tablero();

      tablero.establecerValoresIniciales([1, 2, 3, 4, 5, 6]);
      tablero.colocarDato(0, 6, 1);
      tablero.colocarDato(0, 5, 2);
      tablero.colocarDato(1, 6, 3);

      final resultado = tablero.extraerDatos();

      expect(resultado[0], equals(1));
      expect(resultado[1], equals(2));
      expect(resultado[7], equals(3));
    });

    test('Bloquea la extracción si no se han proporcionado los valores iniciales', () {
      final tablero = Tablero();

      expect(
        () => tablero.extraerDatos(),
        throwsA(isA<StateError>()),
      );
    });

    test('Permite guardar una región sin asignarla a cada celda individualmente', () {
      final tablero = Tablero();
      final region = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [
          tablero.obtenerCelda(0, 0),
          tablero.obtenerCelda(0, 1),
        ],
      );

      tablero.agregarRegion(region);

      expect(tablero.regiones, contains(region));
      expect(tablero.obtenerCeldasDeRegion(region), hasLength(2));
    });

    test('No permite regiones con ids duplicados', () {
      final tablero = Tablero();
      final primera = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [tablero.obtenerCelda(0, 0)],
      );
      final segunda = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [tablero.obtenerCelda(1, 0)],
      );

      tablero.agregarRegion(primera);

      expect(
        () => tablero.agregarRegion(segunda),
        throwsArgumentError,
      );
    });
  });

  group('Zona de una celda', () {
    test('Devuelve la zona que contiene la celda', () {
      final tablero = mapaUno.crearTablero();

      expect(tablero.zonaEn(0, 0)!.id, 0);
      expect(tablero.zonaEn(0, 0)!.tipo.colorZona, ColorZona.amarillo);
      expect(tablero.zonaEn(6, 6), same(tablero.zonaEn(0, 0)));
      expect(tablero.zonaEn(0, 1)!.id, 1);
      expect(tablero.zonaEn(0, 1)!.tipo.colorZona, ColorZona.verde);
      expect(tablero.zonaEn(6, 5)!.tipo.colorZona, ColorZona.azul);
    });

    test('Devuelve null si ninguna zona contiene la celda', () {
      expect(Tablero().zonaEn(3, 3), isNull);
    });

    test('Lanza RangeError fuera del tablero', () {
      final tablero = mapaUno.crearTablero();

      expect(() => tablero.zonaEn(7, 0), throwsRangeError);
      expect(() => tablero.zonaEn(0, -1), throwsRangeError);
    });
  });

  group('Celdas iniciales inyectadas', () {
    test('Usa las celdas iniciales recibidas', () {
      final tablero = Tablero(
        celdasIniciales: const [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6)],
      );

      tablero.establecerValoresIniciales([1, 2, 3, 4, 5, 6]);

      expect(tablero.inicializado, isTrue);
      expect(
        [
          for (var columna = 0; columna < 6; columna++)
            tablero.obtenerCelda(0, columna).valor,
        ],
        [1, 2, 3, 4, 5, 6],
      );
    });

    test('Sin celdas usa las del profesor', () {
      expect(Tablero().celdasIniciales, ValidadorInicio.celdasIniciales);
    });

    test('Rechaza celdas iniciales inválidas', () {
      expect(
        () => Tablero(
          celdasIniciales: const [(1, 1), (1, 2), (1, 3), (1, 4), (1, 5)],
        ),
        throwsArgumentError,
      );
      expect(
        () => Tablero(
          celdasIniciales: const [
            (1, 1),
            (1, 1),
            (1, 3),
            (1, 4),
            (1, 5),
            (1, 6),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => Tablero(
          celdasIniciales: const [
            (0, 1),
            (1, 2),
            (1, 3),
            (1, 4),
            (1, 5),
            (1, 6),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('estaLleno solo es true con todas las celdas con valor', () {
      final tablero = Tablero();
      for (final celda in tablero.celdas) {
        celda.valor = 1;
      }
      expect(tablero.estaLleno, isTrue);

      tablero.colocarDato(3, 3, null);
      expect(tablero.estaLleno, isFalse);
    });
  });
}
