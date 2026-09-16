import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Barra inferior fija con la acción principal y, opcionalmente, una
/// secundaria a su izquierda ("Atrás").
class AppFormActions extends StatelessWidget {
  const AppFormActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryColor,
    this.onPrimaryColor,
  });

  final String primaryLabel;

  /// Null deja el botón principal deshabilitado (paso incompleto).
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Color de la acción principal. Null usa el primario del tema; la pantalla
  /// de revisión lo cambia a verde para "Publicar proyecto".
  final Color? primaryColor;
  final Color? onPrimaryColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (secondaryLabel != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                flex: secondaryLabel == null ? 1 : 3,
                child: FilledButton(
                  style: primaryColor == null
                      ? null
                      : FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: onPrimaryColor,
                        ),
                  onPressed: onPrimary,
                  child: Text(primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
