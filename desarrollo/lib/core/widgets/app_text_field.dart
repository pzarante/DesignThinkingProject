import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Campo de formulario con etiqueta encima y contador opcional de caracteres.
///
/// Es el patrón que repiten todos los pasos del asistente de creación:
/// etiqueta (con `*` si es obligatorio), contador a la derecha y el campo
/// debajo. El texto lo sigue poseyendo quien llama, a través de [controller].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.isRequired = false,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
    this.obscureText = false,
  });

  /// Null deja el campo sin etiqueta encima (pasos que ya la llevan en el
  /// encabezado de la pantalla).
  final String? label;
  final TextEditingController controller;
  final String? hintText;

  /// Texto de apoyo bajo el campo, p. ej. "Define límites claros de tiempo".
  final String? helperText;
  final bool isRequired;

  /// Límite mostrado en el contador `usados / maxLength`. No recorta el texto
  /// automáticamente: el contador informa, igual que en el diseño.
  final int? maxLength;
  final int? minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || maxLength != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label == null ? '' : (isRequired ? '$label *' : label!),
                  style: theme.textTheme.labelMedium,
                ),
              ),
              if (maxLength != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) => Text(
                    '${value.text.length} / $maxLength',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        if (label != null || maxLength != null)
          const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          minLines: minLines,
          maxLines: maxLines,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
          ),
        ),
      ],
    );
  }
}
