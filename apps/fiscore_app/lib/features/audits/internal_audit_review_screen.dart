part of '../../main.dart';

class _InternalAuditReview extends StatelessWidget {
  const _InternalAuditReview({
    required this.questions,
    required this.sections,
    required this.responses,
    required this.error,
    required this.onBack,
    required this.onEditSection,
    required this.onContinue,
  });

  final List<Map<String, dynamic>> questions;
  final List<MapEntry<String, List<Map<String, dynamic>>>> sections;
  final Map<String, Map<String, dynamic>> responses;
  final String? error;
  final VoidCallback onBack;
  final ValueChanged<int> onEditSection;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final failures = questions
        .where(
          (question) =>
              responses[question['id']]?['answer'] == 'needs_attention',
        )
        .toList();
    final missingNotes = failures
        .where(
          (question) => (responses[question['id']]?['note'] as String? ?? '')
              .trim()
              .isEmpty,
        )
        .length;
    final missingAnswers = _internalAuditMissingAnswerCount(
      questions,
      responses,
    );
    final completeSections = sections.where((section) {
      return section.value.every(
        (question) => _internalAuditQuestionComplete(question, responses),
      );
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to last section'),
        ),
        Text(
          'Review checklist',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$completeSections of ${sections.length} sections complete',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < sections.length; index++)
          _AuditReviewSectionRow(
            title: sections[index].key,
            questions: sections[index].value,
            responses: responses,
            onTap: () => onEditSection(index),
          ),
        if (failures.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Issues found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final question in failures)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question['prompt'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    responses[question['id']]?['note'] as String? ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
              ),
            ),
        ],
        if (missingNotes > 0) ...[
          const SizedBox(height: 10),
          _StatusMessage(
            icon: Icons.info_outline,
            color: const Color(0xFFB42318),
            text:
                'Add issue descriptions for $missingNotes item(s) before submitting.',
          ),
        ],
        if (missingAnswers > 0) ...[
          const SizedBox(height: 10),
          _StatusMessage(
            icon: Icons.info_outline,
            color: _muted,
            text: 'Answer $missingAnswers remaining item(s) before submitting.',
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 10),
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: error!,
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _AuditReviewSectionRow extends StatelessWidget {
  const _AuditReviewSectionRow({
    required this.title,
    required this.questions,
    required this.responses,
    required this.onTap,
  });

  final String title;
  final List<Map<String, dynamic>> questions;
  final Map<String, Map<String, dynamic>> responses;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final attentionCount = questions
        .where(
          (question) =>
              responses[question['id']]?['answer'] == 'needs_attention',
        )
        .length;
    final missingAnswers = _internalAuditMissingAnswerCount(
      questions,
      responses,
    );
    final missingIssueNotes = _internalAuditMissingIssueNoteCount(
      questions,
      responses,
    );
    final complete = questions.every(
      (question) => _internalAuditQuestionComplete(question, responses),
    );
    final hasIncompleteWork = missingAnswers > 0 || missingIssueNotes > 0;
    final summary = missingAnswers > 0
        ? '$missingAnswers unanswered'
        : missingIssueNotes > 0
        ? '$missingIssueNotes issue ${missingIssueNotes == 1 ? 'description' : 'descriptions'} missing'
        : attentionCount > 0
        ? '$attentionCount ${attentionCount == 1 ? 'issue' : 'issues'} flagged'
        : '${questions.length} completed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                hasIncompleteWork
                    ? Icons.error_outline
                    : attentionCount > 0
                    ? Icons.warning_amber_outlined
                    : complete
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                size: 20,
                color: hasIncompleteWork
                    ? const Color(0xFFB45309)
                    : attentionCount > 0
                    ? const Color(0xFFB42318)
                    : complete
                    ? _green
                    : _muted,
              ),
              const SizedBox(width: 10),
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
                    Text(
                      summary,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: _navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternalAuditSubmitConfirmation extends StatelessWidget {
  const _InternalAuditSubmitConfirmation({
    required this.audit,
    required this.questions,
    required this.responses,
    required this.isSubmitting,
    required this.error,
    required this.onBack,
    required this.onSubmit,
  });

  final Map<String, dynamic> audit;
  final List<Map<String, dynamic>> questions;
  final Map<String, Map<String, dynamic>> responses;
  final bool isSubmitting;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final violations = questions.where((question) {
      return responses[question['id']]?['answer'] == 'needs_attention' &&
          question['createsViolation'] == true;
    }).toList();
    final criticalCount = violations
        .where((question) => question['failSeverity'] == 'critical')
        .length;
    final missingAnswers = _internalAuditMissingAnswerCount(
      questions,
      responses,
    );
    final missingIssueNotes = _internalAuditMissingIssueNoteCount(
      questions,
      responses,
    );
    final canSubmit = missingAnswers == 0 && missingIssueNotes == 0;
    final answeredQuestions = questions
        .where(
          (question) => _internalAuditQuestionHasAnswer(question, responses),
        )
        .toList();
    final applicable = answeredQuestions
        .where(
          (question) =>
              responses[question['id']]?['answer'] != 'not_applicable',
        )
        .length;
    final passing = answeredQuestions
        .where((question) => responses[question['id']]?['answer'] == 'pass')
        .length;
    final score = applicable == 0
        ? 100
        : ((passing / applicable) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: isSubmitting ? null : onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to review'),
        ),
        Text(
          'Submit check',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          audit['templateNameSnapshot'] as String? ?? 'Internal check',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AuditPill(
                    label: canSubmit ? '$score% score' : 'Incomplete',
                    color: canSubmit ? _green : const Color(0xFFB45309),
                  ),
                  _AuditPill(
                    label:
                        '${violations.length} ${violations.length == 1 ? 'violation' : 'violations'} will be created',
                    color: violations.isEmpty
                        ? _green
                        : const Color(0xFFB42318),
                  ),
                  if (criticalCount > 0)
                    _AuditPill(
                      label: '$criticalCount critical',
                      color: const Color(0xFFB42318),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                !canSubmit
                    ? 'Finish the remaining checklist items before submitting this audit.'
                    : violations.isEmpty
                    ? 'No follow-up violations will be created.'
                    : 'Created violations will be added to the site queue for resolution and review.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.35),
              ),
            ],
          ),
        ),
        if (!canSubmit) ...[
          const SizedBox(height: 12),
          _StatusMessage(
            icon: Icons.info_outline,
            color: const Color(0xFFB45309),
            text: [
              if (missingAnswers > 0) '$missingAnswers unanswered item(s)',
              if (missingIssueNotes > 0)
                '$missingIssueNotes missing issue description(s)',
            ].join(' and '),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: error!,
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSubmitting || !canSubmit ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(isSubmitting ? 'Submitting...' : 'Submit audit'),
          ),
        ),
      ],
    );
  }
}

