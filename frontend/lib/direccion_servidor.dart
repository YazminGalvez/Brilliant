import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/autenticacion.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DireccionServidor {
  const DireccionServidor._();

  static const clave = 'servidor_brilliant';

  static Future<String?> leer() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final direccion = preferencias.getString(clave)?.trim() ?? '';
      return direccion.isEmpty ? null : direccion;
    } catch (_) {
      return null;
    }
  }

  static Future<void> guardar(String direccion) async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(clave, direccion.trim());
    } catch (_) {}
  }

  static Future<String> elegir({String definido = servidorDefinido}) async {
    if (definido.isNotEmpty) return definido;
    return await leer() ?? servidorPorDefecto(definido: '');
  }
}

String? validarServidor(String? valor) {
  final direccion = (valor ?? '').trim();
  if (direccion.startsWith('http://') || direccion.startsWith('https://')) {
    return null;
  }
  return 'Debe empezar por http:// o https://';
}

bool direccionValida(String direccion) =>
    validarServidor(direccion) == null &&
    (Uri.tryParse(direccion.trim())?.host.isNotEmpty ?? false);

class CampoServidor extends StatelessWidget {
  const CampoServidor({
    required this.prefijo,
    required this.controlador,
    required this.servicio,
    required this.soloLectura,
    super.key,
  });

  final String prefijo;
  final TextEditingController controlador;
  final ServicioAutenticacion servicio;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controlador,
      builder: (context, _) {
        final error = validarServidor(controlador.text);
        return ExpansionTile(
          title: const Text('Servidor'),
          subtitle: Text(
            error ?? controlador.text.trim(),
            style: TextStyle(
              color: error == null ? colores.onSurfaceVariant : colores.error,
            ),
          ),
          leading: const Icon(Icons.dns_outlined),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          collapsedShape: const Border(),
          maintainState: true,
          children: [
            TextFormField(
              key: Key('$prefijo-servidor'),
              controller: controlador,
              validator: validarServidor,
              readOnly: soloLectura,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Dirección del servidor',
                hintText: 'http://192.168.1.50:8080',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            EstadoServidor(
              prefijo: prefijo,
              servicio: servicio,
              controlador: controlador,
            ),
          ],
        );
      },
    );
  }
}

enum _Prueba { probando, conectado, sinConexion, invalida }

class EstadoServidor extends StatefulWidget {
  const EstadoServidor({
    required this.prefijo,
    required this.servicio,
    required this.controlador,
    super.key,
  });

  static const mensajeConectado = 'Conectado al servidor';
  static const mensajeSinConexion =
      'No se pudo conectar. Revisa que el celular y la laptop estén en la '
      'misma red, que el servidor esté iniciado y la dirección (por ejemplo '
      'http://192.168.1.50:8080)';
  static const mensajeInvalida =
      'Dirección inválida. Escríbela completa, por ejemplo '
      'http://192.168.1.50:8080';

  final String prefijo;
  final ServicioAutenticacion servicio;
  final TextEditingController controlador;

  @override
  State<EstadoServidor> createState() => _EstadoServidorState();
}

class _EstadoServidorState extends State<EstadoServidor> {
  _Prueba? _resultado;
  String? _probada;

  bool get _probando => _resultado == _Prueba.probando;

  Future<void> _probar() async {
    final direccion = widget.controlador.text.trim();
    if (!direccionValida(direccion)) {
      setState(() {
        _probada = direccion;
        _resultado = _Prueba.invalida;
      });
      return;
    }

    widget.servicio.servidor = direccion;
    setState(() {
      _probada = direccion;
      _resultado = _Prueba.probando;
    });

    bool conectado;
    try {
      conectado = await widget.servicio.probarConexion();
    } catch (_) {
      conectado = false;
    }
    if (conectado) {
      unawaited(DireccionServidor.guardar(widget.servicio.servidor));
    }
    if (!mounted) return;
    setState(
      () => _resultado = conectado ? _Prueba.conectado : _Prueba.sinConexion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final vigente = _probando || widget.controlador.text.trim() == _probada;
    final (mensaje, color) = switch (vigente ? _resultado : null) {
      _Prueba.conectado => (
        EstadoServidor.mensajeConectado,
        Colors.green.shade700,
      ),
      _Prueba.sinConexion => (EstadoServidor.mensajeSinConexion, colores.error),
      _Prueba.invalida => (EstadoServidor.mensajeInvalida, colores.error),
      _ => (null, null),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          key: Key('${widget.prefijo}-probar-conexion'),
          onPressed: _probando ? null : _probar,
          icon: _probando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering),
          label: const Text('Probar conexión'),
        ),
        if (mensaje != null) ...[
          const SizedBox(height: 8),
          Text(
            mensaje,
            key: Key('${widget.prefijo}-estado-servidor'),
            style: TextStyle(color: color),
          ),
        ],
      ],
    );
  }
}
