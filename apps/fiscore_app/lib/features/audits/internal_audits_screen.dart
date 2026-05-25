part of '../../main.dart';

class _AuditsContent extends StatefulWidget {
  const _AuditsContent({
    required this.tenantId,
    required this.siteId,
    required this.currentRole,
  });

  final String tenantId;
  final String siteId;
  final String currentRole;

  @override
  State<_AuditsContent> createState() => _AuditsContentState();
}

class _AuditsContentState extends State<_AuditsContent> {
  String _mode = 'internal';
  bool _inSubflow = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_inSubflow) ...[
          Text(
            'Audits',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'internal',
                icon: Icon(Icons.playlist_add_check_outlined),
                label: Text('Internal'),
              ),
              ButtonSegment(
                value: 'public',
                icon: Icon(Icons.fact_check_outlined),
                label: Text('Public'),
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
    required this.onSubflowChanged,
  });

  final String tenantId;
  final String siteId;
  final String currentRole;
  final ValueChanged<bool> onSubflowChanged;

  @override
  State<_InternalAuditsContent> createState() => _InternalAuditsContentState();
}

class _InternalAuditsContentState extends State<_InternalAuditsContent> {
  final InternalAuditRepository _repository = InternalAuditRepository();
  final ViolationRepository _violationRepository = ViolationRepository();
  String? _activeAuditId;
  String? _selectedViolationId;
  String? _loadedViolationId;
  bool _selectingTemplate = false;
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
    });
    widget.onSubflowChanged(false);
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Saved for later.')));
    } catch (_) {
      if (mounted) {
        setState(() {
          _violationError = 'Could not save the response. Please try again.';
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
        _violationError = 'Enter what was fixed before submitting for review.';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submitted for review.')));
      setState(() {
        _selectedViolationId = null;
        _loadedViolationId = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _violationError = 'Could not submit the response. Please try again.';
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Checklist added to My Library.')),
        );
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not add this checklist. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedViolationId != null) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _violationRepository.streamForSite(
          tenantId: widget.tenantId,
          siteId: widget.siteId,
        ),
        builder: (context, snapshot) {
          QueryDocumentSnapshot<Map<String, dynamic>>? selectedViolation;
          for (final doc in snapshot.data?.docs ?? []) {
            if (doc.id == _selectedViolationId) {
              selectedViolation = doc;
              break;
            }
          }
          if (selectedViolation == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final selectedDoc = selectedViolation;
          _loadViolationResponse(selectedDoc.id, selectedDoc.data());
          return _ViolationDetailView(
            tenantId: widget.tenantId,
            violationId: selectedDoc.id,
            violation: selectedDoc.data(),
            currentRole: widget.currentRole,
            generalController: _generalController,
            containmentController: _containmentController,
            rootCauseController: _rootCauseController,
            correctiveController: _correctiveController,
            preventiveController: _preventiveController,
            isSaving: _isSavingViolation,
            message: _violationMessage,
            error: _violationError,
            backLabel: 'Back to completed check',
            onBack: () {
              setState(() {
                _selectedViolationId = null;
                _loadedViolationId = null;
                _violationMessage = null;
                _violationError = null;
              });
            },
            onSaveResponse: () => _saveViolationResponse(
              selectedDoc.id,
              selectedDoc.data()['status'] as String? ?? 'open',
            ),
            onSubmitForReview: () => _submitViolationForReview(selectedDoc.id),
            onUpdateStatus: (status, {reviewStatus, closureReason}) =>
                _updateViolationStatus(
                  selectedDoc.id,
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
        onBack: _backToInternalAudits,
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
      stream: _repository.streamForSite(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
      ),
      builder: (context, snapshot) {
        final audits = snapshot.data?.docs ?? [];
        final inProgress = audits
            .where((doc) => doc.data()['status'] == 'in_progress')
            .toList();
        final completed = audits
            .where((doc) => doc.data()['status'] == 'completed')
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
            if (_canConduct)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      _openSubflow(() => _selectingTemplate = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Start check'),
                ),
              )
            else
              const _EmptyStateCard(
                icon: Icons.lock_outline,
                title: 'Internal checks are limited',
                body: 'Managers and auditors conduct internal checks.',
              ),
            if (snapshot.connectionState == ConnectionState.waiting) ...[
              const SizedBox(height: 18),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              if (inProgress.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'In progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...inProgress.map(
                  (doc) => _InternalAuditRow(
                    audit: doc.data(),
                    actionLabel: 'Resume',
                    onOpen: () => _openSubflow(() => _activeAuditId = doc.id),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Completed checks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (completed.isEmpty)
                const _EmptyStateCard(
                  icon: Icons.playlist_add_check_circle_outlined,
                  title: 'No completed checks yet',
                  body:
                      'Run an internal check to identify issues before an inspection.',
                )
              else
                ...completed
                    .take(5)
                    .map(
                      (doc) => _InternalAuditRow(
                        audit: doc.data(),
                        actionLabel: 'View',
                        onOpen: () =>
                            _openSubflow(() => _activeAuditId = doc.id),
                      ),
                    ),
            ],
          ],
        );
      },
    );
  }
}
