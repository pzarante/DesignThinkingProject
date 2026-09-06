import '../models/home_feed.dart';

abstract class IHomeRepository {
  Future<HomeFeed> getFeed();
}
