part of '../../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: FiScoreLogoLockup(markSize: 72),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const WelcomeScreen();
        }

        return SignedInHomeScreen(user: user);
      },
    );
  }
}

