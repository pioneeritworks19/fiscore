part of '../../main.dart';

class _SiteSetupContent extends StatelessWidget {
  const _SiteSetupContent({
    required this.tenantId,
    required this.searchController,
    required this.isSearching,
    required this.isLinking,
    required this.linkingRestaurantId,
    required this.results,
    required this.message,
    required this.error,
    required this.onSearch,
    required this.onCancel,
    required this.onLinkRestaurant,
  });

  final String tenantId;
  final TextEditingController searchController;
  final bool isSearching;
  final bool isLinking;
  final String? linkingRestaurantId;
  final List<Map<String, dynamic>> results;
  final String? message;
  final String? error;
  final VoidCallback onSearch;
  final VoidCallback? onCancel;
  final void Function(String masterRestaurantId, String restaurantName)
      onLinkRestaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAddingAnotherSite = onCancel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                isAddingAnotherSite
                    ? 'Add another restaurant'
                    : 'Find your first restaurant',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            if (onCancel != null)
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          isAddingAnotherSite
              ? 'Search the master restaurant database, link the right location, or cancel to return to your current restaurant.'
              : 'Search the FiScore master restaurant database loaded through ingestion, then link the correct restaurant to this workspace.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        _GuidancePanel(
          icon: Icons.manage_search_outlined,
          text:
              'Start with restaurant name, city, ZIP code, or license number. Manual entry should only be used later when the restaurant is not in the master data yet.',
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final searchField = TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search master restaurants',
                hintText: 'Example: diner, 48104, Ann Arbor, or license number',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onSearch(),
            );
            final searchButton = FilledButton.icon(
              onPressed: isSearching ? null : onSearch,
              icon: isSearching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Search'),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  searchButton,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: searchButton,
                ),
              ],
            );
          },
        ),
        if (message != null) ...[
          const SizedBox(height: 18),
          _StatusMessage(
            icon: Icons.check_circle_outline,
            color: colorScheme.primary,
            text: message!,
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 18),
          _StatusMessage(
            icon: Icons.error_outline,
            color: colorScheme.error,
            text: error!,
          ),
        ],
        if (results.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            'Search results',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...results.map(
            (restaurant) => _RestaurantResultTile(
              restaurant: restaurant,
              isLinking: isLinking &&
                  linkingRestaurantId == restaurant['masterRestaurantId'],
              isDisabled: isLinking,
              onLink: () => onLinkRestaurant(
                restaurant['masterRestaurantId'] as String,
                restaurant['displayName'] as String? ?? 'Restaurant',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Workspace ID: $tenantId',
          style: theme.textTheme.bodySmall?.copyWith(
          color: _muted,
          ),
        ),
      ],
    );
  }
}

