part of '../../main.dart';

class _SitesOverviewContent extends StatelessWidget {
  const _SitesOverviewContent({
    required this.sites,
    required this.onOpenSite,
    required this.onAddSite,
    required this.canAddSite,
    required this.canManageSites,
    required this.onEditManualSite,
    required this.onDeleteSite,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> sites;
  final ValueChanged<String> onOpenSite;
  final VoidCallback onAddSite;
  final bool canAddSite;
  final bool canManageSites;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>>
  onEditManualSite;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onDeleteSite;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
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
          final isManualSite = _isManualSite(site);
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
                          ],
                        ),
                      ),
                      if (canManageSites) ...[
                        const SizedBox(width: 2),
                        PopupMenuButton<String>(
                          tooltip: 'Site actions',
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEditManualSite(siteDoc);
                            } else if (value == 'delete') {
                              onDeleteSite(siteDoc);
                            }
                          },
                          itemBuilder: (context) => [
                            if (isManualSite)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit site'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete site'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenSite(siteDoc.id),
                      icon: const Icon(Icons.chevron_right, size: 18),
                      label: Text(strings.openSite),
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
            label: Text(strings.addSite),
          ),
        ],
      ],
    );
  }
}

class _ManualSiteDraft {
  const _ManualSiteDraft({
    required this.siteName,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  final String siteName;
  final String addressLine1;
  final String city;
  final String state;
  final String postalCode;
}

class _EditManualSiteSheet extends StatefulWidget {
  const _EditManualSiteSheet({required this.site});

  final Map<String, dynamic> site;

  @override
  State<_EditManualSiteSheet> createState() => _EditManualSiteSheetState();
}

class _EditManualSiteSheetState extends State<_EditManualSiteSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.site['name'] as String? ?? '',
    );
    _addressController = TextEditingController(
      text: widget.site['addressLine1'] as String? ?? '',
    );
    _cityController = TextEditingController(
      text: widget.site['city'] as String? ?? '',
    );
    _stateController = TextEditingController(
      text: widget.site['state'] as String? ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.site['postalCode'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _save() {
    final draft = _ManualSiteDraft(
      siteName: _nameController.text.trim(),
      addressLine1: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().toUpperCase(),
      postalCode: _postalCodeController.text.trim(),
    );
    if ([
      draft.siteName,
      draft.addressLine1,
      draft.city,
      draft.state,
      draft.postalCode,
    ].any((value) => value.isEmpty)) {
      setState(
        () => _error = 'Enter the restaurant name and complete address.',
      );
      return;
    }
    if (!_usStateCodes.contains(draft.state)) {
      setState(() => _error = 'Enter a valid state.');
      return;
    }
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(draft.postalCode)) {
      setState(() => _error = 'Enter a valid ZIP code.');
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit restaurant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manual sites can be updated until they are linked to public records.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Restaurant name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: 'Street address'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(hintText: 'City'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 82,
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _usStateCodes.contains(
                          _stateController.text.trim().toUpperCase(),
                        )
                        ? _stateController.text.trim().toUpperCase()
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'State'),
                    items: _usStateCodes
                        .map(
                          (state) => DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      _stateController.text = value ?? '';
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 104,
                  child: TextField(
                    controller: _postalCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'ZIP'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteSiteSheet extends StatefulWidget {
  const _DeleteSiteSheet({required this.siteName});

  final String siteName;

  @override
  State<_DeleteSiteSheet> createState() => _DeleteSiteSheetState();
}

class _DeleteSiteSheetState extends State<_DeleteSiteSheet> {
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _confirmationController.text.trim() == 'DELETE';
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete ${widget.siteName}?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This permanently removes the site and all inspections, checks, violations, attachments, assignments, and activity under it. This cannot be recovered.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmationController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Type DELETE to confirm',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: canDelete
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete site'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

bool _isManualSite(Map<String, dynamic> site) {
  return site['manuallyCreated'] == true ||
      (site['linkStatus'] == 'manual_unlinked' &&
          (site['masterRestaurantId'] as String?)?.isNotEmpty != true);
}
