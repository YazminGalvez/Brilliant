import 'package:flutter/foundation.dart';

class SesionUsuario {
  const SesionUsuario({
    required this.token,
    required this.idUsuario,
    required this.nombre,
  });

  final String token;
  final String idUsuario;
  final String nombre;
}

class ErrorAutenticacion implements Exception {
  const ErrorAutenticacion(this.mensaje, {this.codigo, this.codigoServidor});

  final String mensaje;
  final int? codigo;
  final String? codigoServidor;

  @override
  String toString() => mensaje;
}

abstract class ServicioAutenticacion {
  abstract String servidor;

  SesionUsuario? get sesion;

  Future<SesionUsuario> iniciarSesion(String nombre, String contrasena);

  Future<SesionUsuario> crearCuenta(String nombre, String contrasena);

  Future<void> cerrarSesion();

  Future<void> borrarCuenta(String contrasena);

  Future<bool> sesionActiva();

  Future<Map<String, Object?>?> enviarConSesion(
    String metodo,
    String ruta, {
    Map<String, Object?>? cuerpo,
  });

  Future<bool> probarConexion() async => true;
}

const servidorDefinido = String.fromEnvironment('SERVIDOR');

String servidorPorDefecto({String definido = servidorDefinido}) {
  if (definido.isNotEmpty) return definido;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }

  final host = Uri.base.host;
  return 'http://${host.isEmpty ? 'localhost' : host}:8080';
}
