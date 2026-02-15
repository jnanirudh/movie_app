import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up / Sign in
  Future<User?> signIn(String phone, String password) async {
    try {
      // Firebase prefers email; we'll format your phone number as one
      String email = "$phone@movieapp.com";
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // If user doesn't exist, try to create them (Sign Up)
      if (e.code == 'user-not-found') {
        UserCredential result = await _auth.createUserWithEmailAndPassword(
            email: "$phone@movieapp.com",
            password: password
        );
        return result.user;
      }
      rethrow;
    }
  }
}