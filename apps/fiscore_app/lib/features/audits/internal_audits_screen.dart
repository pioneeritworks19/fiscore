part of '../../main.dart';

class _AuditsContent extends StatefulWidget {
  const _AuditsContent({
    required this.tenantId,
    required this.siteId,
    required this.currentRole,
    this.initialAssignmentId,
    this.assignedCheckBackLabel,
    this.onBackFromAssignedCheck,
  });

  final String tenantId;
  final String siteId;
  final String currentRole;
  final String? initialAssignmentId;
  final String? assignedCheckBackLabel;
  final VoidCallback? onBackFromAssignedCheck;

  @override
  State<_AuditsContent> createState() => _AuditsContentState();
}

class _AuditsContentState extends State<_AuditsContent> {
  String _mode = 'internal';
  bool _inSubflow = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_inSubflow) ...[
          Text(
            strings.audits,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'internal',
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: Text(strings.internal),
              ),
              ButtonSegment(
                value: 'public',
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(strings.public),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) {
              setState(() => _mode = value.first);
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_mode == 'internal')
          _InternalAuditsContent(
            tenantId: widget.tenantId,
            siteId: widget.siteId,
            currentRole: widget.currentRole,
            initialAssignmentId: widget.initialAssignmentId,
            assignedCheckBackLabel: widget.assignedCheckBackLabel,
            onBackFromAssignedCheck: widget.onBackFromAssignedCheck,
            onSubflowChanged: (value) {
              if (_inSubflow != value) setState(() => _inSubflow = value);
            },
          )
        else
          _PublicInspectionsContent(
            tenantId: widget.tenantId,
            siteId: widget.siteId,
            currentRole: widget.currentRole,
            showHeader: false,
            onSubflowChanged: (value) {
              if (_inSubflow != value) setState(() => _inSubflow = value);
            },
          ),
      ],
    );
  }
}

class _InternalAuditsContent extends StatefulWidget {
  const _InternalAuditsContent({
    required this.tenantId,
    required this.siteId,
    required this.currentRole,
    required this.initialAssignmentId,
    required this.assignedCheckBackLabel,
    required this.onBackFromAssignedCheck,
    required this.onSubflowChanged,
  });

  final String tenantId;
  final String siteId;
  final String currentRole;
  final String? initialAssignmentId;
  final String? assignedCheckBackLabel;
  final VoidCallback? onBackFromAssignedCheck;
  final ValueChanged<bool> onSubflowChanged;

  @override
  State<_InternalAuditsContent> createState() => _InternalAuditsContentState();
}

class _InternalAuditsContentState extends State<_InternalAuditsContent> {
  final InternalAuditRepository _repository = InternalAuditRepository();
  final ViolationRepository _violationRepository = ViolationRepository();
  String? _activeAuditId;
  String? _selectedViolationId;
  String? _openedInitialAssignmentId;
  String? _loadedViolationId;
  bool _selectingTemplate = false;
  bool _isAssignedCheckFlow = false;
  int _auditLimit = 20;
  int _assignmentLimit = 50;
  bool _showCompletedHistory = false;
  bool _isWorking = false;
  bool _isSavingViolation = false;
  String? _error;
  String? _violationMessage;
  String? _violationError;

  final _generalController = TextEditingController();
  final _containmentController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _correctiveController = TextEditingController();
  final _preventiveController = TextEditingController();

  bool get _canConduct => const [
    'tenant_owner',
    'admin',
    'manager',
    'auditor',
  ].contains(widget.currentRole);

  bool get _canAssignChecks =>
      const ['tenant_owner', 'admin', 'manager'].contains(widget.currentRole);

