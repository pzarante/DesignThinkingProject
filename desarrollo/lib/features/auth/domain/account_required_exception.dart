/// La acción necesita una cuenta de verdad y quien la intentó no la tiene.
///
/// Un invitado sí tiene sesión en ROBLE —por eso puede comentar y reaccionar—
/// pero es una identidad de usar y tirar, atada al dispositivo. Guardar un
/// proyecto o seguir una comunidad en esa identidad sería prometer algo que
/// no se va a poder recuperar desde otro lado.
///
/// `errorMessage` no la conoce y cae en su `toString()`, así que este texto
/// es el que acaba viendo la persona.
class AccountRequiredException implements Exception {
  const AccountRequiredException(this.message);

  final String message;

  @override
  String toString() => message;
}
