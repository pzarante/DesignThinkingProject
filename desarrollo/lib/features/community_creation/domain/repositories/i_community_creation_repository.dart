abstract class ICommunityCreationRepository {
  /// Etiquetas propuestas al escribir en el campo de tags.
  Future<List<String>> getSuggestedTags();
}
