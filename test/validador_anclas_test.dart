import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart';
import 'package:juego_brilliant/validador_anclas.dart';
import 'package:juego_brilliant/validador_inicio.dart';
import 'package:juego_brilliant/zona.dart';
import 'package:test/test.dart';

void main() {
  group('Validador de anclas', () {
    test('ofrece ambas opciones cuando los dos valores están en el tablero',
        () {
      final tablero = Tablero()
        ..colocarDato(0, 0, 6)
        ..colocarDato(0, 1, 1);
      final validador = ValidadorAnclas(tablero);

      expect(validador.obtenerAnclasPosibles(6, 1), [6, 1]);
      expect(
        validador
            .obtenerOpciones(6, 1)
            .map(
              (opcion) => (
                opcion.ancla,
                opcion.numeroAColocar,
                opcion.puedeSeleccionarse,
              ),
            ),
        [(6, 1, true), (1, 6, true)],
      );
    });

    test('solo permite como ancla el valor de dado presente en el tablero',
        () {
      final tablero = Tablero()..colocarDato(0, 0, 2);
      final validador = ValidadorAnclas(tablero);

      expect(validador.obtenerAnclasPosibles(2, 4), [2]);
      expect(
        validador
            .obtenerOpciones(2, 4)
            .map(
              (opcion) => (
                opcion.ancla,
                opcion.numeroAColocar,
                opcion.puedeSeleccionarse,
              ),
            ),
        [(2, 4, true), (4, 2, false)],
      );
    });

    test('reconoce valores iniciales y valores agregados después', () {
      final tablero = Tablero();
      final validador = ValidadorAnclas(tablero);

      for (var index = 0;
          index < ValidadorInicio.celdasIniciales.length;
          index++) {
        final (fila, columna) = ValidadorInicio.celdasIniciales[index];
        tablero.colocarDato(fila - 1, columna - 1, index + 1);
      }

      expect(tablero.valoresColocados, {1, 2, 3, 4, 5, 6});

      tablero.colocarDato(3, 4, null);
      expect(validador.obtenerAnclasPosibles(2, 4), [2]);

      tablero.colocarDato(0, 0, 4);
      expect(validador.obtenerAnclasPosibles(2, 4), [2, 4]);
    });

    test('un valor igual en ambos dados aparece como una sola ancla', () {
      final tablero = Tablero()..colocarDato(0, 0, 3);
      final validador = ValidadorAnclas(tablero);

      expect(validador.obtenerAnclasPosibles(3, 3), [3]);
      expect(validador.obtenerOpciones(3, 3), hasLength(1));
    });

    test('devuelve solo vecinos ortogonales vacíos que cumplen su zona', () {
      final tablero = Tablero();
      tablero.colocarDato(3, 3, 1);

      _agregarZona(tablero, 1, TipoAzul(), [(2, 3), (2, 2)]);
      tablero.colocarDato(2, 2, 3);

      _agregarZona(tablero, 2, TipoAmarillo(), [(3, 4), (3, 5)]);
      tablero.colocarDato(3, 5, 2);

      _agregarZona(tablero, 3, TipoRojo(), [(3, 2), (3, 1)]);
      tablero.colocarDato(3, 1, 2);

      _agregarZona(tablero, 4, TipoVerde(), [(4, 3)]);

      final destinos = ValidadorAnclas(
        tablero,
      ).buscarDestinosValidos(numeroAncla: 1, numeroDelOtroDado: 2);

      expect(destinos.map((celda) => (celda.fila, celda.columna)), [(4, 3)]);
    });

    test('no devuelve celdas ocupadas y respeta los límites del tablero', () {
      final tablero = Tablero();
      tablero.colocarDato(0, 0, 1);
      tablero.colocarDato(0, 1, 4);
      _agregarZona(tablero, 1, TipoVerde(), [(1, 0)]);

      final destinos = ValidadorAnclas(
        tablero,
      ).buscarDestinosValidos(numeroAncla: 1, numeroDelOtroDado: 6);

      expect(destinos.map((celda) => (celda.fila, celda.columna)), [(1, 0)]);
    });

    test(
      'devuelve una lista vacía cuando el número ancla no está en el tablero',
      () {
        final destinos = ValidadorAnclas(
          Tablero(),
        ).buscarDestinosValidos(numeroAncla: 3, numeroDelOtroDado: 5);

        expect(destinos, isEmpty);
      },
    );

    test('rechaza valores de dados fuera del rango de 1 a 6', () {
      final validador = ValidadorAnclas(Tablero());

      expect(
        () => validador.buscarDestinosValidos(
          numeroAncla: 0,
          numeroDelOtroDado: 5,
        ),
        throwsArgumentError,
      );
      expect(
        () => validador.buscarDestinosValidos(
          numeroAncla: 3,
          numeroDelOtroDado: 7,
        ),
        throwsArgumentError,
      );
    });
  });
}

void _agregarZona(
  Tablero tablero,
  int id,
  Tipo tipo,
  List<(int, int)> coordenadas,
) {
  tablero.agregarRegion(
    Zona(
      id: id,
      tipo: tipo,
      coordenadas: [
        for (final (fila, columna) in coordenadas)
          tablero.obtenerCelda(fila, columna),
      ],
    ),
  );
}
