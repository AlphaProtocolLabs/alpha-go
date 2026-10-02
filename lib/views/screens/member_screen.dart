import 'package:alpha_go/models/chat_models.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/services/api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Another member's public profile, with Message, Block and Report.
class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key, required this.memberId});
  final String memberId;

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  Member? member;
  bool blocked = false;
  bool canMessage = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final (m, b, c) = await Api.member(widget.memberId);
      setState(() {
        member = m;
        blocked = b;
        canMessage = c;
      });
    } on ApiException catch (e) {
      setState(() => error = e.message);
    }
  }

  void say(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> message() async {
    try {
      final id = await Api.openDm(widget.memberId);
      if (!mounted) return;
      context.push('/chat',
          extra: ChatSummary(id: id, kind: 'dm', title: member!.name, otherId: member!.id, unread: 0));
    } on ApiException catch (e) {
      say(e.message);
    }
  }

  Future<void> toggleBlock() async {
    try {
      await Api.block(widget.memberId, !blocked);
      await load();
      say(blocked ? 'Blocked' : 'Unblocked');
    } on ApiException catch (e) {
      say(e.message);
    }
  }

  Future<void> report() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Report this member'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          style: Constants.inputStyle,
          decoration: Constants.inputDecoration.copyWith(hintText: 'What happened?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Report')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.report(widget.memberId, reason.text.trim());
      say('Thanks. We will look at it.');
    } on ApiException catch (e) {
      say(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = member;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Constants.gold)),
      ),
      body: error != null
          ? Center(child: Text(error!))
          : m == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Constants.gold,
                        child: Text(m.initials,
                            style: const TextStyle(
                                fontFamily: 'Cinzel',
                                fontSize: 28,
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Center(
                      child: Text(m.name,
                          style: TextStyle(
                              fontFamily: 'Cinzel', color: Constants.gold, fontSize: 21.sp)),
                    ),
                    if (m.memberSince != null)
                      Center(
                        child: Text(
                            'Member since ${DateFormat('d MMM yyyy').format(m.memberSince!.toLocal())}',
                            style: const TextStyle(fontFamily: 'Roboto', color: Colors.white54)),
                      ),
                    if ((m.bio ?? '').isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(m.bio!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Roboto', fontSize: 15.sp)),
                    ],
                    if ((m.link ?? '').isNotEmpty)
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(m.link!),
                            mode: LaunchMode.externalApplication),
                        child: Text(m.link!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Constants.gold)),
                      ),
                    SizedBox(height: 3.h),
                    if (canMessage)
                      ElevatedButton(
                          style: Constants.buttonStyle,
                          onPressed: message,
                          child: const Text('Message')),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            onPressed: toggleBlock,
                            child: Text(blocked ? 'Unblock' : 'Block',
                                style: const TextStyle(color: Colors.white70))),
                        TextButton(
                            onPressed: report,
                            child: const Text('Report', style: TextStyle(color: Colors.white70))),
                      ],
                    ),
                  ],
                ),
    );
  }
}
