import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formato.dart';
import '../../../../core/widgets/mensaje_error.dart';
import '../../data/participante_model.dart';
import '../detalle_plan_view_model.dart';
import 'estilo_asistencia.dart';

// respuesta propia para toda la salida, con el plazo opcional y no bloqueante (rf16)
class TarjetaAsistencia extends StatelessWidget {
  const TarjetaAsistencia({super.key});

  Future<void> _responder(BuildContext context, EstadoAsistencia estado) async {
    final vm = context.read<DetallePlanViewModel>();
    final mensajes = ScaffoldMessenger.of(context);
    if (await vm.responderAsistencia(estado)) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Respuesta guardada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final textos = Theme.of(context).textTheme;
    final actual = vm.miAsistencia;
    final plazo = vm.plazoAsistencia;
    final vencido = vm.plazoAsistenciaVencido;
    final respuesta = switch (actual) {
      EstadoAsistencia.pendiente => 'Pendiente',
      EstadoAsistencia.asistire => 'Asistirás',
      EstadoAsistencia.noAsistire => 'No asistirás',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_reg_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Tu asistencia', style: textos.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.gutterSm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gutterSm),
              decoration: BoxDecoration(
                color: actual.fondo,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(actual.icono, color: actual.color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Tu respuesta: ',
                        style: textos.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: respuesta,
                            style: textos.titleMedium?.copyWith(
                              color: actual.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Responde para toda la salida; puedes cambiar tu respuesta.',
              style: textos.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (plazo != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _LineaPlazo(
                icono: vencido
                    ? Icons.timer_off_outlined
                    : Icons.timer_outlined,
                color: vencido ? AppColors.budgetExceeded : AppColors.tertiary,
                texto: vencido
                    ? 'Plazo vencido (${formatearFechaHoraLima(plazo)}); '
                          'aún puedes responder.'
                    : 'Responde antes de ${formatearFechaHoraLima(plazo)}.',
              ),
            ],
            const SizedBox(height: AppSpacing.gutterSm),
            Row(
              children: [
                Expanded(
                  child: _BotonRespuesta(
                    estado: EstadoAsistencia.asistire,
                    texto: 'Asistiré',
                    onPressed: () =>
                        _responder(context, EstadoAsistencia.asistire),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutterSm),
                Expanded(
                  child: _BotonRespuesta(
                    estado: EstadoAsistencia.noAsistire,
                    texto: 'No asistiré',
                    onPressed: () =>
                        _responder(context, EstadoAsistencia.noAsistire),
                  ),
                ),
              ],
            ),
            if (vm.errorAsistencia != null) ...[
              const SizedBox(height: AppSpacing.gutterSm),
              MensajeError(mensaje: vm.errorAsistencia!),
            ],
          ],
        ),
      ),
    );
  }
}

class _LineaPlazo extends StatelessWidget {
  const _LineaPlazo({
    required this.icono,
    required this.color,
    required this.texto,
  });

  final IconData icono;
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _BotonRespuesta extends StatelessWidget {
  const _BotonRespuesta({
    required this.estado,
    required this.texto,
    required this.onPressed,
  });

  final EstadoAsistencia estado;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetallePlanViewModel>();
    final elegido = vm.miAsistencia == estado;
    final guardando = vm.respondiendo == estado;
    final icono = guardando
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(estado.icono, size: 20);
    final etiqueta = Text(texto, overflow: TextOverflow.ellipsis);
    if (elegido) {
      // la respuesta guardada queda marcada; volver a tocarla no envia nada
      return FilledButton.icon(
        onPressed: () {},
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          backgroundColor: estado.color,
          foregroundColor: AppColors.onPrimary,
        ),
        icon: icono,
        label: etiqueta,
      );
    }
    // mientras se guarda una respuesta no se envia otra
    return OutlinedButton.icon(
      onPressed: vm.respondiendo == null ? onPressed : null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: estado.color,
      ),
      icon: icono,
      label: etiqueta,
    );
  }
}
