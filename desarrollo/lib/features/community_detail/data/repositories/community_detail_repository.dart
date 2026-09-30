import '../../domain/models/community_detail.dart';
import '../../domain/repositories/i_community_detail_repository.dart';
import '../datasources/i_community_detail_source.dart';

class CommunityDetailRepository implements ICommunityDetailRepository {
  CommunityDetailRepository(this.source);

  final ICommunityDetailSource source;

  @override
  Future<CommunityDetail?> getDetail(String communityId) =>
      source.getDetail(communityId);

  @override
  Future<bool> toggleMembership(String communityId) =>
      source.toggleMembership(communityId);
}
