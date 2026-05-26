part of '../../main.dart';

class _MoreContent extends StatelessWidget {
  const _MoreContent({
    required this.onAddSite,
    required this.onManageTeam,
    required this.isSyncingMasterData,
    required this.message,
    required this.error,
    this.onRefreshMasterData,
  });

  final VoidCallback onAddSite;
  final VoidCallback? onManageTeam;
  final bool isSyncingMasterData;
  final String? message;
  final String? error;
  final VoidCallback? onRefreshMasterData;

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
        if (message != null) ...[
          _StatusMessage(
            icon: Icons.check_circle_outline,
            color: _green,
            text: message!,
          ),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: error!,
          ),
          const SizedBox(height: 12),
        ],
        if (onRefreshMasterData != null)
          _ActionRow(
            icon: Icons.sync_outlined,
            title: isSyncingMasterData
                ? 'Refreshing public inspection data...'
                : 'Refresh public inspection data',
            body:
                'Pull the latest available public inspection history and findings into this location.',
            enabled: !isSyncingMasterData,
            onTap: isSyncingMasterData ? null : onRefreshMasterData,
          ),
        _ActionRow(
          icon: Icons.add_business_outlined,
          title: 'Add another restaurant',
          body:
              'Search the master restaurant database and link another site to this workspace.',
          enabled: true,
          onTap: onAddSite,
        ),
        _ActionRow(
          icon: Icons.groups_outlined,
          title: 'Team management',
          body: onManageTeam == null
              ? 'Workspace owners and admins manage team access.'
              : 'Invite staff, assign roles, and control site access.',
          enabled: onManageTeam != null,
          onTap: onManageTeam,
        ),
        const _ActionRow(
          icon: Icons.settings_outlined,
          title: 'Workspace settings',
          body:
              'Billing, tenant configuration, and site settings will be added in a later slice.',
          enabled: false,
        ),
      ],
    );
  }
}
