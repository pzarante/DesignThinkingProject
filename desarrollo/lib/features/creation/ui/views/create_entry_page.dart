import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_icon_badge.dart';
import '../../../../core/widgets/app_option_card.dart';

/// Qué se está creando. Es la bifurcación entre el asistente de proyecto y
/// el formulario de comunidad, así que no necesita estado compartido: solo
/// recuerda la opción marcada hasta pulsar "Continuar".
enum CreationKind { proyecto, comunidad }

class CreateEntryPage extends StatefulWidget {
  const CreateEntryPage({super.key});

  @override
  State<CreateEntryPage> createState() => _CreateEntryPageState();
}

class _CreateEntryPageState extends State<CreateEntryPage> {
  CreationKind? _selected;

  static const Map<CreationKind, ({IconData icon, String title, String text})>
  _options = {
    CreationKind.proyecto: (
      icon: Icons.folder_outlined,
      title: 'Proyecto',
      text:
          'Crea un producto: app, animación, cómic, campaña o cualquier '
          'proyecto colaborativo.',
    ),
    CreationKind.comunidad: (
      icon: Icons.groups_outlined,
      title: 'Comunidad',
      text:
          'Crea un espacio para agrupar y mostrar tus proyectos. Los '
          'visitantes pueden explorar pero solo tú publicas.',
    ),
  };

  void _continue() {
    switch (_selected) {
      case CreationKind.proyecto:
        Get.toNamed(AppRoutes.createProject);
      case CreationKind.comunidad:
        Get.toNamed(AppRoutes.createCommunity);
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear nuevo')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            '¿Qué te gustaría iniciar hoy?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final entry in _options.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppOptionCard(
                title: entry.value.title,
                description: entry.value.text,
                selected: _selected == entry.key,
                onTap: () => setState(() => _selected = entry.key),
                leading: AppIconBadge(
                  icon: entry.value.icon,
                  size: 48,
                  backgroundColor: _selected == entry.key
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  iconColor: _selected == entry.key
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppFormActions(
        primaryLabel: 'Continuar',
        onPrimary: _selected == null ? null : _continue,
      ),
    );
  }
}
