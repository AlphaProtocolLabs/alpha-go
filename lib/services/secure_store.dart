import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secrets live in the Android Keystore / iOS Keychain, never in SharedPreferences.
/// The wallet password is stored only as a salted hash; it is a local unlock, not a key.
class SecureStore {
  static const _s = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _mnemonic = 'wallet_mnemonic';
  static const _pwHash = 'wallet_password_hash';
  static const _token = 'api_token';

  static Future<String?> mnemonic() => _s.read(key: _mnemonic);

  static Future<void> saveWallet(String mnemonic, String password) async {
    await _s.write(key: _mnemonic, value: mnemonic);
    await _s.write(key: _pwHash, value: _hash(password, _salt()));
  }

  static Future<bool> checkPassword(String password) async {
    final stored = await _s.read(key: _pwHash);
    if (stored == null) return false;
    final salt = stored.split('.').first;
    return _hash(password, salt) == stored;
  }

  static Future<String?> token() => _s.read(key: _token);
  static Future<void> saveToken(String token) =>
      _s.write(key: _token, value: token);
  static Future<void> clearToken() => _s.delete(key: _token);

  /// Forget the wallet and the account on this phone.
  static Future<void> wipe() => _s.deleteAll();

  static String _salt() {
    final r = Random.secure();
    return base64UrlEncode(List.generate(16, (_) => r.nextInt(256)));
  }

  static String _hash(String password, String salt) =>
      '$salt.${sha256.convert(utf8.encode('$salt:$password'))}';
}
