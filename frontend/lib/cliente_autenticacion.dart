import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:frontend/autenticacion.dart';

class ClienteAutenticacion implements ServicioAutenticacion {
  ClienteAutenticacion({String? servidor, http.Client? cliente})
    : _cliente = cliente ?? http.Client() {
    this.servidor = servidor ?? servidorPorDefecto();
  }

  static const limiteDeTiempo = Duration(seconds: 10);
  static const limiteDePrueba = Duration(seconds: 5);

  static const mensajeCredenciales = 'Usuario o contraseña incorrectos.';
  static const mensajeContrasenaIncorrecta = 'Contraseña incorrecta.';
  static const mensajeNombreEnUso = 'Ese nombre de usuario ya está en uso.';
  static const mensajeSesionTerminada =
      'Tu sesión terminó. Inicia sesión de nuevo.';
  static const mensajeDatosInvalidos =
      'Revisa los datos: el usuario debe tener de 3 a 32 caracteres y la '
      'contraseña de 8 a 128.';
  static const mensajeConexion =
      'No se pudo conectar con el servidor. Revisa que esté encendido y que '
      'la dirección sea correcta.';
  static const mensajeInesperado =
      'Ocurrió un error inesperado. Inténtalo de nuevo.';
  static const mensajeCuentaSinSesion =
      'Cuenta creada, pero no se pudo iniciar sesión. Inicia sesión '
      'manualmente.';
  static const mensajeRespuestaInesperada =
      'Respuesta inesperada del servidor.';
  static const mensajeDatosDePartida =
      'Los datos de la partida no son válidos.';
  static const mensajePartidaNoEncontrada = 'Esa partida ya no existe.';
  static const mensajePartidaLlena = 'La partida ya está llena.';
  static const mensajePartidaComenzada = 'La partida ya comenzó.';
  static const mensajePartidaNoComenzada = 'La partida todavía no comienza.';
  static const mensajeYaEnPartida = 'Ya estás en una partida en juego.';
  static const mensajeMapaNoDisponible = 'Ese mapa no está disponible.';

  final http.Client _cliente;
  String _servidor = '';
  SesionUsuario? _sesion;

  @override
  String get servidor => _servidor;

  @override
  set servidor(String direccion) {
    var limpia = direccion.trim();
    while (limpia.endsWith('/')) {
      limpia = limpia.substring(0, limpia.length - 1);
    }
    _servidor = limpia;
  }

  @override
  SesionUsuario? get sesion => _sesion;

  @override
  Future<SesionUsuario> iniciarSesion(String nombre, String contrasena) async {
    final respuesta = await _enviar(
      'POST',
      '/sesiones',
      cuerpo: {'nombre': nombre, 'contrasena': contrasena},
    );
    if (!_exitosa(respuesta)) throw _errorDe(respuesta);

    final datos = _leerJson(respuesta);
    final token = datos['token'];
    final usuario = datos['usuario'];
    if (token is! String || usuario is! Map) {
      throw ErrorAutenticacion(mensajeInesperado, codigo: respuesta.statusCode);
    }
    return _sesion = SesionUsuario(
      token: token,
      idUsuario: '${usuario['id']}',
      nombre: '${usuario['nombre']}',
    );
  }

