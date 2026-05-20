part of '../../main.dart';

class _FiScoreAppScaffold extends StatelessWidget {
  const _FiScoreAppScaffold({
    required this.user,
    required this.activeSite,
    required this.siteCount,
    required this.onShowSites,
    required this.showBottomNavigation,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    required this.onSignOut,
    required this.child,
  });

  final User user;
  final Map<String, dynamic>? activeSite;
  final int siteCount;
  final VoidCallback? onShowSites;
  final bool showBottomNavigation;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final VoidCallback onSignOut;
  final Widget child;

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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: _line),
                ),
              ),
              child: Row(
                children: [
                  const FiScoreLogoMark(size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'FiScore',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                            content: Text('Profile settings are coming soon.'),
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
                    child: Padding(
                      padding: const EdgeInsets.all(2),
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
                          foregroundImage:
                              hasPhoto ? NetworkImage(photoUrl) : null,
                          onForegroundImageError: hasPhoto
                              ? (exception, stackTrace) {
                                  // Keep the initial visible if the identity
                                  // provider photo cannot be loaded.
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
                  ),
                ],
              ),
            ),
            if (showBottomNavigation && activeSite != null)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _page,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x10071A4A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: _ActiveSiteHeader(
                  site: activeSite!,
                  showBackToSites: selectedIndex == 1 && onShowSites != null,
                  onShowSites: onShowSites,
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [child],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNavigation
          ? _FiScoreBottomNav(
              siteCount: siteCount,
              selectedIndex: selectedIndex,
              onSelectedIndexChanged: onSelectedIndexChanged,
            )
          : null,
    );
  }
}

