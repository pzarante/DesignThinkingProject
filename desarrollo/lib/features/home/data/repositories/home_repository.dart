import '../../domain/models/home_feed.dart';
import '../../domain/repositories/i_home_repository.dart';
import '../datasources/i_home_source.dart';

class HomeRepository implements IHomeRepository {
  HomeRepository(this.homeSource);

  final IHomeSource homeSource;

  @override
  Future<HomeFeed> getFeed() async => await homeSource.getFeed();
}
