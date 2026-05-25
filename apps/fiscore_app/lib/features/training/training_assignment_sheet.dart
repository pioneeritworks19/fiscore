part of '../../main.dart';

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
