import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/event_model.dart';
import 'package:alpha_go/services/api.dart';
import 'package:get/get.dart';

class EventController extends GetxController {
  final RxList<EventModel> events = <EventModel>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  Future<void> getEvents() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await Api.events();
      list.sort((a, b) => (a.start ?? DateTime(2100)).compareTo(b.start ?? DateTime(2100)));
      events.assignAll(list);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  EventModel? byId(String id) => events.firstWhereOrNull((e) => e.id == id);

  bool isSaved(String id) =>
      Get.find<UserController>().account.value?.saves.contains(id) ?? false;

  Future<void> toggleSave(EventModel ev) async {
    final user = Get.find<UserController>();
    final saved = !isSaved(ev.id);
    await Api.save(ev.id, saved);
    await user.refreshAccount();
  }

  Future<int> checkIn(EventModel ev, double lat, double lng) async {
    final earned = await Api.checkIn(ev.id, lat, lng);
    await Get.find<UserController>().refreshAccount();
    return earned;
  }
}
