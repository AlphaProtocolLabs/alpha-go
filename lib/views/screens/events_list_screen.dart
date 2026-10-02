import 'package:alpha_go/controllers/event_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/event_model.dart';
import 'package:alpha_go/models/sgt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

/// Every event of the week, filterable, including ones without a map pin.
class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final EventController events = Get.find();
  final UserController user = Get.find();
  String query = '';
  String? type;
  int? day; // null = all week
  bool savedOnly = false;
  bool freeOnly = false;

  static const types = [
    'Networking',
    'Party/Dinner',
    'Conference/Summit',
    'Workshop/Hackathon',
    'Sport',
    'Other'
  ];
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool onDay(EventModel e, int i) {
    final s = e.start;
    if (s == null) return false;
    final a = Sgt.week[i];
    final b = a.add(const Duration(days: 1));
    return s.isBefore(b) && e.effectiveEnd!.isAfter(a);
  }

  List<EventModel> filtered() {
    final q = query.toLowerCase();
    final saves = user.account.value?.saves ?? const <String>{};
    return events.events.where((e) {
      if (type != null && e.type != type) return false;
      if (day != null && !onDay(e, day!)) return false;
      if (savedOnly && !saves.contains(e.id)) return false;
      if (freeOnly && !e.free) return false;
      if (q.isEmpty) return true;
      return '${e.name} ${e.hostLabel} ${e.placeLabel}'
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  Widget chip(String label, bool on, VoidCallback tap) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: on ? Colors.black : Colors.white70)),
          selected: on,
          showCheckmark: false,
          selectedColor: Constants.gold,
          backgroundColor: Colors.black,
          side: const BorderSide(color: Constants.gold),
          onSelected: (_) => tap(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
              child: TextField(
                onChanged: (v) => setState(() => query = v),
                style: Constants.inputStyle,
                decoration: Constants.inputDecoration.copyWith(
                  hintText: 'Search events, hosts, venues',
                  prefixIcon: const Icon(Icons.search, color: Constants.gold),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6),
                children: [
                  chip('All week', day == null, () => setState(() => day = null)),
                  for (var i = 0; i < 7; i++)
                    chip('${days[i]} ${5 + i}', day == i,
                        () => setState(() => day = day == i ? null : i)),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6),
                children: [
                  chip('Saved', savedOnly,
                      () => setState(() => savedOnly = !savedOnly)),
                  chip('Free', freeOnly,
                      () => setState(() => freeOnly = !freeOnly)),
                  for (final t in types)
                    chip(t, type == t,
                        () => setState(() => type = type == t ? null : t)),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                user.account.value;
                if (events.loading.value && events.events.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (events.error.value != null && events.events.isEmpty) {
                  return Center(
                    child: TextButton(
                      onPressed: events.getEvents,
                      child: Text('${events.error.value}\nTap to retry',
                          textAlign: TextAlign.center),
                    ),
                  );
                }
                final list = filtered();
                if (list.isEmpty) {
                  return const Center(
                      child: Text('No events match',
                          style: TextStyle(fontFamily: 'Roboto')));
                }
                return RefreshIndicator(
                  onRefresh: events.getEvents,
                  child: ListView.separated(
                    padding: EdgeInsets.only(bottom: 12.h),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (context, i) => _row(context, list[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, EventModel e) {
    final state = e.stateAt(DateTime.now());
    final saved = user.account.value?.saves.contains(e.id) ?? false;
    final small = TextStyle(
        fontFamily: 'Roboto', fontSize: 13, color: Colors.white.withValues(alpha: 0.65));
    return InkWell(
      onTap: () => context.push('/eventDetails', extra: e),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.start == null ? 'TBC' : Sgt.time(e.start!),
                      style: small.copyWith(color: Colors.white)),
                  if (e.start != null && day == null)
                    Text(Sgt.day(e.start!).split(' ').first, style: small),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name,
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                      [e.placeLabel, if (e.hostLabel.isNotEmpty) e.hostLabel]
                          .join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: small),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    if (state == EventState.live)
                      _tag('On now', Constants.gold),
                    if (state == EventState.soon) _tag('Soon', Constants.gold),
                    if (saved) _tag('Saved', Constants.gold),
                    _tag(e.free ? 'Free' : e.price, Colors.white38),
                    _tag(e.type, Colors.white38),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
            border: Border.all(color: c),
            borderRadius: BorderRadius.circular(3)),
        child: Text(t,
            style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: c)),
      );
}
