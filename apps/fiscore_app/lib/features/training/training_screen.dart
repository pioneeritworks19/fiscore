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
    this.initialAssignmentId,
  });

  final String tenantId;
  final String siteId;
  final Map<String, dynamic> currentMember;
  final String initialView;
  final String? initialAssignmentId;

  @override
  State<_TrainingContent> createState() => _TrainingContentState();
}

class _TrainingContentState extends State<_TrainingContent> {
  final TrainingRepository _repository = TrainingRepository();
  late String _view;
  String? _activeAssignmentId;
  Map<String, dynamic>? _activeAssignment;
  String? _openedInitialAssignmentId;
  String? _message;
  String? _error;
  int _activeAssignmentLimit = 50;
  int _historyLimit = 20;

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
    if (widget.initialAssignmentId != oldWidget.initialAssignmentId) {
      _openedInitialAssignmentId = null;
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
      stream: _repository.activeAssignmentsStream(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        userId: _userId,
        canAssign: _canAssign,
        limit: _activeAssignmentLimit,
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
        if (widget.initialAssignmentId != null &&
            widget.initialAssignmentId != _openedInitialAssignmentId) {
          for (final assignment in assignments) {
            if (assignment.id == widget.initialAssignmentId) {
              _activeAssignmentId = assignment.id;
              _activeAssignment = assignment.data();
              _view = 'player';
              _openedInitialAssignmentId = assignment.id;
              break;
            }
          }
        }

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
            activeAssignments: assignments,
            tenantId: widget.tenantId,
            siteId: widget.siteId,
            userId: _userId,
            canAssign: _canAssign,
            repository: _repository,
            activeLimit: _activeAssignmentLimit,
            initialFilter: _view == 'overdue' ? 'overdue' : 'open',
            onBack: () => setState(() => _view = 'home'),
            onOpenAssignment: _openAssignment,
            onCancelAssignment: _cancelAssignment,
            historyLimit: _historyLimit,
            onLoadMoreActive: () =>
                setState(() => _activeAssignmentLimit += 50),
            onLoadMore: () => setState(() => _historyLimit += 20),
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
            if (!_canAssign && myAssignments.length == _activeAssignmentLimit)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _activeAssignmentLimit += 50),
                  child: const Text('Load more assigned training'),
                ),
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
                detail: openCount == _activeAssignmentLimit
                    ? '$openCount+ open assignments'
                    : '$openCount open assignments',
                onTap: () => setState(() => _view = 'team'),
              ),
            ],
          ],
        );
      },
    );
  }
}
