import 'package:alpha_go/controllers/vibe_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Aptos address matches the Aptos SDK derivation test vector', () async {
    final a = await VibeController.addressFor(
        'shoot island position soft burden budget tooth cruel issue economy destroy above');
    expect(a, '0x07968dab936c1bad187c60ce4082f307d030d780e91e694ae03aef16aba73f30');
  });
}
