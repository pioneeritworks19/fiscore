part of '../../main.dart';

class _ActionInboxContent extends StatelessWidget {
  const _ActionInboxContent({
    required this.tenantId,
    required this.siteId,
    required this.currentUserId,
    required this.currentRole,
    required this.initialFilter,
    required this.onBack,
    required this.onOpenViolation,
    required this.onOpenTraining,
    required this.onOpenAudit,
  });

  final String tenantId;
  final String siteId;
  final String currentUserId;
  final String currentRole;
  final String initialFilter;
  final VoidCallback onBack;
  final void Function(String siteId, String violationId, String statusFilter)
  onOpenViolation;
  final void Function(String siteId, String assignmentId) onOpenTraining;
  final void Function(String siteId, String assignmentId) onOpenAudit;

  bool get _canManage =>
      const ['tenant_owner', 'admin', 'manager'].contains(currentRole);

  @override
  Widget build(BuildContext context) {
    final repository = ActionItemRepository();
    final isTeamOverdue =
        (initialFilter == 'training_overdue' ||
            initialFilter == 'audit_overdue') &&
        _canManage;
    final stream = isTeamOverdue
        ? repository.teamOpenActions(tenantId: tenantId, siteId: siteId)
        : repository.myOpenActions(
            tenantId: tenantId,
            userId: currentUserId,
            siteId: siteId,
          );
    final title = switch (initialFilter) {
      'review' => 'Fixes ready for review',
      'assigned_fixes' => 'My assigned fixes',
      'checks' => 'My checks',
      'training' => 'My training',
      'training_overdue' => 'Overdue training',
      'audit_overdue' => 'Overdue checks',
      _ => 'Action inbox',
    };
    final subtitle = switch (initialFilter) {
      'review' => 'Review submitted fixes and close the work loop.',
      'assigned_fixes' => 'Complete resolutions assigned to you.',
      'checks' => 'Continue checks you started or were assigned.',
      'training' => 'Complete the coaching assigned to you.',
      'training_overdue' =>
        'Follow up on training that has passed its due date.',
      'audit_overdue' => 'Follow up on checks that have passed their due date.',
      _ => 'Work that needs your attention.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to today'),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final actions =
                (snapshot.data?.docs ?? []).where((doc) {
                  final action = doc.data();
                  return switch (initialFilter) {
                    'review' => action['type'] == 'violation_review',
                    'assigned_fixes' =>
                      (action['type'] == 'violation_resolution' ||
                              action['type'] == 'violation_sent_back') &&
                          action['recipientUserId'] == currentUserId,
                    'training' =>
                      action['type'] == 'training_completion' &&
                          action['recipientUserId'] == currentUserId,
                    'checks' =>
                      action['type'] == 'audit_completion' &&
                          action['recipientUserId'] == currentUserId,
                    'training_overdue' =>
                      action['type'] == 'training_completion' &&
                          action['dueState'] == 'overdue',
                    'audit_overdue' =>
                      action['type'] == 'audit_completion' &&
                          action['dueState'] == 'overdue',
                    _ => true,
                  };
                }).toList()..sort(
                  (a, b) => _actionSortValue(
                    a.data(),
                  ).compareTo(_actionSortValue(b.data())),
                );
            if (actions.isEmpty) {
              return const _EmptyStateCard(
                icon: Icons.task_alt_outlined,
                title: 'Nothing needs attention',
                body: 'New work will appear here when it is ready.',
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, indent: 14, endIndent: 14),
                    if (actions[index].data()['targetType'] == 'violation')
                      _ViolationListRow(
                        data: _ViolationRowData.fromAction(
                          actions[index].data(),
                        ),
                        framed: false,
                        onOpen: () async {
                          final action = actions[index].data();
                          if (action['recipientUserId'] == currentUserId) {
                            await repository.markRead(
                              tenantId: tenantId,
                              actionItemId: actions[index].id,
                            );
                          }
                          onOpenViolation(
                            action['siteId'] as String? ?? siteId,
                            action['targetId'] as String? ?? '',
                            initialFilter == 'review'
                                ? 'pending_review'
                                : 'active',
                          );
                        },
                      )
                    else
                      _ActionInboxRow(
                        action: actions[index].data(),
                        onTap: () async {
                          final action = actions[index].data();
                          if (action['recipientUserId'] == currentUserId) {
                            await repository.markRead(
                              tenantId: tenantId,
                              actionItemId: actions[index].id,
                            );
                          }
                          final targetId = action['targetId'] as String? ?? '';
                          final targetSiteId =
                              action['siteId'] as String? ?? siteId;
                          if (action['targetType'] == 'training_assignment') {
                            onOpenTraining(targetSiteId, targetId);
                          } else if (action['targetType'] ==
                              'audit_assignment') {
                            onOpenAudit(targetSiteId, targetId);
                          }
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActionInboxRow extends StatelessWidget {
  const _ActionInboxRow({required this.action, required this.onTap});

  final Map<String, dynamic> action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHigh = action['priority'] == 'high';
    final isOverdue = action['dueState'] == 'overdue';
    final isAssignedCheck = action['targetType'] == 'audit_assignment';
    final checkOwnershipLabel =
        action['assignmentSourceSnapshot'] == 'self_started'
        ? 'Started by you'
        : 'Assigned to you';
    final checkActionLabel =
        (action['title'] as String? ?? '').startsWith('Complete')
        ? 'Start'
        : 'Resume';
    final color = isHigh || isOverdue
        ? const Color(0xFFD92D20)
        : const Color(0xFF2859C5);
    final dueText = isOverdue
        ? 'Overdue'
        : action['dueAt'] is Timestamp
        ? _actionDueLabel(action['dueAt'] as Timestamp)
        : null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                action['targetType'] == 'violation'
                    ? Icons.verified_outlined
                    : action['targetType'] == 'audit_assignment'
                    ? Icons.fact_check_outlined
                    : Icons.school_outlined,
                size: 19,
                color: color,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action['title'] as String? ?? 'Action needed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action['detail'] as String? ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                  if (isAssignedCheck) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        checkOwnershipLabel,
                        ?dueText,
                      ].join(' / '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? color : _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else if (dueText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      dueText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? color : _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isAssignedCheck)
              TextButton(onPressed: onTap, child: Text(checkActionLabel))
            else
              const Padding(
                padding: EdgeInsets.only(top: 7),
                child: Icon(Icons.chevron_right, color: _navy, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

int _actionSortValue(Map<String, dynamic> action) {
  if (action['dueState'] == 'overdue') return 0;
  if (action['priority'] == 'high') return 1;
  return 2;
}

String _actionDueLabel(Timestamp timestamp) {
  final due = timestamp.toDate();
  final today = DateTime.now();
  final difference = DateTime(
    due.year,
    due.month,
    due.day,
  ).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (difference == 0) return 'Due today';
  if (difference == 1) return 'Due tomorrow';
  if (difference > 1) return 'Due in $difference days';
  return 'Overdue';
}
