import 'dart:async';

import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/chat_models.dart';
import 'package:alpha_go/services/api.dart';
import 'package:get/get.dart';

/// The member's chat list, refreshed in the background for unread badges.
class ChatController extends GetxController {
  final RxList<ChatSummary> chats = <ChatSummary>[].obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();
  Timer? _timer;

  int get unread => chats.fold(0, (n, c) => n + c.unread);

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => refreshChats(quiet: true));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> refreshChats({bool quiet = false}) async {
    if (!Get.find<UserController>().signedIn) return;
    if (!quiet) loading.value = true;
    try {
      chats.assignAll(await Api.chats());
      error.value = null;
    } on ApiException catch (e) {
      if (!quiet) error.value = e.message;
    } finally {
      loading.value = false;
    }
  }

  ChatSummary? get topsi => chats.firstWhereOrNull((c) => c.isTopsi);
}
