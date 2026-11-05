import 'package:frontend/autenticacion.dart';

const _respuestaInesperada = ErrorAutenticacion(
  'Respuesta inesperada del servidor.',
);

T _campo<T>(Map<String, Object?> json, String nombre) {
  final valor = json[nombre];
  if (valor is T) return valor;
  throw _respuestaInesperada;
}

List<T> _lista<T>(Map<String, Object?> json, String nombre) {
  final valor = _campo<List<Object?>>(json, nombre);
  if (valor.any((elemento) => elemento is! T)) throw _respuestaInesperada;
  return List.unmodifiable(valor.cast<T>());
}

Map<String, int> _numerosPorNombre(Object? valor) {
  if (valor is! Map<String, Object?>) throw _respuestaInesperada;
  return Map.unmodifiable({
    for (final MapEntry(:key, :value) in valor.entries)
      key: value is int ? value : throw _respuestaInesperada,
  });
}

bool _listasIguales<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var indice = 0; indice < a.length; indice++) {
    if (a[indice] != b[indice]) return false;
  }
  return true;
}

bool _mapasIguales<K, V>(
  Map<K, V> a,
  Map<K, V> b, [
  bool Function(V, V)? valoresIguales,
]) {
  if (a.length != b.length) return false;
  for (final MapEntry(:key, :value) in a.entries) {
    if (!b.containsKey(key)) return false;
    final otro = b[key] as V;
    final iguales = valoresIguales?.call(value, otro) ?? value == otro;
    if (!iguales) return false;
  }
  return true;
}

class JugadorSala {
  const JugadorSala({
    required this.nombre,
    required this.listo,
    required this.tableroListo,
    required this.conectado,
    required this.concedio,
    required this.jugoRonda,
  });

  factory JugadorSala.desdeJson(Object? json) {
    if (json is! Map<String, Object?>) throw _respuestaInesperada;
    return JugadorSala(
      nombre: _campo<String>(json, 'nombre'),
      listo: _campo<bool>(json, 'listo'),
      tableroListo: _campo<bool>(json, 'tableroListo'),
      conectado: _campo<bool>(json, 'conectado'),
      concedio: _campo<bool>(json, 'concedio'),
      jugoRonda: _campo<bool>(json, 'jugoRonda'),
    );
  }

  final String nombre;
  final bool listo;
  final bool tableroListo;
  final bool conectado;
  final bool concedio;
  final bool jugoRonda;

  @override
  bool operator ==(Object other) =>
      other is JugadorSala &&
      other.nombre == nombre &&
      other.listo == listo &&
      other.tableroListo == tableroListo &&
      other.conectado == conectado &&
      other.concedio == concedio &&
      other.jugoRonda == jugoRonda;

  @override
  int get hashCode =>
      Object.hash(nombre, listo, tableroListo, conectado, concedio, jugoRonda);
}

class SalaPartida {
  const SalaPartida({
    required this.codigo,
    required this.mapa,
    required this.capacidad,
    required this.anfitrion,
    required this.jugadores,
    required this.comenzada,
    required this.terminada,
    required this.ronda,
    required this.dados,
    required this.miTablero,
    required this.zonas,
    required this.puntos,
    required this.meta,
    required this.ganadores,
    required this.motivoFin,
  });

  factory SalaPartida.desdeJson(Map<String, Object?> json) {
    final zonas = _campo<Map<String, Object?>>(json, 'zonas');
    final motivoFin = json['motivoFin'];
    if (motivoFin != null && motivoFin is! String) throw _respuestaInesperada;

    return SalaPartida(
      codigo: _campo<String>(json, 'codigo'),
      mapa: _campo<int>(json, 'mapa'),
      capacidad: _campo<int>(json, 'capacidad'),
      anfitrion: _campo<String>(json, 'anfitrion'),
      jugadores: List.unmodifiable([
        for (final jugador in _campo<List<Object?>>(json, 'jugadores'))
          JugadorSala.desdeJson(jugador),
      ]),
      comenzada: _campo<bool>(json, 'comenzada'),
      terminada: _campo<bool>(json, 'terminada'),
      ronda: _campo<int>(json, 'ronda'),
      dados: _lista<int>(json, 'dados'),
      miTablero: _lista<int>(json, 'miTablero'),
      zonas: Map.unmodifiable({
        for (final MapEntry(:key, :value) in zonas.entries)
          int.tryParse(key) ?? (throw _respuestaInesperada): _numerosPorNombre(
            value,
          ),
      }),
      puntos: _numerosPorNombre(json['puntos']),
      meta: _campo<int>(json, 'meta'),
      ganadores: _lista<String>(json, 'ganadores'),
      motivoFin: motivoFin as String?,
    );
  }

  final String codigo;
  final int mapa;
  final int capacidad;
  final String anfitrion;
  final List<JugadorSala> jugadores;
  final bool comenzada;
  final bool terminada;
  final int ronda;
  final List<int> dados;
  final List<int> miTablero;
  final Map<int, Map<String, int>> zonas;
  final Map<String, int> puntos;
  final int meta;
  final List<String> ganadores;
  final String? motivoFin;

  @override
  bool operator ==(Object other) =>
      other is SalaPartida &&
      other.codigo == codigo &&
      other.mapa == mapa &&
      other.capacidad == capacidad &&
      other.anfitrion == anfitrion &&
      _listasIguales(other.jugadores, jugadores) &&
      other.comenzada == comenzada &&
      other.terminada == terminada &&
      other.ronda == ronda &&
      _listasIguales(other.dados, dados) &&
      _listasIguales(other.miTablero, miTablero) &&
      _mapasIguales(other.zonas, zonas, _mapasIguales) &&
      _mapasIguales(other.puntos, puntos) &&
      other.meta == meta &&
      _listasIguales(other.ganadores, ganadores) &&
      other.motivoFin == motivoFin;

  @override
  int get hashCode => Object.hash(codigo, mapa, ronda, comenzada, terminada);
}

class ServicioPartidas {
  ServicioPartidas(this.autenticacion);

  final ServicioAutenticacion autenticacion;

  static final _soloLetrasYNumeros = RegExp(r'^[A-Za-z0-9]+$');

  static String? errorCodigo(String codigo) {
    final limpio = codigo.trim();
    if (limpio.length != 6) return 'El código tiene 6 caracteres.';
    if (!_soloLetrasYNumeros.hasMatch(limpio)) {
      return 'El código solo lleva letras y números.';
    }
    return null;
  }

  Future<SalaPartida> crear({required int mapa, required int jugadores}) =>
      _pedirSala(
        'POST',
        '/partidas',
        cuerpo: {'mapa': mapa, 'jugadores': jugadores},
      );

  Future<SalaPartida> unirse(String codigo) =>
      _pedirSala('POST', '/partidas/unirse', cuerpo: {'codigo': codigo.trim()});

  Future<SalaPartida?> actual() async {
    final json = await autenticacion.enviarConSesion('GET', '/partidas/actual');
    return json == null ? null : SalaPartida.desdeJson(json);
  }

  Future<SalaPartida> consultar(String codigo) =>
      _pedirSala('GET', '/partidas/${Uri.encodeComponent(codigo.trim())}');

  Future<SalaPartida> _pedirSala(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
  }) async {
    final json = await autenticacion.enviarConSesion(
      metodo,
      ruta,
      cuerpo: cuerpo,
    );
    if (json == null) throw _respuestaInesperada;
    return SalaPartida.desdeJson(json);
  }
}
