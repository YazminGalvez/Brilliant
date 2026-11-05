import 'mapa.dart';
import 'tipo.dart';

abstract final class PuntosMultijugador {
  static final Map<Mapa, Map<int, Tipo>> _tiposPorMapa = Map.identity();

  static Map<int, Tipo> _tiposDeZonas(Mapa mapa) => _tiposPorMapa.putIfAbsent(
    mapa,
    () => {
      for (final zona in mapa.crearTablero().regiones) zona.id + 1: zona.tipo,
    },
  );

  static List<int> zonasDe(Mapa mapa) =>
      _tiposDeZonas(mapa).keys.toList()..sort();

  static int puntosDeZona(Mapa mapa, int zona, int lugar) {
    final tipo = _tiposDeZonas(mapa)[zona];
    if (tipo == null) {
      throw ArgumentError.value(zona, 'zona', 'El mapa no tiene esa zona.');
    }
    if (lugar < 1) {
      throw ArgumentError.value(lugar, 'lugar', 'El lugar empieza en 1.');
    }
    return lugar > 3 ? 0 : tipo.calcularPuntuacion(lugar);
  }

  static Map<String, int> puntosTotales(
    Mapa mapa,
    Map<int, Map<String, int>> rondasPorZona,
  ) {
    final totales = <String, int>{};
    rondasPorZona.forEach((zona, rondasPorJugador) {
      final rondas = rondasPorJugador.values.toSet();
      rondasPorJugador.forEach((jugador, ronda) {
        final lugar = 1 + rondas.where((otra) => otra < ronda).length;
        totales[jugador] =
            (totales[jugador] ?? 0) + puntosDeZona(mapa, zona, lugar);
      });
    });
    return totales;
  }

  static String _puntosPorLugar(Mapa mapa, int zona) => [
    for (var lugar = 1; lugar <= 3; lugar++) puntosDeZona(mapa, zona, lugar),
  ].join(',');

  static String tablaParaServidor(List<Mapa> mapas) => [
    for (final mapa in mapas)
      '${mapa.numero}:'
          '${zonasDe(mapa).map((zona) => _puntosPorLugar(mapa, zona)).join('|')}',
  ].join(';');
}
