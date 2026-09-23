import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../project_applications/domain/models/project_application.dart';
import '../../../project_applications/ui/viewmodels/apply_controller.dart';
import '../../domain/models/project_role.dart';

const List<String> _availabilityOptions = [
  'Full-time',
  'Part-time',
  'Flexible',
];

/// Abre el formulario de postulación (crear o editar) a través del
/// [ApplyController] de la feature project_applications.
///
/// Si [existingApplication] no es null, abre en modo edición: prellena los
/// campos y ofrece "Guardar cambios" y "Retirar postulación" en vez de
/// "Enviar postulación".
Future<bool> showApplicationForm(
  BuildContext context, {
  required String projectId,
  required String applicantId,
  required String applicantName,
  required String applicantEmail,
  required List<ProjectRole> openRoles,
  ProjectApplication? existingApplication,
}) async {
  final applyController = Get.find<ApplyController>();

  // El rol al que ya se postuló debe seguir siendo elegible en el
  // dropdown aunque ya no tenga cupos libres — es su propia postulación.
  final selectableRoles = openRoles
      .where(
        (role) => role.isOpen || role.title == existingApplication?.roleTitle,
      )
      .toList();

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
      openRoles: selectableRoles,
      existingApplication: existingApplication,
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
    this.existingApplication,
  });

  final ApplyController controller;
  final String projectId;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final List<ProjectRole> openRoles;
  final ProjectApplication? existingApplication;

  bool get isEditing => existingApplication != null;

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  late final TextEditingController _motivationField;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      final existing = widget.existingApplication!;
      _motivationField = TextEditingController(text: existing.motivation);
      widget.controller.desiredRole.value = existing.roleTitle;
      widget.controller.availability.value = existing.availability;
    } else {
      _motivationField = TextEditingController();
      widget.controller.desiredRole.value = null;
      widget.controller.availability.value = '';
    }
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

    final ok = widget.isEditing
        ? await widget.controller.saveEdits()
        : await widget.controller.submit(
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
                  'No se pudo guardar la postulación.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _confirmWithdraw() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Retirar tu postulación?'),
        content: const Text(
          'El equipo ya no la verá. Puedes volver a postularte más '
          'adelante si sigue habiendo vacante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await widget.controller.withdraw();
      if (mounted) Navigator.pop(context, true);
    }
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
            Text(
              widget.isEditing ? 'Tu postulación' : 'Postularme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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

            Obx(
              () => FilledButton(
                onPressed: widget.controller.isSubmitting.value
                    ? null
                    : _submit,
                child: Text(
                  widget.isEditing ? 'Guardar cambios' : 'Enviar postulación',
                ),
              ),
            ),

            if (widget.isEditing) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _confirmWithdraw,
                child: const Text('Retirar postulación'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
