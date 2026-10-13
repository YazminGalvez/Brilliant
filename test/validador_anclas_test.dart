import 'package:juego_brilliant/tablero.dart';
import 'package:juego_brilliant/tipo.dart';
import 'package:juego_brilliant/validador_anclas.dart';
import 'package:juego_brilliant/validador_inicio.dart';
import 'package:juego_brilliant/zona.dart';
import 'package:test/test.dart';

void main() {
  group('Validador de anclas', () {
    test(
      'ofrece ambas opciones cuando los dos valores están en el tablero',
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
      },
    );

    test('solo permite como ancla el valor de dado presente en el tablero', () {
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

      for (
        var index = 0;
        index < ValidadorInicio.celdasIniciales.length;
        index++
      ) {
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

    test('mantiene deshabilitada cada ancla que no aparece en el tablero', () {
      final validador = ValidadorAnclas(Tablero()..colocarDato(6, 6, 6));

      expect(
        validador
            .obtenerOpciones(2, 6)
            .map(
              (opcion) => (
                opcion.ancla,
                opcion.numeroAColocar,
                opcion.puedeSeleccionarse,
              ),
            ),
        [(2, 6, false), (6, 2, true)],
      );
      expect(validador.obtenerAnclasPosibles(2, 6), [6]);
    });

    test('no propone anclas si ninguno de los dados aparece en el tablero', () {
      final validador = ValidadorAnclas(Tablero());

      expect(validador.obtenerAnclasPosibles(2, 5), isEmpty);
      expect(
        validador
            .obtenerOpciones(2, 5)
            .map((opcion) => opcion.puedeSeleccionarse),
        [false, false],
      );
      expect(
        validador.obtenerOpciones(2, 2).single.puedeSeleccionarse,
        isFalse,
      );
    });

    test('rechaza valores de dados inválidos en todas las operaciones', () {
      final validador = ValidadorAnclas(Tablero());
      final operaciones = [
        () => validador.obtenerAnclasPosibles(0, 4),
        () => validador.obtenerAnclasPosibles(2, 7),
        () => validador.obtenerOpciones(0, 4),
        () => validador.obtenerOpciones(2, 7),
        () => validador.buscarDestinosValidos(
          numeroAncla: 0,
          numeroDelOtroDado: 4,
        ),
        () => validador.buscarDestinosValidos(
          numeroAncla: 2,
          numeroDelOtroDado: 7,
        ),
      ];

      for (final operacion in operaciones) {
        expect(operacion, throwsArgumentError);
      }
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

    test('aplica la regla de cada color al destino antes de devolverlo', () {
      final casos =
          <({Tipo tipo, List<int> valoresEnZona, int numero, bool esperado})>[
            (tipo: TipoAzul(), valoresEnZona: [3], numero: 3, esperado: true),
            (tipo: TipoAzul(), valoresEnZona: [3], numero: 4, esperado: false),
            (tipo: TipoRojo(), valoresEnZona: [3], numero: 3, esperado: false),
            (tipo: TipoRojo(), valoresEnZona: [3], numero: 4, esperado: true),
            (
              tipo: TipoVerde(),
              valoresEnZona: [3, 4],
              numero: 3,
              esperado: true,
            ),
            (
              tipo: TipoMorado(),
              valoresEnZona: [3, 4],
              numero: 4,
              esperado: true,
            ),
            (
              tipo: TipoMorado(),
              valoresEnZona: [3, 4],
              numero: 5,
              esperado: false,
            ),
            (
              tipo: TipoAmarillo(),
              valoresEnZona: [3],
              numero: 3,
              esperado: false,
            ),
            (
              tipo: TipoAmarillo(),
              valoresEnZona: [3],
              numero: 4,
              esperado: true,
            ),
          ];

      for (var index = 0; index < casos.length; index++) {
        final caso = casos[index];
        final tablero = Tablero()..colocarDato(3, 3, 1);
        final coordenadasZona = <Coordenada>[tablero.obtenerCelda(3, 4)];
        for (
          var valorIndex = 0;
          valorIndex < caso.valoresEnZona.length;
          valorIndex++
        ) {
          final celda = tablero.obtenerCelda(0, valorIndex);
          celda.valor = caso.valoresEnZona[valorIndex];
          coordenadasZona.add(celda);
        }
        tablero.agregarRegion(
          Zona(id: index, tipo: caso.tipo, coordenadas: coordenadasZona),
        );

        final destinos = ValidadorAnclas(
          tablero,
        ).buscarDestinosValidos(numeroAncla: 1, numeroDelOtroDado: caso.numero);

        expect(
          destinos.any((celda) => celda.fila == 3 && celda.columna == 4),
          caso.esperado,
          reason: '${caso.tipo.runtimeType} con valores ${caso.valoresEnZona}',
        );
      }
    });

    test(
      'ignora celdas sin zona y falla si el destino pertenece a dos zonas',
      () {
        final tablero = Tablero()..colocarDato(3, 3, 1);
        final validador = ValidadorAnclas(tablero);

        expect(
          validador.buscarDestinosValidos(numeroAncla: 1, numeroDelOtroDado: 2),
          isEmpty,
        );

        _agregarZona(tablero, 1, TipoVerde(), [(3, 4)]);
        _agregarZona(tablero, 2, TipoAzul(), [(3, 4)]);

        expect(
          () => validador.buscarDestinosValidos(
            numeroAncla: 1,
            numeroDelOtroDado: 2,
          ),
          throwsStateError,
        );
      },
    );

    test('busca todas las apariciones del ancla y no repite destinos', () {
      final tablero = Tablero()
        ..colocarDato(3, 2, 5)
        ..colocarDato(3, 4, 5);
      _agregarZona(tablero, 1, TipoVerde(), [(3, 3)]);

      final destinos = ValidadorAnclas(
        tablero,
      ).buscarDestinosValidos(numeroAncla: 5, numeroDelOtroDado: 2);

      expect(destinos, hasLength(1));
      expect((destinos.single.fila, destinos.single.columna), (3, 3));
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
