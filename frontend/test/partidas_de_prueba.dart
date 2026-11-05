import 'dart:async';
import 'dart:convert';

import 'package:frontend/cliente_autenticacion.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const servidorDePrueba = 'http://127.0.0.1:8080';

Map<String, Object?> salaJson({
  String codigo = 'K7M2QX',
  int ronda = 0,
  bool comenzada = false,
  Map<String, Object?> cambios = const {},
}) => {
  'codigo': codigo,
  'mapa': 2,
  'capacidad': 4,
  'anfitrion': 'ana',
  'jugadores': [
    {
      'nombre': 'ana',
      'listo': true,
      'tableroListo': false,
      'conectado': true,
      'concedio': false,
      'jugoRonda': false,
    },
    {
      'nombre': 'luis',
      'listo': false,
      'tableroListo': false,
      'conectado': true,
      'concedio': false,
      'jugoRonda': false,
    },
  ],
  'comenzada': comenzada,
  'terminada': false,
  'ronda': ronda,
  'dados': ronda == 0 ? <int>[] : [3, 5],
  'miTablero': <int>[],
  'zonas': <String, Object?>{},
  'puntos': {'ana': 0, 'luis': 0},
  'meta': comenzada ? 26 : 0,
  'ganadores': <String>[],
  'motivoFin': null,
  ...cambios,
};

http.Response respuestaJson(
  Object cuerpo,
  int estado, {
  Map<String, String> cabeceras = const {},
}) => http.Response.bytes(
  utf8.encode(jsonEncode(cuerpo)),
  estado,
  headers: {'content-type': 'application/json', ...cabeceras},
);

http.Response errorDelServidor(String codigo, int estado) =>
    respuestaJson({'codigo': codigo, 'mensaje': 'detalle técnico'}, estado);

class ServidorDePartidasFalso {
  ServidorDePartidasFalso(this.responder);

  FutureOr<http.Response> Function(http.Request peticion) responder;
  final peticiones = <http.Request>[];

  late final MockClient cliente = MockClient((peticion) async {
    if (peticion.url.path == '/api/v1/sesiones') {
      return respuestaJson({
        'token': 'token-de-prueba',
        'tipo': 'Bearer',
        'expiraEnSegundos': 3600,
        'usuario': {'id': 1, 'nombre': 'ana'},
      }, 200);
    }
    peticiones.add(peticion);
    return responder(peticion);
  });

  Future<ClienteAutenticacion> clienteConSesion() async {
    final autenticacion = ClienteAutenticacion(
      servidor: servidorDePrueba,
      cliente: cliente,
    );
    await autenticacion.iniciarSesion('ana', 'secreta123');
    return autenticacion;
  }
}

Object? cuerpoDe(http.Request peticion) =>
    jsonDecode(utf8.decode(peticion.bodyBytes));
