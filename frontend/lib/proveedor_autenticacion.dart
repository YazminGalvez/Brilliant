import 'package:flutter/widgets.dart';
import 'package:frontend/autenticacion.dart';

typedef VolverAlInicio =
    void Function(NavigatorState navegador, {String? aviso});

class ProveedorAutenticacion extends InheritedWidget {
  const ProveedorAutenticacion({
    required this.servicio,
    required this.volverAlInicio,
    required super.child,
    super.key,
  });

  final ServicioAutenticacion servicio;
  final VolverAlInicio volverAlInicio;

  static ProveedorAutenticacion? buscar(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProveedorAutenticacion>();

  static ServicioAutenticacion? maybeOf(BuildContext context) =>
      buscar(context)?.servicio;

  @override
  bool updateShouldNotify(ProveedorAutenticacion oldWidget) =>
      servicio != oldWidget.servicio ||
      volverAlInicio != oldWidget.volverAlInicio;
}
