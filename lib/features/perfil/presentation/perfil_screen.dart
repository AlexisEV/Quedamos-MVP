import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../auth/data/auth_repository.dart';
import '../data/perfil_model.dart';
import '../data/perfil_repository.dart';
import 'editar_nombre_dialog.dart';
import 'perfil_view_model.dart';

// pestana perfil: nombre visible editable, correo y cierre de sesion
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PerfilViewModel(
        perfilRepository: context.read<PerfilRepository>(),
        authRepository: context.read<AuthRepository>(),
      )..cargar(),
      child: const _PerfilVista(),
    );
  }
}

class _PerfilVista extends StatelessWidget {
  const _PerfilVista();

  Future<void> _editarNombre(BuildContext context) async {
    final vm = context.read<PerfilViewModel>();
    final perfil = vm.perfil;
    if (perfil == null) return;
    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: EditarNombreDialog(nombreActual: perfil.nombreVisible),
      ),
    );
    if (guardado == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final mensajes = ScaffoldMessenger.of(context);
    final error = await context.read<PerfilViewModel>().cerrarSesion();
    if (error != null) {
      mensajes.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.cargar,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.margin),
            children: [
              Text(
                'CUENTA DE USUARIO',
                style: textos.labelMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Mi perfil', style: textos.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              _contenido(context, vm),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: vm.cerrandoSesion
                    ? null
                    : () => _cerrarSesion(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.budgetBadgeBg,
                  foregroundColor: AppColors.error,
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: vm.cerrandoSesion
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, PerfilViewModel vm) {
    final perfil = vm.perfil;
    if (perfil != null) {
      return _TarjetaPerfil(
        perfil: perfil,
        onEditar: vm.guardando ? null : () => _editarNombre(context),
      );
    }
    if (vm.errorCarga != null) {
      return _ErrorCarga(mensaje: vm.errorCarga!, onReintentar: vm.cargar);
    }
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _TarjetaPerfil extends StatelessWidget {
  const _TarjetaPerfil({required this.perfil, required this.onEditar});

  final PerfilModel perfil;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final inicial = perfil.nombreVisible.trim().characters.first.toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.tealSurface,
              child: Text(
                inicial,
                style: textos.headlineMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(perfil.nombreVisible, style: textos.titleLarge),
                  if (perfil.correo != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            perfil.correo!,
                            style: textos.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar nombre visible',
              onPressed: onEditar,
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
