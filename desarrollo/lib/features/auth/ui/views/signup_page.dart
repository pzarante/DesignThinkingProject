import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/authentication_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthenticationController controller = Get.find();
  final _userNameField = TextEditingController();
  final _firstNameField = TextEditingController();
  final _lastNameField = TextEditingController();
  final _emailField = TextEditingController();
  final _passwordField = TextEditingController();
  final _careerField = TextEditingController();
  final _academicYearField = TextEditingController();
  final _bioField = TextEditingController();

  @override
  void dispose() {
    _userNameField.dispose();
    _firstNameField.dispose();
    _lastNameField.dispose();
    _emailField.dispose();
    _passwordField.dispose();
    _careerField.dispose();
    _academicYearField.dispose();
    _bioField.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final created = await controller.signUp(
      _emailField.text.trim(),
      _passwordField.text,
      name: _userNameField.text,
      firstName: _firstNameField.text,
      lastName: _lastNameField.text,
      career: _careerField.text,
      academicYear: int.tryParse(_academicYearField.text.trim()),
      bio: _bioField.text,
    );
    if (!mounted) return;
    if (created) {
      Get.back();
    } else {
      Get.snackbar(
        'No se pudo crear la cuenta',
        controller.error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppTextField(
            label: 'Nombre de usuario',
            controller: _userNameField,
            hintText: 'Como te van a ver los demás (debe ser único)',
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Nombre',
                  controller: _firstNameField,
                  hintText: 'Opcional',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: 'Apellido',
                  controller: _lastNameField,
                  hintText: 'Opcional',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Correo',
            controller: _emailField,
            hintText: 'tucorreo@uni.edu',
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Contraseña',
            controller: _passwordField,
            hintText: 'Mín. 8 caracteres, mayúscula, minúscula, número y símbolo (!@#\$_-)',
            obscureText: true,
            isRequired: true,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Programa académico',
            controller: _careerField,
            hintText: 'Opcional, p. ej. Ingeniería de Sistemas',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Año académico',
            controller: _academicYearField,
            hintText: 'Opcional, p. ej. 3',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Biografía',
            controller: _bioField,
            hintText: 'Opcional: una frase sobre ti',
            minLines: 2,
            maxLines: 4,
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          primaryLabel: controller.isLoading ? 'Creando...' : 'Crear cuenta',
          onPrimary: controller.isLoading ? null : _signUp,
        ),
      ),
    );
  }
}
