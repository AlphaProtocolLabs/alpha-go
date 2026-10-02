import 'dart:convert';
import 'dart:typed_data';

import 'package:alpha_go/controllers/user_controller.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha3.dart';

/// VIBE on Aptos testnet, alongside the Bitcoin wallet.
///
/// The Aptos account comes from the same recovery phrase on the standard Aptos
/// path, so wallets like Petra show the same address. This build only reads the
/// balance and receives; it never signs Aptos transactions.
class VibeController extends GetxController {
  static const node = 'https://fullnode.testnet.aptoslabs.com/v1';
  static const module =
      '0x24cb561c64c32942eb8600d5135f0185c23bcd06cd8cf33422ce2f9b77d65388::vibe_token';
  static const decimals = 8;
  static const path = "m/44'/637'/0'/0'/0'";

  final RxnString address = RxnString();

  /// On-chain testnet VIBE, in whole tokens. Null until loaded.
  final Rxn<double> onChain = Rxn<double>();

  static Future<String> addressFor(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final key = await ED25519_HD_KEY.derivePath(path, seed);
    final pub = await ED25519_HD_KEY.getPublicKey(key.key, false);
    // Single-key Ed25519 scheme: address = SHA3-256(public key || 0x00).
    final digest = SHA3Digest(256)
        .process(Uint8List.fromList([...pub, 0x00]));
    return '0x${digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  Future<void> load(String mnemonic) async {
    address.value = await addressFor(mnemonic);
    await Get.find<UserController>().linkAptos(address.value!);
    await refreshBalance();
  }

  /// The profile's Aptos address wins when the member set their own (e.g. Petra).
  String? get balanceAddress =>
      Get.find<UserController>().account.value?.aptosAddress ?? address.value;

  Future<void> refreshBalance() async {
    final a = balanceAddress;
    if (a == null) return;
    try {
      final res = await http
          .post(Uri.parse('$node/view'),
              headers: {'content-type': 'application/json'},
              body: jsonEncode({
                'function': '$module::balance',
                'type_arguments': [],
                'arguments': [a],
              }))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final raw = int.parse((jsonDecode(res.body) as List).first as String);
        onChain.value = raw / 1e8;
      }
    } catch (_) {
      // Leave the last known balance; the profile still shows the account ledger.
    }
  }
}
