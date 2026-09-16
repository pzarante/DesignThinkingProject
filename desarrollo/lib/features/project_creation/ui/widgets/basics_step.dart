import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_input.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/project_creation_controller.dart';

/// Paso 2: nombre, descripción breve y etiquetas.
class BasicsStep extends StatelessWidget {
  const BasicsStep({super.key, required this.controller});

  final ProjectCreationController controller;

  static const int _descriptionLimit = 150;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Nombre del proyecto',
          isRequired: true,
          controller: controller.nameField,
          hintText: 'EcoCampus',
          onChanged: (value) => controller.name.value = value,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Descripción breve',
          isRequired: true,
          controller: controller.descriptionField,
          maxLength: _descriptionLimit,
          minLines: 3,
          maxLines: 5,
          hintText: '¿De qué trata tu proyecto?',
          onChanged: (value) => controller.description.value = value,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Etiquetas del proyecto (Tags)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Obx(
          () => AppTagInput(
            selectedTags: controller.tags.toList(),
            systemTags: controller.options.systemTags,
            communityTags: controller.options.communityTags,
            onAdd: controller.addTag,
            onRemove: controller.removeTag,
          ),
        ),
      ],
    );
  }
}
