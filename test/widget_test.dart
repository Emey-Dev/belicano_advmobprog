import 'package:belicano_advmobprog/main.dart' show initializeFirebase;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase initialization should not crash on web startup', () async {
    await initializeFirebase(isWeb: true);
  });
}
