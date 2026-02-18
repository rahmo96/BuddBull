import 'package:buddbull/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService authService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    authService = AuthService(auth: mockAuth);
  });

  group('AuthService', () {
    group('signUpWithEmail', () {
      test('creates user and returns MockUser when successful', () async {
        final user = await authService.signUpWithEmail(
          'test@example.com',
          'password123',
        );

        expect(user, isNotNull);
        expect(user!.email, 'test@example.com');
        expect(mockAuth.currentUser, isNotNull);
      });

      test('throws on weak password', () async {
        whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(
              FirebaseAuthException(code: 'weak-password'),
            );

        expect(
          () => authService.signUpWithEmail('test@example.com', '123'),
          throwsA(contains('too weak')),
        );
      });

      test('throws on email-already-in-use', () async {
        whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(
              FirebaseAuthException(code: 'email-already-in-use'),
            );

        expect(
          () => authService.signUpWithEmail('existing@example.com', 'pass123'),
          throwsA(contains('already exists')),
        );
      });
    });

    group('signInWithEmail', () {
      test('signs in and returns user when successful', () async {
        // MockFirebaseAuth needs a mockUser for signIn to return email
        mockAuth = MockFirebaseAuth(
          mockUser: MockUser(email: 'test@example.com', uid: 'test-uid'),
        );
        authService = AuthService(auth: mockAuth);

        final user = await authService.signInWithEmail(
          'test@example.com',
          'password123',
        );

        expect(user, isNotNull);
        expect(user!.email, 'test@example.com');
      });

      test('throws on invalid credentials', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(
              FirebaseAuthException(code: 'invalid-credential'),
            );

        expect(
          () => authService.signInWithEmail('bad@example.com', 'wrong'),
          throwsA(contains('Invalid email or password')),
        );
      });

      test('throws on user-disabled', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(
              FirebaseAuthException(code: 'user-disabled'),
            );

        expect(
          () => authService.signInWithEmail('disabled@example.com', 'pass'),
          throwsA(contains('disabled')),
        );
      });
    });

    group('signOut', () {
      test('signs out without throwing', () async {
        mockAuth = MockFirebaseAuth(
          mockUser: MockUser(email: 'test@example.com', uid: 'test-uid'),
        );
        authService = AuthService(auth: mockAuth);
        await authService.signInWithEmail('test@example.com', 'password123');
        expect(mockAuth.currentUser, isNotNull);

        await authService.signOut();
        expect(mockAuth.currentUser, isNull);
      });
    });

    group('getCurrentUser', () {
      test('returns null when signed out', () {
        expect(authService.getCurrentUser(), isNull);
      });

      test('returns user when signed in', () async {
        mockAuth = MockFirebaseAuth(
          mockUser: MockUser(email: 'test@example.com', uid: 'test-uid'),
        );
        authService = AuthService(auth: mockAuth);
        await authService.signInWithEmail('test@example.com', 'password123');
        final user = authService.getCurrentUser();
        expect(user, isNotNull);
        expect(user!.email, 'test@example.com');
      });
    });

    group('resetPassword', () {
      test('completes without throwing when successful', () async {
        await expectLater(
          authService.resetPassword('test@example.com'),
          completes,
        );
      });

      test('throws on Firebase error', () async {
        whenCalling(Invocation.method(#sendPasswordResetEmail, null))
            .on(mockAuth)
            .thenThrow(
              FirebaseAuthException(code: 'invalid-email', message: 'Bad email'),
            );

        expect(
          () => authService.resetPassword('invalid'),
          throwsA(contains('Bad email')),
        );
      });
    });
  });
}
