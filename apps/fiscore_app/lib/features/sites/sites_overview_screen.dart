part of '../../main.dart';

class _SitesOverviewContent extends StatelessWidget {
  const _SitesOverviewContent({
    required this.sites,
    required this.onOpenSite,
    required this.onAddSite,
    required this.canAddSite,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> sites;
  final ValueChanged<String> onOpenSite;
  final VoidCallback onAddSite;
  final bool canAddSite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sites',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          sites.length == 1
              ? 'You have one active site. Open it for daily work, or add another site when this restaurant group grows.'
              : 'Scan your restaurant portfolio, then open one site at a time for inspections, violations, audits, and team work.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        ...sites.map((siteDoc) {
          final site = siteDoc.data();
          final name = site['name'] as String? ?? 'Restaurant';
          final address = _formatSiteAddress(site);
          final latestInspectionDate =
              site['latestInspectionDateSnapshot'] as String?;
          final openViolations =
              (site['openViolationCountSnapshot'] as num?)?.toInt() ?? 0;
          final pendingReview =
              (site['pendingReviewCountSnapshot'] as num?)?.toInt() ?? 0;
          final isLinkedToMaster =
              site['linkStatus'] == 'linked' ||
              site['masterLinkStatus'] == 'linked_to_master' ||
              site['masterRestaurantId'] != null;
          return InkWell(
            onTap: () => onOpenSite(siteDoc.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A071A4A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        child: const Icon(
                          Icons.restaurant_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                address,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: _muted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              !isLinkedToMaster
                                  ? 'Manually added - ready for internal checks'
                                  : latestInspectionDate == null
                                  ? 'No public inspections imported yet'
                                  : '$openViolations open - $pendingReview review - latest $latestInspectionDate',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (latestInspectionDate != null)
                        Text(
                          site['latestInspectionGradeSnapshot'] as String? ??
                              '',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: _green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenSite(siteDoc.id),
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: const Text('Open site'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (canAddSite) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAddSite,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Add site'),
          ),
        ],
      ],
    );
  }
}
