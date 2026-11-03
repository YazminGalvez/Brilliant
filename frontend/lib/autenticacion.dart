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
  const ErrorAutenticacion(this.mensaje, {this.codigo});

  final String mensaje;
  final int? codigo;

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
}

String servidorPorDefecto() {
  const servidor = String.fromEnvironment('SERVIDOR');
  if (servidor.isNotEmpty) return servidor;

  final host = Uri.base.host;
  return 'http://${host.isEmpty ? 'localhost' : host}:8080';
}
