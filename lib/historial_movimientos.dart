import 'color_zona.dart';
import 'tablero.dart';
import 'zona.dart';

enum TipoMovimiento { colocacion, saltoTurno, zonaCompletada, puntosGanados }

class RegistroMovimiento {
  RegistroMovimiento.colocacion({
    required int numero,
    required int numeroTirada,
    required int ancla,
    required int numeroColocado,
    required int fila,
    required int columna,
  }) : this._(
         numero: numero,
         numeroTirada: numeroTirada,
         tipo: TipoMovimiento.colocacion,
         ancla: ancla,
         numeroColocado: numeroColocado,
         fila: fila,
         columna: columna,
       );

  RegistroMovimiento.saltoTurno({
    required int numero,
    required int numeroTirada,
  }) : this._(
         numero: numero,
         numeroTirada: numeroTirada,
         tipo: TipoMovimiento.saltoTurno,
       );

  RegistroMovimiento.zonaCompletada({
    required int numero,
    required int numeroTirada,
    required int idZona,
    required ColorZona color,
  }) : this._(
         numero: numero,
         numeroTirada: numeroTirada,
         tipo: TipoMovimiento.zonaCompletada,
         idZona: idZona,
         color: color,
       );

  RegistroMovimiento.puntosGanados({
    required int numero,
    required int numeroTirada,
    required int puntos,
  }) : this._(
         numero: numero,
         numeroTirada: numeroTirada,
         tipo: TipoMovimiento.puntosGanados,
         puntos: puntos,
       );

  RegistroMovimiento._({
    required this.numero,
    required this.numeroTirada,
    required this.tipo,
    this.ancla,
    this.numeroColocado,
    this.fila,
    this.columna,
    this.idZona,
    this.color,
    this.puntos,
  }) {
    _validarMayorQueCero(numero, 'numero');
    _validarMayorQueCero(numeroTirada, 'numeroTirada');

    final esColocacion = tipo == TipoMovimiento.colocacion;
    final esZona = tipo == TipoMovimiento.zonaCompletada;
    final esPuntos = tipo == TipoMovimiento.puntosGanados;
    _validarPresencia(ancla, 'ancla', esColocacion);
    _validarPresencia(numeroColocado, 'numeroColocado', esColocacion);
    _validarPresencia(fila, 'fila', esColocacion);
    _validarPresencia(columna, 'columna', esColocacion);
    _validarPresencia(idZona, 'idZona', esZona);
    _validarPresencia(color, 'color', esZona);
    _validarPresencia(puntos, 'puntos', esPuntos);

    if (esColocacion) {
      _validarRango(ancla!, 'ancla', 1, 6);
      _validarRango(numeroColocado!, 'numeroColocado', 1, 6);
      _validarRango(fila!, 'fila', 0, Tablero.cantidadFilas - 1);
      _validarRango(columna!, 'columna', 0, Tablero.cantidadColumnas - 1);
    }
    if (esZona && idZona! < 0) {
      throw ArgumentError.value(idZona, 'idZona', 'No puede ser negativo.');
    }
    if (esPuntos) _validarMayorQueCero(puntos!, 'puntos');
  }

  final int numero;
  final int numeroTirada;
  final TipoMovimiento tipo;

  final int? ancla;
  final int? numeroColocado;
  final int? fila;
  final int? columna;

  final int? idZona;
  final ColorZona? color;

  final int? puntos;

  static void _validarPresencia(
    Object? valor,
    String nombre,
    bool debeEstar,
  ) {
    if (debeEstar && valor == null) {
      throw ArgumentError.notNull(nombre);
    }
    if (!debeEstar && valor != null) {
      throw ArgumentError.value(
        valor,
        nombre,
        'No corresponde a este tipo de movimiento.',
      );
    }
  }

  static void _validarMayorQueCero(int valor, String nombre) {
    if (valor <= 0) {
      throw ArgumentError.value(valor, nombre, 'Debe ser mayor que cero.');
    }
  }

  static void _validarRango(int valor, String nombre, int minimo, int maximo) {
    if (valor < minimo || valor > maximo) {
      throw ArgumentError.value(
        valor,
        nombre,
        'Debe estar entre $minimo y $maximo.',
      );
    }
  }
}

class HistorialMovimientos {
  final List<RegistroMovimiento> _movimientos = [];

  List<RegistroMovimiento> get movimientos => List.unmodifiable(_movimientos);
  int get cantidad => _movimientos.length;
  RegistroMovimiento? get ultimo =>
      _movimientos.isEmpty ? null : _movimientos.last;

  int get _siguienteNumero => _movimientos.length + 1;

  RegistroMovimiento registrarColocacion({
    required int numeroTirada,
    required int ancla,
    required int numeroColocado,
    required int fila,
    required int columna,
  }) => _agregar(
    RegistroMovimiento.colocacion(
      numero: _siguienteNumero,
      numeroTirada: numeroTirada,
      ancla: ancla,
      numeroColocado: numeroColocado,
      fila: fila,
      columna: columna,
    ),
  );

  RegistroMovimiento registrarSaltoTurno({required int numeroTirada}) =>
      _agregar(
        RegistroMovimiento.saltoTurno(
          numero: _siguienteNumero,
          numeroTirada: numeroTirada,
        ),
      );

  RegistroMovimiento registrarZonaCompletada({
    required int numeroTirada,
    required int idZona,
    required ColorZona color,
  }) => _agregar(
    RegistroMovimiento.zonaCompletada(
      numero: _siguienteNumero,
      numeroTirada: numeroTirada,
      idZona: idZona,
      color: color,
    ),
  );

  RegistroMovimiento registrarPuntosGanados({
    required int numeroTirada,
    required int puntos,
  }) => _agregar(
    RegistroMovimiento.puntosGanados(
      numero: _siguienteNumero,
      numeroTirada: numeroTirada,
      puntos: puntos,
    ),
  );

  List<RegistroMovimiento> registrarJugada({
    required int numeroTirada,
    required int ancla,
    required int numeroColocado,
    required int fila,
    required int columna,
    Zona? zonaCompletada,
    int puntosGanados = 0,
  }) {
    final colocacion = RegistroMovimiento.colocacion(
      numero: _siguienteNumero,
      numeroTirada: numeroTirada,
      ancla: ancla,
      numeroColocado: numeroColocado,
      fila: fila,
      columna: columna,
    );
    if (puntosGanados < 0) {
      throw ArgumentError.value(
        puntosGanados,
        'puntosGanados',
        'No puede ser negativo.',
      );
    }

    final registros = [colocacion];
    if (zonaCompletada != null) {
      registros.add(
        RegistroMovimiento.zonaCompletada(
          numero: _siguienteNumero + registros.length,
          numeroTirada: numeroTirada,
          idZona: zonaCompletada.id,
          color: zonaCompletada.tipo.colorZona,
        ),
      );
    }
    if (puntosGanados > 0) {
      registros.add(
        RegistroMovimiento.puntosGanados(
          numero: _siguienteNumero + registros.length,
          numeroTirada: numeroTirada,
          puntos: puntosGanados,
        ),
      );
    }

    _movimientos.addAll(registros);
    return List.unmodifiable(registros);
  }

  void limpiar() => _movimientos.clear();

  RegistroMovimiento _agregar(RegistroMovimiento registro) {
    _movimientos.add(registro);
    return registro;
  }
}
