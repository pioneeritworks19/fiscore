part of '../../main.dart';

enum _ViolationRowContext { queue, auditDetail, publicInspectionDetail }

class _ViolationRowData {
  const _ViolationRowData({
    required this.title,
    required this.status,
    this.contextText,
    this.supportingText,
    this.severityText,
    this.assignmentText,
  });

  factory _ViolationRowData.fromViolation(
    Map<String, dynamic> violation, {
    required _ViolationRowContext context,
  }) {
    final sourceType = violation['sourceType'] as String?;
    final title = _firstAvailableText([
      violation['title'],
      violation['summaryText'],
      'Violation finding',
    ]);
    final status = violation['status'] as String? ?? 'open';
    final severity = _severityLabel(violation['severity'] as String?);
    final assignedTo = _displayText(violation['assignedTo']);
    final assignedName = _displayText(violation['assignedToNameSnapshot']);
    final isAssignedToMe =
        assignedTo.isNotEmpty &&
        assignedTo == FirebaseAuth.instance.currentUser?.uid;
    final assignmentText = assignedTo.isEmpty
        ? null
        : isAssignedToMe
        ? 'Assigned to you'
        : 'Assigned to ${assignedName.isEmpty ? 'team member' : assignedName}';
    if (context == _ViolationRowContext.auditDetail) {
      final observation = _firstAvailableText([
        violation['auditorComments'],
        violation['description'],
      ]);
      return _ViolationRowData(
        title: title,
        status: status,
        contextText: observation.isEmpty ? null : 'Observed: $observation',
        severityText: severity,
        assignmentText: assignmentText,
      );
    }
    if (context == _ViolationRowContext.publicInspectionDetail) {
      return _ViolationRowData(
        title: title,
        status: status,
        contextText: _displayText(violation['clauseReference']),
        severityText: severity,
        assignmentText: assignmentText,
      );
    }
    if (sourceType == 'internal_audit') {
      return _ViolationRowData(
        title: title,
        status: status,
        contextText: _joinNonEmpty([
          'Internal check',
          _displayText(violation['sourceTitleSnapshot']),
          _violationSourceDate(violation['sourceOccurredAt']),
        ]),
        severityText: severity,
        assignmentText: assignmentText,
      );
    }
    return _ViolationRowData(
      title: title,
      status: status,
      contextText: _joinNonEmpty([
        _sourceLabel(sourceType),
        _dateText(violation['inspectionDate']),
      ]),
      supportingText: _displayText(violation['clauseReference']),
      severityText: severity,
      assignmentText: assignmentText,
    );
  }

  factory _ViolationRowData.fromAction(Map<String, dynamic> action) {
    final type = action['type'] as String? ?? '';
    final title = _firstAvailableText([action['detail'], 'Violation']);
    final sourceLabel = _displayText(action['sourceLabelSnapshot']);
    final sourceTitle = _displayText(action['sourceTitleSnapshot']);
    final sourceDate = _violationSourceDate(action['sourceOccurredAtSnapshot']);
    final severity = _displayText(action['severitySnapshot']);
    final status = switch (type) {
      'violation_review' => 'pending_review',
      _ => 'in_progress',
    };
    final workflowText = switch (type) {
      'violation_review' => 'Ready for your review',
      'violation_sent_back' => 'Sent back for an update',
      _ => 'Assigned to you',
    };
    return _ViolationRowData(
      title: title,
      status: status,
      contextText: _joinNonEmpty([
        sourceLabel,
        sourceTitle,
        sourceDate,
        workflowText,
      ]),
      severityText: severity.isEmpty ? null : _severityLabel(severity),
    );
  }

  final String title;
  final String status;
  final String? contextText;
  final String? supportingText;
  final String? severityText;
  final String? assignmentText;
}

class _ViolationListRow extends StatelessWidget {
  const _ViolationListRow({
    required this.data,
    required this.onOpen,
    this.framed = true,
  });

  final _ViolationRowData data;
  final VoidCallback onOpen;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: framed ? 10 : 0),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: framed
              ? BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _severityColor(
                      data.severityText ?? 'Severity unknown',
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SmallStatusBadge(status: data.status),
                        ],
                      ),
                      if ((data.contextText ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          data.contextText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _muted,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if ((data.supportingText ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.supportingText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _muted,
                          ),
                        ),
                      ],
                      if ((data.severityText ?? '').isNotEmpty ||
                          (data.assignmentText ?? '').isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if ((data.severityText ?? '').isNotEmpty)
                              Text(
                                data.severityText!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            if ((data.assignmentText ?? '').isNotEmpty)
                              Text(
                                data.assignmentText!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF2859C5),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: _navy, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _violationSourceDate(Object? value) {
  final date = switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    DateTime date => date,
    String string => DateTime.tryParse(string),
    _ => null,
  };
  if (date == null) return '';
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
  return '${months[date.month - 1]} ${date.day}';
}
