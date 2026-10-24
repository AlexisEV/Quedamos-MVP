import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/utils/formato.dart';
import '../../../core/widgets/estado_vacio.dart';
import '../data/lugar_model.dart';
import '../data/lugares_repository.dart';
import 'ficha_lugar_view_model.dart';
import 'widgets/estilo_lugar.dart';

// ficha del lugar: ubicacion, horario y precio, distinguiendo lo desconocido (p04)
class FichaLugarScreen extends StatelessWidget {
  const FichaLugarScreen({super.key, required this.lugarId});

  final String lugarId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          FichaLugarViewModel(context.read<LugaresRepository>(), lugarId)
            ..cargar(),
      child: const _FichaVista(),
    );
  }
}

class _FichaVista extends StatelessWidget {
  const _FichaVista();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FichaLugarViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del lugar')),
      body: _cuerpo(vm),
    );
  }

  Widget _cuerpo(FichaLugarViewModel vm) {
    final lugar = vm.lugar;
    if (lugar != null) {
      final precio = lugar.precioEstimadoPen;
      return RefreshIndicator(
        onRefresh: vm.cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            _Cabecera(lugar: lugar),
            const SizedBox(height: AppSpacing.md),
            // el precio se presenta como estimado, nunca como garantizado (rf04)
            _TarjetaDato(
              icono: Icons.payments_outlined,
              titulo: 'Precio estimado por persona',
              valor: precio == null ? null : formatearSoles(precio),
              detalle: precio == null
                  ? null
                  : [
                      if (lugar.precioNota != null) lugar.precioNota!,
                      TextosLugar.precioOrientativo,
                    ].join('\n'),
              destacado: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _TarjetaDato(
              icono: Icons.schedule,
              titulo: 'Horario de atención (referencial)',
              valor: lugar.horarioAtencion,
            ),
            const SizedBox(height: AppSpacing.md),
            _TarjetaDato(
              icono: Icons.place_outlined,
              titulo: 'Ubicación',
              valor: lugar.direccion,
              detalle: '${lugar.zona.etiqueta}, Arequipa',
            ),
          ],
        ),
      );
    }
    if (vm.noEncontrado) {
      return const EstadoVacio(
        icono: Icons.search_off,
        titulo: 'Este lugar no está disponible',
        mensaje: 'Puede que ya no forme parte del catálogo.',
      );
    }
    if (vm.error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EstadoVacio(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudo cargar el lugar',
            mensaje: vm.error,
          ),
          OutlinedButton(onPressed: vm.cargar, child: const Text('Reintentar')),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.lugar});

  final LugarModel lugar;

  @override
  Widget build(BuildContext context) {
    final categoria = lugar.categoria;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: categoria.colorFondo,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(categoria.icono, color: categoria.colorIcono, size: 40),
            const SizedBox(height: AppSpacing.gutterSm),
            Text(
              lugar.nombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                EtiquetaLugar(
                  texto: lugar.zona.etiqueta,
                  icono: Icons.place_outlined,
                ),
                EtiquetaLugar(
                  texto: categoria.etiqueta,
                  icono: categoria.icono,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// dato de la ficha; un valor null se muestra como desconocido
class _TarjetaDato extends StatelessWidget {
  const _TarjetaDato({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.detalle,
    this.destacado = false,
  });

  final IconData icono;
  final String titulo;
  final String? valor;
  final String? detalle;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estiloValor = destacado ? textos.titleLarge : textos.bodyLarge;
    final colorValor = valor == null
        ? AppColors.textMuted
        : destacado
        ? AppColors.primary
        : AppColors.textPrimary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: AppColors.primary),
            const SizedBox(width: AppSpacing.gutterSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: textos.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    valor ?? TextosLugar.desconocido,
                    style: estiloValor?.copyWith(color: colorValor),
                  ),
                  if (detalle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      detalle!,
                      style: textos.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
