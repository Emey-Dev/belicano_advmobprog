import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user_model.dart';

enum LoginType { dummyJson, firebase }

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      await _saveLoginType(LoginType.dummyJson);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setInt('age', (userData['age'] as num?)?.toInt() ?? 0);
    await prefs.setString('phone', userData['phone'] as String? ?? '');

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'loginType': prefs.getString('loginType') ?? LoginType.dummyJson.name,
    };
  }

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') == LoginType.firebase.name
        ? LoginType.firebase
        : LoginType.dummyJson;
  }

  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  Future<bool> isLoggedIn() async {
    if (firebaseAuth.currentUser != null) {
      try {
        await refreshToken();
      } catch (_) {}
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  final firebase_auth.FirebaseAuth firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  firebase_auth.User? get currentUser => firebaseAuth.currentUser;

  Stream<firebase_auth.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseUser(credential.user);
    await _restoreFirestoreProfile(credential.user);
    return credential;
  }

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseUser(credential.user);
    return credential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Updates the profile source used by the profile screen immediately.
  Future<void> updateUsername({required String username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);

    final firebaseUser = currentUser;
    if (firebaseUser == null) return;

    await _syncUsernameToFirestore(firebaseUser.uid, username);
  }

  Future<void> _syncUsernameToFirestore(String uid, String username) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> refreshToken() async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) return null;
    final token = await firebaseUser.getIdToken(true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token ?? '');
    await prefs.setString('accessToken', token ?? '');
    return token;
  }

  Future<void> saveProfileData({
    required String firstName,
    required String lastName,
    required int age,
    required String phone,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setInt('age', age);
    await prefs.setString('phone', phone);
    await prefs.setString('username', username);

    final firebaseUser = currentUser;
    if (firebaseUser != null) {
      await _upsertFirestoreUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: username,
        firstName: firstName,
        lastName: lastName,
        age: age,
        phone: phone,
      );
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) throw Exception('No Firebase user is signed in.');
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await firebaseUser.reauthenticateWithCredential(credential);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .delete();
    await firebaseUser.delete();
    await signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) throw Exception('No Firebase user is signed in.');
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await firebaseUser.reauthenticateWithCredential(credential);
    await firebaseUser.updatePassword(newPassword);
    await _saveFirebaseUser(firebaseUser);
  }

  Future<void> _upsertFirestoreUser({
    required String uid,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required int age,
    required String phone,
  }) async {
    if (uid.isEmpty) return;

    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    await doc.set({
      'uid': uid,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
      'loginType': LoginType.firebase.name,
    }, SetOptions(merge: true));
  }

  Future<void> _restoreFirestoreProfile(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (!snapshot.exists) return;

    final profile = snapshot.data()!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'username',
      profile['username'] as String? ?? firebaseUser.displayName ?? '',
    );
    await prefs.setString('firstName', profile['firstName'] as String? ?? '');
    await prefs.setString('lastName', profile['lastName'] as String? ?? '');
    await prefs.setInt('age', (profile['age'] as num?)?.toInt() ?? 0);
    await prefs.setString('phone', profile['phone'] as String? ?? '');
  }

  static String messageForError(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'The email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already uses this email address.';
        case 'weak-password':
          return 'Choose a stronger password with at least 6 characters.';
        case 'requires-recent-login':
          return 'For security, sign in again before making this change.';
        case 'network-request-failed':
          return 'No internet connection. Please try again.';
      }
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'You do not have permission to update this profile.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _saveLoginType(LoginType loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', loginType.name);
  }

  Future<void> _saveFirebaseUser(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) return;
    final token = await firebaseUser.getIdToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', firebaseUser.email ?? '');
    await prefs.setString('username', firebaseUser.displayName ?? '');
    await prefs.setString('token', token ?? '');
    await prefs.setString('accessToken', token ?? '');
    await _saveLoginType(LoginType.firebase);
  }
}
