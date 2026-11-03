import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/autenticacion.dart';
import 'package:frontend/inicio_sesion.dart';

final _caracteresDeUsuario = RegExp(r'^[A-Za-z0-9_-]+$');

String? validarUsuario(String? valor) {
  final usuario = (valor ?? '').trim();
  if (usuario.isEmpty) return 'Escribe un usuario.';
  if (!_caracteresDeUsuario.hasMatch(usuario)) {
    return 'Usa solo letras sin acentos, números, - y _.';
  }
  if (usuario.length < 3 || usuario.length > 32) {
    return 'El usuario debe tener de 3 a 32 caracteres.';
  }
  return null;
}

String? validarContrasena(String? valor) {
  final contrasena = valor ?? '';
  if (contrasena.isEmpty) return 'Escribe una contraseña.';
  if (contrasena.length < 8 || contrasena.length > 128) {
    return 'La contraseña debe tener de 8 a 128 caracteres.';
  }
  return null;
}

class RegistroPage extends StatefulWidget {
  const RegistroPage({
    required this.servicio,
    required this.siguiente,
    super.key,
  });

  static const errorGeneral = 'No se pudo crear la cuenta. Inténtalo de nuevo.';

  final ServicioAutenticacion servicio;
  final WidgetBuilder siguiente;

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _contrasena = TextEditingController();
  final _repetir = TextEditingController();

  bool _mostrarContrasena = false;
  bool _enviando = false;
  bool _intentoEnviar = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _contrasena.dispose();
    _repetir.dispose();
    super.dispose();
  }

  String? _validarRepeticion(String? valor) {
    final repetida = valor ?? '';
    if (repetida.isEmpty) return 'Repite la contraseña.';
    if (repetida != _contrasena.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  Future<void> _crearCuenta() async {
    if (_enviando) return;

    setState(() => _intentoEnviar = true);
    if (!_formulario.currentState!.validate()) return;

    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await widget.servicio.crearCuenta(_usuario.text.trim(), _contrasena.text);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: widget.siguiente),
        (_) => false,
      );
    } on ErrorAutenticacion catch (error) {
      if (!mounted) return;
      _mostrarFallo(error.mensaje);
    } catch (_) {
      if (!mounted) return;
      _mostrarFallo(RegistroPage.errorGeneral);
    }
  }

  void _mostrarFallo(String mensaje) {
    setState(() {
      _error = mensaje;
      _enviando = false;
      _contrasena.clear();
      _repetir.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final error = _error;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Crear cuenta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final margen = max(24.0, (restricciones.maxWidth - 420) / 2);
            return AutofillGroup(
              child: Form(
                key: _formulario,
                autovalidateMode: _intentoEnviar
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: margen,
                    vertical: 24,
                  ),
                  children: [
                    const MarcaDelJuego(),
                    const SizedBox(height: 24),
                    Text(
                      'Crea tu cuenta',
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige un usuario y una contraseña para jugar.',
                      style: TextStyle(
                        fontSize: 15,
                        color: colores.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('registro-usuario'),
                      controller: _usuario,
                      validator: validarUsuario,
                      readOnly: _enviando,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        helperText: '3 a 32 caracteres: letras, números, - y _',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('registro-contrasena'),
                      controller: _contrasena,
                      validator: validarContrasena,
                      readOnly: _enviando,
                      obscureText: !_mostrarContrasena,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: '8 a 128 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          key: const Key('registro-mostrar-contrasena'),
                          tooltip: _mostrarContrasena
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          icon: Icon(
                            _mostrarContrasena
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _mostrarContrasena = !_mostrarContrasena,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('registro-repetir'),
                      controller: _repetir,
                      validator: _validarRepeticion,
                      readOnly: _enviando,
                      obscureText: !_mostrarContrasena,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _crearCuenta(),
                      decoration: const InputDecoration(
                        labelText: 'Repite la contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      SelectableText(
                        error,
                        key: const Key('registro-error'),
                        style: TextStyle(color: colores.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('registro-crear'),
                      onPressed: _enviando ? null : _crearCuenta,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
