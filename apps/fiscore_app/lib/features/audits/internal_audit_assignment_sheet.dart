part of '../../main.dart';

Future<bool?> showAuditAssignmentSheet(
  BuildContext context, {
  required String tenantId,
  required String siteId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AssignAuditSheet(tenantId: tenantId, siteId: siteId),
  );
}

Future<String?> showAuditReassignmentSheet(
  BuildContext context, {
  required String tenantId,
  required String siteId,
  required String currentAssigneeId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AuditSingleMemberSheet(
      tenantId: tenantId,
      siteId: siteId,
      currentAssigneeId: currentAssigneeId,
      title: 'Reassign check',
    ),
  );
}

class _AssignAuditSheet extends StatefulWidget {
  const _AssignAuditSheet({required this.tenantId, required this.siteId});

  final String tenantId;
  final String siteId;

  @override
  State<_AssignAuditSheet> createState() => _AssignAuditSheetState();
}

class _AssignAuditSheetState extends State<_AssignAuditSheet> {
  final InternalAuditRepository _repository = InternalAuditRepository();
  final TextEditingController _noteController = TextEditingController();
  String? _templateId;
  String? _assigneeId;
  String? _assigneeName;
  int _dueInDays = 3;
  DateTime? _customDueDate;
  int _duePickerVersion = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    if (_templateId == null) {
      setState(() => _error = 'Choose a checklist.');
      return;
    }
    if (_assigneeId == null) {
      setState(() => _error = 'Choose a teammate.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.assignCheck(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        templateId: _templateId!,
        assignedTo: _assigneeId!,
        dueDate:
            _customDueDate ?? DateTime.now().add(Duration(days: _dueInDays)),
        note: _noteController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not assign this check. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign check',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Choose a checklist and one teammate to complete it.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _muted),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repository.checklistTemplatesStream(
                  tenantId: widget.tenantId,
                ),
                builder: (context, snapshot) {
                  final templates = snapshot.data?.docs ?? [];
                  if (_templateId == null && templates.isNotEmpty) {
                    _templateId = templates.first.id;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _templateId,
                    decoration: const InputDecoration(labelText: 'Checklist'),
                    items: [
                      for (final template in templates)
                        DropdownMenuItem(
                          value: template.id,
                          child: Text(
                            template.data()['name'] as String? ?? 'Checklist',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _templateId = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final userId = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (context) => _AuditSingleMemberSheet(
                      tenantId: widget.tenantId,
                      siteId: widget.siteId,
                      currentAssigneeId: _assigneeId,
                      title: 'Assign to',
                    ),
                  );
                  if (!mounted || userId == null) return;
                  final snap = await FirestorePaths.member(
                    widget.tenantId,
                    userId,
                  ).get();
                  if (!mounted) return;
                  final member = snap.data() ?? const <String, dynamic>{};
                  setState(() {
                    _assigneeId = userId;
                    _assigneeName =
                        member['displayNameSnapshot'] as String? ??
                        member['emailSnapshot'] as String? ??
                        'Team member';
                  });
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Assign to',
                    suffixIcon: Icon(Icons.chevron_right),
                  ),
                  child: Text(
                    _assigneeName ?? 'Choose teammate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _assigneeName == null ? _muted : _ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey(
                  'audit-due-$_duePickerVersion-$_dueInDays-${_customDueDate?.millisecondsSinceEpoch}',
                ),
                initialValue: _dueInDays,
                decoration: const InputDecoration(labelText: 'Due date'),
                items: [
                  const DropdownMenuItem(value: 1, child: Text('Tomorrow')),
                  const DropdownMenuItem(value: 3, child: Text('In 3 days')),
                  const DropdownMenuItem(value: 7, child: Text('In 1 week')),
                  const DropdownMenuItem(value: 14, child: Text('In 2 weeks')),
                  const DropdownMenuItem(value: 30, child: Text('In 1 month')),
                  DropdownMenuItem(
                    value: -1,
                    child: Text(
                      _customDueDate == null
                          ? 'Choose date'
                          : 'Choose date (${_customDueDate!.month}/${_customDueDate!.day})',
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;
                  if (value != -1) {
                    setState(() {
                      _dueInDays = value;
                      _customDueDate = null;
                      _duePickerVersion += 1;
                    });
                    return;
                  }
                  final today = DateUtils.dateOnly(DateTime.now());
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _customDueDate ?? today.add(const Duration(days: 7)),
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 365)),
                  );
                  if (date != null && mounted) {
                    setState(() {
                      _dueInDays = -1;
                      _customDueDate = date;
                      _duePickerVersion += 1;
                    });
                  } else if (mounted) {
                    setState(() => _duePickerVersion += 1);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Optional note',
                  hintText: 'Example: Complete before closing shift.',
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
                  onPressed: _saving ? null : _assign,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Assign check'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditSingleMemberSheet extends StatefulWidget {
  const _AuditSingleMemberSheet({
    required this.tenantId,
    required this.siteId,
    required this.currentAssigneeId,
    required this.title,
  });

  final String tenantId;
  final String siteId;
  final String? currentAssigneeId;
  final String title;

  @override
  State<_AuditSingleMemberSheet> createState() =>
      _AuditSingleMemberSheetState();
}

class _AuditSingleMemberSheetState extends State<_AuditSingleMemberSheet> {
  final TeamRepository _repository = TeamRepository();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _hasAccess(Map<String, dynamic> member) {
    if (member['status'] != 'active') return false;
    final role = member['role'] as String?;
    if (role == 'tenant_owner' || role == 'admin') return true;
    if (member['siteAccessMode'] != 'selected') return true;
    return (member['siteIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .contains(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
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
              widget.title,
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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repository.membersStream(widget.tenantId),
                builder: (context, snapshot) {
                  final members = (snapshot.data?.docs ?? []).where((doc) {
                    final member = doc.data();
                    if (!_hasAccess(member)) return false;
                    final searchable =
                        '${member['displayNameSnapshot'] ?? ''} ${member['emailSnapshot'] ?? ''}'
                            .toLowerCase();
                    return _query.isEmpty ||
                        searchable.contains(_query.toLowerCase());
                  }).toList();
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final member in members)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            member.id == widget.currentAssigneeId
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _navy,
                          ),
                          title: Text(
                            member.data()['displayNameSnapshot'] as String? ??
                                member.data()['emailSnapshot'] as String? ??
                                'Team member',
                          ),
                          subtitle: Text(
                            member.data()['emailSnapshot'] as String? ?? '',
                          ),
                          onTap: () => Navigator.of(context).pop(member.id),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignedAuditRow extends StatelessWidget {
  const _AssignedAuditRow({
    required this.assignment,
    required this.isAssignee,
    required this.canReassign,
    required this.canCancel,
    required this.onStart,
    required this.onReassign,
    required this.onCancel,
  });

  final Map<String, dynamic> assignment;
  final bool isAssignee;
  final bool canReassign;
  final bool canCancel;
  final VoidCallback onStart;
  final VoidCallback onReassign;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final status = assignment['status'] as String? ?? 'assigned';
    final assignee =
        (assignment['assignedToNameSnapshot'] as String? ?? '').trim();
    final selfStarted = assignment['assignmentSource'] == 'self_started';
    final ownerLabel = selfStarted
        ? isAssignee
              ? 'Started by you'
              : assignee.isNotEmpty
              ? 'Started by $assignee'
              : 'Self-started'
        : assignee;
    final due = _auditAssignmentDueLabel(assignment['dueDate']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, color: _navy),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment['templateNameSnapshot'] as String? ??
                        'Internal check',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (ownerLabel.isNotEmpty) ownerLabel,
                      ?due,
                      if (status == 'in_progress') 'In progress',
                    ].join(' / '),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
            if (isAssignee)
              TextButton(
                onPressed: onStart,
                child: Text(status == 'in_progress' ? 'Resume' : 'Start'),
              ),
            if (canReassign || canCancel)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'reassign') onReassign();
                  if (value == 'cancel') onCancel();
                },
                itemBuilder: (context) => [
                  if (canReassign)
                    const PopupMenuItem(
                      value: 'reassign',
                      child: Text('Reassign'),
                    ),
                  if (canCancel)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel check'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String? _auditAssignmentDueLabel(Object? value) {
  if (value is! Timestamp) return null;
  final date = value.toDate();
  final today = DateTime.now();
  final difference = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (difference < 0) return 'Overdue';
  if (difference == 0) return 'Due today';
  if (difference == 1) return 'Due tomorrow';
  return 'Due ${date.month}/${date.day}';
}
