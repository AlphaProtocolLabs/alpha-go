import 'dart:developer';
import 'package:alpha_go/controllers/biometrics_controller.dart';
import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/controllers/wallet_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/services/secure_store.dart';
import 'package:alpha_go/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen(
      {super.key, this.isImport = false, this.isEnter = false});
  final bool isImport;
  final bool isEnter;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  final WalletController controller = Get.find();
  final UserController userController = Get.find();
  final BiometricsController auth = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async {
        if (widget.isEnter && auth.isBiometricEnabled.value) {
          final bool didAuthenticate = await auth.authenticate();
          if (didAuthenticate) {
            goToHome();
          } else {
            Get.snackbar("Error", "Authentication failed",
                colorText: Colors.white);
          }
        }
      },
    );
  }

  bool busy = false;

  /// Unlocks the wallet, then opens the account: home if signed in, sign-in otherwise.
  Future<void> goToHome() async {
    setState(() => busy = true);
    await controller.createOrRestoreOrdinalWallet();
    await controller.createOrRestoreFundingWallet();
    final signedIn = await userController.refreshAccount();
    if (signedIn) await userController.linkWallet(controller.ordinalAddress);
    if (!mounted) return;
    while (context.canPop()) {
      context.pop();
    }
    context.pushReplacement(signedIn ? '/home' : '/account');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage(
                'assets/bg.jpg',
              ),
              fit: BoxFit.cover)),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomNavBar(
            leadingWidget: Padding(
              padding: EdgeInsets.all(1.w),
              child: IconButton(
                onPressed: () {
                  Get.back();
                },
                icon:
                    const Icon(Icons.arrow_back_ios, color: Color(0xFFB4914B)),
              ),
            ),
            actionWidgets: SizedBox(
              width: 76.w,
              child: Row(
                children: [
                  Text(
                    "Set a Password",
                    style: TextStyle(
                      color: const Color(0xFFB4914B), // Gold color
                      fontSize: 18.sp,
                      fontFamily: 'Cinzel',
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 5.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(widget.isEnter
                    ? "Enter your wallet's password"
                    : "Set a password to secure your wallet."),
                Padding(
                  padding: EdgeInsets.only(top: 5.h),
                  child: TextField(
                    style: Constants.inputStyle,
                    controller: password,
                    obscureText: true,
                    decoration: Constants.inputDecoration.copyWith(
                      hintText: "Enter your Password",
                    ),
                    cursorColor: Colors.white,
                  ),
                ),
                widget.isEnter
                    ? Padding(
                        padding: EdgeInsets.only(top: 5.h),
                        child: ElevatedButton(
                            style: Constants.buttonStyle,
                            onPressed: () async {
                              final ok = await confirmForget(context);
                              if (!ok || !context.mounted) return;
                              await SecureStore.wipe();
                              await userController.signOut();
                              while (context.canPop()) {
                                context.pop();
                              }
                              context.pushReplacement('/login');
                            },
                            child: const Text('Use a different wallet')),
                      )
                    : Padding(
                        padding: EdgeInsets.only(top: 5.h),
                        child: TextField(
                          cursorColor: Colors.white,
                          style: Constants.inputStyle,
                          controller: confirmPassword,
                          obscureText: true,
                          decoration: Constants.inputDecoration
                              .copyWith(hintText: "Confirm your password"),
                        ),
                      ),
                Padding(
                  padding: EdgeInsets.only(top: 5.h),
                  child: ElevatedButton(
                    style: Constants.buttonStyle,
                    onPressed: () async {
                      // final alphanumeric =
                      //     RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{6,}$');
                      if (password.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter a password"),
                            backgroundColor: Colors.red,
                          ),
                        );

                        return;
                      }
                      final alphanumeric = RegExp(
                          r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$'); // fix to above regex

                      log(alphanumeric.hasMatch(password.text).toString());
                      if (widget.isEnter) {
                        if (await SecureStore.checkPassword(password.text)) {
                          goToHome();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Password does not match, please use the password you set before"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      } else if (password.text == confirmPassword.text) {
                        if (!alphanumeric.hasMatch(password.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Use at least 8 characters with an uppercase letter, a number and a symbol (@\$!%*?&)."),
                              backgroundColor: Colors.red,
                            ),
                          );

                          return;
                        } else {
                          controller.password = password.text;
                          while (context.canPop()) {
                            context.pop();
                          }
                          context.pushReplacement('/walletCreated',
                              extra: widget.isImport);
                        }
                      }
                    },
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Continue"),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

/// Forgetting the wallet deletes the recovery phrase from this phone.
Future<bool> confirmForget(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Remove this wallet?'),
          content: const Text(
              'This deletes the recovery phrase from this phone. Without your written copy of the phrase, any bitcoin in this wallet is lost.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove')),
          ],
        ),
      ) ??
      false;
}
