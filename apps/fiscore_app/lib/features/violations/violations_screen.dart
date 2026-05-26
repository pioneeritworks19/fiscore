part of '../../main.dart';

class _ViolationsContent extends StatefulWidget {
  const _ViolationsContent({
    required this.tenantId,
    required this.siteId,
    required this.site,
    required this.currentRole,
    this.initialStatusFilter = 'active',
    this.initialViolationId,
    this.detailBackLabel,
    this.onBackFromDetail,
  });

  final String tenantId;
  final String siteId;
  final Map<String, dynamic> site;
  final String currentRole;
  final String initialStatusFilter;
  final String? initialViolationId;
  final String? detailBackLabel;
  final VoidCallback? onBackFromDetail;

  @override
  State<_ViolationsContent> createState() => _ViolationsContentState();
}

class _ViolationsContentState extends State<_ViolationsContent> {
  final ViolationRepository _violationRepository = ViolationRepository();
  String _viewMode = 'queue';
  late String _statusFilter;
  String? _selectedViolationId;
  String? _loadedViolationId;
  bool _isSaving = false;
  String? _message;
  String? _error;

  final _generalController = TextEditingController();
  final _containmentController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _correctiveController = TextEditingController();
  final _preventiveController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
    _selectedViolationId = widget.initialViolationId;
  }

  @override
  void dispose() {
    _generalController.dispose();
    _containmentController.dispose();
    _rootCauseController.dispose();
    _correctiveController.dispose();
    _preventiveController.dispose();
    super.dispose();
  }

  void _loadResponseFields(String violationId, Map<String, dynamic> violation) {
    if (_loadedViolationId == violationId) {
      return;
    }
    _loadedViolationId = violationId;
    _generalController.text = violation['responseGeneral'] as String? ?? '';
    _containmentController.text =
        violation['responseContainment'] as String? ?? '';
    _rootCauseController.text = violation['responseRootCause'] as String? ?? '';
    _correctiveController.text =
        violation['responseCorrectiveAction'] as String? ?? '';
    _preventiveController.text =
        violation['responsePreventiveAction'] as String? ?? '';
  }

  Future<void> _updateViolationStatus(
    String violationId,
    String status, {
    String? reviewStatus,
    String? closureReason,
  }) async {
    setState(() {
      _isSaving = true;
      _message = null;
      _error = null;
    });

    try {
      await _violationRepository.updateStatus(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        status: status,
        reviewStatus: reviewStatus,
        closureReason: closureReason,
      );
      setState(() {
        _message = 'Violation moved to ${_violationStatusLabel(status)}.';
      });
    } catch (_) {
      setState(() {
        _error = 'Could not update the violation. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveResponse(String violationId, String currentStatus) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await _violationRepository.saveStructuredResponse(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        startWork: currentStatus == 'open',
        response: {
          'responseGeneral': _generalController.text.trim(),
          'responseContainment': _containmentController.text.trim(),
          'responseRootCause': _rootCauseController.text.trim(),
          'responseCorrectiveAction': _correctiveController.text.trim(),
          'responsePreventiveAction': _preventiveController.text.trim(),
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Saved for later.')));
    } catch (_) {
      setState(() {
        _error = 'Could not save the response. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _submitResponseForReview(String violationId) async {
    if (_correctiveController.text.trim().isEmpty) {
      setState(() {
        _message = null;
        _error = 'Enter what was fixed before submitting for review.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
      _error = null;
    });

    try {
      await _violationRepository.saveStructuredResponse(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        response: {
          'responseGeneral': _generalController.text.trim(),
          'responseContainment': _containmentController.text.trim(),
          'responseRootCause': _rootCauseController.text.trim(),
          'responseCorrectiveAction': _correctiveController.text.trim(),
          'responsePreventiveAction': _preventiveController.text.trim(),
        },
      );
      await _violationRepository.updateStatus(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        status: 'pending_review',
        reviewStatus: 'submitted',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submitted for review.')));
      setState(() {
        _message = 'Submitted for review.';
      });
    } catch (_) {
      setState(() {
        _error = 'Could not submit the response. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _sendBackForChanges(String violationId) async {
    final feedback = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _SendBackSheet(),
    );
    if (!mounted || feedback == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
      _error = null;
    });

    try {
      await _violationRepository.sendBackForChanges(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        feedback: feedback,
      );
      if (mounted) {
        setState(() {
          _message = 'Sent back for changes.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not send this violation back. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool get _canManageAssignments =>
      const ['tenant_owner', 'admin', 'manager'].contains(widget.currentRole);

  Future<void> _manageAssignment(
    String violationId,
    Map<String, dynamic> violation,
  ) async {
    final choice = await showModalBottomSheet<_ViolationAssignmentChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ViolationAssignmentSheet(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        assignedTo: violation['assignedTo'] as String?,
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    setState(() {
      _isSaving = true;
      _message = null;
      _error = null;
    });
    try {
      if (choice.remove) {
        await _violationRepository.unassignViolation(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: violationId,
        );
        if (mounted) {
          setState(() => _message = 'Assignment removed.');
        }
      } else {
        await _violationRepository.assignViolation(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: violationId,
          assignedTo: choice.userId!,
        );
        if (mounted) {
          setState(() => _message = 'Assigned to ${choice.name}.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not update the assignment. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredViolations(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final siteDocs = docs
        .where((doc) => doc.data()['siteId'] == widget.siteId)
        .toList();
    if (_statusFilter == 'active') {
      return siteDocs.where((doc) {
        final status = doc.data()['status'] as String? ?? 'open';
        return status != 'closed' && status != 'pending_review';
      }).toList();
    }
    if (_statusFilter == 'unassigned') {
      return siteDocs.where((doc) {
        final status = doc.data()['status'] as String? ?? 'open';
        return status != 'closed' &&
            status != 'pending_review' &&
            (doc.data()['assignedTo'] as String? ?? '').isEmpty;
      }).toList();
    }
    if (_statusFilter == 'all') {
      return siteDocs;
    }
    return siteDocs
        .where(
          (doc) => (doc.data()['status'] as String? ?? 'open') == _statusFilter,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _violationRepository.streamForSite(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allViolations = snapshot.data?.docs ?? [];
        allViolations.sort((a, b) {
          final aData = a.data();
          final bData = b.data();
          final aStatus = _statusRank(aData['status'] as String? ?? 'open');
          final bStatus = _statusRank(bData['status'] as String? ?? 'open');
          if (aStatus != bStatus) {
            return aStatus.compareTo(bStatus);
          }
          return _dateText(
            bData['inspectionDate'],
          ).compareTo(_dateText(aData['inspectionDate']));
        });
        final visibleViolations = _filteredViolations(allViolations);
        QueryDocumentSnapshot<Map<String, dynamic>>? selectedDoc;
        for (final doc in allViolations) {
          if (doc.id == _selectedViolationId) {
            selectedDoc = doc;
            break;
          }
        }

        if (selectedDoc != null) {
          _loadResponseFields(selectedDoc.id, selectedDoc.data());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedDoc == null) ...[
              Text(
                'Violations',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              _ViolationSummaryStrip(violations: allViolations),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ViolationFilterChips(
                      value: _statusFilter,
                      reviewCount: allViolations
                          .where(
                            (doc) => doc.data()['status'] == 'pending_review',
                          )
                          .length,
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ViolationGroupButton(
                    isGrouped: _viewMode == 'inspection',
                    onPressed: () {
                      setState(() {
                        _viewMode = _viewMode == 'inspection'
                            ? 'queue'
                            : 'inspection';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (visibleViolations.isEmpty)
                const _EmptyStateCard(
                  icon: Icons.check_circle_outline,
                  title: 'No violations in this view',
                  body:
                      'Change the filter, or refresh public inspection data from More to import new findings.',
                )
              else if (_viewMode == 'inspection')
                _InspectionGroupedViolations(
                  violations: visibleViolations,
                  onOpenViolation: (id) {
                    setState(() {
                      _selectedViolationId = id;
                      _message = null;
                      _error = null;
                    });
                  },
                )
              else
                ...visibleViolations.map(
                  (doc) => _ViolationListCard(
                    violation: doc.data(),
                    onOpen: () {
                      setState(() {
                        _selectedViolationId = doc.id;
                        _message = null;
                        _error = null;
                      });
                    },
                  ),
                ),
            ] else ...[
              Builder(
                builder: (context) {
                  final selectedViolationId = selectedDoc!.id;
                  final selectedViolation = selectedDoc.data();
                  return _ViolationDetailView(
                    tenantId: widget.tenantId,
                    violationId: selectedViolationId,
                    violation: selectedViolation,
                    currentRole: widget.currentRole,
                    generalController: _generalController,
                    containmentController: _containmentController,
                    rootCauseController: _rootCauseController,
                    correctiveController: _correctiveController,
                    preventiveController: _preventiveController,
                    isSaving: _isSaving,
                    message: _message,
                    error: _error,
                    backLabel: widget.detailBackLabel ?? 'Back to violations',
                    onBack: () {
                      if (widget.onBackFromDetail != null) {
                        widget.onBackFromDetail!();
                        return;
                      }
                      setState(() {
                        _selectedViolationId = null;
                        _loadedViolationId = null;
                        _message = null;
                        _error = null;
                      });
                    },
                    onSaveResponse: () => _saveResponse(
                      selectedViolationId,
                      selectedViolation['status'] as String? ?? 'open',
                    ),
                    onSubmitForReview: () =>
                        _submitResponseForReview(selectedViolationId),
                    onSendBack: () => _sendBackForChanges(selectedViolationId),
                    onManageAssignment:
                        _canManageAssignments &&
                            selectedViolation['status'] != 'closed' &&
                            selectedViolation['status'] != 'pending_review'
                        ? () => _manageAssignment(
                            selectedViolationId,
                            selectedViolation,
                          )
                        : null,
                    onUpdateStatus: (status, {reviewStatus, closureReason}) =>
                        _updateViolationStatus(
                          selectedViolationId,
                          status,
                          reviewStatus: reviewStatus,
                          closureReason: closureReason,
                        ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ViolationSummaryStrip extends StatelessWidget {
  const _ViolationSummaryStrip({required this.violations});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> violations;

  int _count(String status) => violations
      .where((doc) => (doc.data()['status'] as String? ?? 'open') == status)
      .length;

  @override
  Widget build(BuildContext context) {
    final open = _count('open');
    final progress = _count('in_progress');
    final review = _count('pending_review');
    final closed = _count('closed');
    final active = open + progress;
    final theme = Theme.of(context);

    return Text(
      '$active active / $review awaiting review / $closed closed',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: _muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ViolationFilterChips extends StatelessWidget {
  const _ViolationFilterChips({
    required this.value,
    required this.reviewCount,
    required this.onChanged,
  });

  final String value;
  final int reviewCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('active', 'Active'),
      if (value == 'unassigned') ('unassigned', 'Unassigned'),
      ('pending_review', reviewCount > 0 ? 'Review ($reviewCount)' : 'Review'),
      ('closed', 'Closed'),
      ('all', 'All'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            ChoiceChip(
              label: Text(filter.$2),
              selected: value == filter.$1,
              onSelected: (_) => onChanged(filter.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ViolationGroupButton extends StatelessWidget {
  const _ViolationGroupButton({
    required this.isGrouped,
    required this.onPressed,
  });

  final bool isGrouped;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isGrouped ? 'Show as queue' : 'Group by inspection',
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(46, 42),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          isGrouped ? Icons.view_list_outlined : Icons.fact_check_outlined,
          size: 20,
        ),
      ),
    );
  }
}

class _InspectionGroupedViolations extends StatelessWidget {
  const _InspectionGroupedViolations({
    required this.violations,
    required this.onOpenViolation,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> violations;
  final ValueChanged<String> onOpenViolation;

  @override
  Widget build(BuildContext context) {
    final groups =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in violations) {
      final data = doc.data();
      final key = _dateText(data['inspectionDate']).isEmpty
          ? 'Inspection date unknown'
          : _dateText(data['inspectionDate']);
      groups.putIfAbsent(key, () => []).add(doc);
    }

    return Column(
      children: [
        for (final entry in groups.entries) ...[
          _DashboardSection(
            title: entry.key,
            trailing: '${entry.value.length} findings',
            children: [
              for (final doc in entry.value)
                _ActionRow(
                  icon: _sourceIcon(doc.data()['sourceType'] as String?),
                  title:
                      doc.data()['title'] as String? ??
                      doc.data()['summaryText'] as String? ??
                      'Violation finding',
                  body:
                      '${_violationStatusLabel(doc.data()['status'] as String? ?? 'open')} - ${_sourceLabel(doc.data()['sourceType'] as String?)}',
                  enabled: true,
                  toneColor: _statusColor(doc.data()['status'] as String?),
                  onTap: () => onOpenViolation(doc.id),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ViolationListCard extends StatelessWidget {
  const _ViolationListCard({required this.violation, required this.onOpen});

  final Map<String, dynamic> violation;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _ViolationListRow(
      data: _ViolationRowData.fromViolation(
        violation,
        context: _ViolationRowContext.queue,
      ),
      onOpen: onOpen,
    );
  }
}

class _ViolationAssignmentChoice {
  const _ViolationAssignmentChoice.assign({
    required this.userId,
    required this.name,
  }) : remove = false;

  const _ViolationAssignmentChoice.remove()
    : userId = null,
      name = null,
      remove = true;

  final String? userId;
  final String? name;
  final bool remove;
}

class _ViolationAssignmentSheet extends StatelessWidget {
  const _ViolationAssignmentSheet({
    required this.tenantId,
    required this.siteId,
    required this.assignedTo,
  });

  final String tenantId;
  final String siteId;
  final String? assignedTo;

  bool _canAccessSite(Map<String, dynamic> member) {
    final role = member['role'] as String?;
    if (role == 'tenant_owner' || role == 'admin') {
      return true;
    }
    if (member['siteAccessMode'] != 'selected') {
      return true;
    }
    return (member['siteIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .contains(siteId);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignedTo == null ? 'Assign violation' : 'Change assignment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Choose who owns the resolution and submission.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestorePaths.members(tenantId).snapshots(),
              builder: (context, snapshot) {
                final members = (snapshot.data?.docs ?? []).where((doc) {
                  final member = doc.data();
                  return member['status'] == 'active' && _canAccessSite(member);
                }).toList();
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final member in members)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline, color: _navy),
                        title: Text(
                          member.data()['displayNameSnapshot'] as String? ??
                              member.data()['emailSnapshot'] as String? ??
                              'Team member',
                        ),
                        subtitle: Text(
                          _roleLabel(
                            member.data()['role'] as String? ?? 'staff',
                          ),
                        ),
                        trailing: member.id == assignedTo
                            ? const Icon(Icons.check, color: _green)
                            : null,
                        onTap: () => Navigator.of(context).pop(
                          _ViolationAssignmentChoice.assign(
                            userId: member.id,
                            name:
                                member.data()['displayNameSnapshot']
                                    as String? ??
                                member.data()['emailSnapshot'] as String? ??
                                'Team member',
                          ),
                        ),
                      ),
                    if (assignedTo != null && assignedTo!.isNotEmpty) ...[
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_off_outlined),
                        title: const Text('Remove assignment'),
                        onTap: () => Navigator.of(
                          context,
                        ).pop(const _ViolationAssignmentChoice.remove()),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ViolationDetailView extends StatelessWidget {
  const _ViolationDetailView({
    required this.tenantId,
    required this.violationId,
    required this.violation,
    required this.currentRole,
    required this.generalController,
    required this.containmentController,
    required this.rootCauseController,
    required this.correctiveController,
    required this.preventiveController,
    required this.isSaving,
    required this.message,
    required this.error,
    required this.onBack,
    required this.onSaveResponse,
    required this.onSubmitForReview,
    this.onSendBack,
    this.onManageAssignment,
    required this.onUpdateStatus,
    this.backLabel = 'Back to violations',
  });

  final String tenantId;
  final String violationId;
  final Map<String, dynamic> violation;
  final String currentRole;
  final TextEditingController generalController;
  final TextEditingController containmentController;
  final TextEditingController rootCauseController;
  final TextEditingController correctiveController;
  final TextEditingController preventiveController;
  final bool isSaving;
  final String? message;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onSaveResponse;
  final VoidCallback onSubmitForReview;
  final VoidCallback? onSendBack;
  final VoidCallback? onManageAssignment;
  final String backLabel;
  final void Function(
    String status, {
    String? reviewStatus,
    String? closureReason,
  })
  onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final status = violation['status'] as String? ?? 'open';
    final title =
        violation['title'] as String? ??
        violation['summaryText'] as String? ??
        'Violation finding';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          label: Text(backLabel),
        ),
        const SizedBox(height: 8),
        _ViolationDetailHero(
          title: title,
          status: status,
          severity: violation['severity'] as String?,
        ),
        if (status == 'pending_review') ...[
          const SizedBox(height: 14),
          const _ReadyForReviewBanner(),
        ],
        const SizedBox(height: 14),
        _ViolationFactsSection(tenantId: tenantId, violation: violation),
        const SizedBox(height: 14),
        _ViolationWorkArea(
          tenantId: tenantId,
          violationId: violationId,
          violation: violation,
          currentRole: currentRole,
          generalController: generalController,
          containmentController: containmentController,
          rootCauseController: rootCauseController,
          correctiveController: correctiveController,
          preventiveController: preventiveController,
          isSaving: isSaving,
          onManageAssignment: onManageAssignment,
          onSaveResponse: onSaveResponse,
          onSubmitForReview: onSubmitForReview,
        ),
        const SizedBox(height: 14),
        if (message != null)
          _StatusMessage(
            icon: Icons.check_circle_outline,
            color: _green,
            text: message!,
          ),
        if (error != null)
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: error!,
          ),
        const SizedBox(height: 14),
        _ViolationActions(
          status: status,
          isSaving: isSaving,
          onSendBack:
              onSendBack ??
              () => onUpdateStatus('in_progress', reviewStatus: 'needs_work'),
          onUpdateStatus: onUpdateStatus,
        ),
      ],
    );
  }
}

class _ViolationDetailHero extends StatelessWidget {
  const _ViolationDetailHero({
    required this.title,
    required this.status,
    required this.severity,
  });

  final String title;
  final String status;
  final String? severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityText = _severityLabel(severity);
    final showSeverity = _shouldShowSeverity(severity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A071A4A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallStatusBadge(status: status),
              if (showSeverity) ...[
                const SizedBox(width: 8),
                _DetailChip(
                  label: severityText,
                  color: _severityColor(severityText),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyForReviewBanner extends StatelessWidget {
  const _ReadyForReviewBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: _softGreen,
        border: Border.all(color: const Color(0xFFCFEBDD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: _green, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready for review',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Resolution submitted and waiting for approval.',
                  style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViolationFactsSection extends StatelessWidget {
  const _ViolationFactsSection({
    required this.tenantId,
    required this.violation,
  });

  final String tenantId;
  final Map<String, dynamic> violation;

  @override
  Widget build(BuildContext context) {
    final sourceType = violation['sourceType'] as String?;
    final violationFacts = [
      _DetailFact(
        'Inspector note',
        _firstAvailableText([
          violation['auditorComments'],
          violation['creatorComments'],
          violation['comments'],
          violation['description'],
        ]),
      ),
      _DetailFact('Section', violation['sectionLabel']),
      _DetailFact('Category', violation['normalizedCategory']),
      _DetailFact('Official code', violation['officialCode']),
      _DetailFact(
        'Clause',
        _firstAvailableText([
          violation['officialClauseReference'],
          violation['clauseReference'],
        ]),
      ),
      _DetailFact('Question', violation['questionLabel']),
      _DetailFact('Observed response', violation['responseLabel']),
      _DetailFact('Severity', _severityLabel(violation['severity'] as String?)),
      _DetailFact(
        'Corrected during inspection',
        violation['correctedDuringInspection'],
      ),
      _DetailFact('Repeat violation', violation['isRepeatViolation']),
      _DetailFact(
        'Official text',
        _firstAvailableText([
          violation['officialText'],
          violation['displayText'],
          violation['summaryText'],
        ]),
      ),
    ];
    final sourceCard = _SourceDetailsCard(
      tenantId: tenantId,
      violation: violation,
      sourceType: sourceType,
    );

    return Column(
      children: [
        sourceCard,
        const SizedBox(height: 12),
        _DetailFactCard(
          title: 'Violation details',
          icon: Icons.subject_outlined,
          facts: violationFacts,
          emptyText: 'No additional violation detail is available yet.',
          collapsedSummary: _firstAvailableText([
            violation['creatorComments'],
            violation['auditorComments'],
            violation['description'],
            violation['officialText'],
            violation['displayText'],
          ]),
          initiallyExpanded: false,
        ),
      ],
    );
  }
}

class _DetailFact {
  const _DetailFact(this.label, this.value);

  final String label;
  final Object? value;
}

class _SourceDetailsCard extends StatelessWidget {
  const _SourceDetailsCard({
    required this.tenantId,
    required this.violation,
    required this.sourceType,
  });

  final String tenantId;
  final Map<String, dynamic> violation;
  final String? sourceType;

  @override
  Widget build(BuildContext context) {
    final siteId = violation['siteId'] as String? ?? '';
    final inspectionId = _firstAvailableText([
      violation['masterInspectionId'],
      violation['sourceReferenceId'],
      violation['sourceInspectionId'],
    ]);

    if (siteId.isEmpty || inspectionId.isEmpty) {
      return _buildCard(violation);
    }

    if (sourceType == 'internal_audit') {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestorePaths.internalAudit(
          tenantId,
          siteId,
          inspectionId,
        ).snapshots(),
        builder: (context, snapshot) {
          final merged = {...violation, ...?snapshot.data?.data()};
          return _buildCard(merged);
        },
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.siteInspection(
        tenantId,
        siteId,
        inspectionId,
      ).snapshots(),
      builder: (context, snapshot) {
        final merged = {...violation, ...?snapshot.data?.data()};
        return _buildCard(merged);
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> source) {
    final facts = [
      _DetailFact('Source', _sourceLabel(sourceType)),
      _DetailFact(
        sourceType == 'internal_audit' ? 'Completed' : 'Inspection date',
        _dateText(
          sourceType == 'internal_audit'
              ? source['completedAt']
              : source['inspectionDate'],
        ),
      ),
      _DetailFact(
        sourceType == 'internal_audit' ? 'Check' : 'Inspection type',
        sourceType == 'internal_audit'
            ? source['templateNameSnapshot']
            : source['inspectionType'],
      ),
      _DetailFact(
        'Inspection score',
        _firstAvailableText([source['inspectionScore'], source['score']]),
      ),
      _DetailFact(
        'Inspection grade',
        _firstAvailableText([source['inspectionGrade'], source['grade']]),
      ),
      _DetailFact('Official status', source['officialStatus']),
      _DetailFact(
        'Report',
        _firstAvailableText([
          source['reportStoragePath'],
          source['reportPath'],
        ]),
      ),
      _DetailFact(
        sourceType == 'internal_audit' ? 'Checklist item' : 'Question response',
        sourceType == 'internal_audit'
            ? source['questionLabel']
            : source['sourceQuestionResponseId'],
      ),
    ];

    return _DetailFactCard(
      title: 'Source details',
      icon: _sourceIcon(sourceType),
      facts: facts,
      emptyText: 'Source information will appear here as imports mature.',
      collapsedSummary: _compactSourceSummary(source),
      initiallyExpanded: false,
    );
  }
}

class _DetailFactCard extends StatelessWidget {
  const _DetailFactCard({
    required this.title,
    required this.icon,
    required this.facts,
    required this.emptyText,
    required this.collapsedSummary,
    required this.initiallyExpanded,
    this.footer,
  });

  final String title;
  final IconData icon;
  final List<_DetailFact> facts;
  final String emptyText;
  final String collapsedSummary;
  final bool initiallyExpanded;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleFacts = facts
        .map((fact) => _DetailFact(fact.label, _displayText(fact.value)))
        .where((fact) => (fact.value as String).isNotEmpty)
        .toList();

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _navy, size: 18),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: collapsedSummary.isEmpty
              ? null
              : Text(
                  collapsedSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted,
                    height: 1.25,
                  ),
                ),
          children: [
            if (visibleFacts.isEmpty)
              Text(
                emptyText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _muted,
                  height: 1.35,
                ),
              )
            else
              for (final fact in visibleFacts)
                _DetailFactRow(label: fact.label, value: fact.value as String),
            if (footer != null) ...[const SizedBox(height: 2), footer!],
          ],
        ),
      ),
    );
  }
}

class _DetailFactRow extends StatelessWidget {
  const _DetailFactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              textAlign: TextAlign.left,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.left,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _ink,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViolationWorkArea extends StatefulWidget {
  const _ViolationWorkArea({
    required this.tenantId,
    required this.violationId,
    required this.violation,
    required this.currentRole,
    required this.generalController,
    required this.containmentController,
    required this.rootCauseController,
    required this.correctiveController,
    required this.preventiveController,
    required this.isSaving,
    required this.onSaveResponse,
    required this.onSubmitForReview,
    this.onManageAssignment,
  });

  final String tenantId;
  final String violationId;
  final Map<String, dynamic> violation;
  final String currentRole;
  final TextEditingController generalController;
  final TextEditingController containmentController;
  final TextEditingController rootCauseController;
  final TextEditingController correctiveController;
  final TextEditingController preventiveController;
  final bool isSaving;
  final VoidCallback onSaveResponse;
  final VoidCallback onSubmitForReview;
  final VoidCallback? onManageAssignment;

  @override
  State<_ViolationWorkArea> createState() => _ViolationWorkAreaState();
}

class _ViolationWorkAreaState extends State<_ViolationWorkArea> {
  final Set<String> _visibleResponseFields = {};
  final Map<String, Uint8List> _localProofPreviews = {};

  @override
  void initState() {
    super.initState();
    _seedVisibleResponseFields();
  }

  void _seedVisibleResponseFields() {
    final fields = {
      'general': widget.generalController,
      'containment': widget.containmentController,
      'rootCause': widget.rootCauseController,
      'corrective': widget.correctiveController,
      'preventive': widget.preventiveController,
    };
    for (final entry in fields.entries) {
      if (entry.value.text.trim().isNotEmpty) {
        _visibleResponseFields.add(entry.key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedTo = widget.violation['assignedTo'] as String?;
    final isAssigned = assignedTo != null && assignedTo.trim().isNotEmpty;
    final isAssignedToMe =
        isAssigned && assignedTo == FirebaseAuth.instance.currentUser?.uid;
    final canManageResolution = const [
      'tenant_owner',
      'admin',
      'manager',
    ].contains(widget.currentRole);
    final canEditResolution =
        !isAssigned || isAssignedToMe || canManageResolution;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkSectionCard(
            child: _StructuredResponsePanel(
              visibleFields: _visibleResponseFields,
              generalController: widget.generalController,
              containmentController: widget.containmentController,
              rootCauseController: widget.rootCauseController,
              correctiveController: widget.correctiveController,
              preventiveController: widget.preventiveController,
              isSaving: widget.isSaving,
              violation: widget.violation,
              canEdit: canEditResolution,
              onManageAssignment: widget.onManageAssignment,
              onAddField: (field) {
                setState(() {
                  _visibleResponseFields.add(field);
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _WorkSectionCard(
            child: _AttachmentsSection(
              tenantId: widget.tenantId,
              siteId: widget.violation['siteId'] as String? ?? '',
              violationId: widget.violationId,
              isSaving: widget.isSaving,
              localPreviews: _localProofPreviews,
              onAddProof: () => _showProofPicker(context),
            ),
          ),
          const SizedBox(height: 12),
          _ViolationTrainingSection(
            tenantId: widget.tenantId,
            siteId: widget.violation['siteId'] as String? ?? '',
            violationId: widget.violationId,
            violation: widget.violation,
            currentRole: widget.currentRole,
          ),
          const SizedBox(height: 12),
          _WorkSectionCard(
            child: _DiscussionPanel(
              tenantId: widget.tenantId,
              siteId: widget.violation['siteId'] as String? ?? '',
              violationId: widget.violationId,
              startWorkOnPost: false,
            ),
          ),
          if ((widget.violation['status'] as String? ?? 'open') !=
                  'pending_review' &&
              (widget.violation['status'] as String? ?? 'open') != 'closed' &&
              canEditResolution) ...[
            const SizedBox(height: 18),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.correctiveController,
              builder: (context, value, _) {
                final canSubmit = value.text.trim().isNotEmpty;
                return _ViolationBottomActions(
                  isSaving: widget.isSaving,
                  canSubmit: canSubmit,
                  onSaveForLater: widget.onSaveResponse,
                  onSubmitForReview: widget.onSubmitForReview,
                );
              },
            ),
          ],
          if (!canEditResolution) ...[
            const SizedBox(height: 14),
            _StatusMessage(
              icon: Icons.person_outline,
              color: _navy,
              text:
                  'This resolution is assigned to ${widget.violation['assignedToNameSnapshot'] as String? ?? 'another teammate'}. You can still add notes and proof.',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showProofPicker(BuildContext context) async {
    final selection = await showModalBottomSheet<_MediaSelection>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                subtitle: const Text('Processed after upload'),
                onTap: () => Navigator.of(context).pop(
                  const _MediaSelection(
                    choice: _MediaChoice.image,
                    source: ImageSource.camera,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose photo'),
                subtitle: const Text('Processed after upload'),
                onTap: () => Navigator.of(context).pop(
                  const _MediaSelection(
                    choice: _MediaChoice.image,
                    source: ImageSource.gallery,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Choose video'),
                subtitle: const Text('Short clips only, capped before upload'),
                onTap: () => Navigator.of(context).pop(
                  const _MediaSelection(
                    choice: _MediaChoice.video,
                    source: ImageSource.gallery,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || selection == null) {
      return;
    }
    await _uploadProof(context, selection);
  }

  Future<void> _uploadProof(
    BuildContext context,
    _MediaSelection selection,
  ) async {
    final siteId = widget.violation['siteId'] as String? ?? '';
    if (siteId.isEmpty) {
      _showMediaSnack(context, 'Cannot upload proof until the site is known.');
      return;
    }

    try {
      final media = ViolationMediaService();
      final attachmentId = switch (selection.choice) {
        _MediaChoice.image => await media.pickAndUploadImage(
          tenantId: widget.tenantId,
          siteId: siteId,
          violationId: widget.violationId,
          linkedContext: 'fix',
          source: selection.source,
          onLocalPreview: (attachmentId, bytes) {
            if (!mounted) {
              return;
            }
            setState(() {
              _localProofPreviews[attachmentId] = bytes;
            });
          },
        ),
        _MediaChoice.video => await media.pickAndUploadVideo(
          tenantId: widget.tenantId,
          siteId: siteId,
          violationId: widget.violationId,
          linkedContext: 'fix',
          source: selection.source,
        ),
      };
      if (!context.mounted || attachmentId == null) {
        return;
      }
    } on AppException catch (error) {
      if (context.mounted) {
        _showMediaSnack(context, error.message);
      }
    } catch (_) {
      if (context.mounted) {
        _showMediaSnack(context, 'Could not upload proof. Please try again.');
      }
    }
  }
}

class _DiscussionPanel extends StatefulWidget {
  const _DiscussionPanel({
    required this.tenantId,
    required this.siteId,
    required this.violationId,
    required this.startWorkOnPost,
  });

  final String tenantId;
  final String siteId;
  final String violationId;
  final bool startWorkOnPost;

  @override
  State<_DiscussionPanel> createState() => _DiscussionPanelState();
}

class _DiscussionPanelState extends State<_DiscussionPanel> {
  final ViolationRepository _violationRepository = ViolationRepository();
  final ViolationMediaService _mediaService = ViolationMediaService();
  final _commentController = TextEditingController();
  final List<_PendingAttachment> _pendingAttachments = [];
  final Map<String, Uint8List> _localNotePreviews = {};
  StateSetter? _noteSheetSetState;
  bool _isPosting = false;
  bool _showAllNotes = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    var body = _commentController.text.trim();
    if (body.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }
    body = body.isEmpty ? 'Added media.' : body;
    final attachmentIds = _pendingAttachments
        .map((attachment) => attachment.id)
        .toList();
    Navigator.of(context).maybePop();
    _noteSheetSetState = null;
    setState(() {
      _isPosting = true;
    });
    try {
      await _violationRepository.addThreadComment(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: widget.violationId,
        body: body,
        attachmentIds: attachmentIds,
        startWork: widget.startWorkOnPost,
      );
      if (!mounted) {
        return;
      }
      _commentController.clear();
      _pendingAttachments.clear();
      _localNotePreviews.clear();
    } catch (_) {
      if (mounted) {
        _showMediaSnack(context, 'Could not post note. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  Future<void> _attachImage() async {
    final source = await _showPhotoSourcePicker(context);
    if (!mounted || source == null) {
      return;
    }
    await _attachMedia(_MediaChoice.image, source: source);
  }

  Future<void> _attachVideo() async {
    await _attachMedia(_MediaChoice.video, source: ImageSource.gallery);
  }

  Future<void> _attachMedia(
    _MediaChoice choice, {
    required ImageSource source,
  }) async {
    if (widget.siteId.isEmpty) {
      _showMediaSnack(context, 'Cannot upload media until the site is known.');
      return;
    }

    try {
      final attachmentId = switch (choice) {
        _MediaChoice.image => await _mediaService.pickAndUploadImage(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: widget.violationId,
          linkedContext: 'note',
          source: source,
          onLocalPreview: (attachmentId, bytes) {
            if (!mounted) {
              return;
            }
            setState(() {
              _localNotePreviews[attachmentId] = bytes;
              if (!_pendingAttachments.any((item) => item.id == attachmentId)) {
                _pendingAttachments.add(
                  _PendingAttachment(
                    id: attachmentId,
                    data: {
                      '_id': attachmentId,
                      'type': 'image',
                      'status': 'uploading',
                      'linkedContext': 'note',
                    },
                  ),
                );
              }
            });
            _noteSheetSetState?.call(() {});
          },
        ),
        _MediaChoice.video => await _mediaService.pickAndUploadVideo(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: widget.violationId,
          linkedContext: 'note',
          source: source,
        ),
      };
      if (!mounted || attachmentId == null) {
        return;
      }
      final attachmentSnapshot = await FirestorePaths.violation(
        widget.tenantId,
        widget.siteId,
        widget.violationId,
      ).collection('attachments').doc(attachmentId).get();
      final attachmentData = attachmentSnapshot.data();
      if (!mounted || attachmentData == null) {
        return;
      }
      setState(() {
        final index = _pendingAttachments.indexWhere(
          (item) => item.id == attachmentId,
        );
        final updatedAttachment = _PendingAttachment(
          id: attachmentId,
          data: attachmentData,
        );
        if (index >= 0) {
          _pendingAttachments[index] = updatedAttachment;
        } else {
          _pendingAttachments.add(updatedAttachment);
        }
      });
      _noteSheetSetState?.call(() {});
    } on AppException catch (error) {
      if (mounted) {
        _showMediaSnack(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMediaSnack(context, 'Could not upload media. Please try again.');
      }
    }
  }

  Future<void> _removePendingAttachment(_PendingAttachment attachment) async {
    setState(() {
      _pendingAttachments.removeWhere((item) => item.id == attachment.id);
      _localNotePreviews.remove(attachment.id);
    });
    _noteSheetSetState?.call(() {});
    try {
      await _mediaService.deleteAttachment(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: widget.violationId,
        attachmentId: attachment.id,
      );
    } catch (_) {
      if (mounted) {
        _showMediaSnack(context, 'Could not remove media. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _violationRepository.streamThreadEntries(
            tenantId: widget.tenantId,
            siteId: widget.siteId,
            violationId: widget.violationId,
          ),
          builder: (context, snapshot) {
            final entries = snapshot.data?.docs ?? [];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkSectionHeader(
                    title: 'Notes',
                    body:
                        'Add quick team updates without changing the fix response.',
                  ),
                  SizedBox(height: 12),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (entries.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _WorkSectionHeader(
                    title: 'Notes',
                    body:
                        'Add quick team updates without changing the fix response.',
                  ),
                  const SizedBox(height: 10),
                  const _EmptyWorkPanel(
                    icon: Icons.forum_outlined,
                    title: 'No notes yet',
                    body:
                        'Add quick updates while the team works this violation.',
                  ),
                  const SizedBox(height: 12),
                  _notesActions(0),
                ],
              );
            }
            final visibleEntries = (_showAllNotes ? entries : entries.take(3))
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WorkSectionHeader(
                  title: 'Notes',
                  body:
                      'Add quick team updates without changing the fix response.',
                ),
                const SizedBox(height: 10),
                for (var index = 0; index < visibleEntries.length; index++)
                  _ThreadEntryTile(
                    tenantId: widget.tenantId,
                    siteId: widget.siteId,
                    violationId: widget.violationId,
                    entryId: visibleEntries.elementAt(index).id,
                    entry: visibleEntries.elementAt(index).data(),
                    showDivider: index < visibleEntries.length - 1,
                  ),
                const SizedBox(height: 12),
                _notesActions(entries.length),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _notesActions(int entryCount) {
    return Row(
      children: [
        _InlineSectionAction(
          icon: Icons.add_comment_outlined,
          label: 'Add note',
          onPressed: _showAddNoteSheet,
        ),
        const Spacer(),
        if (entryCount > 3)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showAllNotes = !_showAllNotes;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            label: Text(
              _showAllNotes
                  ? 'Show recent notes'
                  : 'View all $entryCount notes',
            ),
            icon: Icon(
              _showAllNotes ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
          ),
      ],
    );
  }

  Future<void> _showAddNoteSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            _noteSheetSetState = sheetSetState;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add note',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Add a team update.',
                      ),
                    ),
                    if (_pendingAttachments.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _AttachmentPreviewStrip(
                        attachments: [
                          for (final attachment in _pendingAttachments)
                            {'_id': attachment.id, ...attachment.data},
                        ],
                        localPreviews: _localNotePreviews,
                        onDelete: (attachment) {
                          final id = attachment['_id'] as String?;
                          if (id == null) {
                            return;
                          }
                          final pending = _pendingAttachments.firstWhere(
                            (item) => item.id == id,
                          );
                          _removePendingAttachment(pending);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _AttachmentIconButton(
                          icon: Icons.photo_camera_outlined,
                          tooltip: 'Add photo',
                          onPressed: _isPosting ? null : _attachImage,
                        ),
                        const SizedBox(width: 8),
                        _AttachmentIconButton(
                          icon: Icons.videocam_outlined,
                          tooltip: 'Add video',
                          onPressed: _isPosting ? null : _attachVideo,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isPosting ? null : _postComment,
                            icon: _isPosting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: const Text('Post note'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    _noteSheetSetState = null;
  }
}

class _ThreadEntryTile extends StatelessWidget {
  const _ThreadEntryTile({
    required this.tenantId,
    required this.siteId,
    required this.violationId,
    required this.entryId,
    required this.entry,
    required this.showDivider,
  });

  final String tenantId;
  final String siteId;
  final String violationId;
  final String entryId;
  final Map<String, dynamic> entry;
  final bool showDivider;

  Future<void> _deletePost(
    BuildContext context,
    List<String> attachmentIds,
  ) async {
    try {
      await FirestorePaths.violationThreads(
        tenantId,
        siteId,
        violationId,
      ).doc(entryId).delete();
      final media = ViolationMediaService();
      for (final attachmentId in attachmentIds) {
        await media.deleteAttachment(
          tenantId: tenantId,
          siteId: siteId,
          violationId: violationId,
          attachmentId: attachmentId,
        );
      }
    } catch (_) {
      if (context.mounted) {
        _showMediaSnack(context, 'Could not delete post. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = entry['body'] as String? ?? '';
    final author =
        entry['createdByDisplayNameSnapshot'] as String? ??
        (entry['createdBy'] as String?) ??
        'FiScore user';
    final createdAt = _noteTimeText(entry['createdAt']);
    final attachmentIds = (entry['attachmentIds'] as List?) ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: _line.withValues(alpha: 0.8)))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (body.isNotEmpty)
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _ink,
                fontSize: 14,
                height: 1.38,
              ),
            ),
          if (attachmentIds.isNotEmpty) ...[
            if (body.isNotEmpty) const SizedBox(height: 8),
            _PostedAttachmentStrip(
              tenantId: tenantId,
              siteId: siteId,
              violationId: violationId,
              attachmentIds: attachmentIds.whereType<String>().toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  createdAt.isEmpty ? author : '$author  |  $createdAt',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_horiz, size: 19, color: _muted),
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _deletePost(
                      context,
                      attachmentIds.whereType<String>().toList(),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete post')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingAttachment {
  const _PendingAttachment({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class _StructuredResponsePanel extends StatelessWidget {
  const _StructuredResponsePanel({
    required this.visibleFields,
    required this.generalController,
    required this.containmentController,
    required this.rootCauseController,
    required this.correctiveController,
    required this.preventiveController,
    required this.isSaving,
    required this.violation,
    required this.canEdit,
    this.onManageAssignment,
    required this.onAddField,
  });

  final Set<String> visibleFields;
  final TextEditingController generalController;
  final TextEditingController containmentController;
  final TextEditingController rootCauseController;
  final TextEditingController correctiveController;
  final TextEditingController preventiveController;
  final bool isSaving;
  final Map<String, dynamic> violation;
  final bool canEdit;
  final VoidCallback? onManageAssignment;
  final ValueChanged<String> onAddField;

  @override
  Widget build(BuildContext context) {
    final optionalFields = [
      _ResponseFieldConfig(
        key: 'general',
        label: 'Extra note',
        hint: 'Add any additional context for the reviewer.',
        controller: generalController,
      ),
      _ResponseFieldConfig(
        key: 'containment',
        label: 'Immediate containment',
        hint: 'What was done right away to reduce risk?',
        controller: containmentController,
      ),
      _ResponseFieldConfig(
        key: 'rootCause',
        label: 'Root cause',
        hint: 'Why did this happen?',
        controller: rootCauseController,
      ),
      _ResponseFieldConfig(
        key: 'preventive',
        label: 'Preventive action',
        hint: 'What will prevent it from recurring?',
        controller: preventiveController,
      ),
    ];
    final activeFields = optionalFields
        .where((option) => visibleFields.contains(option.key))
        .toList();
    final inactiveFields = optionalFields
        .where((option) => !visibleFields.contains(option.key))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkSectionHeader(
          title: 'Resolution',
          body: 'Capture the completed correction and any helpful details.',
        ),
        const SizedBox(height: 10),
        _ResolutionAssignmentRow(
          isAssigned:
              (violation['assignedTo'] as String?)?.trim().isNotEmpty ?? false,
          assignedToName: violation['assignedToNameSnapshot'] as String?,
          isAssignedToMe:
              violation['assignedTo'] == FirebaseAuth.instance.currentUser?.uid,
          onManageAssignment: onManageAssignment,
        ),
        const SizedBox(height: 10),
        _ResponseField(
          controller: correctiveController,
          label: 'What was fixed?',
          hint: 'Describe the completed fix.',
          enabled: canEdit,
        ),
        for (final field in activeFields)
          _ResponseField(
            controller: field.controller,
            label: field.label,
            hint: field.hint,
            enabled: canEdit,
          ),
        if (inactiveFields.isNotEmpty)
          _InlineSectionAction(
            icon: Icons.add,
            label: 'Add response detail',
            onPressed: isSaving || !canEdit
                ? null
                : () =>
                      _showFixDetailSheet(context, inactiveFields, onAddField),
          ),
      ],
    );
  }

  void _showFixDetailSheet(
    BuildContext context,
    List<_ResponseFieldConfig> fields,
    ValueChanged<String> onAddField,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in fields)
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(field.label),
                  subtitle: Text(field.hint),
                  onTap: () {
                    Navigator.of(context).pop();
                    onAddField(field.key);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ResponseFieldConfig {
  const _ResponseFieldConfig({
    required this.key,
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String key;
  final String label;
  final String hint;
  final TextEditingController controller;
}

class _ResponseField extends StatelessWidget {
  const _ResponseField({
    required this.controller,
    required this.label,
    required this.hint,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _SubtleHintTextField(
            controller: controller,
            hint: hint,
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class _SubtleHintTextField extends StatelessWidget {
  const _SubtleHintTextField({
    required this.controller,
    required this.hint,
    required this.enabled,
  });

  final TextEditingController controller;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 2,
      maxLines: 5,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: _ink, fontSize: 15, height: 1.3),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _ResolutionAssignmentRow extends StatelessWidget {
  const _ResolutionAssignmentRow({
    required this.isAssigned,
    required this.assignedToName,
    required this.isAssignedToMe,
    required this.onManageAssignment,
  });

  final bool isAssigned;
  final String? assignedToName;
  final bool isAssignedToMe;
  final VoidCallback? onManageAssignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 17, color: _muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isAssigned
                ? isAssignedToMe
                      ? 'Assigned to you'
                      : 'Assigned to ${assignedToName ?? 'team member'}'
                : 'No owner assigned',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isAssigned ? _ink : _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onManageAssignment != null)
          TextButton(
            onPressed: onManageAssignment,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              minimumSize: const Size(0, 30),
            ),
            child: Text(isAssigned ? 'Change' : 'Assign'),
          ),
      ],
    );
  }
}

class _WorkSectionHeader extends StatelessWidget {
  const _WorkSectionHeader({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: _muted.withValues(alpha: 0.92),
            fontSize: 12.5,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _InlineSectionAction extends StatelessWidget {
  const _InlineSectionAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _navy,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ViolationBottomActions extends StatelessWidget {
  const _ViolationBottomActions({
    required this.isSaving,
    required this.canSubmit,
    required this.onSaveForLater,
    required this.onSubmitForReview,
  });

  final bool isSaving;
  final bool canSubmit;
  final VoidCallback onSaveForLater;
  final VoidCallback onSubmitForReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canSubmit)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Enter what was fixed to submit for review.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _muted, height: 1.35),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onSaveForLater,
                icon: const Icon(Icons.bookmark_border_outlined),
                label: const Text('Save for later'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: isSaving || !canSubmit ? null : onSubmitForReview,
                style: _greenFilledButtonStyle(),
                icon: const Icon(Icons.outbox_outlined),
                label: const Text('Submit for review'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkSectionCard extends StatelessWidget {
  const _WorkSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line.withValues(alpha: 0.92)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _ViolationTrainingSection extends StatefulWidget {
  const _ViolationTrainingSection({
    required this.tenantId,
    required this.siteId,
    required this.violationId,
    required this.violation,
    required this.currentRole,
  });

  final String tenantId;
  final String siteId;
  final String violationId;
  final Map<String, dynamic> violation;
  final String currentRole;

  @override
  State<_ViolationTrainingSection> createState() =>
      _ViolationTrainingSectionState();
}

class _ViolationTrainingSectionState extends State<_ViolationTrainingSection> {
  final TrainingRepository _repository = TrainingRepository();

  bool get _canAssign => _canAssignTraining(widget.currentRole);
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _assign() async {
    final created = await showTrainingAssignmentSheet(
      context,
      tenantId: widget.tenantId,
      siteId: widget.siteId,
      preferredTrainingId: _recommendedTrainingIdForViolation(widget.violation),
      linkedViolationId: widget.violationId,
      linkedViolationTitle:
          widget.violation['title'] as String? ??
          widget.violation['summaryText'] as String?,
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Training assigned for this violation.'),
          ),
        );
    }
  }

  Future<void> _openTrainingAssignment(
    String assignmentId,
    Map<String, dynamic> assignment,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => Scaffold(
          backgroundColor: _page,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: _TrainingPlayerView(
                tenantId: widget.tenantId,
                assignmentId: assignmentId,
                assignment: assignment,
                canComplete: assignment['assignedTo'] == _userId,
                canManage: _canAssign,
                onBack: () => Navigator.of(routeContext).pop(),
                onCompleted: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.siteId.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.assignmentsStream(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        userId: _userId,
        canAssign: _canAssign,
      ),
      builder: (context, snapshot) {
        final linked = (snapshot.data?.docs ?? [])
            .where(
              (doc) => doc.data()['linkedViolationId'] == widget.violationId,
            )
            .toList();
        if (linked.isEmpty && !_canAssign) return const SizedBox.shrink();
        return _WorkSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WorkSectionHeader(
                title: 'Training',
                body: 'Targeted coaching to help prevent this issue recurring.',
              ),
              if (linked.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final assignment in linked)
                  _TrainingAssignmentCard(
                    assignment: assignment.data(),
                    onTap: () => _openTrainingAssignment(
                      assignment.id,
                      assignment.data(),
                    ),
                  ),
              ],
              if (_canAssign)
                _InlineSectionAction(
                  icon: Icons.school_outlined,
                  label: linked.isEmpty ? 'Assign training' : 'Assign another',
                  onPressed: _assign,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.tenantId,
    required this.siteId,
    required this.violationId,
    required this.isSaving,
    required this.localPreviews,
    required this.onAddProof,
  });

  final String tenantId;
  final String siteId;
  final String violationId;
  final bool isSaving;
  final Map<String, Uint8List> localPreviews;
  final VoidCallback onAddProof;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WorkSectionHeader(
          title: 'Proof',
          body: 'Photos or short videos that show the issue and completed fix.',
        ),
        _FixProofStrip(
          tenantId: tenantId,
          siteId: siteId,
          violationId: violationId,
          localPreviews: localPreviews,
        ),
        const SizedBox(height: 6),
        _InlineSectionAction(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Add proof',
          onPressed: isSaving ? null : onAddProof,
        ),
      ],
    );
  }
}

class _FixProofStrip extends StatelessWidget {
  const _FixProofStrip({
    required this.tenantId,
    required this.siteId,
    required this.violationId,
    required this.localPreviews,
  });

  final String tenantId;
  final String siteId;
  final String violationId;
  final Map<String, Uint8List> localPreviews;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.violation(
        tenantId,
        siteId,
        violationId,
      ).collection('attachments').snapshots(),
      builder: (context, snapshot) {
        final proofAttachments =
            (snapshot.data?.docs ?? [])
                .map((doc) => {'_id': doc.id, ...doc.data()})
                .where((data) => data['linkedContext'] == 'fix')
                .toList()
              ..sort((a, b) {
                final aTime = a['createdAt'];
                final bTime = b['createdAt'];
                if (aTime is Timestamp && bTime is Timestamp) {
                  return bTime.compareTo(aTime);
                }
                return 0;
              });

        if (proofAttachments.isEmpty) {
          return const SizedBox.shrink();
        }

        final observedProof = proofAttachments
            .where(
              (attachment) =>
                  _displayText(attachment['sourceAuditId']).isNotEmpty,
            )
            .toList();
        final resolutionProof = proofAttachments
            .where(
              (attachment) => _displayText(attachment['sourceAuditId']).isEmpty,
            )
            .toList();

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (observedProof.isNotEmpty)
                _ProofAttachmentGroup(
                  label: 'Observed during check',
                  attachments: observedProof,
                  localPreviews: localPreviews,
                ),
              if (resolutionProof.isNotEmpty)
                _ProofAttachmentGroup(
                  label: observedProof.isEmpty ? null : 'Resolution proof',
                  attachments: resolutionProof,
                  localPreviews: localPreviews,
                  onDelete: (attachment) => _removeProofAttachment(
                    context,
                    attachment: attachment,
                    tenantId: tenantId,
                    siteId: siteId,
                    violationId: violationId,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProofAttachmentGroup extends StatelessWidget {
  const _ProofAttachmentGroup({
    required this.label,
    required this.attachments,
    required this.localPreviews,
    this.onDelete,
  });

  final String? label;
  final List<Map<String, dynamic>> attachments;
  final Map<String, Uint8List> localPreviews;
  final ValueChanged<Map<String, dynamic>>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: label == null ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
          ],
          _AttachmentPreviewStrip(
            attachments: attachments,
            localPreviews: localPreviews,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

Future<void> _removeProofAttachment(
  BuildContext context, {
  required Map<String, dynamic> attachment,
  required String tenantId,
  required String siteId,
  required String violationId,
}) async {
  final id = attachment['_id'] as String?;
  if (id == null) return;
  final status = attachment['status'] as String? ?? 'ready';
  if (status == 'ready') {
    final confirmed = await _confirmDestructiveAction(
      context,
      title: 'Remove this proof photo?',
      body: 'This deletes the photo from this violation.',
      actionLabel: 'Remove',
    );
    if (!confirmed) return;
  }
  try {
    await ViolationMediaService().deleteAttachment(
      tenantId: tenantId,
      siteId: siteId,
      violationId: violationId,
      attachmentId: id,
    );
  } catch (_) {
    if (context.mounted) {
      _showMediaSnack(context, 'Could not remove proof. Please try again.');
    }
  }
}

class _PostedAttachmentStrip extends StatefulWidget {
  const _PostedAttachmentStrip({
    required this.tenantId,
    required this.siteId,
    required this.violationId,
    required this.attachmentIds,
  });

  final String tenantId;
  final String siteId;
  final String violationId;
  final List<String> attachmentIds;

  @override
  State<_PostedAttachmentStrip> createState() => _PostedAttachmentStripState();
}

class _PostedAttachmentStripState extends State<_PostedAttachmentStrip> {
  late Future<List<Map<String, dynamic>>> _attachmentsFuture;

  @override
  void initState() {
    super.initState();
    _attachmentsFuture = _loadAttachments();
  }

  @override
  void didUpdateWidget(covariant _PostedAttachmentStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenantId != widget.tenantId ||
        oldWidget.siteId != widget.siteId ||
        oldWidget.violationId != widget.violationId ||
        oldWidget.attachmentIds.join('|') != widget.attachmentIds.join('|')) {
      _attachmentsFuture = _loadAttachments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _attachmentsFuture,
      builder: (context, snapshot) {
        final attachments = snapshot.data ?? const <Map<String, dynamic>>[];
        if (attachments.isEmpty) {
          return Row(
            children: [
              const Icon(Icons.attachment_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                '${widget.attachmentIds.length} media item${widget.attachmentIds.length == 1 ? '' : 's'} attached',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }
        return _AttachmentPreviewStrip(attachments: attachments);
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadAttachments() async {
    final collection = FirestorePaths.violation(
      widget.tenantId,
      widget.siteId,
      widget.violationId,
    ).collection('attachments');
    final attachments = <Map<String, dynamic>>[];
    for (final id in widget.attachmentIds) {
      final snapshot = await collection.doc(id).get();
      final data = snapshot.data();
      if (data != null) {
        attachments.add({'_id': id, ...data});
      }
    }
    return attachments;
  }
}

class _AttachmentPreviewStrip extends StatelessWidget {
  const _AttachmentPreviewStrip({
    required this.attachments,
    this.localPreviews = const {},
    this.onDelete,
  });

  final List<Map<String, dynamic>> attachments;
  final Map<String, Uint8List> localPreviews;
  final ValueChanged<Map<String, dynamic>>? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          final attachmentId = attachment['_id'] as String? ?? '$index';
          return _AttachmentTile(
            key: ValueKey('attachment-$attachmentId'),
            attachment: attachment,
            localBytes: localPreviews[attachmentId],
            onDelete: onDelete == null ? null : () => onDelete!(attachment),
          );
        },
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    super.key,
    required this.attachment,
    this.localBytes,
    this.onDelete,
  });

  final Map<String, dynamic> attachment;
  final Uint8List? localBytes;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final type = attachment['type'] as String? ?? '';
    final status = attachment['status'] as String? ?? 'ready';
    final previewPath = _attachmentPreviewPath(attachment);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: () => _showAttachmentPreview(context, attachment),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 74,
            height: 74,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _page,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: localBytes != null && status != 'ready'
                ? _LocalProcessingPreview(bytes: localBytes!)
                : status == 'uploading' || status == 'processing'
                ? const _ProcessingAttachmentTile()
                : status == 'failed'
                ? const Icon(Icons.error_outline, color: Color(0xFFB42318))
                : type == 'image' && previewPath != null
                ? _AttachmentImagePreview(
                    storagePath: previewPath,
                    fallbackBytes: localBytes,
                  )
                : localBytes != null
                ? _MemoryAttachmentImage(bytes: localBytes!, fit: BoxFit.cover)
                : const Icon(Icons.videocam_outlined, color: _navy),
          ),
        ),
        if (onDelete != null)
          Positioned(
            right: -6,
            top: -6,
            child: Material(
              color: _navy,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProcessingAttachmentTile extends StatelessWidget {
  const _ProcessingAttachmentTile();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Icon(Icons.image_outlined, color: _muted),
        Positioned(right: 6, bottom: 6, child: _TinyUploadSpinner()),
      ],
    );
  }
}

class _LocalProcessingPreview extends StatelessWidget {
  const _LocalProcessingPreview({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.broken_image_outlined, color: _muted),
        ),
        Container(color: const Color(0x33071A4A)),
        Positioned(right: 6, bottom: 6, child: _TinyUploadSpinner()),
      ],
    );
  }
}

class _TinyUploadSpinner extends StatelessWidget {
  const _TinyUploadSpinner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        shape: BoxShape.circle,
      ),
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _AttachmentImagePreview extends StatefulWidget {
  const _AttachmentImagePreview({
    required this.storagePath,
    this.fallbackBytes,
    this.fit = BoxFit.cover,
  });

  final String storagePath;
  final Uint8List? fallbackBytes;
  final BoxFit fit;

  @override
  State<_AttachmentImagePreview> createState() =>
      _AttachmentImagePreviewState();
}

class _AttachmentImagePreviewState extends State<_AttachmentImagePreview> {
  static final Map<String, Future<String>> _urlFutures = {};

  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _urlForPath(widget.storagePath);
  }

  @override
  void didUpdateWidget(covariant _AttachmentImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storagePath != widget.storagePath) {
      _urlFuture = _urlForPath(widget.storagePath);
    }
  }

  static Future<String> _urlForPath(String storagePath) {
    return _urlFutures.putIfAbsent(
      storagePath,
      () => FirebaseStorage.instance.ref(storagePath).getDownloadURL(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Could not load attachment image ${widget.storagePath}: '
            '${snapshot.error}',
          );
          if (widget.fallbackBytes != null) {
            return _MemoryAttachmentImage(
              bytes: widget.fallbackBytes!,
              fit: widget.fit,
            );
          }
          return const Icon(Icons.broken_image_outlined, color: _muted);
        }
        final url = snapshot.data;
        if (url == null) {
          if (widget.fallbackBytes != null) {
            return _MemoryAttachmentImage(
              bytes: widget.fallbackBytes!,
              fit: widget.fit,
            );
          }
          return const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.network(
          url,
          fit: widget.fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            if (widget.fallbackBytes != null) {
              return _MemoryAttachmentImage(
                bytes: widget.fallbackBytes!,
                fit: widget.fit,
              );
            }
            return const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, error, _) {
            debugPrint(
              'Could not render attachment image ${widget.storagePath}: $error',
            );
            if (widget.fallbackBytes != null) {
              return _MemoryAttachmentImage(
                bytes: widget.fallbackBytes!,
                fit: widget.fit,
              );
            }
            return const Icon(Icons.broken_image_outlined, color: _muted);
          },
        );
      },
    );
  }
}

class _MemoryAttachmentImage extends StatelessWidget {
  const _MemoryAttachmentImage({required this.bytes, required this.fit});

  final Uint8List bytes;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: fit,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.broken_image_outlined, color: _muted),
    );
  }
}

void _showAttachmentPreview(
  BuildContext context,
  Map<String, dynamic> attachment,
) {
  final type = attachment['type'] as String? ?? '';
  final storagePath = _attachmentFullPath(attachment);
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: type == 'image' && storagePath != null
                      ? _AttachmentImagePreview(
                          storagePath: storagePath,
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  color: _navy,
                                  size: 42,
                                ),
                                SizedBox(height: 10),
                                Text('Video attached'),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String? _attachmentPreviewPath(Map<String, dynamic> attachment) {
  final path = _firstAvailableText([
    attachment['thumbnailPath'],
    attachment['storagePath'],
    attachment['compressedPath'],
  ]);
  return path.isEmpty ? null : path;
}

String? _attachmentFullPath(Map<String, dynamic> attachment) {
  final path = _firstAvailableText([
    attachment['storagePath'],
    attachment['compressedPath'],
    attachment['thumbnailPath'],
  ]);
  return path.isEmpty ? null : path;
}

class _AttachmentIconButton extends StatelessWidget {
  const _AttachmentIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(46, 46),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class _EmptyWorkPanel extends StatelessWidget {
  const _EmptyWorkPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _page,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _navy, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
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

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

class _ViolationActions extends StatelessWidget {
  const _ViolationActions({
    required this.status,
    required this.isSaving,
    required this.onSendBack,
    required this.onUpdateStatus,
  });

  final String status;
  final bool isSaving;
  final VoidCallback onSendBack;
  final void Function(
    String status, {
    String? reviewStatus,
    String? closureReason,
  })
  onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (status == 'pending_review') {
      actions.addAll([
        OutlinedButton.icon(
          onPressed: isSaving ? null : onSendBack,
          icon: const Icon(Icons.undo),
          label: const Text('Send back'),
        ),
        FilledButton.icon(
          onPressed: isSaving
              ? null
              : () => onUpdateStatus(
                  'closed',
                  reviewStatus: 'closed',
                  closureReason: 'Closed after manager review.',
                ),
          style: _greenFilledButtonStyle(),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Close violation'),
        ),
      ]);
    } else if (status == 'closed') {
      actions.add(
        FilledButton.icon(
          onPressed: isSaving
              ? null
              : () => onUpdateStatus('open', reviewStatus: 'reopened'),
          icon: const Icon(Icons.replay),
          label: const Text('Reopen'),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (actions.length == 1) {
      return SizedBox(width: double.infinity, child: actions.first);
    }

    return Row(
      children: [
        Expanded(child: actions.first),
        const SizedBox(width: 10),
        Expanded(child: actions.last),
      ],
    );
  }
}

class _SendBackSheet extends StatefulWidget {
  const _SendBackSheet();

  @override
  State<_SendBackSheet> createState() => _SendBackSheetState();
}

class _SendBackSheetState extends State<_SendBackSheet> {
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedbackController.text.trim();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send back for changes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tell the team what needs to be corrected.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _feedbackController,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Add review feedback.',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: feedback.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(feedback),
                    child: const Text('Send back'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStatusBadge extends StatelessWidget {
  const _SmallStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _violationStatusLabel(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _OperationalBanner(icon: icon, title: title, body: body);
  }
}

int _statusRank(String status) {
  switch (status) {
    case 'open':
      return 0;
    case 'in_progress':
      return 1;
    case 'pending_review':
      return 2;
    case 'closed':
      return 3;
    default:
      return 4;
  }
}

String _violationStatusLabel(String status) {
  switch (status) {
    case 'open':
      return 'Open';
    case 'in_progress':
      return 'Working';
    case 'pending_review':
      return 'Review';
    case 'closed':
      return 'Closed';
    default:
      return status;
  }
}

Color _statusColor(String? status) {
  switch (status) {
    case 'closed':
      return _green;
    case 'pending_review':
      return const Color(0xFFF59E0B);
    case 'in_progress':
      return const Color(0xFF1D4ED8);
    case 'open':
    default:
      return const Color(0xFFDC2626);
  }
}

String _sourceLabel(String? sourceType) {
  switch (sourceType) {
    case 'health_department_inspection':
      return 'Public inspection';
    case 'internal_audit':
      return 'Internal check';
    case 'manual':
      return 'Manual issue';
    default:
      return 'Violation';
  }
}

ButtonStyle _greenFilledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _green,
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFFCBD5E1),
    disabledForegroundColor: const Color(0xFF64748B),
  );
}

enum _MediaChoice { image, video }

class _MediaSelection {
  const _MediaSelection({required this.choice, required this.source});

  final _MediaChoice choice;
  final ImageSource source;
}

Future<ImageSource?> _showPhotoSourcePicker(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
}

void _showMediaSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String body,
  required String actionLabel,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.35),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB42318),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

String _severityLabel(String? severity) {
  final normalized = (severity ?? '').trim().toLowerCase();
  switch (normalized) {
    case 'critical':
      return 'Critical';
    case 'major':
      return 'Major';
    case 'minor':
      return 'Minor';
    case 'informational':
      return 'Informational';
    case 'not critical':
      return 'Minor';
    case 'unknown':
    case '':
      return 'Severity unknown';
    default:
      return severity!.trim();
  }
}

bool _shouldShowSeverity(String? severity) {
  return (severity ?? '').trim().isNotEmpty;
}

Color _severityColor(String severity) {
  switch (severity.trim().toLowerCase()) {
    case 'critical':
      return const Color(0xFFDC2626);
    case 'major':
      return const Color(0xFFF59E0B);
    case 'minor':
      return const Color(0xFF2563EB);
    case 'informational':
      return const Color(0xFF64748B);
    case 'severity unknown':
    default:
      return const Color(0xFF64748B);
  }
}

String _compactSourceSummary(Map<String, dynamic> violation) {
  final sourceType = violation['sourceType'] as String?;
  if (sourceType == 'internal_audit') {
    return _joinNonEmpty([
      _sourceLabel(sourceType),
      _displayText(violation['templateNameSnapshot']),
      _dateText(violation['completedAt']),
    ]);
  }
  return _joinNonEmpty([
    _sourceLabel(sourceType),
    _dateText(violation['inspectionDate']),
  ]);
}

String _firstAvailableText(Iterable<Object?> values) {
  for (final value in values) {
    final text = _displayText(value);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _joinNonEmpty(Iterable<String> values) {
  return values.where((value) => value.trim().isNotEmpty).join(' / ');
}

String _displayText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is Timestamp) {
    return _dateText(value);
  }
  if (value is bool) {
    return value ? 'Yes' : 'No';
  }
  if (value is Iterable) {
    return value.map(_displayText).where((text) => text.isNotEmpty).join(', ');
  }
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_displayText(entry.value)}')
        .where((text) => !text.endsWith(': '))
        .join(', ');
  }
  return value.toString().trim();
}

IconData _sourceIcon(String? sourceType) {
  switch (sourceType) {
    case 'health_department_inspection':
      return Icons.fact_check_outlined;
    case 'internal_audit':
      return Icons.playlist_add_check_circle_outlined;
    case 'manual':
      return Icons.edit_note_outlined;
    default:
      return Icons.report_problem_outlined;
  }
}

String _dateText(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  return value.toString();
}

String _noteTimeText(Object? value) {
  if (value is! Timestamp) {
    return _dateText(value);
  }

  final date = value.toDate().toLocal();
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  final nowDay = DateTime(now.year, now.month, now.day);
  final noteDay = DateTime(date.year, date.month, date.day);
  final calendarDays = nowDay.difference(noteDay).inDays;
  if (calendarDays == 0) {
    return '${difference.inHours} hr ago';
  }
  if (calendarDays == 1) {
    return 'Yesterday';
  }
  if (calendarDays < 7) {
    return '$calendarDays days ago';
  }

  final dateText = '${_shortMonthName(date.month)} ${date.day}';
  return date.year == now.year ? dateText : '$dateText, ${date.year}';
}

String _shortMonthName(int month) {
  const monthNames = [
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
  return monthNames[month - 1];
}
