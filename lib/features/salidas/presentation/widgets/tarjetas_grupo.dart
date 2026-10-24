import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../data/participante_model.dart';
import '../detalle_plan_view_model.dart';

// p12 integrada en el detalle: lista del grupo con su rol
class TarjetaParticipantes extends StatelessWidget {
  const TarjetaParticipantes({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final participantes = vm.participantes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.group_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Participantes (${participantes.length})',
                  style: textos.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final participante in participantes)
              _FilaParticipante(
                participante: participante,
                esUsuarioActual: participante.perfilId == vm.usuarioActualId,
                propuestas: vm.propuestasDe(participante.perfilId),
                maxPropuestas: vm.salida?.plan.maxPropuestasPorPersona ?? 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _FilaParticipante extends StatelessWidget {
  const _FilaParticipante({
    required this.participante,
    required this.esUsuarioActual,
    required this.propuestas,
    required this.maxPropuestas,
  });

  final ParticipanteModel participante;
  final bool esUsuarioActual;
  final int propuestas;
  final int maxPropuestas;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          _Avatar(participante: participante),
          const SizedBox(width: AppSpacing.gutterSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participante.nombreVisible,
                        overflow: TextOverflow.ellipsis,
                        style: textos.titleSmall,
                      ),
                    ),
                    if (esUsuarioActual) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _InsigniaTu(),
                    ],
                  ],
                ),
                Text(
                  participante.etiquetaRol,
                  style: textos.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // solo el conteo: proponer no es obligatorio, no hay pendientes
          Text(
            '$propuestas/$maxPropuestas propuestas',
            style: textos.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.participante});

  final ParticipanteModel participante;

  @override
  Widget build(BuildContext context) {
    final nombre = participante.nombreVisible;
    final inicial = nombre.isEmpty ? '' : nombre.characters.first.toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.tealSurface,
          child: Text(
            inicial,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: AppColors.primary),
          ),
        ),
        // estrella de administrador como en el mockup
        if (participante.esAdministrador)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                size: 10,
                color: AppColors.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

class _InsigniaTu extends StatelessWidget {
  const _InsigniaTu();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'Tú',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// acciones de administrador; por ahora solo nombrar administradores (rf17)
class TarjetaGestionAdmin extends StatelessWidget {
  const TarjetaGestionAdmin({super.key});

  Future<void> _nombrar(BuildContext context) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    final elegido = await showModalBottomSheet<ParticipanteModel>(
      context: context,
      // sobre el navegador raiz para que la barra de pestanas no la tape
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => _HojaNombrables(nombrables: vm.nombrables),
    );
    if (elegido == null || !context.mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nombrar a ${elegido.nombreVisible}'),
        content: const Text(
          'Podrá gestionar la salida como administrador. '
          'El rol es permanente y no se puede retirar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Nombrar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final guardado = await vm.nombrarAdministrador(elegido);
    if (guardado) {
      mensajes.showSnackBar(
        SnackBar(
          content: Text('${elegido.nombreVisible} ahora es administrador.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final hayNombrables = vm.nombrables.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Gestión de administrador', style: textos.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.gutterSm),
            Material(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                enabled: hayNombrables && !vm.asignando,
                leading: vm.asignando
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                title: const Text('Nombrar nuevo administrador'),
                subtitle: hayNombrables
                    ? null
                    : const Text('Todos los participantes ya administran.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _nombrar(context),
              ),
            ),
            if (vm.errorAsignacion != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              MensajeError(mensaje: vm.errorAsignacion!),
            ],
          ],
        ),
      ),
    );
  }
}

class _HojaNombrables extends StatelessWidget {
  const _HojaNombrables({required this.nombrables});

  final List<ParticipanteModel> nombrables;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Elige a un participante', style: textos.titleMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final participante in nombrables)
            ListTile(
              leading: _Avatar(participante: participante),
              title: Text(participante.nombreVisible),
              subtitle: Text(participante.etiquetaRol),
              onTap: () => Navigator.of(context).pop(participante),
            ),
        ],
      ),
    );
  }
}
