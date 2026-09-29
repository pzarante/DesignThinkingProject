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
  bool _showPassword = false;

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: Image.asset(
                'assets/launcher_icon/icon.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Bienvenido de vuelta',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Entra para crear proyectos, formar equipo y comentar con tu '
            'nombre.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Correo',
            controller: _emailField,
            hintText: 'tucorreo@uninorte.edu.co',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Contraseña',
            controller: _passwordField,
            hintText: 'Tu contraseña',
            obscureText: !_showPassword,
            suffixIcon: IconButton(
              tooltip: _showPassword
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: TextButton(
              onPressed: () => Get.offNamed(AppRoutes.signup),
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