class _InternalAuditCompletion extends StatelessWidget {
  const _InternalAuditCompletion({
    required this.tenantId,
    required this.siteId,
    required this.auditId,
    required this.audit,
    required this.responses,
    required this.onBack,
    required this.onOpenViolation,
  });

  final String tenantId;
  final String siteId;
  final String auditId;
  final Map<String, dynamic> audit;
  final Map<String, Map<String, dynamic>> responses;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenViolation;

  @override
  Widget build(BuildContext context) {
    final violationCount = _internalAuditViolationCount(audit);
    final failedResponses = responses.values
        .where((response) => response['answer'] == 'needs_attention')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to checks'),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _AuditPill(label: 'Completed', color: _green),
                  const Spacer(),
                  Text(
                    'Submitted',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                audit['templateNameSnapshot'] as String? ?? 'Internal check',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dateText(audit['completedAt']),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AuditPill(
                    label: '${audit['scorePercentage'] ?? 0}% score',
                    color: _green,
                  ),
                  _AuditPill(
                    label:
                        '$violationCount ${violationCount == 1 ? 'violation' : 'violations'} created',
                    color: violationCount == 0
                        ? _green
                        : const Color(0xFFB42318),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (failedResponses.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Needs action',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirestorePaths.violations(tenantId, siteId).snapshots(),
            builder: (context, snapshot) {
              final violations = (snapshot.data?.docs ?? [])
                  .where((doc) => doc.data()['auditId'] == auditId)
                  .toList();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (violations.isEmpty) {
                return Text(
                  'Created violations will appear here shortly.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _muted),
                );
              }
              return Column(
                children: [
                  for (final doc in violations)
                    _InspectionFindingRow(
                      violation: doc.data(),
                      rowContext: _ViolationRowContext.auditDetail,
                      onOpen: () => onOpenViolation(doc.id),
                    ),
                ],
              );
            },
          ),
        ] else ...[
          const SizedBox(height: 16),
          const _EmptyStateCard(
            icon: Icons.check_circle_outline,
            title: 'No follow-up needed',
            body: 'No violations were created from this check.',
          ),
        ],
      ],
    );
  }
}

List<Map<String, dynamic>> _internalQuestionsFromAudit(
  Map<String, dynamic> audit,
) {
  final template = audit['templateSnapshot'];
  if (template is! Map) return [];
  final sections = template['sections'] as List<dynamic>? ?? [];
  return [
    for (final rawSection in sections)
      if (rawSection is Map)
        for (final rawQuestion
            in (rawSection['questions'] as List<dynamic>? ?? []))
          if (rawQuestion is Map)
            {
              ...Map<String, dynamic>.from(rawQuestion),
              'sectionId': rawSection['id'],
              'sectionTitle': rawSection['title'],
            },
  ];
}

List<MapEntry<String, List<Map<String, dynamic>>>> _groupInternalQuestions(
  List<Map<String, dynamic>> questions,
) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final question in questions) {
    final section = question['sectionTitle'] as String? ?? 'Checklist';
    grouped.putIfAbsent(section, () => []).add(question);
  }
  return grouped.entries.toList();
}

int _internalAuditViolationCount(Map<String, dynamic> audit) {
  return (audit['violationCount'] as num?)?.toInt() ??
      (audit['findingCount'] as num?)?.toInt() ??
      0;
}
