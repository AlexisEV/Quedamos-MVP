import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../data/notificacion_model.dart';
import 'notificaciones_view_model.dart';

// p10: historial de avisos con nombre del plan, estado del permiso y apertura del contexto
class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  Future<void> _marcarTodas(BuildContext context) async {
    final vm = context.read<NotificacionesViewModel>();
    await vm.marcarTodas();
    if (!context.mounted) return;
    final error = vm.errorMarcar;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificacionesViewModel>();
    final textos = Theme.of(context).textTheme;
    final historial = vm.historial;
    final nuevas = vm.noLeidas;
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: RefreshIndicator(
        onRefresh: vm.sincronizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _TarjetaPermiso(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Notificaciones y avisos',
                    style: textos.headlineSmall,
                  ),
                ),
                if (nuevas > 0)
                  _InsigniaNuevas(cantidad: nuevas)
                else
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Actualizaciones automáticas según las reglas del plan',
                    style: textos.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: nuevas == 0 || vm.marcandoTodas
                      ? null
                      : () => _marcarTodas(context),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Leídas'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._contenido(context, vm, historial),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(
    BuildContext context,
    NotificacionesViewModel vm,
    List<NotificacionModel> historial,
  ) {
    if (!vm.cargado && vm.cargando) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (!vm.cargado && vm.error != null) {
      return [
        MensajeError(mensaje: vm.error!),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: OutlinedButton(
            onPressed: vm.sincronizar,
            child: const Text('Reintentar'),
          ),
        ),
      ];
    }
    return [
      if (vm.error != null) ...[
        MensajeError(mensaje: vm.error!),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (historial.isEmpty)
        const EstadoVacio(
          icono: Icons.notifications_none,
          titulo: 'Sin avisos todavía',
          mensaje:
              'Aquí aparecerán los recordatorios y cambios de tus salidas.',
        )
      else
        for (final aviso in historial) ...[
          TarjetaAviso(aviso: aviso),
          const SizedBox(height: AppSpacing.gutterSm),
        ],
    ];
  }
}

class _InsigniaNuevas extends StatelessWidget {
  const _InsigniaNuevas({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        cantidad == 1 ? '1 nueva' : '$cantidad nuevas',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.onPrimary),
      ),
    );
  }
}

// estado del permiso del dispositivo y explicacion de los avisos (p10)
class _TarjetaPermiso extends StatelessWidget {
  const _TarjetaPermiso();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificacionesViewModel>();
    final textos = Theme.of(context).textTheme;
    final activado = vm.permiso == true;
    return Card(
      color: activado ? AppColors.tealSurface : AppColors.amberSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  activado
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: activado ? AppColors.primary : AppColors.tertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    activado ? 'Avisos activados' : 'Avisos desactivados',
                    style: textos.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Recibes un aviso 30 minutos antes de cada actividad, 1 hora '
              'antes de los plazos de voto y asistencia, y cuando una salida '
              'cambia o se cancela. Los cambios que hacen otras personas '
              'llegan al abrir la app.',
              style: textos.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (!activado && vm.permiso != null) ...[
              const SizedBox(height: AppSpacing.sm),
              if (vm.permisoBloqueado)
                Text(
                  'Si no aparece el diálogo, activa las notificaciones de '
                  'Quedamos en los Ajustes del teléfono.',
                  style: textos.bodyMedium,
                ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: vm.pedirPermiso,
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Activar avisos'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// tarjeta de un aviso: borde e icono por tipo, plan, titulo, cuerpo y hora
class TarjetaAviso extends StatelessWidget {
  const TarjetaAviso({super.key, required this.aviso});

  final NotificacionModel aviso;

  static (IconData, Color, Color) estilo(TipoNotificacion tipo) =>
      switch (tipo) {
        TipoNotificacion.actividad => (
          Icons.restaurant,
          AppColors.primary,
          AppColors.tealSurface,
        ),
        TipoNotificacion.asistencia => (
          Icons.hourglass_bottom,
          AppColors.tertiary,
          AppColors.amberSurface,
        ),
        TipoNotificacion.voto => (
          Icons.how_to_vote_outlined,
          AppColors.coral,
          AppColors.coralSurface,
        ),
        TipoNotificacion.cambio => (
          Icons.update,
          AppColors.tealDark,
          AppColors.surfaceContainerLow,
        ),
        TipoNotificacion.cancelacion => (
          Icons.event_busy_outlined,
          AppColors.error,
          AppColors.budgetBadgeBg,
        ),
      };

  void _abrir(BuildContext context) {
    // marca leido sin esperar; la pantalla de destino valida el acceso
    context.read<NotificacionesViewModel>().marcarLeida(aviso.id);
    context.go(aviso.rutaDestino);
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final (icono, color, fondo) = estilo(aviso.tipo);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrir(context),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: fondo,
                        child: Icon(icono, color: color, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _cuerpo(context, textos, color, fondo)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(
    BuildContext context,
    TextTheme textos,
    Color color,
    Color fondo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                aviso.nombrePlan,
                style: textos.labelMedium?.copyWith(color: color),
              ),
            ),
            Text(
              formatearFechaHoraLima(aviso.programadaPara),
              style: textos.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(child: Text(aviso.titulo, style: textos.titleMedium)),
            if (!aviso.leida)
              Semantics(
                container: true,
                label: 'No leído',
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          aviso.cuerpo,
          style: textos.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: fondo,
              foregroundColor: color,
            ),
            onPressed: () => _abrir(context),
            child: Text(aviso.tipo.accion),
          ),
        ),
      ],
    );
  }
}
