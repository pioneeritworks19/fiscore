part of '../main.dart';

class AuthService {
  static const String _hostedEmailLinkUrl =
      'https://fiscore-dev.firebaseapp.com';

  Stream<User?> authStateChanges() {
    return FirebaseAuth.instance.authStateChanges();
  }

  bool isEmailSignInLink(String link) {
    return FirebaseAuth.instance.isSignInWithEmailLink(link);
  }

  Future<void> sendEmailSignInLink(String email) async {
    // TODO: Before native mobile testing/release, configure a hosted FiScore
    // auth return domain plus Android App Links/iOS Universal Links, and handle
    // incoming email sign-in links inside the installed app. Chrome testing
    // currently completes this flow through the browser origin.
    final continueUrl = kIsWeb
        ? '${Uri.base.scheme}://${Uri.base.authority}'
        : _hostedEmailLinkUrl;
    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email.trim().toLowerCase(),
      actionCodeSettings: ActionCodeSettings(
        url: continueUrl,
        handleCodeInApp: true,
        androidPackageName: 'com.pioneeritworks.fiscore.dev',
        androidInstallApp: true,
        iOSBundleId: 'com.pioneeritworks.fiscore.dev',
      ),
    );
  }

  Future<void> completeEmailSignIn({
    required String email,
    required String emailLink,
  }) async {
    await FirebaseAuth.instance.signInWithEmailLink(
      email: email.trim().toLowerCase(),
      emailLink: emailLink,
    );
  }

  Future<void> signInWithGoogle() async {
    // TODO: Configure the Google OAuth consent screen/custom auth domain so
    // users see "FiScore" (and the production FiScore domain) instead of
    // "fiscore-dev.firebaseapp.com" during Google sign-in.
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      return;
    }

    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();
    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Google did not return an ID token for Firebase sign-in.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }
}
