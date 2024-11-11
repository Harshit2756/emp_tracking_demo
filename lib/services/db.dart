import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String usersCollection = 'users';

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final QuerySnapshot querySnapshot = await _db.collection(usersCollection).get();
      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Get single user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot querySnapshot = await _db
          .collection(usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Get single user by id
  Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      final DocumentSnapshot documentSnapshot = await _db
          .collection(usersCollection)
          .doc(id)
          .get();

      if (!documentSnapshot.exists) {
        return null;
      }

      return documentSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // Add user
  Future<void> addUser(Map<String, dynamic> user) async {
    try {
      await _db.collection(usersCollection).doc(user['id']).set(user);
    } catch (e) {
      rethrow;
    }
  }

  // Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _db.collection(usersCollection).doc(userId).update(userData);
    } catch (e) {
      rethrow;
    }
  }
}
