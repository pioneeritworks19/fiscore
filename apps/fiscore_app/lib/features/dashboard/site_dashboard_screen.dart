part of '../../main.dart';

class _SiteDashboardContent extends StatefulWidget {
  const _SiteDashboardContent({
    required this.tenantId,
    required this.siteId,
    required this.site,
    required this.currentUserId,
    required this.canManageTraining,
    required this.onOpenUnassignedViolations,
    required this.onOpenActions,
    required this.onOpenAudits,
    required this.onAddSite,
    required this.onStartAudit,
    required this.canStartAudit,
  });

  final String tenantId;
  final String siteId;
  final Map<String, dynamic> site;
  final String currentUserId;
  final bool canManageTraining;
  final VoidCallback onOpenUnassignedViolations;
  final ValueChanged<String> onOpenActions;
  final VoidCallback onOpenAudits;
  final VoidCallback onAddSite;
  final VoidCallback onStartAudit;
  final bool canStartAudit;

  @override
  State<_SiteDashboardContent> createState() => _SiteDashboardContentState();
}

class _SiteDashboardContentState extends State<_SiteDashboardContent> {
  final ViolationRepository _violationRepository = ViolationRepository();
  final ActionItemRepository _actionItemRepository = ActionItemRepository();
  final InternalAuditRepository _internalAuditRepository =
      InternalAuditRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final site = widget.site;
    final latestInspectionDate =
        site['latestInspectionDateSnapshot'] as String?;
    final latestGrade = site['latestInspectionGradeSnapshot'] as String?;
    final latestScore = (site['latestInspectionScoreSnapshot'] as num?)
        ?.toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Today',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              'Daily work',
              style: theme.textTheme.bodySmall?.copyWith(color: _muted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _violationRepository.streamForSite(
            tenantId: widget.tenantId,
            siteId: widget.siteId,
          ),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final active = docs.where((doc) {
              final status = doc.data()['status'];
              return status != 'closed' && status != 'pending_review';
            }).toList();
            final unassignedViolations = active
                .where(
                  (doc) => (doc.data()['assignedTo'] as String? ?? '').isEmpty,
                )
                .length;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _actionItemRepository.myOpenActions(
                tenantId: widget.tenantId,
                userId: widget.currentUserId,
              ),
              builder: (context, myActionSnapshot) {
                final myActions = (myActionSnapshot.data?.docs ?? [])
                    .map((doc) => doc.data())
                    .where((action) => action['siteId'] == widget.siteId)
                    .toList();
                final myOpenTraining = myActions
                    .where((action) => action['type'] == 'training_completion')
                    .length;
                final myChecks = myActions
                    .where((action) => action['type'] == 'audit_completion')
                    .length;
                final reviews = myActions
                    .where((action) => action['type'] == 'violation_review')
                    .length;
                final assignedFixes = myActions
                    .where(
                      (action) =>
                          action['type'] == 'violation_resolution' ||
                          action['type'] == 'violation_sent_back',
                    )
                    .length;
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: widget.canManageTraining
                      ? _actionItemRepository.teamOpenActions(
                          tenantId: widget.tenantId,
                          siteId: widget.siteId,
                        )
                      : null,
                  builder: (context, teamActionSnapshot) {
                    final overdueTraining = widget.canManageTraining
                        ? (teamActionSnapshot.data?.docs ?? [])
                              .where(
                                (doc) =>
                                    doc.data()['type'] ==
                                        'training_completion' &&
                                    doc.data()['dueState'] == 'overdue',
                              )
                              .length
                        : 0;
                    final overdueChecks = widget.canManageTraining
                        ? (teamActionSnapshot.data?.docs ?? [])
                              .where(
                                (doc) =>
                                    doc.data()['type'] == 'audit_completion' &&
                                    doc.data()['dueState'] == 'overdue',
                              )
                              .length
                        : 0;
                    return _NeedsActionCard(
                      unassignedViolationCount: unassignedViolations,
                      assignedFixCount: assignedFixes,
                      reviewCount: reviews,
                      myCheckCount: myChecks,
                      myTrainingCount: myOpenTraining,
                      overdueCheckCount: overdueChecks,
                      overdueTrainingCount: overdueTraining,
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting ||
                          myActionSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          (widget.canManageTraining &&
                              teamActionSnapshot.connectionState ==
                                  ConnectionState.waiting),
                      showManagerActions: widget.canManageTraining,
                      onOpenViolations: widget.onOpenUnassignedViolations,
                      onOpenAssignedFixes: () =>
                          widget.onOpenActions('assigned_fixes'),
                      onOpenMyChecks: () => widget.onOpenActions('checks'),
                      onOpenReviews: () => widget.onOpenActions('review'),
                      onOpenMyTraining: () => widget.onOpenActions('training'),
                      onOpenOverdueChecks: () =>
                          widget.onOpenActions('audit_overdue'),
                      onOpenOverdueTraining: () =>
                          widget.onOpenActions('training_overdue'),
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          'Recent activity',
          style: theme.textTheme.titleMedium?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _DashboardActivityRow(
                icon: Icons.fact_check_outlined,
                title: 'Public inspection',
                detail: latestInspectionDate == null
                    ? 'No imported inspection yet'
                    : _dashboardDateLabel(latestInspectionDate),
                chips: [
                  if (latestGrade != null && latestGrade.isNotEmpty)
                    _DashboardChip(label: 'Grade $latestGrade'),
                  if (latestScore != null)
                    _DashboardChip(label: 'Score $latestScore', color: _green),
                ],
                onTap: widget.onOpenAudits,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _internalAuditRepository.streamForSite(
                  tenantId: widget.tenantId,
                  siteId: widget.siteId,
                ),
                builder: (context, snapshot) {
                  final audits = snapshot.data?.docs ?? [];
                  final audit = audits.isEmpty ? null : audits.first.data();
                  final title =
                      audit?['templateNameSnapshot'] as String? ??
                      'Internal check';
                  final isComplete = audit?['status'] == 'completed';
                  final detail = audit == null
                      ? 'No internal check completed yet'
                      : isComplete
                      ? 'Most recent check completed'
                      : 'Check in progress';
                  final score = audit?['scorePercentage'];

                  return _DashboardActivityRow(
                    icon: Icons.playlist_add_check_circle_outlined,
                    title: title,
                    detail: detail,
                    chips: [
                      if (isComplete && score != null)
                        _DashboardChip(label: '$score% score', color: _green),
                    ],
                    onTap: widget.onOpenAudits,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (widget.canStartAudit)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onStartAudit,
              icon: const Icon(Icons.playlist_add_check_outlined),
              label: const Text('Start internal check'),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: widget.onOpenAudits,
                icon: const Icon(Icons.fact_check_outlined, size: 19),
                label: const Text('View audits'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextButton.icon(
                onPressed: widget.onAddSite,
                icon: const Icon(Icons.add_business_outlined, size: 19),
                label: const Text('Add site'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NeedsActionCard extends StatelessWidget {
  const _NeedsActionCard({
    required this.unassignedViolationCount,
    required this.assignedFixCount,
    required this.reviewCount,
    required this.myCheckCount,
    required this.myTrainingCount,
    required this.overdueCheckCount,
    required this.overdueTrainingCount,
    required this.isLoading,
    required this.showManagerActions,
    required this.onOpenViolations,
    required this.onOpenAssignedFixes,
    required this.onOpenMyChecks,
    required this.onOpenReviews,
    required this.onOpenMyTraining,
    required this.onOpenOverdueChecks,
    required this.onOpenOverdueTraining,
  });

  final int unassignedViolationCount;
  final int assignedFixCount;
  final int reviewCount;
  final int myCheckCount;
  final int myTrainingCount;
  final int overdueCheckCount;
  final int overdueTrainingCount;
  final bool isLoading;
  final bool showManagerActions;
  final VoidCallback onOpenViolations;
  final VoidCallback onOpenAssignedFixes;
  final VoidCallback onOpenMyChecks;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenMyTraining;
  final VoidCallback onOpenOverdueChecks;
  final VoidCallback onOpenOverdueTraining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Needs action',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: CircularProgressIndicator(),
            )
          else if (assignedFixCount == 0 &&
              myCheckCount == 0 &&
              myTrainingCount == 0 &&
              (!showManagerActions ||
                  (reviewCount == 0 &&
                      unassignedViolationCount == 0 &&
                      overdueCheckCount == 0 &&
                      overdueTrainingCount == 0)))
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Text(
                'Nothing needs attention right now.',
                style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
              ),
            )
          else ...[
            if (assignedFixCount > 0 || myCheckCount > 0 || myTrainingCount > 0)
              const _DashboardActionGroupLabel(label: 'My work'),
            if (assignedFixCount > 0)
              _DashboardActionRow(
                icon: Icons.assignment_ind_outlined,
                color: const Color(0xFF2859C5),
                count: assignedFixCount,
                title: 'Fixes assigned to me',
                detail: 'Complete assigned resolutions',
                onTap: onOpenAssignedFixes,
              ),
            if (myCheckCount > 0)
              _DashboardActionRow(
                icon: Icons.fact_check_outlined,
                color: const Color(0xFF2859C5),
                count: myCheckCount,
                title: 'Checks assigned to me',
                detail: 'Complete assigned checklists',
                onTap: onOpenMyChecks,
              ),
            if (myTrainingCount > 0)
              _DashboardActionRow(
                icon: Icons.school_outlined,
                color: const Color(0xFF2859C5),
                count: myTrainingCount,
                title: 'Training assigned to me',
                detail: 'Complete assigned coaching',
                onTap: onOpenMyTraining,
              ),
            if (showManagerActions &&
                (reviewCount > 0 ||
                    unassignedViolationCount > 0 ||
                    overdueCheckCount > 0 ||
                    overdueTrainingCount > 0))
              const _DashboardActionGroupLabel(label: 'Team follow-up'),
            if (showManagerActions && reviewCount > 0)
              _DashboardActionRow(
                icon: Icons.verified_outlined,
                color: _green,
                count: reviewCount,
                title: 'Fixes ready for review',
                detail: 'Approve or send back completed work',
                onTap: onOpenReviews,
              ),
            if (showManagerActions && unassignedViolationCount > 0)
              _DashboardActionRow(
                icon: Icons.report_problem_outlined,
                color: const Color(0xFFD92D20),
                count: unassignedViolationCount,
                title: 'Unassigned violations',
                detail: 'Assign follow-up responsibility',
                onTap: onOpenViolations,
              ),
            if (showManagerActions && overdueCheckCount > 0)
              _DashboardActionRow(
                icon: Icons.fact_check_outlined,
                color: const Color(0xFFB54708),
                count: overdueCheckCount,
                title: 'Overdue checks',
                detail: 'Follow up with assigned staff',
                onTap: onOpenOverdueChecks,
              ),
            if (showManagerActions && overdueTrainingCount > 0)
              _DashboardActionRow(
                icon: Icons.schedule_outlined,
                color: const Color(0xFFB54708),
                count: overdueTrainingCount,
                title: 'Staff training overdue',
                detail: 'Follow up on overdue assignments',
                onTap: onOpenOverdueTraining,
              ),
          ],
        ],
      ),
    );
  }
}

class _DashboardActionGroupLabel extends StatelessWidget {
  const _DashboardActionGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DashboardActionRow extends StatelessWidget {
  const _DashboardActionRow({
    required this.icon,
    required this.color,
    required this.count,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                color: count == 0 ? _muted : color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: _navy, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DashboardActivityRow extends StatelessWidget {
  const _DashboardActivityRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.chips,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final List<Widget> chips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: _navy, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(spacing: 6, runSpacing: 6, children: chips),
                  ],
                ],
              ),
            ),
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

class _DashboardChip extends StatelessWidget {
  const _DashboardChip({required this.label, this.color = _navy});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _dashboardDateLabel(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return date;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

bool _isTrainingOverdue(Object? value) {
  if (value is! Timestamp) {
    return false;
  }
  final due = value.toDate();
  final today = DateTime.now();
  return DateTime(
    due.year,
    due.month,
    due.day,
  ).isBefore(DateTime(today.year, today.month, today.day));
}
