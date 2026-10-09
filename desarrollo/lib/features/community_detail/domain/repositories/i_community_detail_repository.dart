import '../models/community_detail.dart';

abstract class ICommunityDetailRepository {
  Future<CommunityDetail?> getDetail(String communityId);

  Future<bool> toggleMembership(String communityId);
}
