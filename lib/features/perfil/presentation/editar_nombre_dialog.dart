import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/validadores.dart';
import '../../../core/widgets/mensaje_error.dart';
import 'perfil_view_model.dart';

// se cierra con true solo despues de que el servidor guardo el nombre
class EditarNombreDialog extends StatefulWidget {
  const EditarNombreDialog({super.key, required this.nombreActual});

  final String nombreActual;

  @override
  State<EditarNombreDialog> createState() => _EditarNombreDialogState();
}

class _EditarNombreDialogState extends State<EditarNombreDialog> {
  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.nombreActual);
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final vm = context.read<PerfilViewModel>();
    if (vm.guardando) return;
    if (!(_formulario.currentState?.validate() ?? false)) return;
    if (_nombre.text.trim() == widget.nombreActual) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _error = null);
    final error = await vm.guardarNombreVisible(_nombre.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardando = context.watch<PerfilViewModel>().guardando;
    return AlertDialog(
      title: const Text('Nombre visible'),
      content: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nombre,
              enabled: !guardando,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                helperText: 'Así te verá tu grupo.',
              ),
              validator: Validadores.nombreVisible,
              onFieldSubmitted: (_) => _guardar(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              MensajeError(mensaje: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: guardando ? null : _guardar,
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          child: guardando
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
