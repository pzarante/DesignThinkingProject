import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/project.dart';
import '../viewmodels/home_controller.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rolesController = TextEditingController();
  int _step = 0;
  String _stage = 'Idea';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rolesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear proyecto')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: _continue,
          onStepCancel: () => setState(() => _step = (_step - 1).clamp(0, 1)),
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(_step == 1 ? 'Publicar proyecto' : 'Siguiente'),
                ),
                if (_step > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Atrás'),
                  ),
              ],
            ),
          ),
          steps: [
            Step(
              title: const Text('Define la idea'),
              subtitle: const Text('Qué quieres construir'),
              isActive: _step >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe un nombre'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descripción y objetivo',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Describe el objetivo del proyecto'
                        : null,
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Prepara la colaboración'),
              subtitle: const Text('Etapa y perfiles que buscas'),
              isActive: _step >= 1,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _stage,
                    decoration: const InputDecoration(labelText: 'Etapa'),
                    items: const ['Idea', 'Investigación', 'Prototipo', 'Equipo']
                        .map((stage) => DropdownMenuItem(
                              value: stage,
                              child: Text(stage),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _stage = value!),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _rolesController,
                    decoration: const InputDecoration(
                      labelText: 'Perfiles necesarios',
                      hintText: 'Diseño, investigación, desarrollo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    if (_step == 0) {
      if (_formKey.currentState!.validate()) setState(() => _step = 1);
      return;
    }

    final project = Project(
      id: 'project-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      stage: _stage,
      requiredRoles: _rolesController.text
          .split(',')
          .map((role) => role.trim())
          .where((role) => role.isNotEmpty)
          .toList(),
      createdAt: DateTime.now(),
    );
    Get.find<HomeController>().addProject(project);
    Get.offNamed('/project-detail', arguments: project);
  }
}