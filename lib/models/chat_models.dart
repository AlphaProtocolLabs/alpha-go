class ChatSummary {
  ChatSummary({
    required this.id,
    required this.kind,
    required this.title,
    this.otherId,
    this.otherBio,
    this.lastBody,
    this.lastKind,
    this.lastAt,
    this.lastMine = false,
    required this.unread,
  });

  final String id;

  /// 'topsi' or 'dm'.
  final String kind;
  final String title;
  final String? otherId;
  final String? otherBio;
  final String? lastBody;
  final String? lastKind;
  final DateTime? lastAt;
  final bool lastMine;
  final int unread;

  bool get isTopsi => kind == 'topsi';

  factory ChatSummary.fromApi(Map<String, dynamic> m) {
    final other = m['other'] as Map<String, dynamic>?;
    final last = m['last'] as Map<String, dynamic>?;
    return ChatSummary(
      id: m['id'] as String,
      kind: m['kind'] as String,
      title: m['title'] as String,
      otherId: other?['id'] as String?,
      otherBio: other?['bio'] as String?,
      lastBody: last?['body'] as String?,
      lastKind: last?['kind'] as String?,
      lastAt: DateTime.tryParse(last?['at'] as String? ?? ''),
      lastMine: last?['mine'] as bool? ?? false,
      unread: (m['unread'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.sender,
    required this.kind,
    required this.body,
    this.vibe,
    this.cost,
    required this.at,
  });

  final int id;

  /// 'me', 'them' or 'topsi'.
  final String sender;

  /// 'text', 'vibe' (a VIBE send) or 'notice' (Topsi unavailable, etc.).
  final String kind;
  final String body;
  final int? vibe;

  /// VIBE charged for a Topsi reply.
  final int? cost;
  final DateTime at;

  bool get mine => sender == 'me';

  factory ChatMessage.fromApi(Map<String, dynamic> m) => ChatMessage(
        id: (m['id'] as num).toInt(),
        sender: m['sender'] as String,
        kind: m['kind'] as String,
        body: m['body'] as String,
        vibe: (m['vibe'] as num?)?.toInt(),
        cost: (m['cost'] as num?)?.toInt(),
        at: DateTime.tryParse(m['at'] as String? ?? '') ?? DateTime.now(),
      );
}

class Member {
  Member({required this.id, required this.name, this.bio, this.link, this.memberSince});
  final String id;
  final String name;
  final String? bio;
  final String? link;
  final DateTime? memberSince;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }

  factory Member.fromApi(Map<String, dynamic> m) => Member(
        id: m['id'] as String,
        name: m['name'] as String,
        bio: m['bio'] as String?,
        link: m['link'] as String?,
        memberSince: DateTime.tryParse(m['memberSince'] as String? ?? ''),
      );
}
