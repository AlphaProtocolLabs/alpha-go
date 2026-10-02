import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/services/api.dart';
import 'package:alpha_go/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserController user = Get.find();
  late final name = TextEditingController(text: user.account.value?.name);
  late final bio = TextEditingController(text: user.account.value?.bio);
  late final link = TextEditingController(text: user.account.value?.link);
  bool busy = false;
  String? error;

  void done() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.pushReplacement('/home');
    }
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    var url = link.text.trim();
    if (url.isNotEmpty && !url.startsWith('http')) url = 'https://$url';
    try {
      await Api.updateProfile(
          {'name': name.text.trim(), 'bio': bio.text.trim(), 'link': url});
      await user.refreshAccount();
      if (mounted) done();
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String label) =>
        Constants.inputDecoration.copyWith(labelText: label);
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomNavBar(
          leadingWidget: IconButton(
            onPressed: done,
            icon: const Icon(Icons.arrow_back_ios, color: Constants.gold),
          ),
          actionWidgets: SizedBox(
            width: 76.w,
            child: Text('Your profile',
                style: TextStyle(
                    color: Constants.gold,
                    fontSize: 18.sp,
                    fontFamily: 'Cinzel')),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This is what other members see. You can change it any time.',
                style: TextStyle(fontSize: 15.sp, fontFamily: 'Roboto'),
              ),
              SizedBox(height: 2.h),
              TextField(
                  controller: name,
                  style: Constants.inputStyle,
                  decoration: deco('Name')),
              SizedBox(height: 2.h),
              TextField(
                  controller: bio,
                  maxLength: 280,
                  maxLines: 3,
                  style: Constants.inputStyle,
                  decoration: deco('What are you working on?')),
              SizedBox(height: 1.h),
              TextField(
                  controller: link,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: Constants.inputStyle,
                  decoration: deco('Link (X, LinkedIn, website)')),
              if (error != null)
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Text(error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontFamily: 'Roboto')),
                ),
              SizedBox(height: 3.h),
              ElevatedButton(
                style: Constants.buttonStyle,
                onPressed: busy ? null : save,
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
