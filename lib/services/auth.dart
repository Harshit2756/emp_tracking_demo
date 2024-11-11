import 'package:emp_tracking_demo/services/db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/storage_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<UserCredential?> login(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get token and store user data
      final String? token = await userCredential.user?.getIdToken();
      if (token != null) {
        await StorageHelper.storeUserToken(token);
      }
      if (userCredential.user?.uid != null) {
        await StorageHelper.storeUserId(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up new user
  Future<UserCredential?> signup({required String email, required String password, required String name}) async {
    try {
      // Check if user already exists
      final DatabaseService _db = DatabaseService();
      final existingUser = await _db.getUserByEmail(email);
      
      if (existingUser != null) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
      }

      // Create new Firebase auth user
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get token and store user data
      final String? token = await userCredential.user?.getIdToken();
      if (token != null) {
        await StorageHelper.storeUserToken(token);
      }
      if (userCredential.user?.uid != null) {
        await StorageHelper.storeUserId(userCredential.user!.uid);
      }

      // Create and store user in Firestore
      final newUser = {
        'id': userCredential.user!.uid,
        'name': name,
        'email': email,
      };
      await _db.addUser(newUser);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await StorageHelper.deleteUserData();
    } catch (e) {
      rethrow;
    }
  }
}
