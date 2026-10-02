import 'dart:async';

import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/chat_models.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/sgt.dart';
import 'package:alpha_go/services/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

/// One conversation: Topsi or a member. New messages are fetched every few seconds while open.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chat, this.embedded = false});
  final ChatSummary chat;

  /// Shown as a tab (no back button) rather than a pushed page.
  final bool embedded;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final UserController user = Get.find();
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<ChatMessage> messages = [];
  Timer? _poll;
  bool sending = false;
  bool loaded = false;
  String? error;

  ChatSummary get chat => widget.chat;
  int get lastId => messages.isEmpty ? 0 : messages.last.id;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Topsi only answers what you send, so only member chats need polling.
    if (!chat.isTopsi) {
      _poll = Timer.periodic(const Duration(seconds: 4), (_) => _fetch());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final fresh = await Api.messages(chat.id, after: lastId);
      if (!mounted) return;
      setState(() {
        loaded = true;
        error = null;
        final have = messages.map((m) => m.id).toSet();
        messages.addAll(fresh.where((m) => !have.contains(m.id)));
      });
      if (fresh.isNotEmpty) _toBottom();
    } on ApiException catch (e) {
      if (mounted && !loaded) setState(() => error = e.message);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void say(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    input.clear();
    try {
      await Api.sendMessage(chat.id, text);
      await _fetch();
      if (chat.isTopsi) await user.refreshAccount();
    } on ApiException catch (e) {
      input.text = text;
      say(e.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> sendVibe() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final sendable = user.account.value?.vibeSendable ?? 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Constants.gold)),
        title: Text('Send VIBE to ${chat.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You can send ${NumberFormat.decimalPattern().format(sendable)} VIBE. Earned VIBE stays with you for Topsi.',
                style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Constants.inputStyle,
              decoration: Constants.inputDecoration.copyWith(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLength: 140,
              style: Constants.inputStyle,
              decoration: Constants.inputDecoration.copyWith(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    final n = int.tryParse(amount.text);
    if (ok != true || n == null || n <= 0) return;
    try {
      await Api.sendVibe(chat.id, n, note.text.trim());
      await user.refreshAccount();
      await _fetch();
      say('Sent $n VIBE');
    } on ApiException catch (e) {
      say(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        automaticallyImplyLeading: false,
        leading: widget.embedded
            ? null
            : IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios, color: Constants.gold)),
        title: InkWell(
          onTap: chat.otherId == null ? null : () => context.push('/member', extra: chat.otherId),
          child: Text(chat.title,
              style: TextStyle(fontFamily: 'Cinzel', color: Constants.gold, fontSize: 18.sp)),
        ),
        actions: [
          if (chat.isTopsi)
            Obx(() => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                        '${NumberFormat.decimalPattern().format(user.account.value?.vibe ?? 0)} VIBE',
                        style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70)),
                  ),
                ))
          else
            IconButton(
              tooltip: 'Send VIBE',
              onPressed: sendVibe,
              icon: const Icon(Icons.token, color: Constants.gold),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _list()),
            if (sending && chat.isTopsi)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('Topsi is looking through the events…',
                    style: TextStyle(fontFamily: 'Roboto', color: Colors.white54)),
              ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    if (error != null) return Center(child: Text(error!));
    if (!loaded) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) => _bubble(messages[i]),
    );
  }

  Widget _bubble(ChatMessage m) {
    if (m.kind == 'notice') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(m.body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Roboto', color: Colors.white54, fontSize: 13)),
      );
    }
    final mine = m.mine;
    final isVibe = m.kind == 'vibe';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 78.w),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: mine ? Constants.gold.withValues(alpha: 0.22) : const Color(0xff1b1b1b),
          border: Border.all(color: isVibe ? Constants.gold : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isVibe)
              Text('${mine ? 'You sent' : 'Sent you'} ${NumberFormat.decimalPattern().format(m.vibe ?? 0)} VIBE',
                  style: const TextStyle(
                      fontFamily: 'Roboto', color: Constants.gold, fontWeight: FontWeight.bold)),
            if (!isVibe || !m.body.startsWith('Sent '))
              SelectableText(m.body,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 15, height: 1.35)),
            const SizedBox(height: 3),
            Text(
              [
                Sgt.time(m.at),
                if (m.cost != null && m.cost! > 0) '${m.cost} VIBE',
              ].join(' · '),
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 8),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: Constants.inputStyle,
              decoration: Constants.inputDecoration.copyWith(
                hintText: chat.isTopsi ? 'Ask Topsi about the events' : 'Message',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => send(),
            ),
          ),
          IconButton(
            onPressed: sending ? null : send,
            icon: sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: Constants.gold),
          ),
        ],
      ),
    );
  }
}
