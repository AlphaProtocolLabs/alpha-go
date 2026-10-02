/// The signed-in member. One profile, shared with the go.alphaprotocol.network guide.
class Account {
  Account({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.link,
    this.avatarUrl,
    this.btcAddress,
    this.aptosAddress,
    required this.refCode,
    required this.memberSince,
    required this.saves,
    required this.checkins,
    required this.vibe,
  });

  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? link;
  final String? avatarUrl;
  final String? btcAddress;
  final String? aptosAddress;
  final String refCode;
  final DateTime memberSince;
  final Set<String> saves;
  final Set<String> checkins;

  /// Testnet VIBE balance on the account ledger.
  final int vibe;

  factory Account.fromApi(Map<String, dynamic> data) {
    final u = data['user'] as Map<String, dynamic>;
    return Account(
      id: u['id'] as String,
      name: u['name'] as String,
      email: u['email'] as String,
      bio: u['bio'] as String?,
      link: u['link'] as String?,
      avatarUrl: u['avatarUrl'] as String?,
      btcAddress: u['btcAddress'] as String?,
      aptosAddress: u['aptosAddress'] as String?,
      refCode: u['refCode'] as String,
      memberSince: DateTime.tryParse(u['memberSince'] as String? ?? '') ??
          DateTime.now(),
      saves: Set<String>.from(data['saves'] as List? ?? const []),
      checkins: Set<String>.from(data['checkins'] as List? ?? const []),
      vibe: (data['balance'] as num?)?.toInt() ?? 0,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }
}
