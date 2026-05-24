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

class _AuditTemplatePicker extends StatefulWidget {
  const _AuditTemplatePicker({
    required this.tenantId,
    required this.repository,
    required this.isWorking,
    required this.error,
    required this.canManageLibrary,
    required this.onBack,
    required this.onAddLibraryChecklist,
    required this.onSelect,
  });

  final String tenantId;
  final InternalAuditRepository repository;
  final bool isWorking;
  final String? error;
  final bool canManageLibrary;
  final VoidCallback onBack;
  final ValueChanged<String> onAddLibraryChecklist;
  final ValueChanged<String> onSelect;

  @override
  State<_AuditTemplatePicker> createState() => _AuditTemplatePickerState();
}

class _AuditTemplatePickerState extends State<_AuditTemplatePicker> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _libraryView = 'my';

  @override
  void initState() {
    super.initState();
    widget.repository
        .fiScoreLibraryChecklists(tenantId: widget.tenantId)
        .catchError((_) => <Map<String, dynamic>>[]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.isWorking ? null : widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back'),
        ),
        Text(
          'Start a check',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _libraryView == 'my'
              ? 'Choose a checklist your team uses at this site.'
              : 'Add curated FiScore checklists to your team library.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 14),
        if (widget.error != null) ...[
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: widget.error!,
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _searchController,
          enabled: !widget.isWorking,
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search checklists',
          ),
        ),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'my', label: Text('My Library')),
            ButtonSegment(value: 'explore', label: Text('Explore FiScore')),
          ],
          selected: {_libraryView},
          onSelectionChanged: widget.isWorking
              ? null
              : (value) => setState(() => _libraryView = value.first),
        ),
        const SizedBox(height: 14),
        if (_libraryView == 'my')
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: widget.repository.checklistTemplatesStream(
              tenantId: widget.tenantId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final templates =
                  (snapshot.data?.docs ?? []).where((doc) {
                    final template = doc.data();
                    final haystack =
                        '${template['name'] ?? ''} ${template['description'] ?? ''} '
                                '${template['category'] ?? ''}'
                            .toLowerCase();
                    return _query.isEmpty || haystack.contains(_query);
                  }).toList()..sort((left, right) {
                    final leftName = left.data()['name'] as String? ?? '';
                    final rightName = right.data()['name'] as String? ?? '';
                    return leftName.compareTo(rightName);
                  });
              if ((snapshot.data?.docs ?? []).isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No checklists in My Library',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.canManageLibrary
                            ? 'Explore FiScore Library to add a checklist your team can use.'
                            : 'Ask a manager to add an internal checklist for this site.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: _muted),
                      ),
                      const SizedBox(height: 12),
                      if (widget.canManageLibrary)
                        TextButton.icon(
                          onPressed: widget.isWorking
                              ? null
                              : () => setState(() => _libraryView = 'explore'),
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Explore FiScore Library'),
                        ),
                    ],
                  ),
                );
              }
              if (templates.isEmpty) {
                return const _EmptyStateCard(
                  icon: Icons.search_off_outlined,
                  title: 'No matching checklists',
                  body: 'Try another search term.',
                );
              }
              return Column(
                children: templates
                    .map(
                      (document) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChecklistTemplateCard(
                          templateId: document.id,
                          template: document.data(),
                          isWorking: widget.isWorking,
                          onSelect: widget.onSelect,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          )
        else
          FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.repository.fiScoreLibraryChecklists(
              tenantId: widget.tenantId,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _EmptyStateCard(
                  icon: Icons.error_outline,
                  title: 'Could not load FiScore Library',
                  body: 'Please try again shortly.',
                );
              }
              final items = (snapshot.data ?? const []).where((template) {
                final haystack =
                    '${template['name'] ?? ''} ${template['description'] ?? ''} '
                            '${template['category'] ?? ''}'
                        .toLowerCase();
                return _query.isEmpty || haystack.contains(_query);
              }).toList();
              if (items.isEmpty) {
                return const _EmptyStateCard(
                  icon: Icons.search_off_outlined,
                  title: 'No matching checklists',
                  body: 'Try another search term.',
                );
              }
              return Column(
                children: items
                    .map(
                      (template) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ChecklistTemplateCard(
                          templateId: template['libraryItemId'] as String,
                          template: template,
                          isWorking: widget.isWorking,
                          onSelect: widget.onAddLibraryChecklist,
                          actionLabel: template['updateAvailable'] == true
                              ? 'Update'
                              : template['inMyLibrary'] == true
                              ? 'Added'
                              : 'Add to My Library',
                          actionEnabled:
                              widget.canManageLibrary &&
                              (template['inMyLibrary'] != true ||
                                  template['updateAvailable'] == true),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _ChecklistTemplateCard extends StatelessWidget {
  const _ChecklistTemplateCard({
    required this.templateId,
    required this.template,
    required this.isWorking,
    required this.onSelect,
    this.actionLabel = 'Start',
    this.actionEnabled = true,
  });

  final String templateId;
  final Map<String, dynamic> template;
  final bool isWorking;
  final ValueChanged<String> onSelect;
  final String actionLabel;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    final duration = template['estimatedMinutes'] as int? ?? 0;
    final questions = template['questionCount'] as int? ?? 0;
    final isLibraryItem =
        template['templateSource'] == 'library_synced' ||
        template['libraryTemplateId'] != null;
    final updateAvailable = template['updateAvailable'] == true;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template['name'] as String? ?? 'Checklist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            template['description'] as String? ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted),
          ),
          const SizedBox(height: 10),
          Text(
            '${isLibraryItem ? 'FiScore Library' : 'Created by your team'}  |  $duration min  |  $questions items',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (updateAvailable && actionLabel == 'Start') ...[
            const SizedBox(height: 6),
            Text(
              'Update available in FiScore Library',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF2859C5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isWorking || !actionEnabled
                  ? null
                  : () => onSelect(templateId),
              icon: Icon(
                actionLabel == 'Start'
                    ? Icons.play_arrow_outlined
                    : Icons.add_circle_outline,
              ),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _InternalAuditRow extends StatelessWidget {
  const _InternalAuditRow({
    required this.audit,
    required this.actionLabel,
    required this.onOpen,
  });

  final Map<String, dynamic> audit;
  final String actionLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final complete = audit['status'] == 'completed';
    final violationCount = _internalAuditViolationCount(audit);
    final completedBy = audit['startedByDisplayNameSnapshot'] as String? ?? '';
    final auditDate = _dateText(
      complete ? audit['completedAt'] : audit['startedAt'],
    );
    final detailText = complete && completedBy.isNotEmpty
        ? '$auditDate / Completed by $completedBy'
        : auditDate;
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
                  Icons.playlist_add_check_outlined,
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
                      audit['templateNameSnapshot'] as String? ??
                          'Internal check',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (complete)
                          _AuditPill(
                            label: 'Score ${audit['scorePercentage'] ?? 0}',
                            color: _green,
                          )
                        else
                          const _AuditPill(label: 'In progress'),
                        if (complete)
                          _AuditPill(
                            label:
                                '$violationCount ${violationCount == 1 ? 'violation' : 'violations'}',
                            color: violationCount == 0 ? _green : _navy,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!complete) ...[
                Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
              ],
              const Icon(Icons.chevron_right, color: _navy, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _InternalAuditSessionView extends StatefulWidget {
  const _InternalAuditSessionView({
    required this.tenantId,
    required this.siteId,
    required this.auditId,
    required this.repository,
    required this.onBack,
    required this.onOpenViolation,
  });

  final String tenantId;
  final String siteId;
  final String auditId;
  final InternalAuditRepository repository;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenViolation;

  @override
  State<_InternalAuditSessionView> createState() =>
      _InternalAuditSessionViewState();
}

class _InternalAuditSessionViewState extends State<_InternalAuditSessionView> {
  final AuditMediaService _mediaService = AuditMediaService();
  int _sectionIndex = 0;
  String _phase = 'execute';
  bool _returnToReviewAfterEdit = false;
  bool _saving = false;
  String? _error;

  Future<void> _saveAnswer(
    Map<String, dynamic> question,
    String answer,
    String existingNote,
  ) async {
    try {
      await widget.repository.saveResponse(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        auditId: widget.auditId,
        question: question,
        answer: answer,
        note: existingNote,
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save that response.');
    }
  }

  Future<void> _editNote(
    Map<String, dynamic> question,
    String? answer,
    String note,
  ) async {
    final needsAttention = answer == 'needs_attention';
    final notApplicable = answer == 'not_applicable';
    final title = needsAttention
        ? (note.isEmpty ? 'Describe issue' : 'Edit issue')
        : notApplicable
        ? (note.isEmpty ? 'Add reason' : 'Edit reason')
        : (note.isEmpty ? 'Add observation' : 'Edit observation');
    final hint = needsAttention
        ? 'Describe what needs attention.'
        : notApplicable
        ? 'Explain why this item does not apply.'
        : 'Add any useful observation.';
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AuditObservationSheet(
        title: title,
        prompt: question['prompt'] as String,
        hint: hint,
        initialValue: note,
      ),
    );
    if (value == null) return;
    await widget.repository.saveResponse(
      tenantId: widget.tenantId,
      siteId: widget.siteId,
      auditId: widget.auditId,
      question: question,
      answer: answer,
      note: value,
    );
  }

  Future<void> _addPhoto(String responseId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      await _mediaService.pickAndUploadPhoto(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        auditId: widget.auditId,
        responseId: responseId,
        source: source,
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not upload that photo.');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.submitAudit(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        auditId: widget.auditId,
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not submit this check.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _questionIsComplete(
    Map<String, dynamic> question,
    Map<String, Map<String, dynamic>> responses,
  ) {
    final response = responses[question['id']];
    final answer = response?['answer'] as String?;
    if (answer == null) return false;
    if (answer == 'needs_attention') {
      return (response?['note'] as String? ?? '').trim().isNotEmpty;
    }
    return true;
  }

  bool _sectionIsComplete(
    List<Map<String, dynamic>> questions,
    Map<String, Map<String, dynamic>> responses,
  ) {
    return questions.every(
      (question) => _questionIsComplete(question, responses),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: widget.repository.auditStream(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        auditId: widget.auditId,
      ),
      builder: (context, auditSnapshot) {
        final audit = auditSnapshot.data?.data();
        if (audit == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final questions = _internalQuestionsFromAudit(audit);
        final completed = audit['status'] == 'completed';
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: widget.repository.responseStream(
            tenantId: widget.tenantId,
            siteId: widget.siteId,
            auditId: widget.auditId,
          ),
          builder: (context, responseSnapshot) {
            final responses = <String, Map<String, dynamic>>{
              for (final doc in responseSnapshot.data?.docs ?? [])
                doc.id: doc.data(),
            };
            final answered = questions
                .where((question) => _questionIsComplete(question, responses))
                .length;
            if (completed) {
              return _InternalAuditCompletion(
                tenantId: widget.tenantId,
                siteId: widget.siteId,
                auditId: widget.auditId,
                audit: audit,
                responses: responses,
                onBack: widget.onBack,
                onOpenViolation: widget.onOpenViolation,
              );
            }
            final sections = _groupInternalQuestions(questions);
            if (_phase == 'review') {
              return _InternalAuditReview(
                questions: questions,
                sections: sections,
                responses: responses,
                error: _error,
                onBack: () => setState(() {
                  _phase = 'execute';
                  _sectionIndex = sections.isEmpty ? 0 : sections.length - 1;
                  _returnToReviewAfterEdit = false;
                }),
                onEditSection: (index) => setState(() {
                  _phase = 'execute';
                  _sectionIndex = index;
                  _returnToReviewAfterEdit = true;
                }),
                onContinue: () => setState(() => _phase = 'submit'),
              );
            }
            if (_phase == 'submit') {
              return _InternalAuditSubmitConfirmation(
                audit: audit,
                questions: questions,
                responses: responses,
                isSubmitting: _saving,
                error: _error,
                onBack: () => setState(() => _phase = 'review'),
                onSubmit: _submit,
              );
            }
            final safeSectionIndex = sections.isEmpty
                ? 0
                : _sectionIndex.clamp(0, sections.length - 1);
            final currentSection = sections.isEmpty
                ? null
                : sections[safeSectionIndex];
            final sectionQuestions =
                currentSection?.value ?? const <Map<String, dynamic>>[];
            final canContinue = _sectionIsComplete(sectionQuestions, responses);
            final progressValue = questions.isEmpty
                ? 0.0
                : answered / questions.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Back to checks'),
                ),
                Text(
                  audit['templateNameSnapshot'] as String? ?? 'Internal check',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sections.isEmpty
                      ? 'No checklist sections found.'
                      : 'Section ${safeSectionIndex + 1} of ${sections.length}  |  $answered of ${questions.length} complete',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _muted),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  minHeight: 7,
                  value: progressValue,
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: const Color(0xFFE8EEF6),
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _StatusMessage(
                    icon: Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    text: _error!,
                  ),
                ],
                const SizedBox(height: 18),
                if (currentSection != null) ...[
                  Text(
                    currentSection.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (
                    var index = 0;
                    index < currentSection.value.length;
                    index++
                  )
                    _InternalQuestionCard(
                      tenantId: widget.tenantId,
                      siteId: widget.siteId,
                      auditId: widget.auditId,
                      questionNumber: index + 1,
                      question: currentSection.value[index],
                      response: responses[currentSection.value[index]['id']],
                      onAnswer: (answer, note) => _saveAnswer(
                        currentSection.value[index],
                        answer,
                        note,
                      ),
                      onNote: (answer, note) =>
                          _editNote(currentSection.value[index], answer, note),
                      onPhoto: () => _addPhoto(
                        currentSection.value[index]['id'] as String,
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
                if (!canContinue && currentSection != null) ...[
                  Text(
                    'You can continue now and finish open items from review.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    if (safeSectionIndex > 0)
                      TextButton.icon(
                        onPressed: () => setState(
                          () => _sectionIndex = safeSectionIndex - 1,
                        ),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous'),
                      )
                    else
                      TextButton(
                        onPressed: widget.onBack,
                        child: const Text('Save & exit'),
                      ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        if (_returnToReviewAfterEdit) {
                          setState(() {
                            _phase = 'review';
                            _returnToReviewAfterEdit = false;
                          });
                        } else if (safeSectionIndex + 1 < sections.length) {
                          setState(() {
                            _sectionIndex = safeSectionIndex + 1;
                          });
                        } else {
                          setState(() => _phase = 'review');
                        }
                      },
                      icon: Icon(
                        !_returnToReviewAfterEdit &&
                                safeSectionIndex + 1 < sections.length
                            ? Icons.chevron_right
                            : Icons.fact_check_outlined,
                      ),
                      label: Text(
                        _returnToReviewAfterEdit
                            ? 'Done'
                            : safeSectionIndex + 1 < sections.length
                            ? 'Next'
                            : 'Review',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Responses save automatically.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AuditObservationSheet extends StatefulWidget {
  const _AuditObservationSheet({
    required this.title,
    required this.prompt,
    required this.hint,
    required this.initialValue,
  });

  final String title;
  final String prompt;
  final String hint;
  final String initialValue;

  @override
  State<_AuditObservationSheet> createState() => _AuditObservationSheetState();
}

class _AuditObservationSheetState extends State<_AuditObservationSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
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
            const SizedBox(height: 6),
            Text(
              widget.prompt,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(hintText: widget.hint),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, _controller.text.trim()),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InternalQuestionCard extends StatelessWidget {
  const _InternalQuestionCard({
    required this.tenantId,
    required this.siteId,
    required this.auditId,
    required this.questionNumber,
    required this.question,
    required this.response,
    required this.onAnswer,
    required this.onNote,
    required this.onPhoto,
  });

  final String tenantId;
  final String siteId;
  final String auditId;
  final int questionNumber;
  final Map<String, dynamic> question;
  final Map<String, dynamic>? response;
  final void Function(String answer, String note) onAnswer;
  final void Function(String? answer, String note) onNote;
  final VoidCallback onPhoto;

  @override
  Widget build(BuildContext context) {
    final answer = response?['answer'] as String?;
    final note = response?['note'] as String? ?? '';
    final failed = answer == 'needs_attention';
    final notApplicable = answer == 'not_applicable';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: failed ? const Color(0xFFF3B4AE) : _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$questionNumber. ${question['prompt'] as String}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'pass', label: Text('Pass')),
              ButtonSegment(value: 'needs_attention', label: Text('Attention')),
              ButtonSegment(value: 'not_applicable', label: Text('N/A')),
            ],
            selected: answer == null ? {} : {answer},
            emptySelectionAllowed: true,
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onAnswer(selection.first, note);
            },
          ),
          const SizedBox(height: 10),
          if (failed && note.isEmpty)
            Text(
              'Describe this issue before submitting.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB42318)),
            )
          else if (note.isNotEmpty)
            Text(
              note,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _muted, height: 1.35),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            children: [
              _InlineSectionAction(
                icon: Icons.edit_note_outlined,
                label: failed
                    ? (note.isEmpty ? 'Describe issue' : 'Edit issue')
                    : notApplicable
                    ? (note.isEmpty ? 'Add reason' : 'Edit reason')
                    : (note.isEmpty ? 'Add observation' : 'Edit observation'),
                onPressed: () => onNote(answer, note),
              ),
              _InlineSectionAction(
                icon: Icons.add_a_photo_outlined,
                label: 'Add photo',
                onPressed: onPhoto,
              ),
            ],
          ),
          _AuditResponseEvidence(
            tenantId: tenantId,
            siteId: siteId,
            auditId: auditId,
            responseId: question['id'] as String,
          ),
        ],
      ),
    );
  }
}

class _AuditResponseEvidence extends StatelessWidget {
  const _AuditResponseEvidence({
    required this.tenantId,
    required this.siteId,
    required this.auditId,
    required this.responseId,
  });

  final String tenantId;
  final String siteId;
  final String auditId;
  final String responseId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestorePaths.auditAttachments(
        tenantId,
        siteId,
        auditId,
      ).snapshots(),
      builder: (context, snapshot) {
        final items = (snapshot.data?.docs ?? [])
            .where((doc) => doc.data()['responseId'] == responseId)
            .toList();
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((doc) => _AuditPhotoThumbnail(attachment: doc.data()))
                .toList(),
          ),
        );
      },
    );
  }
}

class _AuditPhotoThumbnail extends StatelessWidget {
  const _AuditPhotoThumbnail({required this.attachment});

  final Map<String, dynamic> attachment;

  @override
  Widget build(BuildContext context) {
    final path = attachment['thumbnailPath'] as String?;
    if (path == null) return const SizedBox.shrink();
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(path).getDownloadURL(),
      builder: (context, snapshot) {
        return InkWell(
          onTap: snapshot.data == null
              ? null
              : () => _showAttachmentPreview(context, {
                  ...attachment,
                  'compressedPath': path,
                  'storagePath': path,
                }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 58,
            height: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF4F7FB),
            ),
            child: snapshot.data == null
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Image.network(snapshot.data!, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

bool _internalAuditQuestionHasAnswer(
  Map<String, dynamic> question,
  Map<String, Map<String, dynamic>> responses,
) {
  return responses[question['id']]?['answer'] != null;
}

bool _internalAuditQuestionNeedsIssueNote(
  Map<String, dynamic> question,
  Map<String, Map<String, dynamic>> responses,
) {
  final response = responses[question['id']];
  return response?['answer'] == 'needs_attention' &&
      (response?['note'] as String? ?? '').trim().isEmpty;
}

bool _internalAuditQuestionComplete(
  Map<String, dynamic> question,
  Map<String, Map<String, dynamic>> responses,
) {
  return _internalAuditQuestionHasAnswer(question, responses) &&
      !_internalAuditQuestionNeedsIssueNote(question, responses);
}

int _internalAuditMissingAnswerCount(
  Iterable<Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> responses,
) {
  return questions
      .where(
        (question) => !_internalAuditQuestionHasAnswer(question, responses),
      )
      .length;
}

int _internalAuditMissingIssueNoteCount(
  Iterable<Map<String, dynamic>> questions,
  Map<String, Map<String, dynamic>> responses,
) {
  return questions
      .where(
        (question) => _internalAuditQuestionNeedsIssueNote(question, responses),
      )
      .length;
}

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
