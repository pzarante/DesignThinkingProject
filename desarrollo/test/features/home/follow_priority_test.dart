import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/features/home/domain/models/community.dart';
import 'package:f_clean_template/features/home/domain/models/home_feed.dart';
import 'package:f_clean_template/features/home/domain/models/project.dart';
import 'package:f_clean_template/features/home/domain/repositories/i_home_repository.dart';
import 'package:f_clean_template/features/home/ui/viewmodels/home_controller.dart';

class _FeedRepository implements IHomeRepository {
  _FeedRepository(this.feed);

  final HomeFeed feed;

  @override
  Future<HomeFeed> getFeed() async => feed;

  @override
  Future<void> addCommunity(Community community) async {}

  @override
  Future<Project> addProject(
    Project project, {
    required String problem,
    required String objective,
    String? scope,
    required int maxMembers,
    required String availability,
    String? coLeaderId,
    List<String> links = const [],
  }) async => project;

  @override
  Future<void> updateCommunity(Community community) async {}

  @override
  Future<void> updateProject(Project project) async {}
}

const _a = Project(id: 'a', name: 'A', tags: ['ux']);
const _b = Project(id: 'b', name: 'B');
const _c = Project(id: 'c', name: 'C');

Future<HomeController> _controllerWith({
  Set<String> followed = const {},
}) async {
  final controller = HomeController(
    _FeedRepository(
      HomeFeed(
        followedCommunities: const [],
        recommendedProjects: const [_a, _b, _c],
        opportunities: const [],
        myProjects: const [],
        savedProjects: const [
          Project(id: 's', name: 'S', tags: ['ux']),
        ],
        followedProjectIds: followed,
      ),
    ),
  );
  await controller.getFeed();
  return controller;
}

List<String> _ids(HomeController controller) => [
  for (final project in controller.filteredRecommendedProjects) project.id,
];

void main() {
  test(
    'los proyectos que sigue van primero, aunque otro tenga más afinidad',
    () async {
      final controller = await _controllerWith(followed: {'c'});

      expect(_ids(controller), ['c', 'a', 'b']);
    },
  );

  test(
    'sin seguidos se ordena por afinidad y a igualdad queda el orden original',
    () async {
      final controller = await _controllerWith();

      expect(_ids(controller), ['a', 'b', 'c']);
    },
  );

  test(
    'seguir un proyecto desde el detalle lo sube sin pedir el feed otra vez',
    () async {
      final controller = await _controllerWith();

      controller.markFollowed('b', followed: true);
      expect(_ids(controller), ['b', 'a', 'c']);

      controller.markFollowed('b', followed: false);
      expect(_ids(controller), ['a', 'b', 'c']);
    },
  );
}
