part of '../main.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return _FiScoreMaterialApp(locale: null);
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestorePaths.user(user.uid).snapshots(),
          builder: (context, profileSnapshot) {
            return _FiScoreMaterialApp(
              locale: _localeFromPreference(
                profileSnapshot.data?.data()?['languagePreference'] as String?,
              ),
            );
          },
        );
      },
    );
  }
}

Locale? _localeFromPreference(String? preference) {
  return switch (preference) {
    'en' => const Locale('en'),
    'es' => const Locale('es'),
    _ => null,
  };
}

class _FiScoreMaterialApp extends StatelessWidget {
  const _FiScoreMaterialApp({required this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FiScore',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _navy,
          primary: _navy,
          secondary: _green,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _page,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _navy,
            minimumSize: const Size(0, 46),
            side: const BorderSide(color: Color(0xFFCFD8E6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          alignLabelWithHint: true,
          labelStyle: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: _muted.withValues(alpha: 0.66),
            height: 1.35,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _navy, width: 1.4),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
