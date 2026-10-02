import 'dart:convert';

import 'package:alpha_go/controllers/event_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/event_model.dart';
import 'package:alpha_go/models/sgt.dart';
import 'package:alpha_go/views/widgets/drawer_widget.dart';
import 'package:alpha_go/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:responsive_sizer/responsive_sizer.dart';

/// Map of the week. Like Blackrock GO, pins appear only while an event is on
/// (gold) or about to start (outlined), at the time chosen on the dial.
class MapHomePage extends StatefulWidget {
  const MapHomePage({super.key});

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  final EventController events = Get.find();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  mb.MapboxMap? map;
  bool styleReady = false;
  late DateTime at = _defaultTime();
  Worker? _sub;

  /// Marina Bay, where most of the week happens.
  static final center =
      mb.Point(coordinates: mb.Position(103.8545, 1.2850));

  static DateTime _defaultTime() {
    final now = DateTime.now().toUtc();
    final first = Sgt.week.first;
    final last = Sgt.week.last.add(const Duration(days: 1));
    if (now.isAfter(first) && now.isBefore(last)) return now;
    // Before the week: preview the first evening.
    return first.add(const Duration(hours: 13)); // 18:00 SGT Monday
  }

  int get dayIndex {
    final i = at.difference(Sgt.week.first).inHours ~/ 24;
    return i.clamp(0, 6);
  }

  /// Hours since 05:00 SGT on the chosen day, 0 to 23.99.
  double get hourOfDay =>
      at.difference(Sgt.week[dayIndex]).inMinutes / 60.0;

  List<EventModel> get visible => events.events
      .where((e) =>
          e.hasLocation &&
          (e.stateAt(at) == EventState.live ||
              e.stateAt(at) == EventState.soon))
      .toList();

  @override
  void initState() {
    super.initState();
    mb.MapboxOptions.setAccessToken(Constants.mapboxToken);
    _sub = ever(events.events, (_) => _refreshPins());
    _askLocation();
  }

  @override
  void dispose() {
    _sub?.dispose();
    super.dispose();
  }

  Future<void> _askLocation() async {
    var p = await geo.Geolocator.checkPermission();
    if (p == geo.LocationPermission.denied) {
      p = await geo.Geolocator.requestPermission();
    }
    if (p == geo.LocationPermission.whileInUse ||
        p == geo.LocationPermission.always) {
      await map?.location.updateSettings(mb.LocationComponentSettings(
          enabled: true, pulsingEnabled: true));
    }
  }

  String _geojson() {
    final list = visible;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final e in list)
          {
            'type': 'Feature',
            'id': e.id,
            'geometry': {
              'type': 'Point',
              'coordinates': [e.lng, e.lat]
            },
            'properties': {
              'id': e.id,
              'live': e.stateAt(at) == EventState.live,
            },
          }
      ],
    });
  }

  Future<void> _refreshPins() async {
    if (!styleReady || map == null) return;
    final src = await map!.style.getSource('events');
    if (src is mb.GeoJsonSource) await src.updateGeoJSON(_geojson());
    if (mounted) setState(() {});
  }

  Future<void> _onStyleLoaded(mb.StyleLoadedEventData _) async {
    final m = map!;
    await m.style.addSource(mb.GeoJsonSource(id: 'events', data: _geojson()));
    await m.style.addLayer(mb.CircleLayer(
      id: 'events-dots',
      sourceId: 'events',
      circleRadius: 9,
      circleColorExpression: [
        'case',
        ['get', 'live'],
        0xffecc978,
        0x00000000
      ],
      circleStrokeColor: 0xffecc978,
      circleStrokeWidth: 2.5,
      circlePitchAlignment: mb.CirclePitchAlignment.MAP,
    ));
    m.addInteraction(
      mb.TapInteraction(mb.FeaturesetDescriptor(layerId: 'events-dots'),
          (feature, _) {
        final id = feature.properties['id'] as String?;
        final ev = id == null ? null : events.byId(id);
        if (ev != null && mounted) context.push('/eventDetails', extra: ev);
      }, stopPropagation: false),
      interactionID: 'eventTap',
    );
    styleReady = true;
    await _askLocation();
    if (mounted) setState(() {});
  }

  void _setDay(int i) {
    setState(() => at = Sgt.week[i].add(Duration(
        minutes: (hourOfDay * 60).round())));
    _refreshPins();
  }

  void _setHour(double h) {
    setState(() =>
        at = Sgt.week[dayIndex].add(Duration(minutes: (h * 60).round())));
    _refreshPins();
  }

  void _now() {
    setState(() => at = _defaultTime());
    _refreshPins();
  }

  @override
  Widget build(BuildContext context) {
    final styleUrl = Constants.mapboxStyleUrl.isNotEmpty
        ? Constants.mapboxStyleUrl
        : mb.MapboxStyles.DARK;
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: Colors.black,
      appBar: CustomNavBar(
        leadingWidget: Padding(
          padding: EdgeInsets.only(left: 3.w),
          child: Image.asset('assets/alpha.jpg', fit: BoxFit.contain),
        ),
        actionWidgets: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: Icon(Icons.menu, color: Constants.gold, size: 29.sp),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                mb.MapWidget(
                  key: const ValueKey('mapWidget'),
                  styleUri: styleUrl,
                  cameraOptions: mb.CameraOptions(
                      center: center, zoom: 13.6, pitch: 45),
                  onMapCreated: (m) => map = m,
                  onStyleLoadedListener: _onStyleLoaded,
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Obx(() {
                    events.events.length;
                    final text = events.loading.value
                        ? 'Loading events…'
                        : events.error.value ??
                            '${visible.length} on or starting soon';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Constants.gold)),
                      child: Text(text,
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 13)),
                    );
                  }),
                ),
              ],
            ),
          ),
          _dial(),
        ],
      ),
    );
  }

  Widget _dial() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 9.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('${Sgt.day(at)}  ${Sgt.time(at)}',
                  style: TextStyle(
                      fontFamily: 'Cinzel',
                      color: Constants.gold,
                      fontSize: 17.sp)),
              const Spacer(),
              OutlinedButton(
                onPressed: _now,
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Constants.gold)),
                child: const Text('Now',
                    style: TextStyle(color: Constants.gold)),
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => _setDay(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Text(days[i],
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  color: i == dayIndex
                                      ? Constants.gold
                                      : Colors.white60)),
                          Text('${5 + i}',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                  color: i == dayIndex
                                      ? Constants.gold
                                      : Colors.white60)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Slider(
            value: hourOfDay.clamp(0, 23.75),
            min: 0,
            max: 23.75,
            divisions: 95,
            activeColor: Constants.gold,
            onChanged: _setHour,
          ),
        ],
      ),
    );
  }
}
