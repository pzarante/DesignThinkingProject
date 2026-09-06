import 'package:f_clean_template/core/widgets/app_section_header.dart';
import 'package:f_clean_template/features/auth/domain/models/authentication_user.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:f_clean_template/features/home/data/datasources/local/local_home_source.dart';
import 'package:f_clean_template/features/home/data/repositories/home_repository.dart';
import 'package:f_clean_template/features/home/domain/repositories/i_home_repository.dart';
import 'package:f_clean_template/features/home/ui/viewmodels/home_controller.dart';
import 'package:f_clean_template/features/home/ui/views/home_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _StubAuthRepository implements IAuthRepository {
  @override
  Future<AuthenticationUser?> getLoggedUser() async =>
      AuthenticationUser(email: 'maria@uni.edu', name: 'María', password: 'x');

  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<bool> login(AuthenticationUser user) async => true;

  @override
  Future<bool> signUp(AuthenticationUser user) async => true;

  @override
  Future<bool> logOut() async => true;

  @override
  Future<bool> validate(String email, String validationCode) async => true;

  @override
  Future<bool> validateToken() async => true;

  @override
  Future<void> forgotPassword(String email) async {}
}

void main() {
  testWidgets('HomePage renders every feed section', (tester) async {
    Get.testMode = true;
    Get.put<IHomeRepository>(HomeRepository(LocalHomeSource()));
    Get.put(HomeController(Get.find()));
    Get.put(AuthenticationController(_StubAuthRepository()));

    await tester.pumpWidget(const GetMaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    expect(find.text('Innovation Hub'), findsOneWidget);
    expect(find.text('Comunidades que sigues'), findsOneWidget);
    expect(find.text('Studio Creativo UNI'), findsOneWidget);
    expect(find.text('Recomendado para ti'), findsOneWidget);
    expect(find.text('Tecnología • Investigación'), findsOneWidget);
    expect(find.text('Ferias y oportunidades'), findsOneWidget);
    expect(find.text('Crear'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('15 proyectos participando'), 300);
    await tester.scrollUntilVisible(
      find.widgetWithText(AppSectionHeader, 'Mis Proyectos'),
      300,
    );
    await tester.scrollUntilVisible(find.text('MotionLab'), 300);
    expect(find.text('3 Integrantes'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ComicVerse App'), 300);
    expect(find.text('2 Integrantes'), findsOneWidget);

    Get.reset();
  });
}
