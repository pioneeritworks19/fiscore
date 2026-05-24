part of '../../main.dart';

bool _canAssignTraining(String? role) {
  return const ['tenant_owner', 'admin', 'manager'].contains(role);
}

class _TrainingContent extends StatefulWidget {
  const _TrainingContent({
    required this.tenantId,
    required this.siteId,
    required this.currentMember,
    this.initialView = 'home',
  });

  final String tenantId;
  final String siteId;
  final Map<String, dynamic> currentMember;
  final String initialView;

  @override
  State<_TrainingContent> createState() => _TrainingContentState();
}

class _TrainingContentState extends State<_TrainingContent> {
  final TrainingRepository _repository = TrainingRepository();
  late String _view;
  String? _activeAssignmentId;
  Map<String, dynamic>? _activeAssignment;
  String? _message;
  String? _error;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _canAssign =>
      _canAssignTraining(widget.currentMember['role'] as String?);

  @override
  void initState() {
    super.initState();
    _view = widget.initialView;
  }

  @override
  void didUpdateWidget(covariant _TrainingContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialView != oldWidget.initialView) {
      _view = widget.initialView;
    }
  }

  Future<void> _addLibraryTraining(String libraryItemId) async {
    try {
      await _repository.addLibraryTraining(
        tenantId: widget.tenantId,
        libraryItemId: libraryItemId,
      );
      if (!mounted) return;
      setState(() {
        _message = 'Training added to My Library.';
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not add this training. Please try again.';
        _message = null;
      });
    }
  }

  Future<void> _assignFromLibrary(Map<String, dynamic> training) async {
    final created = await showTrainingAssignmentSheet(
      context,
      tenantId: widget.tenantId,
      siteId: widget.siteId,
      initialTraining: training,
    );
    if (!mounted || created != true) return;
    setState(() {
      _view = 'team';
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Training assigned.')));
  }

  Future<void> _cancelAssignment(String assignmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this assignment?'),
        content: const Text(
          'The team member will no longer be expected to complete this training. The assignment stays in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep assignment'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel assignment'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.cancelAssignment(
        tenantId: widget.tenantId,
        assignmentId: assignmentId,
      );
      if (!mounted) return;
      setState(() {
        _error = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Training assignment cancelled.')),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not cancel training. Please try again.';
        _message = null;
      });
    }
  }

  void _openAssignment(String assignmentId, Map<String, dynamic> assignment) {
    setState(() {
      _activeAssignmentId = assignmentId;
      _activeAssignment = assignment;
      _view = 'player';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.assignmentsStream(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        userId: _userId,
        canAssign: _canAssign,
      ),
      builder: (context, snapshot) {
        final assignments =
            (snapshot.data?.docs ?? []).where((doc) {
              return doc.data()['siteId'] == widget.siteId;
            }).toList()..sort(
              (a, b) => _trainingSortValue(
                a.data(),
              ).compareTo(_trainingSortValue(b.data())),
            );
        final myAssignments = assignments
            .where(
              (doc) =>
                  doc.data()['assignedTo'] == _userId &&
                  doc.data()['status'] != 'cancelled',
            )
            .toList();
        final openCount = assignments
            .where(
              (doc) =>
                  doc.data()['status'] != 'completed' &&
                  doc.data()['status'] != 'cancelled',
            )
            .length;
        final completedCount = assignments
            .where((doc) => doc.data()['status'] == 'completed')
            .length;

        final statusMessages = <Widget>[
          if (_message != null)
            _StatusMessage(
              icon: Icons.check_circle_outline,
              color: _green,
              text: _message!,
            ),
          if (_error != null)
            _StatusMessage(
              icon: Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              text: _error!,
            ),
        ];
        if (_view == 'player' &&
            _activeAssignmentId != null &&
            _activeAssignment != null) {
          return _TrainingPlayerView(
            tenantId: widget.tenantId,
            assignmentId: _activeAssignmentId!,
            assignment: _activeAssignment!,
            canComplete: _activeAssignment!['assignedTo'] == _userId,
            canManage: _canAssign,
            onBack: () => setState(() {
              _activeAssignmentId = null;
              _activeAssignment = null;
              _view = 'home';
            }),
            onCompleted: () => setState(() {
              _message = 'Training completed.';
              _error = null;
            }),
          );
        }
        if (_view == 'assign') {
          return _TrainingAssignView(
            tenantId: widget.tenantId,
            repository: _repository,
            statusMessages: statusMessages,
            onBack: () => setState(() => _view = 'home'),
            onAddLibraryTraining: _addLibraryTraining,
            onAssign: _assignFromLibrary,
          );
        }
        if (_view == 'team' || _view == 'overdue') {
          return _TrainingTeamProgressView(
            assignments: assignments,
            initialFilter: _view == 'overdue' ? 'overdue' : 'open',
            onBack: () => setState(() => _view = 'home'),
            onOpenAssignment: _openAssignment,
            onCancelAssignment: _cancelAssignment,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Training',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete assigned coaching for this restaurant.',
              style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            for (final status in statusMessages) ...[
              const SizedBox(height: 14),
              status,
            ],
            const SizedBox(height: 18),
            const _TrainingSectionTitle(
              title: 'My training',
              body: 'Items assigned to you.',
            ),
            const SizedBox(height: 8),
            if (myAssignments.isEmpty)
              const _EmptyStateCard(
                icon: Icons.school_outlined,
                title: 'No training assigned',
                body: 'Assigned learning will appear here.',
              )
            else
              for (final doc in myAssignments)
                _TrainingAssignmentCard(
                  assignment: doc.data(),
                  onTap: () => _openAssignment(doc.id, doc.data()),
                ),
            if (_canAssign) ...[
              const SizedBox(height: 20),
              const _TrainingSectionTitle(
                title: 'For managers',
                body: 'Assign coaching and monitor completion.',
              ),
              const SizedBox(height: 8),
              _TrainingNavigationRow(
                icon: Icons.person_add_alt_outlined,
                title: 'Assign training',
                detail: 'Browse the training library',
                onTap: () => setState(() => _view = 'assign'),
              ),
              _TrainingNavigationRow(
                icon: Icons.groups_outlined,
                title: 'Team progress',
                detail: '$openCount open / $completedCount completed',
                onTap: () => setState(() => _view = 'team'),
              ),
            ],
          ],
        );
      },
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to training'),
        ),
        const SizedBox(height: 4),
        Text(
          'Assign training',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _libraryView == 'my'
              ? 'Choose coaching from your library, then assign it.'
              : 'Add curated FiScore training to your team library.',
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
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search training',
          ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'my', label: Text('My Library')),
            ButtonSegment(value: 'explore', label: Text('Explore FiScore')),
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
    required this.assignments,
    required this.initialFilter,
    required this.onBack,
    required this.onOpenAssignment,
    required this.onCancelAssignment,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> assignments;
  final String initialFilter;
  final VoidCallback onBack;
  final void Function(String, Map<String, dynamic>) onOpenAssignment;
  final ValueChanged<String> onCancelAssignment;

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
    final open = widget.assignments
        .where(
          (doc) =>
              doc.data()['status'] != 'completed' &&
              doc.data()['status'] != 'cancelled',
        )
        .length;
    final completed = widget.assignments
        .where((doc) => doc.data()['status'] == 'completed')
        .length;
    final cancelled = widget.assignments
        .where((doc) => doc.data()['status'] == 'cancelled')
        .length;
    final overdue = widget.assignments.where((doc) {
      final data = doc.data();
      return data['status'] != 'completed' &&
          data['status'] != 'cancelled' &&
          _isTrainingOverdue(data['dueDate']);
    }).length;
    final visible = widget.assignments.where((doc) {
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
          label: const Text('Back to training'),
        ),
        const SizedBox(height: 4),
        Text(
          'Team progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$open open  |  $overdue overdue  |  $completed done',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final option in [
              ('open', 'Open'),
              ('overdue', 'Overdue'),
              ('completed', 'Done'),
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
              tooltip: 'More filters',
              icon: const Icon(Icons.filter_list_outlined, color: _navy),
              onSelected: (value) => setState(() => _filter = value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cancelled',
                  child: Text('Cancelled ($cancelled)'),
                ),
                const PopupMenuItem(value: 'all', child: Text('All')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const _EmptyStateCard(
            icon: Icons.check_circle_outline,
            title: 'Nothing in this view',
            body: 'There are no training assignments to follow up on.',
          )
        else
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
      ],
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
          return const _EmptyStateCard(
            icon: Icons.search_off_outlined,
            title: 'No matching training',
            body: 'Try a different search term.',
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
                  'No training in My Library',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore FiScore Library to add coaching for your team.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _muted),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onExplore,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('Explore FiScore Library'),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repository.fiScoreLibraryTrainings(tenantId),
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
        final query = searchText.trim().toLowerCase();
        final trainings = (snapshot.data ?? const []).where((training) {
          final text =
              '${training['title'] ?? ''} ${training['description'] ?? ''}'
                  .toLowerCase();
          return query.isEmpty || text.contains(query);
        }).toList();
        if (trainings.isEmpty) {
          return const _EmptyStateCard(
            icon: Icons.search_off_outlined,
            title: 'No matching training',
            body: 'Try another search term.',
          );
        }
        return Column(
          children: [
            for (final training in trainings)
              _TrainingLibraryCard(
                training: training,
                actionLabel: training['updateAvailable'] == true
                    ? 'Update'
                    : training['inMyLibrary'] == true
                    ? 'Added'
                    : 'Add',
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
    final isLibraryItem =
        training['trainingSource'] == 'library_synced' ||
        training['libraryTrainingId'] != null;
    final updateAvailable = training['updateAvailable'] == true;
    final sourceLabel = isLibraryItem
        ? 'FiScore Library'
        : 'Created by your team';
    final durationMinutes = training['durationMinutes'] as int? ?? 0;
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
                  '$sourceLabel  |  $durationMinutes min  |  Micro-learning',
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
                label: Text(actionLabel),
              ),
            ],
          ),
          if (updateAvailable && actionLabel == 'Assign') ...[
            const SizedBox(height: 6),
            Text(
              'Update available in FiScore Library',
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
    final status = assignment['status'] as String? ?? 'assigned';
    final title = assignment['trainingTitleSnapshot'] as String? ?? 'Training';
    final assignee =
        assignment['assignedToNameSnapshot'] as String? ?? 'Team member';
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
                    '$assignee - ${_trainingDueLabel(assignment['dueDate'])}',
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
                tooltip: 'Assignment actions',
                icon: const Icon(Icons.more_horiz, size: 20, color: _muted),
                onSelected: (value) {
                  if (value == 'cancel') onCancel!();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel assignment'),
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

class _TrainingPlayerView extends StatefulWidget {
  const _TrainingPlayerView({
    required this.tenantId,
    required this.assignmentId,
    required this.assignment,
    required this.canComplete,
    required this.canManage,
    required this.onBack,
    required this.onCompleted,
  });
  final String tenantId;
  final String assignmentId;
  final Map<String, dynamic> assignment;
  final bool canComplete;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onCompleted;

  @override
  State<_TrainingPlayerView> createState() => _TrainingPlayerViewState();
}

class _TrainingPlayerViewState extends State<_TrainingPlayerView> {
  final TrainingRepository _repository = TrainingRepository();
  Map<String, dynamic>? _libraryTraining;
  int _page = 0;
  int _incorrectAnswerCount = 0;
  int? _selectedAnswer;
  bool _answerChecked = false;
  bool _checkedAnswerIsCorrect = false;
  String? _feedback;
  String? _completionError;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _completed = false;

  String get _title =>
      widget.assignment['trainingTitleSnapshot'] as String? ?? 'Training';
  String get _description =>
      widget.assignment['trainingDescriptionSnapshot'] as String? ?? '';
  List<Map<String, dynamic>> get _sections => _mapsFrom(
    widget.assignment['trainingSectionsSnapshot'] ??
        _libraryTraining?['sections'],
  );
  List<Map<String, dynamic>> get _questions => _mapsFrom(
    widget.assignment['quickCheckQuestionsSnapshot'] ??
        _libraryTraining?['quickCheckQuestions'],
  );
  bool get _isAlreadyComplete =>
      _completed || widget.assignment['status'] == 'completed';
  bool get _isCancelled => widget.assignment['status'] == 'cancelled';

  @override
  void initState() {
    super.initState();
    _completed = widget.assignment['status'] == 'completed';
    _loadLibraryFallback();
  }

  List<Map<String, dynamic>> _mapsFrom(Object? value) {
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _loadLibraryFallback() async {
    if (_sections.isNotEmpty) return;
    final trainingId = widget.assignment['trainingId'] as String?;
    if (trainingId == null) return;
    setState(() => _isLoading = true);
    try {
      final training = await _repository.trainingById(
        tenantId: widget.tenantId,
        trainingId: trainingId,
      );
      if (mounted) setState(() => _libraryTraining = training);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTrainingContent() async {
    final trainingId = widget.assignment['trainingId'] as String?;
    if (trainingId == null) return;
    setState(() => _isLoading = true);
    try {
      await _repository.addLibraryTraining(
        tenantId: widget.tenantId,
        libraryItemId: trainingId,
      );
      await _loadLibraryFallback();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not update the Training library.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _start() async {
    if (!widget.canComplete) return;
    if (widget.assignment['status'] == 'assigned') {
      await _repository.startAssignment(
        tenantId: widget.tenantId,
        assignmentId: widget.assignmentId,
      );
    }
    if (mounted) setState(() => _page = 1);
  }

  Future<void> _nextTopic() async {
    if (_page == _sections.length && _questions.isEmpty) {
      await _complete();
      return;
    }
    setState(() {
      _feedback = null;
      _completionError = null;
      _selectedAnswer = null;
      _answerChecked = false;
      _checkedAnswerIsCorrect = false;
      _page += 1;
    });
  }

  void _previousPage() {
    if (_page <= 1) {
      setState(() => _page = 0);
      return;
    }
    setState(() {
      _feedback = null;
      _completionError = null;
      _selectedAnswer = null;
      _answerChecked = false;
      _checkedAnswerIsCorrect = false;
      _page -= 1;
    });
  }

  Future<void> _checkAnswer(Map<String, dynamic> question) async {
    if (_selectedAnswer == null) return;
    if (_answerChecked) {
      if (_page < _sections.length + _questions.length) {
        await _nextTopic();
      } else {
        await _complete();
      }
      return;
    }
    final correctAnswer = question['correctOptionIndex'] as int? ?? -1;
    final correct = _selectedAnswer == correctAnswer;
    setState(() {
      _answerChecked = true;
      _checkedAnswerIsCorrect = correct;
      _completionError = null;
      if (!correct) _incorrectAnswerCount += 1;
      _feedback =
          question['explanation'] as String? ??
          'Review this practice before continuing.';
    });
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);
    try {
      await _repository.completeAssignment(
        tenantId: widget.tenantId,
        assignmentId: widget.assignmentId,
        incorrectAnswerCount: _incorrectAnswerCount,
        completedTopicCount: _sections.length,
        completionSummary: {
          'trainingTitle': _title,
          'trainingVersion': widget.assignment['trainingVersion'],
          'topics': _sections
              .map((section) => section['title'] as String? ?? '')
              .where((title) => title.isNotEmpty)
              .toList(),
          'linkedViolationId': widget.assignment['linkedViolationId'],
          'linkedViolationTitleSnapshot':
              widget.assignment['linkedViolationTitleSnapshot'],
        },
      );
      if (mounted) {
        setState(() => _completed = true);
        widget.onCompleted();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _completionError =
              'Could not record your completion. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) return _buildCancelled(context);
    if (_isAlreadyComplete) return _buildSummary(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_page == 0) return _buildOverview(context);
    if (_page <= _sections.length) {
      return _buildTopic(context, _sections[_page - 1]);
    }
    if (_questions.isNotEmpty) {
      return _buildQuestion(context, _questions[_page - _sections.length - 1]);
    }
    return _buildOverview(context);
  }

  Widget _buildCancelled(BuildContext context) {
    return _shell(
      context,
      children: [
        Text(
          _title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const _StatusMessage(
          icon: Icons.block_outlined,
          color: _muted,
          text:
              'This training assignment was cancelled and no longer needs to be completed.',
        ),
      ],
    );
  }

  Widget _shell(BuildContext context, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to training'),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _buildOverview(BuildContext context) {
    final linkedTitle =
        widget.assignment['linkedViolationTitleSnapshot'] as String?;
    if (_sections.isEmpty) {
      return _shell(
        context,
        children: [
          Text(
            _title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _StatusMessage(
            icon: Icons.info_outline,
            color: _navy,
            text: widget.canManage
                ? 'This assignment uses content that is not currently in My Library. Add its FiScore lesson, then reopen it or assign a new version.'
                : 'This training is not available yet. Please contact your manager.',
          ),
          if (widget.canManage) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _updateTrainingContent,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add lesson to My Library'),
            ),
          ],
        ],
      );
    }
    return _shell(
      context,
      children: [
        Text(
          _title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _TrainingPill(
              label:
                  '${widget.assignment['durationMinutes'] ?? _sections.length} min',
            ),
            const SizedBox(width: 8),
            _TrainingPill(label: '${_questions.length} question check'),
          ],
        ),
        if (linkedTitle != null && linkedTitle.isNotEmpty) ...[
          const SizedBox(height: 18),
          _TrainingInfoBlock(
            title: 'Assigned for follow-up',
            body: linkedTitle,
          ),
        ],
        const SizedBox(height: 18),
        _TrainingInfoBlock(
          title: 'You will cover',
          body: _sections
              .map((section) => section['title'] as String? ?? '')
              .where((title) => title.isNotEmpty)
              .join(' | '),
        ),
        const SizedBox(height: 22),
        if (widget.canComplete)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sections.isEmpty ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start training'),
            ),
          )
        else
          _StatusMessage(
            icon: Icons.info_outline,
            color: _navy,
            text:
                'Assigned to ${widget.assignment['assignedToNameSnapshot'] ?? 'team member'}.',
          ),
      ],
    );
  }

  Widget _buildTopic(BuildContext context, Map<String, dynamic> section) {
    return _shell(
      context,
      children: [
        Text(
          'Topic $_page of ${_sections.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _page / (_sections.length + _questions.length),
          color: _green,
          backgroundColor: _line,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 22),
        Text(
          section['title'] as String? ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          section['body'] as String? ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: _ink, height: 1.45),
        ),
        const SizedBox(height: 18),
        _TrainingInfoBlock(
          title: 'Remember',
          body: section['actionTip'] as String? ?? '',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(onPressed: _previousPage, child: const Text('Previous')),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isSaving ? null : _nextTopic,
              icon: const Icon(Icons.chevron_right),
              label: Text(
                _page == _sections.length
                    ? _questions.isNotEmpty
                          ? 'Quick check'
                          : 'Complete'
                    : 'Next',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final questionNumber = _page - _sections.length;
    final options = List<String>.from(question['options'] as List? ?? const []);
    final correctAnswer = question['correctOptionIndex'] as int? ?? -1;
    return _shell(
      context,
      children: [
        Text(
          'Quick check $questionNumber of ${_questions.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _page / (_sections.length + _questions.length),
          color: _green,
          backgroundColor: _line,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 22),
        Text(
          question['prompt'] as String? ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 15),
        for (var index = 0; index < options.length; index++)
          _TrainingAnswerOption(
            label: options[index],
            selected: _selectedAnswer == index,
            answerChecked: _answerChecked,
            isCorrect: index == correctAnswer,
            onTap: _answerChecked
                ? null
                : () => setState(() {
                    _selectedAnswer = index;
                    _feedback = null;
                  }),
          ),
        if (_feedback != null) ...[
          const SizedBox(height: 8),
          _TrainingAnswerFeedback(
            correct: _checkedAnswerIsCorrect,
            correctAnswer: correctAnswer >= 0 && correctAnswer < options.length
                ? options[correctAnswer]
                : '',
            explanation: _feedback!,
          ),
        ],
        if (_completionError != null) ...[
          const SizedBox(height: 10),
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: _completionError!,
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            TextButton(onPressed: _previousPage, child: const Text('Previous')),
            const Spacer(),
            FilledButton(
              onPressed: _isSaving || _selectedAnswer == null
                  ? null
                  : () => _checkAnswer(question),
              child: Text(
                !_answerChecked
                    ? 'Check answer'
                    : questionNumber == _questions.length
                    ? 'Finish'
                    : 'Continue',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final completedAt = widget.assignment['completedAt'];
    final completedDate = completedAt is Timestamp
        ? completedAt.toDate()
        : DateTime.now();
    final completionDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(completedDate);
    final summary = widget.assignment['completionSummarySnapshot'] as Map?;
    final topicNames =
        summary?['topics'] as List? ??
        _sections.map((section) => section['title']).toList();
    return _shell(
      context,
      children: [
        const Icon(Icons.check_circle_outline, color: _green, size: 34),
        const SizedBox(height: 12),
        Text(
          'Training complete',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 20),
        _TrainingInfoBlock(
          title: 'Completed by',
          body:
              '${widget.assignment['assignedToNameSnapshot'] ?? 'Team member'} | $completionDate',
        ),
        const SizedBox(height: 12),
        _TrainingInfoBlock(
          title: 'Topics covered',
          body: topicNames.whereType<String>().join(' | '),
        ),
        const SizedBox(height: 12),
        _StatusMessage(
          icon: Icons.verified_outlined,
          color: _green,
          text: 'Quick check completed. This completion is recorded.',
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.onBack,
            style: _greenFilledButtonStyle(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _TrainingInfoBlock extends StatelessWidget {
  const _TrainingInfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TrainingAnswerOption extends StatelessWidget {
  const _TrainingAnswerOption({
    required this.label,
    required this.selected,
    required this.answerChecked,
    required this.isCorrect,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool answerChecked;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showsCorrect = answerChecked && isCorrect;
    final showsIncorrect = answerChecked && selected && !isCorrect;
    final borderColor = showsCorrect
        ? _green
        : showsIncorrect
        ? Theme.of(context).colorScheme.error
        : selected
        ? _navy
        : _line;
    final fillColor = showsCorrect
        ? _softGreen
        : showsIncorrect
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08)
        : selected
        ? _navy.withValues(alpha: 0.06)
        : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              showsCorrect
                  ? Icons.check_circle
                  : showsIncorrect
                  ? Icons.cancel_outlined
                  : selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: showsCorrect
                  ? _green
                  : showsIncorrect
                  ? Theme.of(context).colorScheme.error
                  : selected
                  ? _navy
                  : _muted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _TrainingAnswerFeedback extends StatelessWidget {
  const _TrainingAnswerFeedback({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
  });

  final bool correct;
  final String correctAnswer;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: _green, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Correct' : 'Correct answer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!correct) ...[
                  const SizedBox(height: 3),
                  Text(
                    correctAnswer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _ink, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showTrainingAssignmentSheet(
  BuildContext context, {
  required String tenantId,
  required String siteId,
  Map<String, dynamic>? initialTraining,
  String? preferredTrainingId,
  String? linkedViolationId,
  String? linkedViolationTitle,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AssignTrainingSheet(
      tenantId: tenantId,
      siteId: siteId,
      initialTraining: initialTraining,
      preferredTrainingId: preferredTrainingId,
      linkedViolationId: linkedViolationId,
      linkedViolationTitle: linkedViolationTitle,
    ),
  );
}

class _AssignTrainingSheet extends StatefulWidget {
  const _AssignTrainingSheet({
    required this.tenantId,
    required this.siteId,
    this.initialTraining,
    this.preferredTrainingId,
    this.linkedViolationId,
    this.linkedViolationTitle,
  });
  final String tenantId;
  final String siteId;
  final Map<String, dynamic>? initialTraining;
  final String? preferredTrainingId;
  final String? linkedViolationId;
  final String? linkedViolationTitle;

  @override
  State<_AssignTrainingSheet> createState() => _AssignTrainingSheetState();
}

class _AssignTrainingSheetState extends State<_AssignTrainingSheet> {
  final TrainingRepository _repository = TrainingRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic>? _training;
  Map<String, String> _selectedAssignees = {};
  int _dueInDays = 7;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _training = widget.initialTraining;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    if (_training == null) {
      setState(() => _error = 'Choose a training item to assign.');
      return;
    }
    if (_selectedAssignees.isEmpty) {
      setState(() => _error = 'Choose at least one teammate to assign.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await _repository.createAssignments(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        training: _training!,
        assignees: _selectedAssignees,
        dueDate: DateTime.now().add(Duration(days: _dueInDays)),
        note: _noteController.text,
        linkedViolationId: widget.linkedViolationId,
        linkedViolationTitle: widget.linkedViolationTitle,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not assign training. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign training',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.linkedViolationId != null) ...[
                const SizedBox(height: 5),
                Text(
                  'For this violation',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repository.trainingsStream(widget.tenantId),
                builder: (context, snapshot) {
                  final trainings = (snapshot.data?.docs ?? [])
                      .map((doc) => {'_id': doc.id, ...doc.data()})
                      .toList();
                  if (_training == null && trainings.isNotEmpty) {
                    final preferredId = widget.preferredTrainingId;
                    _training = trainings.first;
                    for (final training in trainings) {
                      if (training['_id'] == preferredId ||
                          training['libraryTrainingId'] == preferredId) {
                        _training = training;
                        break;
                      }
                    }
                  }
                  if (trainings.isEmpty) {
                    return Text(
                      'No active training items are available.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _muted),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _training?['_id'] as String?,
                    decoration: const InputDecoration(labelText: 'Training'),
                    items: [
                      for (final training in trainings)
                        DropdownMenuItem(
                          value: training['_id'] as String,
                          child: Text(
                            training['title'] as String? ?? 'Training',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _training = trainings.firstWhere(
                          (training) => training['_id'] == value,
                        );
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _teamRepository.membersStream(widget.tenantId),
                builder: (context, snapshot) {
                  final members = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data();
                    if (data['status'] != 'active') return false;
                    final role = data['role'] as String?;
                    if (role == 'tenant_owner' || role == 'admin') {
                      return true;
                    }
                    if (data['siteAccessMode'] != 'selected') return true;
                    return (data['siteIds'] as List<dynamic>? ?? const [])
                        .whereType<String>()
                        .contains(widget.siteId);
                  }).toList();
                  return _AssigneeSelectionField(
                    selected: _selectedAssignees,
                    onTap: () async {
                      final result =
                          await showModalBottomSheet<Map<String, String>>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (context) => _TrainingMemberPickerSheet(
                              members: members,
                              initialSelection: _selectedAssignees,
                            ),
                          );
                      if (result != null && mounted) {
                        setState(() => _selectedAssignees = result);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dueInDays,
                decoration: const InputDecoration(labelText: 'Due date'),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('In 3 days')),
                  DropdownMenuItem(value: 7, child: Text('In 1 week')),
                  DropdownMenuItem(value: 14, child: Text('In 2 weeks')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _dueInDays = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Optional note',
                  hintText: 'Example: Complete before your next prep shift.',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _StatusMessage(
                  icon: Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  text: _error!,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _assign,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    _selectedAssignees.length <= 1
                        ? 'Assign training'
                        : 'Assign to ${_selectedAssignees.length} people',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssigneeSelectionField extends StatelessWidget {
  const _AssigneeSelectionField({required this.selected, required this.onTap});

  final Map<String, String> selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final names = selected.values.toList();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Assign to',
          suffixIcon: Icon(Icons.chevron_right),
        ),
        child: Text(
          names.isEmpty
              ? 'Choose team members'
              : names.length == 1
              ? names.first
              : '${names.length} team members selected',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: names.isEmpty ? _muted : _ink,
          ),
        ),
      ),
    );
  }
}

class _TrainingMemberPickerSheet extends StatefulWidget {
  const _TrainingMemberPickerSheet({
    required this.members,
    required this.initialSelection,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> members;
  final Map<String, String> initialSelection;

  @override
  State<_TrainingMemberPickerSheet> createState() =>
      _TrainingMemberPickerSheetState();
}

class _TrainingMemberPickerSheetState
    extends State<_TrainingMemberPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, String> _selection;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = Map<String, String>.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _nameFor(QueryDocumentSnapshot<Map<String, dynamic>> member) {
    return member.data()['displayNameSnapshot'] as String? ??
        member.data()['emailSnapshot'] as String? ??
        'Team member';
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.members.where((member) {
      if (_query.isEmpty) return true;
      final data = member.data();
      final searchText =
          '${data['displayNameSnapshot'] ?? ''} ${data['emailSnapshot'] ?? ''}'
              .toLowerCase();
      return searchText.contains(_query.toLowerCase());
    }).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose team members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search team members',
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final member in visible)
                    CheckboxListTile(
                      value: _selection.containsKey(member.id),
                      title: Text(_nameFor(member)),
                      subtitle: Text(
                        member.data()['emailSnapshot'] as String? ?? '',
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selection[member.id] = _nameFor(member);
                          } else {
                            _selection.remove(member.id);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_selection),
                child: Text(
                  _selection.isEmpty
                      ? 'Done'
                      : 'Select ${_selection.length} team member${_selection.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _trainingSortValue(Map<String, dynamic> assignment) {
  final status = assignment['status'] as String? ?? 'assigned';
  final statusValue = status == 'completed'
      ? 1
      : status == 'cancelled'
      ? 2
      : 0;
  final dueDate = assignment['dueDate'];
  final millis = dueDate is Timestamp ? dueDate.millisecondsSinceEpoch : 0;
  return statusValue * 2000000000 + millis;
}

String _trainingDueLabel(Object? value) {
  if (value is! Timestamp) return 'No due date';
  final date = value.toDate();
  final now = DateTime.now();
  final difference = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (difference < 0) return 'Overdue';
  if (difference == 0) return 'Due today';
  if (difference == 1) return 'Due tomorrow';
  return 'Due ${date.month}/${date.day}';
}

String? _recommendedTrainingIdForViolation(Map<String, dynamic> violation) {
  final text = [
    violation['title'],
    violation['summaryText'],
    violation['description'],
    violation['normalizedCategory'],
  ].whereType<String>().join(' ').toLowerCase();
  if (text.contains('handwash') ||
      text.contains('hygiene') ||
      text.contains('glove')) {
    return 'handwashing_basics';
  }
  if (text.contains('date') ||
      text.contains('label') ||
      text.contains('temperature') ||
      text.contains('storage')) {
    return 'date_marking_storage';
  }
  if (text.contains('clean') ||
      text.contains('sanit') ||
      text.contains('chemical')) {
    return 'cleaning_sanitizer';
  }
  return null;
}
