import 'package:alpha_go/controllers/event_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/event_model.dart';
import 'package:alpha_go/models/sgt.dart';
import 'package:alpha_go/services/api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.event});
  final EventModel event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final EventController events = Get.find();
  final UserController user = Get.find();
  bool busy = false;
  String? message;

  EventModel get ev => widget.event;

  void say(String m) => setState(() => message = m);

  Future<void> toggleSave() async {
    if (!user.signedIn) return say('Sign in to save events.');
    try {
      await events.toggleSave(ev);
      setState(() {});
    } on ApiException catch (e) {
      say(e.message);
    }
  }

  Future<void> checkIn() async {
    if (!user.signedIn) return say('Sign in to check in.');
    setState(() => busy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return say('Turn on location to check in.');
      }
      final pos = await Geolocator.getCurrentPosition();
      final earned = await events.checkIn(ev, pos.latitude, pos.longitude);
      say('Checked in. +$earned testnet VIBE');
    } on ApiException catch (e) {
      say(e.message);
    } catch (_) {
      say('Could not get your location. Try again outside.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final state = ev.stateAt(now);
    final when = ev.start == null
        ? 'Time to be confirmed'
        : '${Sgt.day(ev.start!)}, ${Sgt.time(ev.start!)}'
            '${ev.effectiveEnd != null ? ' to ${Sgt.time(ev.effectiveEnd!)}' : ''} (Singapore)';
    final stateLabel = {
      EventState.live: 'Happening now',
      EventState.soon: 'Starting soon',
      EventState.later: '',
      EventState.ended: 'Ended',
    }[state]!;
    final body = TextStyle(fontFamily: 'Roboto', fontSize: 15.sp, height: 1.4);

    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Constants.gold)),
          actions: [
            Obx(() {
              user.account.value; // rebuild when saves change
              final saved = events.isSaved(ev.id);
              return IconButton(
                onPressed: toggleSave,
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                    color: Constants.gold),
              );
            }),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
          children: [
            if (ev.cover != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: ev.cover!,
                  fit: BoxFit.cover,
                  height: 22.h,
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            SizedBox(height: 2.h),
            if (stateLabel.isNotEmpty)
              Text(stateLabel,
                  style: TextStyle(
                      color: Constants.gold,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp)),
            Text(ev.name,
                style: TextStyle(
                    fontFamily: 'Cinzel',
                    color: Constants.gold,
                    fontSize: 21.sp)),
            SizedBox(height: 1.h),
            Text(when, style: body.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 1.h),
            Text(
                [ev.placeLabel, if (ev.address != null) ev.address!]
                    .join('\n'),
                style: body),
            if (ev.hostLabel.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text('Hosted by ${ev.hostLabel}', style: body),
            ],
            SizedBox(height: 1.h),
            Text(
                [
                  ev.type,
                  ev.free ? 'Free' : ev.price,
                  if (ev.approval) 'Host approves guests',
                  if (ev.inviteOnly) 'Invite only',
                ].join(' · '),
                style: body.copyWith(color: Colors.white70)),
            if (message != null) ...[
              SizedBox(height: 2.h),
              Text(message!, style: body.copyWith(color: Constants.gold)),
            ],
            SizedBox(height: 3.h),
            if (ev.url.isNotEmpty)
              ElevatedButton(
                style: Constants.buttonStyle,
                onPressed: () => open(ev.url),
                child: const Text('Register'),
              ),
            if (ev.hasLocation) ...[
              SizedBox(height: 1.5.h),
              ElevatedButton(
                style: Constants.buttonStyle,
                onPressed: () => open(
                    'https://www.google.com/maps/dir/?api=1&destination=${ev.lat},${ev.lng}'),
                child: const Text('Directions'),
              ),
            ],
            if (ev.hasLocation &&
                !ev.locationHidden &&
                (state == EventState.live || state == EventState.soon)) ...[
              SizedBox(height: 1.5.h),
              ElevatedButton(
                style: Constants.buttonStyle,
                onPressed: busy ? null : checkIn,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Check in'),
              ),
            ],
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}
