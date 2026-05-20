part of '../../main.dart';

class _AuditsContent extends StatefulWidget {
  const _AuditsContent({
    required this.tenantId,
    required this.siteId,
  });

  final String tenantId;
  final String siteId;

  @override
  State<_AuditsContent> createState() => _AuditsContentState();
}

class _AuditsContentState extends State<_AuditsContent> {
  final InspectionRepository _inspectionRepository = InspectionRepository();
  final ViolationRepository _violationRepository = ViolationRepository();
  String? _selectedInspectionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _inspectionRepository.streamForSite(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
      ),
      builder: (context, inspectionSnapshot) {
        if (inspectionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final inspections = inspectionSnapshot.data?.docs ?? [];
        inspections.sort((a, b) {
          return _dateText(
            b.data()['inspectionDate'],
          ).compareTo(_dateText(a.data()['inspectionDate']));
        });

        if (inspections.isEmpty) {
          return const _EmptyStateCard(
            icon: Icons.fact_check_outlined,
            title: 'No inspections yet',
            body:
                'Refresh from master data to import public inspection history for this site.',
          );
        }

        QueryDocumentSnapshot<Map<String, dynamic>>? selectedInspection;
        for (final doc in inspections) {
          if (doc.id == _selectedInspectionId) {
            selectedInspection = doc;
            break;
          }
        }

        if (selectedInspection != null) {
          final selectedDoc = selectedInspection;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _violationRepository.streamForSite(
              tenantId: widget.tenantId,
              siteId: widget.siteId,
            ),
            builder: (context, violationSnapshot) {
              final violations = (violationSnapshot.data?.docs ?? [])
                  .where(
                    (doc) =>
                        doc.data()['masterInspectionId'] ==
                        selectedDoc.id,
                  )
                  .toList();
              violations.sort((a, b) {
                final aStatus = _statusRank(
                  a.data()['status'] as String? ?? '',
                );
                final bStatus = _statusRank(
                  b.data()['status'] as String? ?? '',
                );
                if (aStatus != bStatus) {
                  return aStatus.compareTo(bStatus);
                }
                final aOrder = a.data()['findingOrder'] as num? ?? 9999;
                final bOrder = b.data()['findingOrder'] as num? ?? 9999;
                return aOrder.compareTo(bOrder);
              });

              return _InspectionDetailView(
                inspectionId: selectedDoc.id,
                inspection: selectedDoc.data(),
                violations: violations,
                isLoadingViolations:
                    violationSnapshot.connectionState ==
                    ConnectionState.waiting,
                onBack: () {
                  setState(() {
                    _selectedInspectionId = null;
                  });
                },
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audits',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _inspectionSummaryText(inspections),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            for (final inspection in inspections)
              _InspectionListCard(
                inspection: inspection.data(),
                onOpen: () {
                  setState(() {
                    _selectedInspectionId = inspection.id;
                  });
                },
              ),
          ],
        );
      },
    );
  }
}

class _InspectionListCard extends StatelessWidget {
  const _InspectionListCard({required this.inspection, required this.onOpen});

