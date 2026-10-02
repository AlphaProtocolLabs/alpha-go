import 'package:alpha_go/controllers/chat_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/views/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

/// Topsi as a tab: the member's private Topsi chat, one tap away.
class TopsiTab extends StatelessWidget {
  const TopsiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chats = Get.find();
    final UserController user = Get.find();
    return Obx(() {
      if (!user.signedIn) {
        return Center(
          child: ElevatedButton(
              style: Constants.buttonStyle,
              onPressed: () => context.push('/account'),
              child: const Text('Sign in to talk to Topsi')),
        );
      }
      final t = chats.topsi;
      if (t == null) {
        if (!chats.loading.value) chats.refreshChats();
        return const Center(child: CircularProgressIndicator());
      }
      return ChatScreen(key: ValueKey(t.id), chat: t, embedded: true);
    });
  }
}
