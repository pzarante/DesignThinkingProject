import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../viewmodels/apply_controller.dart';

/// Postularse a un proyecto. Recibe por [Get.arguments] un mapa con
/// projectId, projectName, applicantId, applicantName, applicantEmail.
class ApplyPage extends StatefulWidget {
  const ApplyPage({super.key});

  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final ApplyController controller = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _motivationField = TextEditingController();
  final _availabilityField = TextEditingController();

  late final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;

  @override
  void dispose() {
    _motivationField.dispose();
    _availabilityField.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    controller.motivation.value = _motivationField.text.trim();
    controller.availability.value = _availabilityField.text.trim();

    final ok = await controller.submit(
      projectId: args['projectId'] as String,
      applicantId: args['applicantId'] as String,
      applicantName: args['applicantName'] as String,
      applicantEmail: args['applicantEmail'] as String,
    );

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage.value ?? 'No se pudo enviar.'),
        ),
      );
      return;
    }

    Get.back(result: true);
    Get.snackbar('Postulación enviada', 'El equipo revisará tu solicitud.');
  }

  @override
  Widget build(BuildContext context) {
    final projectName = args['projectName'] as String? ?? 'este proyecto';

    return Scaffold(
      appBar: AppBar(title: Text('Postularme a $projectName')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _motivationField,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Motivación'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Cuéntale al equipo cómo puedes aportar'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              Obx(
                () => FilledButton(
                  onPressed: controller.isSubmitting.value ? null : _submit,
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar postulación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
