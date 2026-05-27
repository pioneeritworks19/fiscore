part of '../../main.dart';

class _FiScoreSetupScaffold extends StatelessWidget {
  const _FiScoreSetupScaffold({
    required this.child,
    required this.user,
    required this.onSignOut,
  });

  final Widget child;
  final User user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user.displayName ?? 'FiScore user';
    final email = user.email ?? '';
    final photoUrl = user.photoURL?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final initialSource = (displayName.isNotEmpty ? displayName : email).trim();
    final initial = initialSource.isEmpty
        ? 'F'
        : initialSource.substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const FiScoreHeaderBrand(),
                      const Spacer(),
                      PopupMenuButton<String>(
                        tooltip: 'Account',
                        position: PopupMenuPosition.under,
                        offset: const Offset(0, 8),
                        onSelected: (value) {
                          if (value == 'sign_out') {
                            onSignOut();
                          } else if (value == 'profile') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile settings are coming soon.',
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.person_outline),
                              title: Text('Profile'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'sign_out',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.logout),
                              title: Text('Sign out'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _softGreen,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: const Color(0xFFCFEBDD)),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _softGreen,
                            foregroundImage: hasPhoto
                                ? NetworkImage(photoUrl)
                                : null,
                            onForegroundImageError: hasPhoto
                                ? (exception, stackTrace) {
                                    // Keep the initial visible when the
                                    // identity provider photo is unavailable.
                                  }
                                : null,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
