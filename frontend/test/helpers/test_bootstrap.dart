import 'package:buddbull/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

bool _firebaseTestHarnessReady = false;

/// Registers Firebase Core mocks and initializes the default Firebase app for
/// widget tests on the Dart VM (`flutter test` without a device target).
Future<void> initTestFirebaseAndBinding() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_firebaseTestHarnessReady) {
    return;
  }

  setupFirebaseCoreMocks();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  _firebaseTestHarnessReady = true;
}