  @override
  Future<SesionUsuario> crearCuenta(String nombre, String contrasena) async {
    final respuesta = await _enviar(
      'POST',
      '/cuentas',
      cuerpo: {'nombre': nombre, 'contrasena': contrasena},
    );
    if (!_exitosa(respuesta)) throw _errorDe(respuesta);

    try {
      return await iniciarSesion(nombre, contrasena);
    } on ErrorAutenticacion catch (error) {
      throw ErrorAutenticacion(mensajeCuentaSinSesion, codigo: error.codigo);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    final sesion = _sesion;
    if (sesion == null) return;

    try {
      final respuesta = await _enviar(
        'DELETE',
        '/sesiones/actual',
        token: sesion.token,
      );
      if (_exitosa(respuesta) || respuesta.statusCode == 401) return;
      throw _errorDe(respuesta);
    } finally {
      _olvidar(sesion);
    }
  }

  @override
  Future<void> borrarCuenta(String contrasena) async {
    final sesion = _sesion;
    if (sesion == null) {
      throw const ErrorAutenticacion(mensajeSesionTerminada, codigo: 401);
    }

    final respuesta = await _enviar(
      'DELETE',
      '/cuentas/yo',
      token: sesion.token,
      cuerpo: {'contrasena': contrasena},
    );
    if (_exitosa(respuesta)) {
      _olvidar(sesion);
      return;
    }
    if (_codigoDe(respuesta) == 'NO_AUTORIZADO') _olvidar(sesion);
    throw _errorDe(
      respuesta,
      mensajeDeCredenciales: mensajeContrasenaIncorrecta,
    );
  }

  @override
  Future<bool> sesionActiva() async {
    final sesion = _sesion;
    if (sesion == null) return false;

    final respuesta = await _enviar('GET', '/cuentas/yo', token: sesion.token);
    if (_exitosa(respuesta)) return true;
    if (respuesta.statusCode == 401) {
      _olvidar(sesion);
      return false;
    }
    throw _errorDe(respuesta);
  }

  @override
  Future<Map<String, Object?>?> enviarConSesion(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
  }) async {
    final sesion = _sesion;
    if (sesion == null) {
      throw const ErrorAutenticacion(
        mensajeSesionTerminada,
        codigo: 401,
        codigoServidor: 'NO_AUTORIZADO',
      );
    }

    final respuesta = await _enviar(
      metodo,
      ruta,
      token: sesion.token,
      cuerpo: cuerpo,
    );
    if (!_exitosa(respuesta)) {
      if (respuesta.statusCode == 401) _olvidar(sesion);
      throw _errorDe(respuesta, mensajeDeDatosInvalidos: mensajeDatosDePartida);
    }
    if (respuesta.statusCode == 204 || respuesta.bodyBytes.isEmpty) return null;

    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is Map<String, Object?>) return datos;
    } on FormatException {
      throw ErrorAutenticacion(
        mensajeRespuestaInesperada,
        codigo: respuesta.statusCode,
      );
    }
    throw ErrorAutenticacion(
      mensajeRespuestaInesperada,
      codigo: respuesta.statusCode,
    );
  }

  @override
  Future<bool> probarConexion() async {
    try {
      final respuesta = await _cliente
          .get(
            Uri.parse('$servidor/api/v1/salud'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(limiteDePrueba);
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _enviar(
    String metodo,
    String ruta, {
    String? token,
    Map<String, Object?>? cuerpo,
  }) async {
    try {
      final peticion = http.Request(metodo, Uri.parse('$servidor/api/v1$ruta'))
        ..headers['Accept'] = 'application/json';
      if (token != null) peticion.headers['Authorization'] = 'Bearer $token';
      if (cuerpo != null) {
        peticion.headers['Content-Type'] = 'application/json';
        peticion.bodyBytes = utf8.encode(jsonEncode(cuerpo));
      }
      return await _cliente
          .send(peticion)
          .then(http.Response.fromStream)
          .timeout(limiteDeTiempo);
    } catch (_) {
      throw const ErrorAutenticacion(mensajeConexion);
    }
  }

  void _olvidar(SesionUsuario sesion) {
    if (identical(_sesion, sesion)) _sesion = null;
  }

  static bool _exitosa(http.Response respuesta) =>
      respuesta.statusCode >= 200 && respuesta.statusCode < 300;

  static Map<String, Object?> _leerJson(http.Response respuesta) {
    try {
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is Map<String, Object?>) return datos;
    } on FormatException {
      return const {};
    }
    return const {};
  }

  static String? _codigoDe(http.Response respuesta) {
    final codigo = _leerJson(respuesta)['codigo'];
    return codigo is String ? codigo : null;
  }

  static ErrorAutenticacion _errorDe(
    http.Response respuesta, {
    String mensajeDeCredenciales = mensajeCredenciales,
    String mensajeDeDatosInvalidos = mensajeDatosInvalidos,
  }) {
    final estado = respuesta.statusCode;
    final codigoServidor = _codigoDe(respuesta);
    final mensaje = switch (codigoServidor) {
      'CREDENCIALES_INVALIDAS' => mensajeDeCredenciales,
      'NOMBRE_EN_USO' => mensajeNombreEnUso,
      'DEMASIADOS_INTENTOS' => _mensajeDemasiadosIntentos(respuesta),
      'NO_AUTORIZADO' => mensajeSesionTerminada,
      'PARTIDA_NO_ENCONTRADA' => mensajePartidaNoEncontrada,
      'PARTIDA_LLENA' => mensajePartidaLlena,
      'PARTIDA_COMENZADA' => mensajePartidaComenzada,
      'PARTIDA_NO_COMENZADA' => mensajePartidaNoComenzada,
      'YA_EN_PARTIDA' => mensajeYaEnPartida,
      'MAPA_NO_DISPONIBLE' => mensajeMapaNoDisponible,
      _ when estado == 429 => _mensajeDemasiadosIntentos(respuesta),
      _ when estado == 400 => mensajeDeDatosInvalidos,
      _ => mensajeInesperado,
    };
    return ErrorAutenticacion(
      mensaje,
      codigo: estado,
      codigoServidor: codigoServidor,
    );
  }

  static String _mensajeDemasiadosIntentos(http.Response respuesta) {
    final segundos = int.tryParse(
      (respuesta.headers['retry-after'] ?? '').trim(),
    );
    final espera = switch (segundos) {
      null || < 0 => 'unos minutos',
      1 => '1 segundo',
      _ => '$segundos segundos',
    };
    return 'Demasiados intentos. Espera $espera e inténtalo de nuevo.';
  }
}
