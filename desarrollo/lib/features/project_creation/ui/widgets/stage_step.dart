import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_option_card.dart';
import '../viewmodels/project_creation_controller.dart';

/// Paso 1: en qué etapa está el proyecto.
class StageStep extends StatelessWidget {
  const StageStep({super.key, required this.controller});

  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.stage.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona la etapa actual',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (controller.options.stages.isEmpty)
            const AppEmptyState(
              icon: Icons.flag_outlined,
              title: 'Sin etapas configuradas',
              message:
                  'El proyecto todavía no tiene etapas cargadas en ROBLE '
                  '(project_stages). Pídele a quien administra el proyecto '
                  'que las agregue desde la consola.',
            )
          else
            for (final option in controller.options.stages)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppOptionCard(
                  title: option.name,
                  description: option.description,
                  selected: option.name == selected,
                  onTap: () => controller.selectStage(option.name),
                  leading: Icon(
                    option.name == selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: option.name == selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
        ],
      );
    });
  }
}
