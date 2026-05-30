part of '../../main.dart';

class _AuditTemplatePicker extends StatefulWidget {
  const _AuditTemplatePicker({
    required this.tenantId,
    required this.repository,
    required this.isWorking,
    required this.error,
    required this.canManageLibrary,
    required this.onBack,
    required this.onAddLibraryChecklist,
    required this.onSelect,
  });

  final String tenantId;
  final InternalAuditRepository repository;
  final bool isWorking;
  final String? error;
  final bool canManageLibrary;
  final VoidCallback onBack;
  final ValueChanged<String> onAddLibraryChecklist;
  final ValueChanged<String> onSelect;

  @override
  State<_AuditTemplatePicker> createState() => _AuditTemplatePickerState();
}

class _AuditTemplatePickerState extends State<_AuditTemplatePicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _libraryView = 'my';

  @override
  void initState() {
    super.initState();
    widget.repository
        .fiScoreLibraryChecklists(tenantId: widget.tenantId)
        .catchError((_) => <Map<String, dynamic>>[]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.isWorking ? null : widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: Text(strings.back),
        ),
        Text(
          strings.startACheck,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _libraryView == 'my'
              ? strings.chooseChecklistForSite
              : strings.addCuratedChecklistsHelp,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 14),
        if (widget.error != null) ...[
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: widget.error!,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _searchController,
          enabled: !widget.isWorking,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: strings.searchChecklists,
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          expandedInsets: EdgeInsets.zero,
          segments: [
            ButtonSegment(value: 'my', label: Text(strings.myLibrary)),
            ButtonSegment(
              value: 'explore',
              label: Text(strings.exploreFiScore),
            ),
          ],
          selected: {_libraryView},
          onSelectionChanged: widget.isWorking
              ? null
              : (value) => setState(() => _libraryView = value.first),
        ),
        const SizedBox(height: 14),
        if (_libraryView == 'my')
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.repository.checklistTemplatesStream(
              tenantId: widget.tenantId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final templates =
                  (snapshot.data?.docs ?? []).where((doc) {
                    final template = doc.data();
                    final haystack =
                        '${template['name'] ?? ''} ${template['description'] ?? ''} '
                                '${template['category'] ?? ''}'
                            .toLowerCase();
                    return _query.isEmpty || haystack.contains(_query);
                  }).toList()..sort((left, right) {
                    final leftName = left.data()['name'] as String? ?? '';
                    final rightName = right.data()['name'] as String? ?? '';
                    return leftName.compareTo(rightName);
                  });
              if ((snapshot.data?.docs ?? []).isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.noChecklistsInMyLibrary,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.canManageLibrary
                            ? strings.exploreChecklistLibraryHelp
                            : strings.askManagerToAddChecklist,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: _muted),
                      ),
                      const SizedBox(height: 12),
                      if (widget.canManageLibrary)
                        TextButton.icon(
                          onPressed: widget.isWorking
                              ? null
                              : () => setState(() => _libraryView = 'explore'),
                          icon: const Icon(Icons.explore_outlined),
                          label: Text(strings.exploreFiScoreLibrary),
                        ),
                    ],
                  ),
                );
              }
              if (templates.isEmpty) {
                return _EmptyStateCard(
                  icon: Icons.search_off_outlined,
                  title: strings.noMatchingChecklists,
                  body: strings.tryDifferentSearchTerm,
                );
              }
              return Column(
                children: templates
                    .map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChecklistTemplateCard(
                          templateId: document.id,
                          template: document.data(),
                          isWorking: widget.isWorking,
                          onSelect: widget.onSelect,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          )
        else
          FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.repository.fiScoreLibraryChecklists(
              tenantId: widget.tenantId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyStateCard(
                  icon: Icons.error_outline,
                  title: 'Could not load FiScore Library',
                  body: 'Please try again shortly.',
                );
              }
              final items = (snapshot.data ?? const []).where((template) {
                final haystack =
                    '${template['name'] ?? ''} ${template['description'] ?? ''} '
                            '${template['category'] ?? ''}'
                        .toLowerCase();
                return _query.isEmpty || haystack.contains(_query);
              }).toList();
              if (items.isEmpty) {
                return const _EmptyStateCard(
                  icon: Icons.search_off_outlined,
                  title: 'No matching checklists',
                  body: 'Try another search term.',
                );
              }
              return Column(
                children: items
                    .map(
                      (template) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChecklistTemplateCard(
                          templateId: template['libraryItemId'] as String,
                          template: template,
                          isWorking: widget.isWorking,
                          onSelect: widget.onAddLibraryChecklist,
                          actionLabel: template['updateAvailable'] == true
                              ? 'Update'
                              : template['inMyLibrary'] == true
                              ? 'Added'
                              : 'Add to My Library',
                          actionEnabled:
                              widget.canManageLibrary &&
                              (template['inMyLibrary'] != true ||
                                  template['updateAvailable'] == true),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _ChecklistTemplateCard extends StatelessWidget {
  const _ChecklistTemplateCard({
    required this.templateId,
    required this.template,
    required this.isWorking,
    required this.onSelect,
    this.actionLabel = 'Start',
    this.actionEnabled = true,
  });

  final String templateId;
  final Map<String, dynamic> template;
  final bool isWorking;
  final ValueChanged<String> onSelect;
  final String actionLabel;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    final duration = template['estimatedMinutes'] as int? ?? 0;
    final questions = template['questionCount'] as int? ?? 0;
    final isLibraryItem =
        template['templateSource'] == 'library_synced' ||
        template['libraryTemplateId'] != null;
    final updateAvailable = template['updateAvailable'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template['name'] as String? ?? 'Checklist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            template['description'] as String? ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted),
          ),
          const SizedBox(height: 10),
          Text(
            '${isLibraryItem ? 'FiScore Library' : 'Created by your team'}  |  $duration min  |  $questions items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (updateAvailable && actionLabel == 'Start') ...[
            const SizedBox(height: 6),
            Text(
              'Update available in FiScore Library',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF2859C5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isWorking || !actionEnabled
                  ? null
                  : () => onSelect(templateId),
              icon: Icon(
                actionLabel == 'Start'
                    ? Icons.play_arrow_outlined
                    : Icons.add_circle_outline,
              ),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _InternalAuditRow extends StatelessWidget {
  const _InternalAuditRow({
    required this.audit,
    required this.actionLabel,
    required this.onOpen,
  });

  final Map<String, dynamic> audit;
  final String actionLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final complete = audit['status'] == 'completed';
    final violationCount = _internalAuditViolationCount(audit);
    final completedBy = audit['startedByDisplayNameSnapshot'] as String? ?? '';
    final auditDate = _dateText(
      complete ? audit['completedAt'] : audit['startedAt'],
    );
    final detailText = complete && completedBy.isNotEmpty
        ? '$auditDate / Completed by $completedBy'
        : auditDate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A071A4A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.playlist_add_check_outlined,
                  color: _navy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audit['templateNameSnapshot'] as String? ??
                          'Internal check',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (complete)
                          _AuditPill(
                            label: 'Score ${audit['scorePercentage'] ?? 0}',
                            color: _green,
                          )
                        else
                          const _AuditPill(label: 'In progress'),
                        if (complete)
                          _AuditPill(
                            label:
                                '$violationCount ${violationCount == 1 ? 'violation' : 'violations'}',
                            color: violationCount == 0 ? _green : _navy,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!complete) ...[
                Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              const Icon(Icons.chevron_right, color: _navy, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
