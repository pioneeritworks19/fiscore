part of '../../main.dart';

class _SiteSetupContent extends StatelessWidget {
  const _SiteSetupContent({
    required this.searchController,
    required this.isSearching,
    required this.isLinking,
    required this.isCreatingManualSite,
    required this.isEnteringManualSite,
    required this.linkingRestaurantId,
    required this.results,
    required this.hasCompletedSearch,
    required this.message,
    required this.error,
    required this.manualSiteNameController,
    required this.manualAddressController,
    required this.manualCityController,
    required this.manualStateController,
    required this.manualPostalCodeController,
    required this.onSearch,
    required this.onShowManualEntry,
    required this.onHideManualEntry,
    required this.onCreateManualSite,
    required this.onCancel,
    required this.onLinkRestaurant,
  });

  final TextEditingController searchController;
  final bool isSearching;
  final bool isLinking;
  final bool isCreatingManualSite;
  final bool isEnteringManualSite;
  final String? linkingRestaurantId;
  final List<Map<String, dynamic>> results;
  final bool hasCompletedSearch;
  final String? message;
  final String? error;
  final TextEditingController manualSiteNameController;
  final TextEditingController manualAddressController;
  final TextEditingController manualCityController;
  final TextEditingController manualStateController;
  final TextEditingController manualPostalCodeController;
  final VoidCallback onSearch;
  final VoidCallback onShowManualEntry;
  final VoidCallback onHideManualEntry;
  final VoidCallback onCreateManualSite;
  final VoidCallback? onCancel;
  final void Function(String masterRestaurantId, String restaurantName)
  onLinkRestaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = isEnteringManualSite
        ? 'Add restaurant manually'
        : 'Add restaurant';
    final subtitle = isEnteringManualSite
        ? 'Enter the restaurant location to start running internal checks.'
        : 'Find your restaurant to bring in public inspection history.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            if (onCancel != null)
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        if (!isEnteringManualSite) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final searchField = TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Restaurant name, city, or ZIP',
                  hintText: 'Search public restaurant records',
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
                isLinking:
                    isLinking &&
                    linkingRestaurantId == restaurant['masterRestaurantId'],
                isDisabled: isLinking,
                onLink: () => onLinkRestaurant(
                  restaurant['masterRestaurantId'] as String,
                  restaurant['displayName'] as String? ?? 'Restaurant',
                ),
              ),
            ),
          ],
          if (hasCompletedSearch && results.isEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'No matching restaurants found. Try another search or add this location manually.',
              style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
            ),
          ],
          const SizedBox(height: 22),
          TextButton.icon(
            onPressed: isLinking || isSearching ? null : onShowManualEntry,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Add restaurant manually'),
          ),
        ] else ...[
          if (error != null) ...[
            _StatusMessage(
              icon: Icons.error_outline,
              color: colorScheme.error,
              text: error!,
            ),
            const SizedBox(height: 18),
          ],
          _ManualSiteForm(
            siteNameController: manualSiteNameController,
            addressController: manualAddressController,
            cityController: manualCityController,
            stateController: manualStateController,
            postalCodeController: manualPostalCodeController,
            isCreating: isCreatingManualSite,
            onCreate: onCreateManualSite,
            onCancel: onHideManualEntry,
          ),
        ],
      ],
    );
  }
}

const _usStateCodes = <String>[
  'AL',
  'AK',
  'AZ',
  'AR',
  'CA',
  'CO',
  'CT',
  'DE',
  'FL',
  'GA',
  'HI',
  'ID',
  'IL',
  'IN',
  'IA',
  'KS',
  'KY',
  'LA',
  'ME',
  'MD',
  'MA',
  'MI',
  'MN',
  'MS',
  'MO',
  'MT',
  'NE',
  'NV',
  'NH',
  'NJ',
  'NM',
  'NY',
  'NC',
  'ND',
  'OH',
  'OK',
  'OR',
  'PA',
  'RI',
  'SC',
  'SD',
  'TN',
  'TX',
  'UT',
  'VT',
  'VA',
  'WA',
  'WV',
  'WI',
  'WY',
  'DC',
];

class _ManualSiteForm extends StatelessWidget {
  const _ManualSiteForm({
    required this.siteNameController,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.isCreating,
    required this.onCreate,
    required this.onCancel,
  });

  final TextEditingController siteNameController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final bool isCreating;
  final VoidCallback onCreate;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stateCode = stateController.text.trim().toUpperCase();
    final selectedState = _usStateCodes.contains(stateCode) ? stateCode : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Public inspection history can be linked later.',
          style: theme.textTheme.bodySmall?.copyWith(color: _muted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: siteNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Restaurant name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressController,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.streetAddressLine1],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Street address'),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: cityController,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.addressCity],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'City'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 82,
              child: DropdownButtonFormField<String>(
                initialValue: selectedState,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'State'),
                items: _usStateCodes
                    .map(
                      (state) =>
                          DropdownMenuItem(value: state, child: Text(state)),
                    )
                    .toList(),
                onChanged: isCreating
                    ? null
                    : (value) {
                        stateController.text = value ?? '';
                      },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: TextField(
                controller: postalCodeController,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.postalCode],
                maxLength: 10,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onCreate(),
                decoration: const InputDecoration(
                  labelText: 'ZIP',
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: isCreating ? null : onCreate,
          icon: isCreating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_outlined),
          label: const Text('Add restaurant'),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: isCreating ? null : onCancel,
          child: const Text('Back to search'),
        ),
      ],
    );
  }
}
