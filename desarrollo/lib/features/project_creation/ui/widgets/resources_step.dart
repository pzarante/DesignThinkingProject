import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_cover_picker.dart';
import '../viewmodels/project_creation_controller.dart';

/// Paso 6: portada y enlaces de referencia.
class ResourcesStep extends StatelessWidget {
  const ResourcesStep({super.key, required this.controller});

  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imagen de portada', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => AppCoverPicker(
            imageUrl: controller.coverUrl.value,
            fileName: controller.coverName.value,
            onTap: controller.pickPlaceholderCover,
            onRemove: controller.removeCover,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Referencias y enlaces', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.linkField,
                keyboardType: TextInputType.url,
                onSubmitted: controller.addLink,
                decoration: const InputDecoration(
                  hintText: 'https://github.com/mi-proyecto',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              icon: const Icon(Icons.add),
              onPressed: () => controller.addLink(controller.linkField.text),
            ),
          ],
        ),
        Obx(
          () => Column(
            children: [
              for (final link in controller.links)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link),
                  title: Text(link),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.removeLink(link),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
