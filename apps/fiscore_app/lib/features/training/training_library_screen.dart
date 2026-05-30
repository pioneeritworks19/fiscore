part of '../../main.dart';

class _TrainingAssignView extends StatefulWidget {
  const _TrainingAssignView({
    required this.tenantId,
    required this.repository,
    required this.statusMessages,
    required this.onBack,
    required this.onAddLibraryTraining,
    required this.onAssign,
  });

  final String tenantId;
  final TrainingRepository repository;
  final List<Widget> statusMessages;
  final VoidCallback onBack;
  final ValueChanged<String> onAddLibraryTraining;
  final ValueChanged<Map<String, dynamic>> onAssign;

  @override
  State<_TrainingAssignView> createState() => _TrainingAssignViewState();
}

class _TrainingAssignViewState extends State<_TrainingAssignView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _libraryView = 'my';

  @override
  void initState() {
    super.initState();
    widget.repository
        .fiScoreLibraryTrainings(widget.tenantId)
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
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: Text(strings.backToTraining),
        ),
        const SizedBox(height: 4),
        Text(
          strings.assignTraining,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _libraryView == 'my'
              ? strings.assignTrainingMyHelp
              : strings.assignTrainingExploreHelp,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
        for (final status in widget.statusMessages) ...[
          const SizedBox(height: 12),
          status,
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: strings.searchTraining,
          ),
        ),
        const SizedBox(height: 16),
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
          onSelectionChanged: (value) =>
              setState(() => _libraryView = value.first),
        ),
        const SizedBox(height: 16),
        if (_libraryView == 'my')
          _TrainingLibraryList(
            tenantId: widget.tenantId,
            repository: widget.repository,
            searchText: _query,
            onAssign: widget.onAssign,
            onExplore: () => setState(() => _libraryView = 'explore'),
          )
        else
          _FiScoreTrainingLibraryList(
            tenantId: widget.tenantId,
            repository: widget.repository,
            searchText: _query,
            onAdd: widget.onAddLibraryTraining,
          ),
      ],
    );
  }
}

class _TrainingTeamProgressView extends StatefulWidget {
  const _TrainingTeamProgressView({
    required this.activeAssignments,
    required this.tenantId,
    required this.siteId,
    required this.userId,
    required this.canAssign,
    required this.repository,
    required this.activeLimit,
    required this.initialFilter,
    required this.onBack,
    required this.onOpenAssignment,
    required this.onCancelAssignment,
    required this.historyLimit,
    required this.onLoadMoreActive,
    required this.onLoadMore,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> activeAssignments;
  final String tenantId;
  final String siteId;
  final String userId;
  final bool canAssign;
  final TrainingRepository repository;
  final int activeLimit;
  final String initialFilter;
  final VoidCallback onBack;
  final void Function(String, Map<String, dynamic>) onOpenAssignment;
  final ValueChanged<String> onCancelAssignment;
  final int historyLimit;
  final VoidCallback onLoadMoreActive;
  final VoidCallback onLoadMore;

  @override
  State<_TrainingTeamProgressView> createState() =>
      _TrainingTeamProgressViewState();
}

class _TrainingTeamProgressViewState extends State<_TrainingTeamProgressView> {
  late String _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.repository.historyAssignmentsStream(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        userId: widget.userId,
        canAssign: widget.canAssign,
        limit: widget.historyLimit,
      ),
      builder: (context, snapshot) {
        final history = snapshot.data?.docs ?? [];
        final assignments = [...widget.activeAssignments, ...history];
        final open = widget.activeAssignments.length;
        final completed = history
            .where((doc) => doc.data()['status'] == 'completed')
            .length;
        final cancelled = history
            .where((doc) => doc.data()['status'] == 'cancelled')
            .length;
        final overdue = widget.activeAssignments.where((doc) {
          return _isTrainingOverdue(doc.data()['dueDate']);
        }).length;
        final visible = assignments.where((doc) {
          final data = doc.data();
          if (_filter == 'overdue') {
            return data['status'] != 'completed' &&
                data['status'] != 'cancelled' &&
                _isTrainingOverdue(data['dueDate']);
          }
          if (_filter == 'completed') return data['status'] == 'completed';
          if (_filter == 'cancelled') return data['status'] == 'cancelled';
          if (_filter == 'all') return true;
          return data['status'] != 'completed' && data['status'] != 'cancelled';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.chevron_left),
              label: Text(strings.backToTraining),
            ),
            const SizedBox(height: 4),
            Text(
              strings.teamProgress,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              strings.teamProgressSummary(open, overdue, completed),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _muted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final option in [
                  ('open', strings.openStatus),
                  ('overdue', strings.overdue),
                  ('completed', strings.done),
                ]) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(option.$2),
                        selected: _filter == option.$1,
                        onSelected: (_) => setState(() => _filter = option.$1),
                      ),
                    ),
                  ),
                ],
                PopupMenuButton<String>(
                  tooltip: strings.moreFilters,
                  icon: const Icon(Icons.filter_list_outlined, color: _navy),
                  onSelected: (value) => setState(() => _filter = value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'cancelled',
                      child: Text(strings.cancelledCount(cancelled)),
                    ),
                    PopupMenuItem(value: 'all', child: Text(strings.all)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              _EmptyStateCard(
                icon: Icons.check_circle_outline,
                title: strings.nothingInThisView,
                body: strings.noTrainingAssignmentsToFollowUp,
              )
            else ...[
              for (final doc in visible)
                _TrainingAssignmentCard(
                  assignment: doc.data(),
                  onTap: () => widget.onOpenAssignment(doc.id, doc.data()),
                  onCancel:
                      doc.data()['status'] == 'completed' ||
                          doc.data()['status'] == 'cancelled'
                      ? null
                      : () => widget.onCancelAssignment(doc.id),
                ),
              if ((_filter == 'completed' ||
                      _filter == 'cancelled' ||
                      _filter == 'all') &&
                  history.length == widget.historyLimit)
                Center(
                  child: TextButton(
                    onPressed: widget.onLoadMore,
                    child: Text(strings.loadMoreAssignments),
                  ),
                ),
              if ((_filter == 'open' || _filter == 'overdue') &&
                  widget.activeAssignments.length == widget.activeLimit)
                Center(
                  child: TextButton(
                    onPressed: widget.onLoadMoreActive,
                    child: Text(strings.loadMoreActiveAssignments),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _TrainingNavigationRow extends StatelessWidget {
  const _TrainingNavigationRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: _navy, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _navy),
          ],
        ),
      ),
    );
  }
}

