import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/community.dart';
import '../../domain/models/home_feed.dart';
import '../../domain/models/project.dart';
import '../../domain/repositories/i_home_repository.dart';

/// Type of entry the Home search/filter bar can narrow results to.
enum HomeEntryType { todos, proyectos, comunidades }

class HomeController extends GetxController with UiLoggy {
  HomeController(this.repository);

  final IHomeRepository repository;
  final Rx<HomeFeed> _feed = const HomeFeed.empty().obs;
  final RxBool isLoading = false.obs;

  /// Free-text query typed in the Home search bar. Empty = sin filtro.
  final RxString searchQuery = ''.obs;

  /// Filtro de tipo activo (Todos / Proyectos / Comunidades).
  final Rx<HomeEntryType> selectedType = HomeEntryType.todos.obs;

  /// Tag de categoría activo. Null equivale al chip "Todos".
  final Rx<String?> selectedTag = Rx<String?>(null);

  HomeFeed get feed => _feed.value;

  @override
  void onInit() {
    getFeed();
    super.onInit();
  }

  Future<void> getFeed() async {
    loggy.debug('HomeController: Getting home feed');
    isLoading.value = true;
    _feed.value = await repository.getFeed();
    isLoading.value = false;
  }

  void setSearchQuery(String value) => searchQuery.value = value;

  void setType(HomeEntryType type) => selectedType.value = type;

  void setTag(String? tag) => selectedTag.value = tag;

  /// Todos los tags presentes en el feed actual, para armar los chips de
  /// categoría dinámicamente en vez de hardcodear una lista fija.
  // TODO: validar con usuarios — el orden alfabético es un supuesto propio,
  // el spec no define cómo deben ordenarse las categorías dinámicas.
  List<String> get availableTags {
    final tags = <String>{
      for (final p in feed.recommendedProjects) ...p.tags,
      for (final p in feed.myProjects) ...p.tags,
      for (final c in feed.followedCommunities) ...c.tags,
    };
    return tags.toList()..sort();
  }

  List<Project> get filteredRecommendedProjects {
    if (selectedType.value == HomeEntryType.comunidades) return [];
    return feed.recommendedProjects.where(_matchesProject).toList();
  }

  List<Project> get filteredMyProjectsSummary {
    if (selectedType.value == HomeEntryType.comunidades) return [];
    return feed.myProjectsSummary.where(_matchesProject).toList();
  }

  List<Community> get filteredCommunities {
    if (selectedType.value == HomeEntryType.proyectos) return [];
    return feed.followedCommunities.where(_matchesCommunity).toList();
  }

  bool _matchesProject(Project project) =>
      _matchesQuery(project.name) && _matchesTag(project.tags);

  bool _matchesCommunity(Community community) =>
      _matchesQuery(community.name) && _matchesTag(community.tags);

  bool _matchesQuery(String name) {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return true;
    return name.toLowerCase().contains(query);
  }

  bool _matchesTag(List<String> tags) {
    final tag = selectedTag.value;
    if (tag == null) return true;
    return tags.contains(tag);
  }
}
