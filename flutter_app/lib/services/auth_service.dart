import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registers a new student in Firebase Auth and saves their profile to Firestore
  Future<UserCredential> registerStudent({
    required String email,
    required String username,
    required String carnet,
    required String password,
  }) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email.trim().toLowerCase(),
        'username': username.trim(),
        'carnet': carnet.trim(),
        'rol': 'estudiante',
        'estadoActivo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  /// Signs in a user using an email or carnet with password
  Future<UserCredential> loginUser({
    required String accountIdentifier,
    required String password,
  }) async {
    String emailToUse = accountIdentifier.trim();

    // If identifier is numeric (carnet), retrieve corresponding email from Firestore
    if (RegExp(r'^[0-9]+$').hasMatch(emailToUse)) {
      final QuerySnapshot query = await _firestore
          .collection('users')
          .where('carnet', isEqualTo: emailToUse)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No se encontró ningún usuario con ese carnet.',
        );
      }
      emailToUse = query.docs.first.get('email') as String;
    }

    return await _auth.signInWithEmailAndPassword(
      email: emailToUse,
      password: password,
    );
  }

  /// Signs out current session
  Future<void> signOut() async {
    await _auth.signOut();
  }
}