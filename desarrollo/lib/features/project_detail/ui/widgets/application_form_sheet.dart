import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../project_applications/ui/viewmodels/apply_controller.dart';

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
  });

  final ApplyController controller;
  final String projectId;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  final TextEditingController _motivationField = TextEditingController();
  final TextEditingController _availabilityField = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _motivationField.dispose();
    _availabilityField.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    widget.controller.motivation.value = _motivationField.text.trim();
    widget.controller.availability.value = _availabilityField.text.trim();

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
            TextFormField(
              controller: _motivationField,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Motivación'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Cuéntale al equipo cómo puedes aportar'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _availabilityField,
              decoration: const InputDecoration(
                labelText: 'Disponibilidad',
                hintText: '6 horas por semana',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Indica tu disponibilidad'
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
