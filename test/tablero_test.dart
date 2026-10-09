import 'package:test/test.dart';
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
    test('Bloquea el avance hasta configurar los valores iniciales', () {
      final validador = ValidadorInicio();

      expect(validador.validarAvance, throwsA(isA<StateError>()));

      validador.marcarValoresInicialesConfigurados();
      expect(validador.validarAvance, returnsNormally);
    });

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
      final region = Zona(
        id: 1,
        tipo: crearTipoVerde(),
        coordenadas: [tablero.obtenerCelda(0, 0)],
      );

      tablero.establecerValoresIniciales([region]);
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
}