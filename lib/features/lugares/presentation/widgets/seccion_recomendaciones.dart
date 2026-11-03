import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/estado_vacio.dart';
import '../../data/lugar_model.dart';
import '../../data/lugares_repository.dart';
import '../recomendaciones_view_model.dart';
import 'tarjeta_lugar.dart';

// entradas obligatorias y lista de recomendaciones dentro de explorar (p09)
List<Widget> seccionRecomendaciones(BuildContext context) {
  final vm = context.watch<RecomendacionesViewModel>();
  final textos = Theme.of(context).textTheme;
  final secundario = textos.bodySmall?.copyWith(color: AppColors.textSecondary);
  return [
    Text(
      'Elige zona, categoría y presupuesto por persona. Se muestran hasta '
      '${LugaresRepository.maxRecomendaciones} lugares, del más económico '
      'al más caro.',
      style: textos.bodyMedium?.copyWith(color: AppColors.textSecondary),
    ),
    const SizedBox(height: AppSpacing.md),
    _Grupo<ZonaLugar>(
      titulo: 'Zona',
      opciones: ZonaLugar.values,
      etiqueta: (zona) => zona.etiqueta,
      elegida: vm.zona,
      alElegir: vm.elegirZona,
    ),
    _Grupo<CategoriaLugar>(
      titulo: 'Categoría',
      opciones: CategoriaLugar.values,
      etiqueta: (categoria) => categoria.etiqueta,
      elegida: vm.categoria,
      alElegir: vm.elegirCategoria,
    ),
    _Grupo<int>(
      titulo: 'Presupuesto por persona',
      opciones: RecomendacionesViewModel.topesPresupuesto,
      etiqueta: (tope) => 'Hasta S/ $tope',
      elegida: vm.tope,
      alElegir: vm.elegirTope,
    ),
    FilledButton(
      onPressed: vm.puedeConsultar ? vm.consultar : null,
      child: const Text('Ver recomendaciones'),
    ),
    if (!vm.puedeConsultar && !vm.consultando) ...[
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Elige las tres opciones para ver recomendaciones.',
        textAlign: TextAlign.center,
        style: secundario,
      ),
    ],
    const SizedBox(height: AppSpacing.lg),
    ..._resultado(context, vm, secundario),
  ];
}

List<Widget> _resultado(
  BuildContext context,
  RecomendacionesViewModel vm,
  TextStyle? secundario,
) {
  if (vm.consultando) {
    return const [
      Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }
  if (vm.error != null) {
    return [
      EstadoVacio(
        icono: Icons.cloud_off_outlined,
        titulo: 'No se pudieron cargar las recomendaciones',
        mensaje: vm.error,
      ),
      Center(
        child: OutlinedButton(
          onPressed: vm.consultar,
          child: const Text('Reintentar'),
        ),
      ),
    ];
  }
  if (vm.sinOpciones) {
    return const [
      EstadoVacio(
        icono: Icons.search_off_outlined,
        titulo: 'Sin opciones compatibles',
        mensaje:
            'No hay lugares con precio conocido dentro de ese presupuesto. '
            'Prueba otra zona, otra categoría o un presupuesto mayor.',
      ),
    ];
  }
  if (!vm.consultado) return const [];
  return [
    for (final lugar in vm.recomendaciones)
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TarjetaLugar(
          lugar: lugar,
          yaPropuesto: vm.yaPropuesto(lugar.id),
          onTap: () => context.push(Rutas.fichaLugar(lugar.id)),
        ),
      ),
    Text(
      'Los lugares sin precio conocido no aparecen aquí, pero sí en el '
      'catálogo. Una recomendación no es un acuerdo del grupo: se decide '
      'al votar.',
      style: secundario,
    ),
  ];
}

class _Grupo<T> extends StatelessWidget {
  const _Grupo({
    required this.titulo,
    required this.opciones,
    required this.etiqueta,
    required this.elegida,
    required this.alElegir,
  });

  final String titulo;
  final List<T> opciones;
  final String Function(T) etiqueta;
  final T? elegida;
  final ValueChanged<T> alElegir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: textos.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final opcion in opciones)
                ChoiceChip(
                  label: Text(etiqueta(opcion)),
                  selected: opcion == elegida,
                  onSelected: (_) => alElegir(opcion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
