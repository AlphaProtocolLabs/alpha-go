import 'package:alpha_go/models/user_model.dart';
import 'package:alpha_go/services/api.dart';
import 'package:get/get.dart';

/// The signed-in Alpha GO account (shared with go.alphaprotocol.network).
class UserController extends GetxController {
  final Rxn<Account> account = Rxn<Account>();

  bool get signedIn => account.value != null;

  /// Loads the profile; returns false when there is no valid session.
  Future<bool> refreshAccount() async {
    try {
      account.value = await Api.me();
    } on ApiException {
      // Keep what we have if the network is down.
    }
    return account.value != null;
  }

  Future<void> signOut() async {
    await Api.logout();
    account.value = null;
  }

  /// Testnet VIBE from the presale and rewards is sent to this Aptos address.
  Future<void> linkAptos(String aptosAddress) async {
    final a = account.value;
    if (a == null || a.aptosAddress != null) return; // never overwrite one the member set
    try {
      await Api.updateProfile({'aptosAddress': aptosAddress});
      await refreshAccount();
    } on ApiException {
      // Retried next launch.
    }
  }

  /// Puts this phone's wallet address on the profile, once.
  Future<void> linkWallet(String? btcAddress) async {
    final a = account.value;
    if (a == null || btcAddress == null || a.btcAddress == btcAddress) return;
    try {
      await Api.updateProfile({'btcAddress': btcAddress});
      await refreshAccount();
    } on ApiException {
      // Not fatal: the profile works without it and we retry next launch.
    }
  }
}
