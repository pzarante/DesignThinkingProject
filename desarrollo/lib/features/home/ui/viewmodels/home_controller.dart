import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/home_feed.dart';
import '../../domain/repositories/i_home_repository.dart';

class HomeController extends GetxController with UiLoggy {
  HomeController(this.repository);

  final IHomeRepository repository;
  final Rx<HomeFeed> _feed = const HomeFeed.empty().obs;
  final RxBool isLoading = false.obs;

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
}
