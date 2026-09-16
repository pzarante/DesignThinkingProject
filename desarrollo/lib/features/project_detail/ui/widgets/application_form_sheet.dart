import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../home/domain/models/project_application.dart';
import '../../../home/ui/viewmodels/project_application_controller.dart';

/// Abre el formulario de postulación y entrega la postulación al controller
/// que ya existe en la feature home.
///
/// La lógica de postulación (modelo, repositorio y controller) es de esa
/// feature; aquí solo se ofrece la entrada desde el detalle del proyecto.
Future<bool> showApplicationForm(
  BuildContext context, {
  required String projectId,
  required String applicantName,
  required String applicantEmail,
}) async {
  final answers = await showModalBottomSheet<_ApplicationAnswers>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ApplicationForm(),
  );

  if (answers == null) return false;

  await Get.find<ProjectApplicationController>().submit(
    ProjectApplication(
      id: 'application-${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      motivation: answers.motivation,
      availability: answers.availability,
    ),
  );
  return true;
}

/// Lo que responde quien se postula.
class _ApplicationAnswers {
  const _ApplicationAnswers({
    required this.motivation,
    required this.availability,
  });

  final String motivation;
  final String availability;
}

/// La hoja posee sus campos para liberarlos cuando el widget se desmonta,
/// no al devolver el resultado: la animación de cierre todavía los usa.
class _ApplicationForm extends StatefulWidget {
  const _ApplicationForm();

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ApplicationAnswers(
        motivation: _motivationField.text.trim(),
        availability: _availabilityField.text.trim(),
      ),
    );
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
