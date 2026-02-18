import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class AuthService {
  // Instance of Firebase Auth to interact with the service
  // Optional [auth] parameter for testing with mocks
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // 1. Sign Up (Create new user)
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Throw specific errors so the UI can catch and show them
      if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        throw 'The account already exists for that email.';
      }
      throw 'Registration failed. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // 2. Sign In (Login)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Handling common Login errors
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw 'Invalid email or password.';
      } else if (e.code == 'user-disabled') {
        throw 'This user has been disabled.';
      }
      throw 'Login failed. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  //  Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      // כאן כדאי לטפל בשגיאות כמו מייל לא תקין או משתמש שלא קיים
      throw e.message ?? "אירעה שגיאה בשליחת המייל";
    }
  }

  //  Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<bool> saveUserToMongo(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post('/users/register', data: userData);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Mongo Saving Error: $e");
      return false;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