  @override
  void initState() {
    super.initState();
    _openInitialAssignmentIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _InternalAuditsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAssignmentId != oldWidget.initialAssignmentId) {
      _openedInitialAssignmentId = null;
      _openInitialAssignmentIfNeeded();
    }
  }

  void _openInitialAssignmentIfNeeded() {
    final assignmentId = widget.initialAssignmentId;
    if (assignmentId == null || assignmentId == _openedInitialAssignmentId) {
      return;
    }
    _openedInitialAssignmentId = assignmentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAssignedAudit(assignmentId);
    });
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

  void _openSubflow(VoidCallback update) {
    setState(update);
    widget.onSubflowChanged(true);
  }

  void _backToInternalAudits() {
    setState(() {
      _activeAuditId = null;
      _selectedViolationId = null;
      _loadedViolationId = null;
      _selectingTemplate = false;
      _violationMessage = null;
      _violationError = null;
      _isAssignedCheckFlow = false;
    });
    widget.onSubflowChanged(false);
  }

  void _exitAuditSession() {
    if (_isAssignedCheckFlow && widget.onBackFromAssignedCheck != null) {
      widget.onBackFromAssignedCheck!();
      return;
    }
    _backToInternalAudits();
  }

  void _loadViolationResponse(
    String violationId,
    Map<String, dynamic> violation,
  ) {
    if (_loadedViolationId == violationId) return;
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

  Map<String, String> _currentViolationResponse() => {
    'responseGeneral': _generalController.text.trim(),
    'responseContainment': _containmentController.text.trim(),
    'responseRootCause': _rootCauseController.text.trim(),
    'responseCorrectiveAction': _correctiveController.text.trim(),
    'responsePreventiveAction': _preventiveController.text.trim(),
  };

  Future<void> _saveViolationResponse(
    String violationId,
    String currentStatus,
  ) async {
    setState(() {
      _isSavingViolation = true;
      _violationError = null;
    });
    try {
      await _violationRepository.saveStructuredResponse(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        startWork: currentStatus == 'open',
        response: _currentViolationResponse(),
      );
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.savedForLater)));
    } catch (_) {
      if (mounted) {
        setState(() {
          _violationError = AppLocalizations.of(context).couldNotSaveResponse;
        });
      }
    } finally {
      if (mounted) setState(() => _isSavingViolation = false);
    }
  }

  Future<void> _submitViolationForReview(String violationId) async {
    if (_correctiveController.text.trim().isEmpty) {
      setState(() {
        _violationMessage = null;
        _violationError = AppLocalizations.of(context).enterFixBeforeSubmit;
      });
      return;
    }
    setState(() {
      _isSavingViolation = true;
      _violationMessage = null;
      _violationError = null;
    });
    try {
      await _violationRepository.saveStructuredResponse(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        response: _currentViolationResponse(),
      );
      await _violationRepository.updateStatus(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        violationId: violationId,
        status: 'pending_review',
        reviewStatus: 'submitted',
      );
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.submittedForReview)));
      setState(() {
        _violationMessage = strings.submittedForReview;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _violationError = AppLocalizations.of(context).couldNotSubmitResponse;
        });
      }
    } finally {
      if (mounted) setState(() => _isSavingViolation = false);
    }
  }

  Future<void> _updateViolationStatus(
    String violationId,
    String status, {
    String? reviewStatus,
    String? closureReason,
  }) async {
    setState(() {
      _isSavingViolation = true;
      _violationMessage = null;
      _violationError = null;
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
      if (mounted) {
        setState(() {
          _violationMessage =
              'Violation moved to ${_violationStatusLabel(status)}.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _violationError = 'Could not update the violation. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSavingViolation = false);
    }
  }

  bool get _canManageAssignments =>
      const ['tenant_owner', 'admin', 'manager'].contains(widget.currentRole);

  Future<void> _manageViolationAssignment(
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
    if (!mounted || choice == null) return;
    setState(() {
      _isSavingViolation = true;
      _violationMessage = null;
      _violationError = null;
    });
    try {
      if (choice.remove) {
        await _violationRepository.unassignViolation(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: violationId,
        );
        if (mounted) setState(() => _violationMessage = 'Assignment removed.');
      } else {
        await _violationRepository.assignViolation(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: violationId,
          assignedTo: choice.userId!,
        );
        if (mounted) {
          setState(() => _violationMessage = 'Assigned to ${choice.name}.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _violationError = 'Could not update the assignment.');
      }
    } finally {
      if (mounted) setState(() => _isSavingViolation = false);
    }
  }

  Future<void> _startAudit(String templateId) async {
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      final auditId = await _repository.createAudit(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        templateId: templateId,
      );
      if (!mounted) return;
      setState(() {
        _activeAuditId = auditId;
        _selectingTemplate = false;
        _isAssignedCheckFlow = false;
      });
      widget.onSubflowChanged(true);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not start this check. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _startAssignedAudit(String assignmentId) async {
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      final auditId = await _repository.startAssignment(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        assignmentId: assignmentId,
      );
      if (!mounted) return;
      _openSubflow(() {
        _activeAuditId = auditId;
        _isAssignedCheckFlow = true;
      });
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context).couldNotStartAssignedCheck,
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _assignCheck() async {
    final created = await showAuditAssignmentSheet(
      context,
      tenantId: widget.tenantId,
      siteId: widget.siteId,
    );
    if (!mounted || created != true) return;
    final strings = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.checkAssigned)));
  }

  Future<void> _reassignCheck(
    String assignmentId,
    Map<String, dynamic> assignment,
  ) async {
    final assigneeId = await showAuditReassignmentSheet(
      context,
      tenantId: widget.tenantId,
      siteId: widget.siteId,
      currentAssigneeId: assignment['assignedTo'] as String? ?? '',
    );
    if (!mounted || assigneeId == null) return;
    try {
      await _repository.reassignCheck(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        assignmentId: assignmentId,
        assignedTo: assigneeId,
      );
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.checkReassigned)));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).couldNotReassignCheck,
        );
      }
    }
  }

  Future<void> _cancelCheck(
    String assignmentId, {
    bool selfStarted = false,
  }) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          selfStarted
              ? strings.cancelThisCheckQuestion
              : strings.cancelAssignedCheckQuestion,
        ),
        content: Text(
          selfStarted
              ? strings.cancelSelfStartedCheckBody
              : strings.cancelAssignedCheckBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.keep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.cancelCheck),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.cancelAssignment(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        assignmentId: assignmentId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(strings.assignedCheckCancelled)));
    } catch (_) {
      if (mounted) {
        setState(() => _error = strings.couldNotCancelCheck);
      }
    }
  }

  Future<void> _addLibraryChecklist(String libraryItemId) async {
    setState(() {
      _isWorking = true;
      _error = null;
    });
    try {
      await _repository.addLibraryChecklist(
        tenantId: widget.tenantId,
        libraryItemId: libraryItemId,
      );
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(strings.checklistAddedToMyLibrary)),
        );
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).couldNotAddChecklist,
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_selectedViolationId != null) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _violationRepository.streamViolation(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
          violationId: _selectedViolationId!,
        ),
        builder: (context, snapshot) {
          final selectedViolation = snapshot.data?.data();
          if (selectedViolation == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final selectedId = _selectedViolationId!;
          _loadViolationResponse(selectedId, selectedViolation);
          return _ViolationDetailView(
            tenantId: widget.tenantId,
            violationId: selectedId,
            violation: selectedViolation,
            currentRole: widget.currentRole,
            generalController: _generalController,
            containmentController: _containmentController,
            rootCauseController: _rootCauseController,
            correctiveController: _correctiveController,
            preventiveController: _preventiveController,
            isSaving: _isSavingViolation,
            message: _violationMessage,
            error: _violationError,
            backLabel: strings.backToChecks,
            onBack: () {
              setState(() {
                _selectedViolationId = null;
                _loadedViolationId = null;
                _violationMessage = null;
                _violationError = null;
              });
            },
            onSaveResponse: () => _saveViolationResponse(
              selectedId,
              selectedViolation['status'] as String? ?? 'open',
            ),
            onSubmitForReview: () => _submitViolationForReview(selectedId),
            onManageAssignment:
                _canManageAssignments &&
                    selectedViolation['status'] != 'closed' &&
                    selectedViolation['status'] != 'pending_review'
                ? () =>
                      _manageViolationAssignment(selectedId, selectedViolation)
                : null,
            onUpdateStatus: (status, {reviewStatus, closureReason}) =>
                _updateViolationStatus(
                  selectedId,
                  status,
                  reviewStatus: reviewStatus,
                  closureReason: closureReason,
                ),
          );
        },
      );
    }
    if (_activeAuditId != null) {
      return _InternalAuditSessionView(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        auditId: _activeAuditId!,
        repository: _repository,
        exitLabel: _isAssignedCheckFlow && widget.assignedCheckBackLabel != null
            ? widget.assignedCheckBackLabel!
            : strings.backToChecks,
        onBack: _exitAuditSession,
        onOpenViolation: (violationId) {
          setState(() {
            _selectedViolationId = violationId;
            _loadedViolationId = null;
            _violationMessage = null;
            _violationError = null;
          });
        },
      );
    }
    if (_selectingTemplate) {
      return _AuditTemplatePicker(
        tenantId: widget.tenantId,
        repository: _repository,
        isWorking: _isWorking,
        error: _error,
        canManageLibrary: const [
          'tenant_owner',
          'admin',
          'manager',
        ].contains(widget.currentRole),
        onBack: _backToInternalAudits,
        onAddLibraryChecklist: _addLibraryChecklist,
        onSelect: _startAudit,
      );
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.completedForSite(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        limit: _auditLimit,
      ),
      builder: (context, completedSnapshot) {
        final completed = completedSnapshot.data?.docs ?? [];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _repository.inProgressForSite(
            tenantId: widget.tenantId,
            siteId: widget.siteId,
          ),
          builder: (context, inProgressSnapshot) {
            final inProgress = (inProgressSnapshot.data?.docs ?? [])
                .where((doc) => doc.data()['auditAssignmentId'] == null)
                .toList();
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.assignmentsForSite(
                tenantId: widget.tenantId,
                siteId: widget.siteId,
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                canManage: _canAssignChecks,
                limit: _assignmentLimit,
              ),
              builder: (context, assignmentSnapshot) {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final assignments =
                    (assignmentSnapshot.data?.docs ?? []).where((doc) {
                      final data = doc.data();
                      if (data['status'] == 'completed' ||
                          data['status'] == 'cancelled') {
                        return false;
                      }
                      return _canAssignChecks ||
                          data['assignedTo'] == currentUserId;
                    }).toList()..sort((a, b) {
                      final aDue = a.data()['dueDate'] as Timestamp?;
                      final bDue = b.data()['dueDate'] as Timestamp?;
                      return (aDue?.millisecondsSinceEpoch ?? 0).compareTo(
                        bDue?.millisecondsSinceEpoch ?? 0,
                      );
                    });
                final assignedChecks = assignments
                    .where(
                      (doc) => doc.data()['assignmentSource'] != 'self_started',
                    )
                    .toList();
                final selfStartedChecks = assignments
                    .where(
                      (doc) => doc.data()['assignmentSource'] == 'self_started',
                    )
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      _StatusMessage(
                        icon: Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        text: _error!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_canConduct || _canAssignChecks)
                      Row(
                        children: [
                          if (_canConduct)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openSubflow(
                                  () => _selectingTemplate = true,
                                ),
                                icon: const Icon(Icons.add),
                                label: Text(strings.startCheck),
                              ),
                            ),
                          if (_canConduct && _canAssignChecks)
                            const SizedBox(width: 10),
                          if (_canAssignChecks)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _assignCheck,
                                icon: const Icon(Icons.person_add_alt_outlined),
                                label: Text(strings.assignCheck),
                              ),
                            ),
                        ],
                      ),
                    if (completedSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        inProgressSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        assignmentSnapshot.connectionState ==
                            ConnectionState.waiting) ...[
                      const SizedBox(height: 18),
                      const Center(child: CircularProgressIndicator()),
                    ] else ...[
                      if (assignedChecks.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          _canAssignChecks
                              ? strings.assignedChecks
                              : strings.assignedToMe,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        ...assignedChecks.map(
                          (doc) => _AssignedAuditRow(
                            assignment: doc.data(),
                            isAssignee:
                                doc.data()['assignedTo'] == currentUserId,
                            canReassign: _canAssignChecks,
                            canCancel: _canAssignChecks,
                            onStart: () => _startAssignedAudit(doc.id),
                            onReassign: () =>
                                _reassignCheck(doc.id, doc.data()),
                            onCancel: () => _cancelCheck(doc.id),
                          ),
                        ),
                      ],
                      if (selfStartedChecks.isNotEmpty ||
                          inProgress.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          strings.inProgress,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        ...selfStartedChecks.map(
                          (doc) => _AssignedAuditRow(
                            assignment: doc.data(),
                            isAssignee:
                                doc.data()['assignedTo'] == currentUserId,
                            canReassign: false,
                            canCancel:
                                _canAssignChecks ||
                                doc.data()['assignedTo'] == currentUserId,
                            onStart: () => _startAssignedAudit(doc.id),
                            onReassign: () {},
                            onCancel: () =>
                                _cancelCheck(doc.id, selfStarted: true),
                          ),
                        ),
                        ...inProgress.map(
                          (doc) => _AssignedAuditRow(
                            assignment: {
                              'templateNameSnapshot': doc
                                  .data()['templateNameSnapshot'],
                              'assignedToNameSnapshot': doc
                                  .data()['startedByDisplayNameSnapshot'],
                              'status': 'in_progress',
                            },
                            isAssignee:
                                doc.data()['startedBy'] == currentUserId,
                            canReassign: false,
                            canCancel: false,
                            onStart: () =>
                                _openSubflow(() => _activeAuditId = doc.id),
                            onReassign: () {},
                            onCancel: () {},
                          ),
                        ),
                      ],
                      if (assignments.length == _assignmentLimit)
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _assignmentLimit += 50),
                            child: Text(strings.loadMoreActiveChecks),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        strings.completedChecks,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (completed.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.playlist_add_check_circle_outlined,
                          title: strings.noCompletedChecksYet,
                          body: strings.runInternalCheckHelp,
                        )
                      else
                        ...completed
                            .take(_showCompletedHistory ? _auditLimit : 5)
                            .map(
                              (doc) => _InternalAuditRow(
                                audit: doc.data(),
                                actionLabel: strings.view,
                                onOpen: () =>
                                    _openSubflow(() => _activeAuditId = doc.id),
                              ),
                            ),
                      if (!_showCompletedHistory && completed.length > 5)
                        TextButton(
                          onPressed: () =>
                              setState(() => _showCompletedHistory = true),
                          child: Text(strings.viewMoreCompletedChecks),
                        ),
                      if (_showCompletedHistory &&
                          completed.length == _auditLimit)
                        TextButton(
                          onPressed: () => setState(() => _auditLimit += 20),
                          child: Text(strings.loadMoreCompletedChecks),
                        ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
