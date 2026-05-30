part of '../../main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isSigningIn = false;
  bool _isEmailSending = false;
  bool _showEmailSignIn = false;
  bool _hasSentEmailLink = false;
  String? _sentEmail;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = error.message ?? error.code;
      });
    } on GoogleSignInException catch (error) {
      setState(() {
        _errorMessage = error.description ?? error.code.name;
      });
    } catch (error) {
      setState(() {
        _errorMessage = strings.requestFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _sendEmailLink() async {
    final strings = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = strings.checkInformationAndTryAgain;
      });
      return;
    }

    setState(() {
      _isEmailSending = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendEmailSignInLink(email);
      if (!mounted) return;
      setState(() {
        _hasSentEmailLink = true;
        _sentEmail = email;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? error.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = strings.requestFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
      }
    }
  }

  void _returnToSignIn() {
    setState(() {
      _showEmailSignIn = false;
      _hasSentEmailLink = false;
      _sentEmail = null;
      _emailController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact =
                constraints.maxHeight < 680 ||
                MediaQuery.viewInsetsOf(context).bottom > 0;
            final verticalPadding = isCompact ? 16.0 : 24.0;
            final minimumHeight = isCompact
                ? 0.0
                : constraints.maxHeight - (verticalPadding * 2);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimumHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_showEmailSignIn) ...[
                          const Center(child: FiScoreAuthBrand(width: 370)),
                          const SizedBox(height: 20),
                          Text(
                            strings.signInIntro,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: _isSigningIn || _isEmailSending
                                ? null
                                : _signInWithGoogle,
                            icon: _isSigningIn
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(strings.continueWithGoogle),
                          ),
                          const SizedBox(height: 12),
                          // TODO: Enable Apple sign-in after Apple Developer and
                          // Firebase provider configuration is completed.
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.apple),
                            label: Text(strings.continueWithApple),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  strings.or,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _muted,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _isSigningIn || _isEmailSending
                                ? null
                                : () {
                                    setState(() {
                                      _showEmailSignIn = true;
                                      _hasSentEmailLink = false;
                                      _sentEmail = null;
                                      _errorMessage = null;
                                    });
                                  },
                            icon: const Icon(Icons.mail_outline),
                            label: Text(strings.continueWithEmail),
                          ),
                        ] else if (_hasSentEmailLink) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _isEmailSending
                                  ? null
                                  : _returnToSignIn,
                              child: Text(strings.cancel),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(child: FiScoreAuthBrand(width: 285)),
                          const SizedBox(height: 30),
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 44,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            strings.checkYourEmail,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            strings.secureLinkSentTo,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sentEmail ?? '',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.openLinkOnDevice,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 32),
                          OutlinedButton(
                            onPressed: _isEmailSending ? null : _sendEmailLink,
                            child: _isEmailSending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.resendLink),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _isEmailSending
                                ? null
                                : () {
                                    setState(() {
                                      _hasSentEmailLink = false;
                                      _sentEmail = null;
                                      _emailController.clear();
                                      _errorMessage = null;
                                    });
                                  },
                            child: Text(strings.useDifferentEmail),
                          ),
                        ] else ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isEmailSending
                                  ? null
                                  : _returnToSignIn,
                              icon: const Icon(Icons.chevron_left),
                              label: Text(strings.back),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(child: FiScoreAuthBrand(width: 285)),
                          const SizedBox(height: 30),
                          Text(
                            strings.signInWithEmail,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.emailSignInHelp,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _muted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 26),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _sendEmailLink(),
                            decoration: InputDecoration(
                              labelText: strings.emailAddress,
                              hintText: strings.emailAddressHint,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _isSigningIn || _isEmailSending
                                ? null
                                : _sendEmailLink,
                            icon: _isEmailSending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.mail_outline),
                            label: Text(strings.emailMeSignInLink),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
