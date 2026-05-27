part of '../../main.dart';

class _EmailLinkCompletionScreen extends StatefulWidget {
  const _EmailLinkCompletionScreen({required this.emailLink});

  final String emailLink;

  @override
  State<_EmailLinkCompletionScreen> createState() =>
      _EmailLinkCompletionScreenState();
}

class _EmailLinkCompletionScreenState
    extends State<_EmailLinkCompletionScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isSigningIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _completeSignIn() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter the email address that received this link.';
      });
      return;
    }

    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      await _authService.completeEmailSignIn(
        email: email,
        emailLink: widget.emailLink,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            error.message ??
            'This link could not be used. Request a new sign-in email.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'This link could not be used. Request a new sign-in email.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
                        const Center(child: FiScoreAuthBrand(width: 285)),
                        const SizedBox(height: 30),
                        Text(
                          'Confirm your email',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'For security, enter the email address that received this sign-in link.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _completeSignIn(),
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'name@example.com',
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _isSigningIn ? null : _completeSignIn,
                          child: _isSigningIn
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Continue'),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
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
