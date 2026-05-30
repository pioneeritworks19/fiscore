part of '../../main.dart';

Future<void> showProfilePreferencesSheet(
  BuildContext context, {
  required User user,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProfilePreferencesSheet(user: user),
  );
}

class _ProfilePreferencesSheet extends StatelessWidget {
  const _ProfilePreferencesSheet({required this.user});

  final User user;

  Future<void> _saveLanguage(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final strings = AppLocalizations.of(context);
    try {
      await FirestorePaths.user(user.uid).set({
        'languagePreference': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (navigator.mounted) navigator.pop();
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.requestFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final displayName = user.displayName ?? user.email ?? 'FiScore user';
    final email = user.email ?? '';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirestorePaths.user(user.uid).snapshots(),
          builder: (context, snapshot) {
            final preference =
                snapshot.data?.data()?['languagePreference'] as String? ??
                'system';
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.profileAndPreferences,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  strings.language,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.languagePreferenceHelp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _LanguageOptionTile(
                  title: strings.useDeviceLanguage,
                  subtitle: strings.deviceLanguageDescription,
                  value: 'system',
                  groupValue: preference,
                  onChanged: (value) => _saveLanguage(context, value),
                ),
                _LanguageOptionTile(
                  title: 'English',
                  subtitle: strings.englishDescription,
                  value: 'en',
                  groupValue: preference,
                  onChanged: (value) => _saveLanguage(context, value),
                ),
                _LanguageOptionTile(
                  title: 'Español',
                  subtitle: strings.spanishDescription,
                  value: 'es',
                  groupValue: preference,
                  onChanged: (value) => _saveLanguage(context, value),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: selected ? null : () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _navy : _muted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
