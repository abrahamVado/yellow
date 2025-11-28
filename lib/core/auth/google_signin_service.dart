import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn;

  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
              ],
            );

  Future<GoogleSignInAccount?> signIn() async {
    final account = await _googleSignIn.signIn();
    return account;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
