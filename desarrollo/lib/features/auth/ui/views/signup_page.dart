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
  final _nameField = TextEditingController();
  final _emailField = TextEditingController();
  final _passwordField = TextEditingController();

  @override
  void dispose() {
    _nameField.dispose();
    _emailField.dispose();
    _passwordField.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final created = await controller.signUp(
      _emailField.text.trim(),
      _passwordField.text,
      name: _nameField.text,
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
            label: 'Nombre',
            controller: _nameField,
            hintText: 'Tu nombre completo',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Correo',
            controller: _emailField,
            hintText: 'tucorreo@uni.edu',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Contraseña',
            controller: _passwordField,
            hintText: 'Mínimo 7 caracteres',
            obscureText: true,
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
