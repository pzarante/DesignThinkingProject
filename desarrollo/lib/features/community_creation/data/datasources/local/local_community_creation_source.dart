import '../i_community_creation_source.dart';

/// Etiquetas sembradas en memoria mientras no haya backend.
class LocalCommunityCreationSource implements ICommunityCreationSource {
  static const List<String> _suggestedTags = [
    'InnovaciónSocial',
    'Comunidad',
    'Sostenibilidad',
    'Tecnología',
    'Arte',
  ];

  @override
  Future<List<String>> getSuggestedTags() async => _suggestedTags;
}
