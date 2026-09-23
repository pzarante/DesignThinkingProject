import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../project_applications/ui/viewmodels/apply_controller.dart';
import '../../domain/models/project_role.dart';

const List<String> _availabilityOptions = [
  'Full-time',
  'Part-time',
  'Flexible',
];

/// Abre el formulario de postulación y lo envía a través del
/// [ApplyController] de la feature project_applications.
///
/// La lógica de postulación (modelo, repositorio y validación) es de esa
/// feature; aquí solo se ofrece la entrada desde el detalle del proyecto.
Future<bool> showApplicationForm(
  BuildContext context, {
  required String projectId,
  required String applicantId,
  required String applicantName,
  required String applicantEmail,
  required List<ProjectRole> openRoles,
}) async {
  final applyController = Get.find<ApplyController>();

  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ApplicationForm(
      controller: applyController,
      projectId: projectId,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      openRoles: openRoles.where((role) => role.isOpen).toList(),
    ),
  );

  return submitted ?? false;
}

class _ApplicationForm extends StatefulWidget {
  const _ApplicationForm({
    required this.controller,
    required this.projectId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.openRoles,
  });

  final ApplyController controller;
  final String projectId;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final List<ProjectRole> openRoles;

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  final TextEditingController _motivationField = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.controller.desiredRole.value = null;
    widget.controller.availability.value = '';
  }

  @override
  void dispose() {
    _motivationField.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.controller.desiredRole.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige el rol al que quieres aplicar.')),
      );
      return;
    }
    if (widget.controller.availability.value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Elige tu disponibilidad.')));
      return;
    }

    widget.controller.motivation.value = _motivationField.text.trim();

    final ok = await widget.controller.submit(
      projectId: widget.projectId,
      applicantId: widget.applicantId,
      applicantName: widget.applicantName,
      applicantEmail: widget.applicantEmail,
    );

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.errorMessage.value ??
                  'No se pudo enviar la postulación.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Postularme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Rol al que aplicas',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(
              () => DropdownButtonFormField<String>(
                initialValue: widget.controller.desiredRole.value,
                items: [
                  for (final role in widget.openRoles)
                    DropdownMenuItem(
                      value: role.title,
                      child: Text(role.title),
                    ),
                ],
                onChanged: (value) =>
                    widget.controller.desiredRole.value = value,
                decoration: const InputDecoration(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Disponibilidad',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Obx(
              () => SegmentedButton<String>(
                segments: [
                  for (final option in _availabilityOptions)
                    ButtonSegment(value: option, label: Text(option)),
                ],
                selected: widget.controller.availability.value.isEmpty
                    ? const {}
                    : {widget.controller.availability.value},
                emptySelectionAllowed: true,
                onSelectionChanged: (selection) =>
                    widget.controller.availability.value = selection.isEmpty
                    ? ''
                    : selection.first,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Text('Motivación', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _motivationField,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Cuéntale al equipo cómo puedes aportar'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),

            FilledButton(
              onPressed: _submit,
              child: const Text('Enviar postulación'),
            ),
          ],
        ),
      ),
    );
  }
}
