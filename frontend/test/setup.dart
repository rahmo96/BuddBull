import 'package:buddbull/services/auth_service.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates an AuthService with mocked Firebase Auth for widget tests.
/// Use this to test screens without initializing real Firebase.
AuthService createMockAuthService() {
  return AuthService(auth: MockFirebaseAuth());
}
