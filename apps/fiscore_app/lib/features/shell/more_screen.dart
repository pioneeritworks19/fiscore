part of '../../main.dart';

class _MoreContent extends StatelessWidget {
  const _MoreContent({
    required this.onAddSite,
  });

  final VoidCallback onAddSite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Lower-frequency workspace and restaurant management actions live here.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        _ActionRow(
          icon: Icons.add_business_outlined,
          title: 'Add another restaurant',
          body:
              'Search the master restaurant database and link another site to this workspace.',
          enabled: true,
          onTap: onAddSite,
        ),
        const _ActionRow(
          icon: Icons.groups_outlined,
          title: 'Team management',
          body: 'Invite staff and assign role-based access after the core dashboard is stable.',
          enabled: false,
        ),
        const _ActionRow(
          icon: Icons.settings_outlined,
          title: 'Workspace settings',
          body: 'Billing, tenant configuration, and site settings will be added in a later slice.',
          enabled: false,
        ),
      ],
    );
  }
}

