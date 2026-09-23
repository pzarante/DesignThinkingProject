import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/authentication_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthenticationController controller = Get.find();
  final _emailField = TextEditingController();
  final _passwordField = TextEditingController();

  @override
  void dispose() {
    _emailField.dispose();
    _passwordField.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final loggedIn = await controller.login(
      _emailField.text.trim(),
      _passwordField.text,
    );
    if (!mounted) return;
    if (loggedIn) {
      Get.back();
    } else {
      Get.snackbar(
        'No se pudo iniciar sesión',
        controller.error.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Inicia sesión para crear proyectos y comunidades.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Correo',
            controller: _emailField,
            hintText: 'tucorreo@uni.edu',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Contraseña',
            controller: _passwordField,
            hintText: 'Tu contraseña',
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton(
              onPressed: () => Get.toNamed(AppRoutes.signup),
              child: const Text('¿No tienes cuenta? Crear una'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          primaryLabel: controller.isLoading
              ? 'Ingresando...'
              : 'Iniciar sesión',
          onPrimary: controller.isLoading ? null : _login,
        ),
      ),
    );
  }
}
