enum EventState { live, soon, later, ended }

/// One event from the go.alphaprotocol.network feed.
class EventModel {
  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.free,
    required this.url,
    this.start,
    this.end,
    this.lat,
    this.lng,
    this.venue,
    this.address,
    this.area,
    this.org,
    this.hosts = const [],
    this.cover,
    this.locationHidden = false,
    this.inviteOnly = false,
    this.approval = false,
  });

  final String id;
  final String name;
  final String type;
  final String price;
  final bool free;
  final String url;
  final DateTime? start;
  final DateTime? end;
  final double? lat;
  final double? lng;
  final String? venue;
  final String? address;
  final String? area;
  final String? org;
  final List<String> hosts;
  final String? cover;

  /// The organiser shares the address after you register; the pin is the approximate area.
  final bool locationHidden;
  final bool inviteOnly;
  final bool approval;

  static const soonWindow = Duration(hours: 2);

  bool get hasLocation => lat != null && lng != null;

  /// Events without an end time are treated as two hours long.
  DateTime? get effectiveEnd =>
      end ?? start?.add(const Duration(hours: 2));

  EventState stateAt(DateTime t) {
    final s = start;
    final e = effectiveEnd;
    if (s == null || e == null) return EventState.later;
    if (t.isAfter(e)) return EventState.ended;
    if (!t.isBefore(s)) return EventState.live;
    if (s.difference(t) <= soonWindow) return EventState.soon;
    return EventState.later;
  }

  String get placeLabel =>
      venue ?? area ?? (locationHidden ? 'Location shared after you register' : 'Singapore');

  String get hostLabel =>
      hosts.isNotEmpty ? hosts.join(', ') : (org ?? '');

  static DateTime? _ms(Object? v) =>
      v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true) : null;

  factory EventModel.fromApi(Map<String, dynamic> m) => EventModel(
        id: m['id'] as String,
        name: m['name'] as String,
        type: m['type'] as String? ?? 'Other',
        price: m['price'] as String? ?? '',
        free: m['free'] as bool? ?? false,
        url: m['url'] as String? ?? '',
        start: _ms(m['s']),
        end: _ms(m['e']),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        venue: m['venue'] as String?,
        address: m['address'] as String?,
        area: m['area'] as String?,
        org: m['org'] as String?,
        hosts: List<String>.from(m['hosts'] as List? ?? const []),
        cover: m['cover'] as String?,
        locationHidden: m['hidden'] as bool? ?? false,
        inviteOnly: m['invite'] as bool? ?? false,
        approval: m['approval'] as bool? ?? false,
      );
}
