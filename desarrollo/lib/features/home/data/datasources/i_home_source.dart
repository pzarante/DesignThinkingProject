import '../../domain/models/home_feed.dart';

abstract class IHomeSource {
  Future<HomeFeed> getFeed();
}
