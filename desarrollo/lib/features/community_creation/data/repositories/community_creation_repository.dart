import '../../domain/repositories/i_community_creation_repository.dart';
import '../datasources/i_community_creation_source.dart';

class CommunityCreationRepository implements ICommunityCreationRepository {
  CommunityCreationRepository(this.source);

  final ICommunityCreationSource source;

  @override
  Future<List<String>> getSuggestedTags() async =>
      await source.getSuggestedTags();
}
