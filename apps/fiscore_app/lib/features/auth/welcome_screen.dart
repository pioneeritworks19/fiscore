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
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSigningIn = true;
      _message = null;
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
        _errorMessage = 'Sign-in failed. Please try again.';
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
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email address.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isEmailSending = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      await _authService.sendEmailSignInLink(email);
      if (!mounted) return;
      setState(() {
        _message = 'Check your email for a secure FiScore sign-in link.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? error.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not send sign-in link. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isEmailSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: FiScoreLogoLockup(markSize: 92),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Review inspections, run audits, and manage food safety work from one place.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _muted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed:
                        _isSigningIn || _isEmailSending ? null : _signInWithGoogle,
                    icon: _isSigningIn
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _muted,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendEmailLink(),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        _isSigningIn || _isEmailSending ? null : _sendEmailLink,
                    icon: _isEmailSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mail_outline),
                    label: const Text('Continue with email'),
                  ),
                  const SizedBox(height: 12),
                  // TODO: Enable Apple sign-in after Apple Developer and
                  // Firebase provider configuration is completed.
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.apple),
                    label: const Text('Continue with Apple'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Apple sign-in coming later.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    _StatusMessage(
                      icon: Icons.check_circle_outline,
                      color: _green,
                      text: _message!,
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
      ),
    );
  }
}

