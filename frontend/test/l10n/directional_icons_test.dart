import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Icons.logout_rounded does not mirror by itself; profile_screen.dart flips it
// manually with Transform.flip.
void main() {
  test('directional icons used in the app mirror in RTL', () {
    for (final icon in [
      Icons.chevron_right_rounded,
      Icons.chevron_left_rounded,
      Icons.arrow_back_rounded,
      Icons.arrow_forward_rounded,
      Icons.arrow_back_ios_new_rounded,
      Icons.send_rounded,
      Icons.arrow_back,
      Icons.reply,
    ]) {
      expect(icon.matchTextDirection, isTrue, reason: '$icon should mirror');
    }
  });
}