class _TrainingLibraryList extends StatelessWidget {
  const _TrainingLibraryList({
    required this.tenantId,
    required this.repository,
    required this.onAssign,
    required this.onExplore,
    this.searchText = '',
  });

  final String tenantId;
  final TrainingRepository repository;
  final ValueChanged<Map<String, dynamic>> onAssign;
  final VoidCallback onExplore;
  final String searchText;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.trainingsStream(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final trainings =
            (snapshot.data?.docs ?? [])
                .map((doc) => {'_id': doc.id, ...doc.data()})
                .where((training) {
                  if (searchText.isEmpty) return true;
                  final query = searchText.toLowerCase();
                  final text =
                      '${training['title'] ?? ''} ${training['description'] ?? ''}'
                          .toLowerCase();
                  return text.contains(query);
                })
                .toList()
              ..sort(
                (a, b) => (a['title'] as String? ?? '').compareTo(
                  b['title'] as String? ?? '',
                ),
              );
        if (trainings.isEmpty && searchText.isNotEmpty) {
          return _EmptyStateCard(
            icon: Icons.search_off_outlined,
            title: strings.noMatchingTraining,
            body: strings.tryDifferentSearchTerm,
          );
        }
        if (trainings.isEmpty) {
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
                  strings.noTrainingInMyLibrary,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.exploreTrainingLibraryHelp,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _muted),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: Text(strings.exploreFiScoreLibrary),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final training in trainings)
              _TrainingLibraryCard(
                training: training,
                onAssign: () => onAssign(training),
              ),
          ],
        );
      },
    );
  }
}

class _FiScoreTrainingLibraryList extends StatelessWidget {
  const _FiScoreTrainingLibraryList({
    required this.tenantId,
    required this.repository,
    required this.searchText,
    required this.onAdd,
  });

