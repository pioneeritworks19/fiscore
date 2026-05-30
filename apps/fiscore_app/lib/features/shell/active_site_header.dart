part of '../../main.dart';

class _ActiveSiteHeader extends StatelessWidget {
  const _ActiveSiteHeader({
    required this.site,
    required this.showBackToSites,
    required this.onShowSites,
  });

  final Map<String, dynamic> site;
  final bool showBackToSites;
  final VoidCallback? onShowSites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final name = site['name'] as String? ?? strings.restaurant;
    final address = _formatSiteAddress(site);
    final isLinked =
        site['linkStatus'] == 'linked' ||
        site['masterLinkStatus'] == 'linked_to_master' ||
        site['masterRestaurantId'] != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF102762)],
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          if (showBackToSites && onShowSites != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              tooltip: strings.backToSites,
              onPressed: onShowSites,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (isLinked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified_outlined,
                        color: Color(0xFF83E6A7),
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Linked',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFBDF3CF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address.isEmpty ? 'Site workspace' : address,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD5DEF2),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
