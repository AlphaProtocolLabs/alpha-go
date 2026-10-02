import 'package:alpha_go/controllers/biometrics_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/services/secure_store.dart';
import 'package:alpha_go/views/screens/set_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final UserController user = Get.find();
    final BiometricsController auth = Get.find();
    final itemStyle = TextStyle(color: Constants.gold, fontSize: 20.px);

    Widget item(IconData icon, String label, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: Constants.gold, size: 24.px),
          title: Text(label, style: itemStyle),
          onTap: onTap,
        );

    void open(String url) =>
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    void restart(String to) {
      while (context.canPop()) {
        context.pop();
      }
      context.pushReplacement(to);
    }

    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 8.h, 5.w, 3.h),
            child: Obx(() {
              final a = user.account.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a?.name ?? 'Alpha GO',
                      style: TextStyle(
                          fontFamily: 'Cinzel',
                          color: Constants.gold,
                          fontSize: 22.px)),
                  if (a != null)
                    Text(a.email,
                        style: const TextStyle(
                            fontFamily: 'Roboto', color: Colors.white60)),
                ],
              );
            }),
          ),
          item(Icons.edit, 'Edit profile', () => context.push('/editProfile')),
          item(Icons.public, 'Alpha Protocol',
              () => open('https://www.alphaprotocol.network')),
          item(Icons.token, 'VIBE presale',
              () => open('${Constants.apiBase}/vibe')),
          item(Icons.description_outlined, 'Terms',
              () => open('${Constants.apiBase}/terms')),
          if (auth.canCheckBiometrics)
            Obx(() => SwitchListTile(
                  activeColor: Constants.gold,
                  secondary: Icon(Icons.fingerprint,
                      color: Constants.gold, size: 24.px),
                  title: Text('Unlock with biometrics', style: itemStyle),
                  value: auth.isBiometricEnabled.value,
                  onChanged: auth.toggleBiometric,
                )),
          SizedBox(height: 3.h),
          Obx(() => user.signedIn
              ? item(Icons.logout, 'Sign out', () async {
                  await user.signOut();
                  restart('/account');
                })
              : item(Icons.login, 'Sign in', () => context.push('/account'))),
          item(Icons.delete_outline, 'Remove wallet from this phone',
              () async {
            if (!await confirmForget(context)) return;
            await SecureStore.wipe();
            await user.signOut();
            restart('/login');
          }),
        ],
      ),
    );
  }
}
