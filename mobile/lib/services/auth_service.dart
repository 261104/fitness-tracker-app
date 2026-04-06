import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? google})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = google ?? GoogleSignIn(scopes: ['email']);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  Future<UserCredential?> signInWithGoogle() async {
    final acc = await _google.signIn();
    if (acc == null) return null;
    final ga = await acc.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: ga.accessToken,
      idToken: ga.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait<void>([
      _google.signOut(),
      _auth.signOut(),
    ]);
  }
}
