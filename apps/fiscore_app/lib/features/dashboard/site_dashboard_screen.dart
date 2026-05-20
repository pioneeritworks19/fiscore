part of '../../main.dart';

class _SiteDashboardContent extends StatelessWidget {
  const _SiteDashboardContent({
    required this.siteId,
    required this.site,
    required this.siteCount,
    required this.isSyncingMasterData,
    required this.syncMessage,
    required this.syncError,
    required this.onSyncMasterData,
    required this.onAddSite,
  });

  final String siteId;
  final Map<String, dynamic> site;
  final int siteCount;
  final bool isSyncingMasterData;
  final String? syncMessage;
  final String? syncError;
  final VoidCallback onSyncMasterData;
  final VoidCallback onAddSite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLinked = site['linkStatus'] == 'linked' ||
        site['masterLinkStatus'] == 'linked_to_master' ||
        site['masterRestaurantId'] != null;
    final inspectionCount = site['inspectionCountSnapshot'] ?? 0;
    final latestInspectionDate = site['latestInspectionDateSnapshot'] as String?;
    final openViolationCount =
        (site['openViolationCountSnapshot'] as num?)?.toInt() ?? 0;
    final pendingReviewCount =
        (site['pendingReviewCountSnapshot'] as num?)?.toInt() ?? 0;
    final isSingleSiteTenant = siteCount == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 720 ? 2 : 4;
            final tiles = [
              _MetricTile(
                label: 'Public inspections',
                value: inspectionCount.toString(),
                helper: 'From master data',
                icon: Icons.fact_check_outlined,
                accentColor: const Color(0xFF1D4ED8),
              ),
              _MetricTile(
                label: 'Latest inspection',
                value: latestInspectionDate ?? 'Not available',
                helper: latestInspectionDate == null
                    ? 'No public inspection yet'
                    : 'County health dept.',
                icon: Icons.event_available_outlined,
                accentColor: _green,
              ),
              _MetricTile(
                label: 'Open violations',
                value: openViolationCount.toString(),
                helper: openViolationCount == 0
                    ? 'None copied yet'
                    : 'From latest findings',
                icon: Icons.report_problem_outlined,
                accentColor: const Color(0xFFDC2626),
              ),
              _MetricTile(
                label: 'Pending review',
                value: pendingReviewCount.toString(),
                helper: 'Manager queue',
                icon: Icons.groups_2_outlined,
                accentColor: const Color(0xFFF59E0B),
              ),
            ];

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: columns == 2 ? 1.48 : 1.55,
              children: tiles,
            );
          },
        ),
        const SizedBox(height: 18),
        _DashboardSection(
          title: 'Attention',
          trailing: openViolationCount == 0 ? 'Clear' : 'View queue',
          children: [
            if (openViolationCount == 0)
              _ActionRow(
                icon: Icons.check_circle_outline,
                title: isLinked
                    ? 'No active public findings yet'
                    : 'Ready for internal tracking',
                body: isLinked
                    ? 'Latest inspection findings appear here as open work after master-data refresh.'
                    : 'Manual sites can create issues from audits or direct entry when work begins.',
                enabled: false,
                toneColor: _green,
              )
            else
              _ActionRow(
                icon: Icons.warning_amber_rounded,
                title: '$openViolationCount open findings need response',
                body:
                    'Assign ownership, capture corrective action, and submit completed work for review.',
                enabled: true,
                toneColor: const Color(0xFFDC2626),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _DashboardSection(
          title: 'Next best actions',
          trailing: 'Plan',
          children: [
            _ActionRow(
              icon: Icons.sync,
              title: isSyncingMasterData
                  ? 'Refreshing master data'
                  : 'Refresh from master data',
              body:
                  'Pull the latest public inspections and violation findings into this site.',
              enabled: isLinked && !isSyncingMasterData,
              toneColor: const Color(0xFF1D4ED8),
              onTap: isLinked && !isSyncingMasterData ? onSyncMasterData : null,
            ),
            _ActionRow(
              icon: Icons.manage_search_outlined,
              title: latestInspectionDate == null
                  ? 'Import public inspection history'
                  : 'Review latest public inspection',
              body: latestInspectionDate == null
                  ? 'Inspection detail is not available yet for this site.'
                  : 'Confirm latest findings, then work only the items that need response.',
              enabled: latestInspectionDate != null,
              toneColor: _green,
            ),
            _ActionRow(
              icon: Icons.playlist_add_check_circle_outlined,
              title: 'Start first internal audit',
              body:
                  'Run a site checklist and create tenant-owned findings from failed items.',
              enabled: false,
              toneColor: const Color(0xFF1D4ED8),
            ),
          ],
        ),
        if (syncMessage != null) ...[
          const SizedBox(height: 14),
          _StatusMessage(
            icon: Icons.check_circle_outline,
            color: _green,
            text: syncMessage!,
          ),
        ],
        if (syncError != null) ...[
          const SizedBox(height: 14),
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: syncError!,
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Start audit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddSite,
                icon: const Icon(Icons.add_business_outlined),
                label: Text(isSingleSiteTenant ? 'Add second site' : 'Add site'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Site ID: $siteId',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _muted,
          ),
        ),
      ],
    );
  }
}

