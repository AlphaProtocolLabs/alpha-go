import 'dart:async';

import 'package:alpha_go/controllers/chat_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/chat_models.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/sgt.dart';
import 'package:alpha_go/services/api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

/// Inbox: Topsi pinned at the top, then DMs. Search finds members to message.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ChatController chats = Get.find();
  final UserController user = Get.find();
  final search = TextEditingController();
  List<Member> results = [];
  String? searchError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    chats.refreshChats();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void onSearch(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final r = await Api.searchMembers(q.trim());
        if (mounted) setState(() {
          results = r;
          searchError = null;
        });
      } on ApiException catch (e) {
        if (mounted) setState(() => searchError = e.message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searching = search.text.trim().length >= 2;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 1.h),
              child: Row(children: [
                Text('Chats',
                    style: TextStyle(
                        fontFamily: 'Cinzel',
                        color: Constants.gold,
                        fontSize: 20.sp)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: TextField(
                controller: search,
                onChanged: (v) {
                  setState(() {});
                  onSearch(v);
                },
                style: Constants.inputStyle,
                decoration: Constants.inputDecoration.copyWith(
                  hintText: 'Find members by name',
                  prefixIcon: const Icon(Icons.search, color: Constants.gold),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Expanded(child: searching ? _results() : _inbox()),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    if (searchError != null) {
      return Center(child: Text(searchError!, style: const TextStyle(fontFamily: 'Roboto')));
    }
    if (results.isEmpty) {
      return const Center(
          child: Text('No members found', style: TextStyle(fontFamily: 'Roboto')));
    }
    return ListView(
      children: [
        for (final m in results)
          ListTile(
            leading: _avatar(m.initials),
            title: Text(m.name, style: const TextStyle(fontFamily: 'Roboto')),
            subtitle: m.bio == null
                ? null
                : Text(m.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Roboto', color: Colors.white60)),
            onTap: () => context.push('/member', extra: m.id),
          ),
      ],
    );
  }

  Widget _inbox() {
    return Obx(() {
      if (!user.signedIn) {
        return Center(
          child: ElevatedButton(
              style: Constants.buttonStyle,
              onPressed: () => context.push('/account'),
              child: const Text('Sign in to chat')),
        );
      }
      if (chats.loading.value && chats.chats.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (chats.error.value != null && chats.chats.isEmpty) {
        return Center(
          child: TextButton(
              onPressed: chats.refreshChats,
              child: Text('${chats.error.value}\nTap to retry', textAlign: TextAlign.center)),
        );
      }
      return RefreshIndicator(
        onRefresh: chats.refreshChats,
        child: ListView.separated(
          padding: EdgeInsets.only(bottom: 12.h),
          itemCount: chats.chats.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, i) {
            if (i == chats.chats.length) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  chats.chats.length <= 1
                      ? 'Search for a member above to start a chat.'
                      : '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Roboto', color: Colors.white54),
                ),
              );
            }
            return _row(chats.chats[i]);
          },
        ),
      );
    });
  }

  Widget _row(ChatSummary c) {
    final preview = c.lastBody == null
        ? ''
        : c.lastKind == 'vibe'
            ? '${c.lastMine ? 'You sent' : 'Sent you'} VIBE'
            : '${c.lastMine ? 'You: ' : ''}${c.lastBody}';
    return ListTile(
      leading: c.isTopsi
          ? CircleAvatar(
              backgroundColor: Colors.black,
              child: ClipOval(child: Image.asset('assets/alpha.jpg', fit: BoxFit.cover)))
          : _avatar(c.title.isEmpty ? '?' : c.title[0].toUpperCase()),
      title: Text(c.title,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: c.unread > 0 ? FontWeight.bold : FontWeight.w500,
              color: c.isTopsi ? Constants.gold : Colors.white)),
      subtitle: Text(preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Roboto', color: Colors.white60)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastAt != null)
            Text(Sgt.time(c.lastAt!),
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: Colors.white54)),
          if (c.unread > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: Constants.gold, borderRadius: BorderRadius.circular(10)),
              child: Text('${c.unread}',
                  style: const TextStyle(color: Colors.black, fontSize: 12, fontFamily: 'Roboto')),
            ),
        ],
      ),
      onTap: () async {
        await context.push('/chat', extra: c);
        chats.refreshChats(quiet: true);
      },
    );
  }

  Widget _avatar(String initials) => CircleAvatar(
        backgroundColor: Constants.gold,
        child: Text(initials,
            style: const TextStyle(
                fontFamily: 'Cinzel', color: Colors.black, fontWeight: FontWeight.bold)),
      );
}