  final String tenantId;
  final TrainingRepository repository;
  final String searchText;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repository.fiScoreLibraryTrainings(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _EmptyStateCard(
            icon: Icons.error_outline,
            title: strings.couldNotLoadFiScoreLibrary,
            body: strings.pleaseTryAgainShortly,
          );
        }
        final query = searchText.trim().toLowerCase();
        final trainings = (snapshot.data ?? const []).where((training) {
          final text =
              '${training['title'] ?? ''} ${training['description'] ?? ''}'
                  .toLowerCase();
          return query.isEmpty || text.contains(query);
        }).toList();
        if (trainings.isEmpty) {
          return _EmptyStateCard(
            icon: Icons.search_off_outlined,
            title: strings.noMatchingTraining,
            body: strings.tryDifferentSearchTerm,
          );
        }
        return Column(
          children: [
            for (final training in trainings)
              _TrainingLibraryCard(
                training: training,
                actionLabel: training['updateAvailable'] == true
                    ? strings.update
                    : training['inMyLibrary'] == true
                    ? strings.added
                    : strings.add,
                actionEnabled:
                    training['inMyLibrary'] != true ||
                    training['updateAvailable'] == true,
                onAssign: () => onAdd(training['libraryItemId'] as String),
              ),
          ],
        );
      },
    );
  }
}

class _TrainingSectionTitle extends StatelessWidget {
  const _TrainingSectionTitle({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
        ),
      ],
    );
  }
}

class _TrainingLibraryCard extends StatelessWidget {
  const _TrainingLibraryCard({
    required this.training,
    required this.onAssign,
    this.actionLabel = 'Assign',
    this.actionEnabled = true,
  });
  final Map<String, dynamic> training;
  final VoidCallback onAssign;
  final String actionLabel;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final isLibraryItem =
        training['trainingSource'] == 'library_synced' ||
        training['libraryTrainingId'] != null;
    final updateAvailable = training['updateAvailable'] == true;
    final sourceLabel = isLibraryItem
        ? strings.exploreFiScoreLibrary
        : strings.createdByYourTeam;
    final durationMinutes = training['durationMinutes'] as int? ?? 0;
    final contentLabel =
        training['mediaSummary'] as String? ?? strings.microLearning;
    final effectiveActionLabel = actionLabel == 'Assign'
        ? strings.assign
        : actionLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            training['title'] as String,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            training['description'] as String,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _muted, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$sourceLabel  |  $durationMinutes ${strings.minUnit}  |  $contentLabel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: actionEnabled ? onAssign : null,
                icon: Icon(
                  actionLabel == 'Assign'
                      ? Icons.person_add_alt_outlined
                      : Icons.add_circle_outline,
                  size: 18,
                ),
                label: Text(effectiveActionLabel),
              ),
            ],
          ),
          if (updateAvailable && actionLabel == 'Assign') ...[
            const SizedBox(height: 6),
            Text(
              strings.updateAvailableInFiScoreLibrary,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF2859C5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainingAssignmentCard extends StatelessWidget {
  const _TrainingAssignmentCard({
    required this.assignment,
    required this.onTap,
    this.onCancel,
  });

  final Map<String, dynamic> assignment;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final status = assignment['status'] as String? ?? 'assigned';
    final title =
        assignment['trainingTitleSnapshot'] as String? ?? strings.trainingLabel;
    final assignee =
        assignment['assignedToNameSnapshot'] as String? ?? strings.teamMember;
    final assignmentDateLabel = status == 'completed'
        ? _trainingCompletionLabel(assignment['completedAt'], strings)
        : _trainingDueLabel(assignment['dueDate'], strings);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$assignee - $assignmentDateLabel',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _TrainingStatusPill(status: status),
            if (onCancel != null)
              PopupMenuButton<String>(
                tooltip: strings.assignmentActions,
                icon: const Icon(Icons.more_horiz, size: 20, color: _muted),
                onSelected: (value) {
                  if (value == 'cancel') onCancel!();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(strings.cancelAssignment),
                  ),
                ],
              )
            else ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: _muted),
            ],
          ],
        ),
      ),
    );
  }
}

String _trainingCompletionLabel(Object? value, AppLocalizations strings) {
  if (value is! Timestamp) return strings.completedLabel;
  final date = value.toDate();
  return strings.completedShortDate('${date.month}/${date.day}/${date.year}');
}

class _TrainingPill extends StatelessWidget {
  const _TrainingPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _navy,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrainingStatusPill extends StatelessWidget {
  const _TrainingStatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final complete = status == 'completed';
    final progress = status == 'in_progress';
    final cancelled = status == 'cancelled';
    final color = complete
        ? _green
        : cancelled
        ? _muted
        : progress
        ? const Color(0xFF2859C5)
        : _navy;
    final label = complete
        ? 'Done'
        : cancelled
        ? 'Cancelled'
        : progress
        ? 'Started'
        : 'Assigned';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
