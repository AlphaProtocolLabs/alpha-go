import 'package:alpha_go/controllers/user_controller.dart';
import 'package:alpha_go/controllers/vibe_controller.dart';
import 'package:alpha_go/controllers/wallet_controller.dart';
import 'package:alpha_go/models/const_model.dart';
import 'package:alpha_go/models/user_model.dart';
import 'package:alpha_go/services/api.dart';
import 'package:alpha_go/views/widgets/drawer_widget.dart';
import 'package:alpha_go/views/widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final WalletController wallet = Get.find();
  final UserController user = Get.find();
  final VibeController vibe = Get.find();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool syncing = false;
  String? walletError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  Future<void> refresh() async {
    setState(() {
      syncing = true;
      walletError = null;
    });
    await user.refreshAccount();
    await vibe.refreshBalance();
    try {
      await wallet.initWallet();
      await wallet.getFundingAddress();
    } catch (_) {
      walletError = 'Could not sync the Bitcoin wallet. Pull to retry.';
    }
    if (mounted) setState(() => syncing = false);
  }

  void copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$what copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: Colors.black,
      appBar: CustomNavBar(
        leadingWidget: Text('Profile',
            style: TextStyle(
                fontFamily: 'Cinzel', color: Constants.gold, fontSize: 19.sp)),
        actionWidgets: IconButton(
          icon: Icon(Icons.menu, size: 29.px, color: Constants.gold),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: Obx(() {
          final a = user.account.value;
          return ListView(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 14.h),
            children: [
              if (a == null) _signedOut() else _header(a),
              SizedBox(height: 2.h),
              if (a != null) _vibeCard(a),
              SizedBox(height: 2.h),
              _bitcoinCard(),
            ],
          );
        }),
      ),
    );
  }

  Widget _signedOut() => _card(
        children: [
          const Text('You are not signed in.',
              style: TextStyle(fontFamily: 'Roboto')),
          SizedBox(height: 1.h),
          ElevatedButton(
              style: Constants.buttonStyle,
              onPressed: () => context.push('/account'),
              child: const Text('Sign in or create account')),
        ],
      );

  Widget _header(Account a) {
    final body = TextStyle(fontFamily: 'Roboto', fontSize: 15.sp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Constants.gold,
              child: Text(a.initials,
                  style: const TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name,
                      style: TextStyle(
                          fontFamily: 'Cinzel',
                          color: Constants.gold,
                          fontSize: 20.sp)),
                  Text(
                      'Member since ${DateFormat('d MMM yyyy').format(a.memberSince.toLocal())}',
                      style: body.copyWith(color: Colors.white60, fontSize: 13.sp)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/editProfile'),
              icon: const Icon(Icons.edit, color: Constants.gold),
            ),
          ],
        ),
        if ((a.bio ?? '').isNotEmpty) ...[
          SizedBox(height: 1.5.h),
          Text(a.bio!, style: body),
        ],
        if ((a.link ?? '').isNotEmpty)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => launchUrl(Uri.parse(a.link!),
                mode: LaunchMode.externalApplication),
            child: Text(a.link!,
                style: body.copyWith(color: Constants.gold),
                overflow: TextOverflow.ellipsis),
          ),
        SizedBox(height: 1.h),
        Row(children: [
          _stat('${a.saves.length}', 'saved'),
          _stat('${a.checkins.length}', 'check-ins'),
        ]),
        SizedBox(height: 1.h),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Constants.gold)),
          onPressed: () => Share.share(
              'Join me on Alpha GO for TOKEN2049 week: ${Constants.apiBase}/join?r=${a.refCode}'),
          icon: const Icon(Icons.ios_share, color: Constants.gold),
          label: const Text('Invite friends',
              style: TextStyle(color: Constants.gold)),
        ),
      ],
    );
  }

  Widget _stat(String n, String label) => Padding(
        padding: EdgeInsets.only(right: 6.w),
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontFamily: 'Roboto', fontSize: 15.sp),
            children: [
              TextSpan(
                  text: '$n ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                  text: label, style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      );

  Widget _vibeCard(Account a) {
    final fmt = NumberFormat.decimalPattern();
    return _card(
      title: 'VIBE (testnet)',
      children: [
        _line('Balance', '${fmt.format(a.vibe)} VIBE'),
        _line('  Sendable', '${fmt.format(a.vibeSendable)} VIBE'),
        _line('  Earned (Topsi only)', '${fmt.format(a.vibeEarned)} VIBE'),
        Obx(() => _line(
            'In your Aptos wallet',
            vibe.onChain.value == null
                ? '…'
                : '${fmt.format(vibe.onChain.value)} VIBE')),
        Obx(() {
          final addr = vibe.balanceAddress;
          if (addr == null) return const SizedBox();
          return _address('Aptos address', addr);
        }),
        SizedBox(height: 1.h),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Constants.gold)),
          onPressed: a.vibeSendable > 0 ? () => _withdraw(a) : null,
          child: const Text('Withdraw to Aptos wallet',
              style: TextStyle(color: Constants.gold)),
        ),
        Text(
          'Testnet VIBE has utility inside the Alpha Protocol ecosystem. It is not a mainnet token. VIBE you buy or receive can be sent and withdrawn; VIBE you earn pays for Topsi.',
          style: TextStyle(
              fontFamily: 'Roboto', fontSize: 12.sp, color: Colors.white54),
        ),
      ],
    );
  }

  Future<void> _withdraw(Account a) async {
    final amount = TextEditingController();
    final address = TextEditingController(text: vibe.balanceAddress ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Constants.gold)),
        title: const Text('Withdraw VIBE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Up to ${NumberFormat.decimalPattern().format(a.vibeSendable)} VIBE, to an Aptos testnet address. Check the address: transfers cannot be reversed.',
                style: const TextStyle(fontFamily: 'Roboto', color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Constants.inputStyle,
              decoration: Constants.inputDecoration.copyWith(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              style: Constants.inputStyle,
              decoration: Constants.inputDecoration
                  .copyWith(labelText: 'To (this phone\'s address, or Petra)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    final n = int.tryParse(amount.text);
    if (ok != true || n == null || n <= 0) return;
    setState(() => syncing = true);
    try {
      await Api.withdraw(n, address.text.trim());
      await user.refreshAccount();
      await vibe.refreshBalance();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sent $n VIBE to your Aptos wallet')));
      }
    } on ApiException catch (e) {
      await user.refreshAccount();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => syncing = false);
    }
  }

  Widget _bitcoinCard() {
    final fmt = NumberFormat.decimalPattern();
    final runes = wallet.runes.values.toList();
    return _card(
      title: 'Bitcoin wallet',
      children: [
        if (syncing) const LinearProgressIndicator(color: Constants.gold),
        if (walletError != null)
          Text(walletError!,
              style: const TextStyle(
                  fontFamily: 'Roboto', color: Colors.redAccent)),
        _line('Spending', '${fmt.format(wallet.fundingWalletBalance ?? 0)} sats'),
        _line('Ordinals wallet',
            '${fmt.format(wallet.ordinalWalletBalance ?? 0)} sats'),
        if (wallet.fundingAddress != null)
          _address('Receive bitcoin at', wallet.fundingAddress!),
        if (wallet.ordinalAddress != null)
          _address('Receive ordinals and runes at', wallet.ordinalAddress!),
        if (runes.isNotEmpty) ...[
          SizedBox(height: 1.h),
          const Text('Runes', style: TextStyle(fontFamily: 'Roboto')),
          for (final r in runes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${r['name']}',
                  style: const TextStyle(fontFamily: 'Roboto')),
              subtitle: Text('${r['balance'] ?? 0} ${r['symbol'] ?? ''}'),
              onTap: () => context.push('/token', extra: r),
            ),
        ],
        Text(
          'Mainnet bitcoin. Your recovery phrase stays on this phone; keep your written copy safe.',
          style: TextStyle(
              fontFamily: 'Roboto', fontSize: 12.sp, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _card({String? title, required List<Widget> children}) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            border: Border.all(color: Constants.gold.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(title,
                    style: TextStyle(
                        fontFamily: 'Cinzel',
                        color: Constants.gold,
                        fontSize: 17.sp)),
              ),
            ...children,
          ],
        ),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Roboto', color: Colors.white70)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _address(String label, String addr) => InkWell(
        onTap: () => copy(addr, label),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Roboto', color: Colors.white70)),
              Row(children: [
                Expanded(
                  child: Text(addr,
                      style: const TextStyle(
                          fontFamily: 'Roboto', fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                const Icon(Icons.copy, size: 16, color: Constants.gold),
              ]),
            ],
          ),
        ),
      );
}
