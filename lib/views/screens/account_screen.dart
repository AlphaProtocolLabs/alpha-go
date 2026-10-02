import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/controllers/wallet_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/services/api.dart';
import 'package:alpha_go/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sign in or create the Alpha GO account. It is the same account as the
/// go.alphaprotocol.network event guide, so people who joined there just sign in.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool joining = true;
  bool busy = false;
  String? error;
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final ref = TextEditingController();
  final UserController user = Get.find();
  final WalletController wallet = Get.find();

  Future<void> submit() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (joining) {
        await Api.join(
            email: email.text.trim(),
            name: name.text.trim(),
            password: password.text,
            ref: ref.text.trim());
      } else {
        await Api.login(email.text.trim(), password.text);
      }
      await user.refreshAccount();
      await user.linkWallet(wallet.ordinalAddress);
      if (!mounted) return;
      while (context.canPop()) {
        context.pop();
      }
      context.pushReplacement(joining ? '/editProfile' : '/home');
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(TextEditingController c, String label,
      {bool obscure = false, TextInputType? type}) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        autocorrect: false,
        style: Constants.inputStyle,
        cursorColor: Colors.white,
        decoration: Constants.inputDecoration.copyWith(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover)),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomNavBar(
            leadingWidget: const SizedBox(),
            actionWidgets: SizedBox(
              width: 76.w,
              child: Text(
                joining ? 'Create your profile' : 'Sign in',
                style: TextStyle(
                    color: Constants.gold,
                    fontSize: 18.sp,
                    fontFamily: 'Cinzel'),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  joining
                      ? 'Your Alpha GO profile works here and on go.alphaprotocol.network. You start with testnet VIBE.'
                      : 'Use the email and password from go.alphaprotocol.network.',
                  style: TextStyle(fontSize: 15.sp, fontFamily: 'Roboto'),
                ),
                if (joining) field(name, 'Name others will see'),
                field(email, 'Email', type: TextInputType.emailAddress),
                field(password, 'Password (8+ characters)', obscure: true),
                if (joining) field(ref, 'Invite code (optional)'),
                if (error != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontFamily: 'Roboto')),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 3.h),
                  child: ElevatedButton(
                    style: Constants.buttonStyle,
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(joining ? 'Create account' : 'Sign in'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    joining = !joining;
                    error = null;
                  }),
                  child: Text(
                    joining
                        ? 'Already joined on the web? Sign in'
                        : 'New here? Create an account',
                    style: const TextStyle(color: Constants.gold),
                  ),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                      Uri.parse('${Constants.apiBase}/terms'),
                      mode: LaunchMode.externalApplication),
                  child: const Text('Terms',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
