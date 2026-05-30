part of '../../main.dart';

class _RestaurantResultTile extends StatelessWidget {
  const _RestaurantResultTile({
    required this.restaurant,
    required this.isLinking,
    required this.isDisabled,
    required this.onLink,
  });

  final Map<String, dynamic> restaurant;
  final bool isLinking;
  final bool isDisabled;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    final displayName =
        restaurant['displayName'] as String? ?? strings.restaurant;
    final addressLine1 = restaurant['addressLine1'] as String? ?? '';
    final city = restaurant['city'] as String? ?? '';
    final stateCode = restaurant['stateCode'] as String? ?? '';
    final zipCode = restaurant['zipCode'] as String? ?? '';
    final inspectionCount = restaurant['inspectionCount'] ?? 0;
    final latestInspectionDate = restaurant['latestInspectionDate'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_outlined, color: _navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    addressLine1,
                    [
                      city,
                      stateCode,
                      zipCode,
                    ].where((part) => part.trim().isNotEmpty).join(' '),
                  ].where((part) => part.trim().isNotEmpty).join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
                ),
                const SizedBox(height: 8),
                Text(
                  latestInspectionDate == null
                      ? strings.inspectionCount(inspectionCount)
                      : strings.inspectionCountLatest(
                          inspectionCount,
                          latestInspectionDate,
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: isDisabled ? null : onLink,
            child: isLinking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(strings.link),
          ),
        ],
      ),
    );
  }
}
