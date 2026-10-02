import 'package:alpha_go/controllers/biometrics_controller.dart';
import 'package:alpha_go/controllers/chat_controller.dart';
import 'package:alpha_go/models/chat_models.dart';
import 'package:alpha_go/views/screens/chat_screen.dart';
import 'package:alpha_go/views/screens/member_screen.dart';
import 'package:alpha_go/controllers/event_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/controllers/vibe_controller.dart';
import 'package:alpha_go/controllers/wallet_controller.dart';
import 'package:alpha_go/models/event_model.dart';
import 'package:alpha_go/services/secure_store.dart';
import 'package:alpha_go/views/screens/account_screen.dart';
import 'package:alpha_go/views/screens/base_view.dart';
import 'package:alpha_go/views/screens/edit_profile_screen.dart';
import 'package:alpha_go/views/screens/event_details_screen.dart';
import 'package:alpha_go/views/screens/generate_mnemonic_screen.dart';
import 'package:alpha_go/views/screens/import_mnemonic_screen.dart';
import 'package:alpha_go/views/screens/legal_screen.dart';
import 'package:alpha_go/views/screens/send_token_screen.dart';
import 'package:alpha_go/views/screens/wallet_created_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:alpha_go/views/screens/login_screen.dart';
import 'package:alpha_go/views/screens/set_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final SharedPreferencesWithCache prefs =
      Get.put(await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  ));

  final WalletController controller = Get.put(WalletController());
  Get.put(UserController());
  Get.put(VibeController());
  Get.put(ChatController());
  final EventController eventController = Get.put(EventController());
  final BiometricsController auth = Get.put(BiometricsController());
  await auth.initialize();
  // Events load in the background; the map and list show progress.
  eventController.getEvents();

  // Builds before 1.5 kept the phrase in plain SharedPreferences. Move it into
  // secure storage and delete the old copies.
  final legacy = prefs.getString("mnemonic");
  if (legacy != null) {
    await SecureStore.saveWallet(legacy, prefs.getString("password") ?? "");
    await prefs.remove("mnemonic");
    await prefs.remove("password");
  }

  final mnemonic = await SecureStore.mnemonic();
  if (mnemonic != null) {
    controller.mnemonic = mnemonic;
    runApp(MyApp(initWidget: const SetPasswordScreen(isEnter: true)));
  } else {
    runApp(MyApp(initWidget: const LoginPage()));
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key, required this.initWidget}) {
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => initWidget,
          routes: [
            GoRoute(
                path: 'walletCreated',
                builder: (context, state) {
                  final bool isImport = state.extra as bool;
                  return WalletCreatedScreen(
                    isImport: isImport,
                  );
                }),
            GoRoute(
              path: 'home',
              builder: (context, state) => const NavBar(),
            ),
            GoRoute(
                path: 'legal',
                builder: (context, state) {
                  final bool isGenerate = state.extra as bool;
                  return LegalPage(
                    isGenerate: isGenerate,
                  );
                }),
            GoRoute(
                path: 'generateMnemonic',
                builder: (context, state) {
                  return const GenerateWalletMnemonic();
                }),
            GoRoute(
                path: 'enterMnemonic',
                builder: (context, state) {
                  return const EnterWalletMnemonic();
                }),
            GoRoute(
                path: 'setPassword',
                builder: (context, state) {
                  return SetPasswordScreen(
                    isEnter: (state.extra as List)[0],
                    isImport: (state.extra as List)[1],
                  );
                }),
            GoRoute(
                path: 'login',
                builder: (context, state) {
                  return const LoginPage();
                }),
            GoRoute(
                path: 'account',
                builder: (context, state) {
                  return const AccountScreen();
                }),
            GoRoute(
                path: 'editProfile',
                builder: (context, state) {
                  return const EditProfileScreen();
                }),
            GoRoute(
              path: 'eventDetails',
              builder: (context, state) =>
                  EventDetailsScreen(event: state.extra as EventModel),
            ),
            GoRoute(
              path: 'chat',
              builder: (context, state) =>
                  ChatScreen(chat: state.extra as ChatSummary),
            ),
            GoRoute(
              path: 'member',
              builder: (context, state) =>
                  MemberScreen(memberId: state.extra as String),
            ),
            GoRoute(
              path: 'token',
              builder: (context, state) => SendTokenScreen(
                  tokenData: state.extra as Map<String, dynamic>),
            )
          ],
        ),
      ],
    );
  }
  final Widget initWidget;
  late final GoRouter router;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(builder: (context, orientation, screenType) {
      return GetMaterialApp.router(
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
        routeInformationProvider: router.routeInformationProvider,
        backButtonDispatcher: router.backButtonDispatcher,
        title: 'Alpha Go',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: TextTheme(
            displayLarge: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 57,
                fontWeight: FontWeight.bold),
            displayMedium: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 45,
                fontWeight: FontWeight.bold),
            displaySmall: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 36,
                fontWeight: FontWeight.bold),
            headlineLarge: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 32,
                fontWeight: FontWeight.bold),
            headlineMedium: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 28,
                fontWeight: FontWeight.bold),
            headlineSmall: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 24,
                fontWeight: FontWeight.bold),
            titleLarge: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 22,
                fontWeight: FontWeight.w900),
            titleMedium: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 16,
                fontWeight: FontWeight.w900),
            titleSmall: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 14,
                fontWeight: FontWeight.w500),
            bodyLarge: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 16,
                fontWeight: FontWeight.w400),
            bodyMedium: TextStyle(
                color: Colors.white,
                fontFamily: 'Cinzel',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600),
            bodySmall: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 12,
                fontWeight: FontWeight.w400),
            labelLarge: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 14,
                fontWeight: FontWeight.w500),
            labelMedium: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 12,
                fontWeight: FontWeight.w400),
            labelSmall: const TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 11,
                fontWeight: FontWeight.w400),
          ),
        ),
      );
    });
  }
}
