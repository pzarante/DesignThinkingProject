import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_choice_chip_row.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_wizard_progress.dart';
import '../../domain/password_policy.dart';
import '../viewmodels/authentication_controller.dart';
import '../widgets/password_checklist.dart';

/// Registro en dos pasos: primero la cuenta (lo que ROBLE necesita para
/// existir), después el perfil (lo que llena la tabla `users`).
///
/// Se parte en dos a propósito: el primer paso es obligatorio y tiene reglas
/// que hay que ir enseñando mientras se escribe; el segundo es todo opcional
/// y pedirlo junto hacía un formulario largo donde no se distinguía qué
/// bloqueaba el registro.
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
  final _bioField = TextEditingController();

  int _step = 0;
  int? _academicYear;
  bool _showPassword = false;

  /// Solo se enseña el error del usuario o del correo cuando ya se tocó el
  /// campo: marcar en rojo algo que aún no se ha escrito es ruido.
  bool _userNameTouched = false;
  bool _emailTouched = false;

  static const int _totalSteps = 2;

  @override
  void initState() {
    super.initState();
    // El botón de continuar y la lista de requisitos dependen de lo escrito,
    // así que hay que repintar en cada tecla.
    for (final field in [_userNameField, _emailField, _passwordField]) {
      field.addListener(_onAccountFieldChanged);
    }
  }

  void _onAccountFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final field in [_userNameField, _emailField, _passwordField]) {
      field.removeListener(_onAccountFieldChanged);
    }
    _userNameField.dispose();
    _firstNameField.dispose();
    _lastNameField.dispose();
    _emailField.dispose();
    _passwordField.dispose();
    _careerField.dispose();
    _bioField.dispose();
    super.dispose();
  }

  String get _userName => _userNameField.text.trim();

  String? get _userNameError => UserNamePolicy.validate(_userNameField.text);

  bool get _emailLooksValid {
    final email = _emailField.text.trim();
    return email.contains('@') && email.split('@').last.contains('.');
  }

  bool get _accountStepIsValid =>
      _userNameError == null &&
      _emailLooksValid &&
      PasswordPolicy.isValid(_passwordField.text);

  void _goToProfileStep() {
    setState(() {
      _userNameTouched = true;
      _emailTouched = true;
      if (_accountStepIsValid) _step = 1;
    });
  }

  Future<void> _signUp() async {
    final created = await controller.signUp(
      _emailField.text.trim(),
      _passwordField.text,
      name: _userName,
      firstName: _firstNameField.text,
      lastName: _lastNameField.text,
      career: _careerField.text,
      academicYear: _academicYear,
      bio: _bioField.text,
    );
    if (!mounted) return;
    if (created) {
      // `off` y no `to`: volver atrás desde la confirmación tendría que
      // devolver a Explorar, no al formulario de una cuenta ya creada.
      Get.offNamed(AppRoutes.signupSuccess, arguments: _userName);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        leading: BackButton(
          onPressed: () =>
              _step == 0 ? Get.back() : setState(() => _step = 0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          AppWizardProgress(currentStep: _step + 1, totalSteps: _totalSteps),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _step == 0 ? 'Tu cuenta' : 'Cuéntanos de ti',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _step == 0
                ? 'Con esto entras a la app y los demás te encuentran.'
                : 'Todo lo de este paso es opcional: hace que tu perfil diga '
                      'algo más que tu nombre de usuario.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_step == 0) ..._accountStep(theme) else ..._profileStep(),
          Obx(() {
            final error = controller.error.value;
            if (error.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: _ErrorBanner(message: error),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          secondaryLabel: _step == 0 ? null : 'Atrás',
          onSecondary: () => setState(() => _step = 0),
          primaryLabel: controller.isLoading
              ? 'Creando...'
              : (_step == 0 ? 'Continuar' : 'Crear cuenta'),
          onPrimary: controller.isLoading
              ? null
              : (_step == 0
                    ? (_accountStepIsValid ? _goToProfileStep : null)
                    : _signUp),
        ),
      ),
    );
  }

  List<Widget> _accountStep(ThemeData theme) => [
    AppTextField(
      label: 'Nombre de usuario',
      controller: _userNameField,
      hintText: 'ana.martinez',
      isRequired: true,
      helperText: _userName.isEmpty
          ? 'Así te van a ver los demás, y así te van a buscar.'
          : 'Te verán como @$_userName',
      errorText: _userNameTouched ? _userNameError : null,
      onChanged: (_) {
        if (!_userNameTouched) setState(() => _userNameTouched = true);
      },
    ),
    const SizedBox(height: AppSpacing.md),
    AppTextField(
      label: 'Correo',
      controller: _emailField,
      hintText: 'tucorreo@uninorte.edu.co',
      isRequired: true,
      keyboardType: TextInputType.emailAddress,
      errorText: _emailTouched && !_emailLooksValid && _emailField.text.isNotEmpty
          ? 'Escribe un correo válido.'
          : null,
      onChanged: (_) {
        if (!_emailTouched) setState(() => _emailTouched = true);
      },
    ),
    const SizedBox(height: AppSpacing.md),
    AppTextField(
      label: 'Contraseña',
      controller: _passwordField,
      hintText: 'Tu contraseña',
      isRequired: true,
      obscureText: !_showPassword,
      suffixIcon: IconButton(
        tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
        icon: Icon(
          _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
        onPressed: () => setState(() => _showPassword = !_showPassword),
      ),
    ),
    const SizedBox(height: AppSpacing.sm),
    PasswordChecklist(password: _passwordField.text),
    const SizedBox(height: AppSpacing.lg),
    Center(
      child: TextButton(
        onPressed: () => Get.offNamed(AppRoutes.login),
        child: const Text('¿Ya tienes cuenta? Inicia sesión'),
      ),
    ),
  ];

  List<Widget> _profileStep() => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            label: 'Nombre',
            controller: _firstNameField,
            hintText: 'Ana',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppTextField(
            label: 'Apellido',
            controller: _lastNameField,
            hintText: 'Martínez',
          ),
        ),
      ],
    ),
    const SizedBox(height: AppSpacing.md),
    AppTextField(
      label: 'Programa académico',
      controller: _careerField,
      hintText: 'Ingeniería de Sistemas',
    ),
    const SizedBox(height: AppSpacing.md),
    Text('Año que cursas', style: Theme.of(context).textTheme.labelMedium),
    const SizedBox(height: AppSpacing.xs),
    AppChoiceChipRow<int?>(
      options: const [1, 2, 3, 4, 5, 6],
      labelBuilder: (year) => '$yearº',
      selected: _academicYear,
      // Volver a tocar el año elegido lo quita: es opcional y no hay otra
      // forma de dejarlo en blanco después de haberlo marcado.
      onSelected: (year) => setState(
        () => _academicYear = _academicYear == year ? null : year,
      ),
    ),
    const SizedBox(height: AppSpacing.md),
    AppTextField(
      label: 'Sobre ti',
      controller: _bioField,
      hintText: 'En qué andas, qué te interesa, qué buscas en un equipo.',
      minLines: 3,
      maxLines: 5,
      maxLength: 280,
    ),
  ];
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
