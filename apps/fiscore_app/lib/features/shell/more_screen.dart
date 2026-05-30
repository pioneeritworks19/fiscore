part of '../../main.dart';

class _MoreContent extends StatelessWidget {
  const _MoreContent({
    required this.onAddSite,
    required this.canAddSite,
    required this.onOpenProfile,
    required this.onManageTeam,
    required this.isSyncingMasterData,
    required this.message,
    required this.error,
    this.onRefreshMasterData,
  });

  final VoidCallback onAddSite;
  final bool canAddSite;
  final VoidCallback onOpenProfile;
  final VoidCallback? onManageTeam;
  final bool isSyncingMasterData;
  final String? message;
  final String? error;
  final VoidCallback? onRefreshMasterData;

  Future<void> _confirmRefreshPublicData(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final shouldRefresh = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.refreshPublicInspectionQuestion),
        content: Text(strings.refreshPublicInspectionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.refresh),
          ),
        ],
      ),
    );
    if (shouldRefresh == true) {
      onRefreshMasterData?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.more,
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
                : strings.refreshPublicInspectionData,
            body:
                'Pull the latest available public inspection history and findings into this location.',
            enabled: !isSyncingMasterData,
            trailingIcon: Icons.sync_outlined,
            onTap: isSyncingMasterData
                ? null
                : () => _confirmRefreshPublicData(context),
          ),
        if (canAddSite)
          _ActionRow(
            icon: Icons.add_business_outlined,
            title: 'Add another restaurant',
            body:
                'Search the master restaurant database and link another site to this workspace.',
            enabled: true,
            onTap: onAddSite,
          ),
        _ActionRow(
          icon: Icons.person_outline,
          title: 'Profile & preferences',
          body: 'Choose your language and review account details.',
          enabled: true,
          onTap: onOpenProfile,
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