  final Map<String, dynamic> inspection;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grade = _inspectionGradeText(inspection);
    final score = _inspectionScoreText(inspection);
    final findingCount = (inspection['findingCount'] as num?)?.toInt() ?? 0;
    final reportReady =
        _displayText(inspection['reportStoragePath']).isNotEmpty ||
        _displayText(inspection['reportAvailabilityStatus']) == 'available';

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
                  Icons.fact_check_outlined,
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
                      _inspectionTitle(inspection),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _joinNonEmpty([
                        _dateText(inspection['inspectionDate']),
                        _displayText(inspection['sourceName']),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (grade.isNotEmpty) _AuditPill(label: 'Grade $grade'),
                        if (score.isNotEmpty)
                          _AuditPill(label: 'Score $score', color: _green),
                        _AuditPill(
                          label: '$findingCount findings',
                          color: findingCount == 0 ? _green : _navy,
                        ),
                        if (reportReady)
                          const _AuditPill(
                            label: 'Report stored',
                            color: Color(0xFF1D4ED8),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _navy, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectionDetailView extends StatelessWidget {
  const _InspectionDetailView({
    required this.inspectionId,
    required this.inspection,
    required this.violations,
    required this.isLoadingViolations,
    required this.onBack,
  });

  final String inspectionId;
  final Map<String, dynamic> inspection;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> violations;
  final bool isLoadingViolations;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final closed = _countViolations('closed');
    final review = _countViolations('pending_review');
    final active = violations.length - closed - review;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          label: const Text('Back to audits'),
        ),
        const SizedBox(height: 8),
        _InspectionHeroCard(inspection: inspection),
        const SizedBox(height: 14),
        _InspectionSourceCard(inspection: inspection),
        const SizedBox(height: 14),
        if (isLoadingViolations)
          const Center(child: CircularProgressIndicator())
        else if (violations.isEmpty)
          const _EmptyStateCard(
            icon: Icons.check_circle_outline,
            title: 'No findings on this inspection',
            body:
                'This inspection does not have linked violation work in FiScore yet.',
          )
        else ...[
          _DashboardSection(
            title: 'Work summary',
            trailing: '$closed of ${violations.length} closed',
            children: [
              _InspectionProgressRow(
                active: active,
                review: review,
                closed: closed,
                total: violations.length,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InspectionViolationGroup(
            title: 'Needs action',
            violations: violations
                .where((doc) {
                  final status = doc.data()['status'] as String? ?? 'open';
                  return status == 'open' || status == 'in_progress';
                })
                .toList(),
          ),
          const SizedBox(height: 14),
          _InspectionViolationGroup(
            title: 'Submitted for review',
            violations: violations
                .where(
                  (doc) =>
                      (doc.data()['status'] as String? ?? 'open') ==
                      'pending_review',
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          _InspectionViolationGroup(
            title: 'Closed',
            violations: violations
                .where(
                  (doc) =>
                      (doc.data()['status'] as String? ?? 'open') == 'closed',
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Inspection ID: $inspectionId',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
        ),
      ],
    );
  }

  int _countViolations(String status) {
    return violations
        .where((doc) => (doc.data()['status'] as String? ?? 'open') == status)
        .length;
  }
}

class _InspectionHeroCard extends StatelessWidget {
  const _InspectionHeroCard({required this.inspection});

  final Map<String, dynamic> inspection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AuditPill(
                label: _inspectionStateLabel(
                  inspection['importState'] as String?,
                ),
                color: _inspectionStateColor(
                  inspection['importState'] as String?,
                ),
              ),
              if (_inspectionGradeText(inspection).isNotEmpty)
                _AuditPill(label: 'Grade ${_inspectionGradeText(inspection)}'),
              if (_inspectionScoreText(inspection).isNotEmpty)
                _AuditPill(
                  label: 'Score ${_inspectionScoreText(inspection)}',
                  color: _green,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _inspectionTitle(inspection),
            style: theme.textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _joinNonEmpty([
              _dateText(inspection['inspectionDate']),
              _displayText(inspection['sourceName']),
            ]),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionSourceCard extends StatelessWidget {
  const _InspectionSourceCard({required this.inspection});

  final Map<String, dynamic> inspection;

  @override
  Widget build(BuildContext context) {
    final facts = [
      _DetailFact('Inspection date', _dateText(inspection['inspectionDate'])),
      _DetailFact('Inspection type', inspection['inspectionType']),
      _DetailFact('Score', _inspectionScoreText(inspection)),
      _DetailFact('Grade', _inspectionGradeText(inspection)),
      _DetailFact('Official status', inspection['officialStatus']),
      _DetailFact('Findings', inspection['findingCount']),
      _DetailFact('Report status', inspection['reportAvailabilityStatus']),
      _DetailFact('Report format', inspection['reportFormat']),
      _DetailFact(
        'Report',
        _displayText(inspection['reportStoragePath']).isEmpty
            ? ''
            : 'Stored in FiScore',
      ),
    ];

    return _DetailFactCard(
      title: 'Inspection details',
      icon: Icons.fact_check_outlined,
      facts: facts,
      emptyText: 'Inspection details will appear here after master-data sync.',
      collapsedSummary: _joinNonEmpty([
        _displayText(inspection['inspectionType']),
        _dateText(inspection['inspectionDate']),
        _inspectionGradeText(inspection).isEmpty
            ? ''
            : 'Grade ${_inspectionGradeText(inspection)}',
      ]),
      initiallyExpanded: true,
    );
  }
}

class _InspectionProgressRow extends StatelessWidget {
  const _InspectionProgressRow({
    required this.active,
    required this.review,
    required this.closed,
    required this.total,
  });

  final int active;
  final int review;
  final int closed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : closed / total;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFE8EEF6),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$active active / $review review / $closed closed',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionViolationGroup extends StatelessWidget {
  const _InspectionViolationGroup({
    required this.title,
    required this.violations,
  });

  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> violations;

  @override
  Widget build(BuildContext context) {
    if (violations.isEmpty) {
      return _DashboardSection(
        title: title,
        trailing: '0',
        children: const [
          _InspectionEmptyRow(),
        ],
      );
    }

    return _DashboardSection(
      title: title,
      trailing: violations.length.toString(),
      children: [
        for (final doc in violations)
          _InspectionFindingRow(violation: doc.data()),
      ],
    );
  }
}

class _InspectionFindingRow extends StatelessWidget {
  const _InspectionFindingRow({required this.violation});

  final Map<String, dynamic> violation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = violation['status'] as String? ?? 'open';
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line.withValues(alpha: 0.7))),
      ),
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
            child: Icon(Icons.report_problem_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  violation['title'] as String? ??
                      violation['summaryText'] as String? ??
                      'Violation finding',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _joinNonEmpty([
                    _violationStatusLabel(status),
                    _severityLabel(violation['severity'] as String?),
                  ]),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionEmptyRow extends StatelessWidget {
  const _InspectionEmptyRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        'Nothing here right now.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _muted,
            ),
      ),
    );
  }
}

class _AuditPill extends StatelessWidget {
  const _AuditPill({required this.label, this.color = _navy});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

String _inspectionSummaryText(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> inspections,
) {
  final latestDate = inspections.isEmpty
      ? ''
      : _dateText(inspections.first.data()['inspectionDate']);
  return _joinNonEmpty([
    '${inspections.length} imported inspections',
    latestDate.isEmpty ? '' : 'latest $latestDate',
  ]);
}

String _inspectionTitle(Map<String, dynamic> inspection) {
  final type = _displayText(inspection['inspectionType']);
  if (type.isNotEmpty) {
    return type;
  }
  return 'Public inspection';
}

String _inspectionScoreText(Map<String, dynamic> inspection) {
  return _firstAvailableText([
    inspection['inspectionScore'],
    inspection['score'],
  ]);
}

String _inspectionGradeText(Map<String, dynamic> inspection) {
  return _firstAvailableText([
    inspection['inspectionGrade'],
    inspection['grade'],
  ]);
}

String _inspectionStateLabel(String? state) {
  switch ((state ?? '').trim().toLowerCase()) {
    case 'latest':
      return 'Latest';
    case 'historical':
      return 'Historical';
    default:
      return 'Imported';
  }
}

Color _inspectionStateColor(String? state) {
  switch ((state ?? '').trim().toLowerCase()) {
    case 'latest':
      return const Color(0xFF1D4ED8);
    case 'historical':
      return const Color(0xFF64748B);
    default:
      return _navy;
  }
}
