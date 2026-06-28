import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CardEncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'card_aes_key';
  static const _ivAlias = 'card_aes_iv';

  static Future<Key> _getOrCreateKey() async {
    String? stored = await _storage.read(key: _keyAlias);
    if (stored == null) {
        final key = Key.fromSecureRandom(32);
      stored = key.base64;
      await _storage.write(key: _keyAlias, value: stored);
    }
    return Key.fromBase64(stored);
  }

  static Future<IV> _getOrCreateIV() async {
    String? stored = await _storage.read(key: _ivAlias);
    if (stored == null) {
      final iv = IV.fromSecureRandom(16);
      stored = iv.base64;
      await _storage.write(key: _ivAlias, value: stored);
    }
    return IV.fromBase64(stored);
  }

  static Future<String> encrypt(String plainText) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }

  static Future<String> decrypt(String encryptedBase64) async {
    final key = await _getOrCreateKey();
    final iv = await _getOrCreateIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt64(encryptedBase64, iv: iv);
  }
}
