part of '../../main.dart';

class _PublicInspectionsContent extends StatefulWidget {
  const _PublicInspectionsContent({
    required this.tenantId,
    required this.siteId,
    required this.currentRole,
    this.showHeader = true,
    this.onSubflowChanged,
  });

  final String tenantId;
  final String siteId;
  final String currentRole;
  final bool showHeader;
  final ValueChanged<bool>? onSubflowChanged;

  @override
  State<_PublicInspectionsContent> createState() =>
      _PublicInspectionsContentState();
}

class _PublicInspectionsContentState extends State<_PublicInspectionsContent> {
  final InspectionRepository _inspectionRepository = InspectionRepository();
  final ViolationRepository _violationRepository = ViolationRepository();
  String? _selectedInspectionId;
  String? _selectedViolationId;
  String? _loadedViolationId;
  bool _isSavingViolation = false;
  String? _violationMessage;
  String? _violationError;

  final _generalController = TextEditingController();
  final _containmentController = TextEditingController();
  final _rootCauseController = TextEditingController();
  final _correctiveController = TextEditingController();
  final _preventiveController = TextEditingController();

  @override
  void dispose() {
    _generalController.dispose();
    _containmentController.dispose();
    _rootCauseController.dispose();
    _correctiveController.dispose();
    _preventiveController.dispose();
    super.dispose();
  }

  void _loadViolationResponse(
    String violationId,
    Map<String, dynamic> violation,
  ) {
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Saved for later.')));
    } catch (_) {
      setState(() {
        _violationError = 'Could not save the response. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingViolation = false;
        });
      }
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submitted for review.')));
      setState(() {
        _violationMessage = 'Submitted for review.';
      });
    } catch (_) {
      setState(() {
        _violationError = 'Could not submit the response. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingViolation = false;
        });
      }
    }
  }

  Future<void> _updateAuditViolationStatus(
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
      setState(() {
        _violationMessage =
            'Violation moved to ${_violationStatusLabel(status)}.';
      });
    } catch (_) {
      setState(() {
        _violationError = 'Could not update the violation. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingViolation = false;
        });
      }
    }
  }

  Map<String, String> _currentViolationResponse() {
    return {
      'responseGeneral': _generalController.text.trim(),
      'responseContainment': _containmentController.text.trim(),
      'responseRootCause': _rootCauseController.text.trim(),
      'responseCorrectiveAction': _correctiveController.text.trim(),
      'responsePreventiveAction': _preventiveController.text.trim(),
    };
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
                'Refresh public inspection data from More to import history for this site.',
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
                    (doc) => doc.data()['masterInspectionId'] == selectedDoc.id,
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

              if (_selectedViolationId != null) {
                QueryDocumentSnapshot<Map<String, dynamic>>? selectedViolation;
                for (final doc in violations) {
                  if (doc.id == _selectedViolationId) {
                    selectedViolation = doc;
                    break;
                  }
                }
                if (selectedViolation != null) {
                  final selectedViolationDoc = selectedViolation;
                  _loadViolationResponse(
                    selectedViolationDoc.id,
                    selectedViolationDoc.data(),
                  );
                  return _ViolationDetailView(
                    tenantId: widget.tenantId,
                    violationId: selectedViolationDoc.id,
                    violation: selectedViolationDoc.data(),
                    currentRole: widget.currentRole,
                    generalController: _generalController,
                    containmentController: _containmentController,
                    rootCauseController: _rootCauseController,
                    correctiveController: _correctiveController,
                    preventiveController: _preventiveController,
                    isSaving: _isSavingViolation,
                    message: _violationMessage,
                    error: _violationError,
                    backLabel: 'Back to inspection',
                    onBack: () {
                      setState(() {
                        _selectedViolationId = null;
                        _loadedViolationId = null;
                        _violationMessage = null;
                        _violationError = null;
                      });
                    },
                    onSaveResponse: () => _saveViolationResponse(
                      selectedViolationDoc.id,
                      selectedViolationDoc.data()['status'] as String? ??
                          'open',
                    ),
                    onSubmitForReview: () =>
                        _submitViolationForReview(selectedViolationDoc.id),
                    onManageAssignment:
                        _canManageAssignments &&
                            selectedViolationDoc.data()['status'] != 'closed' &&
                            selectedViolationDoc.data()['status'] !=
                                'pending_review'
                        ? () => _manageViolationAssignment(
                            selectedViolationDoc.id,
                            selectedViolationDoc.data(),
                          )
                        : null,
                    onUpdateStatus: (status, {reviewStatus, closureReason}) =>
                        _updateAuditViolationStatus(
                          selectedViolationDoc.id,
                          status,
                          reviewStatus: reviewStatus,
                          closureReason: closureReason,
                        ),
                  );
                }
              }

              return _InspectionDetailView(
                tenantId: widget.tenantId,
                siteId: widget.siteId,
                inspectionId: selectedDoc.id,
                inspection: selectedDoc.data(),
                violations: violations,
                isLoadingViolations:
                    violationSnapshot.connectionState ==
                    ConnectionState.waiting,
                onBack: () {
                  setState(() {
                    _selectedInspectionId = null;
                    _selectedViolationId = null;
                  });
                  widget.onSubflowChanged?.call(false);
                },
                onOpenViolation: (violationId) {
                  setState(() {
                    _selectedViolationId = violationId;
                    _loadedViolationId = null;
                    _violationMessage = null;
                    _violationError = null;
                  });
                },
              );
            },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              Text(
                'Audits',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
            ],
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
                  widget.onSubflowChanged?.call(true);
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
        _displayText(inspection['tenantReportStoragePath']).isNotEmpty ||
        _displayText(inspection['tenantReportStatus']) == 'available';

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
    required this.tenantId,
    required this.siteId,
    required this.inspectionId,
    required this.inspection,
    required this.violations,
    required this.isLoadingViolations,
    required this.onBack,
    required this.onOpenViolation,
  });

  final String tenantId;
  final String siteId;
  final String inspectionId;
  final Map<String, dynamic> inspection;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> violations;
  final bool isLoadingViolations;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenViolation;

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
          label: const Text('Back to public inspections'),
        ),
        const SizedBox(height: 8),
        _InspectionHeroCard(inspection: inspection),
        const SizedBox(height: 14),
        _InspectionSourceCard(
          tenantId: tenantId,
          siteId: siteId,
          inspectionId: inspectionId,
          inspection: inspection,
        ),
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
            violations: violations.where((doc) {
              final status = doc.data()['status'] as String? ?? 'open';
              return status == 'open' || status == 'in_progress';
            }).toList(),
            onOpenViolation: onOpenViolation,
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
            onOpenViolation: onOpenViolation,
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
            onOpenViolation: onOpenViolation,
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
  const _InspectionSourceCard({
    required this.tenantId,
    required this.siteId,
    required this.inspectionId,
    required this.inspection,
  });

  final String tenantId;
  final String siteId;
  final String inspectionId;
  final Map<String, dynamic> inspection;

  @override
  Widget build(BuildContext context) {
    final findingCount = (inspection['findingCount'] as num?)?.toInt() ?? 0;
    final facts = [
      _DetailFact('Inspection date', _dateText(inspection['inspectionDate'])),
      _DetailFact('Inspection type', inspection['inspectionType']),
      _DetailFact('Score', _inspectionScoreText(inspection)),
      _DetailFact('Grade', _inspectionGradeText(inspection)),
      _DetailFact('Official status', inspection['officialStatus']),
      _DetailFact('Findings', findingCount),
      _DetailFact('Report status', inspection['reportAvailabilityStatus']),
      _DetailFact('Report format', inspection['reportFormat']),
    ];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: InspectionRepository().streamReportAttachments(
        tenantId: tenantId,
        siteId: siteId,
        inspectionId: inspectionId,
      ),
      builder: (context, snapshot) {
        final reports = (snapshot.data?.docs ?? [])
            .where((doc) => doc.data()['type'] == 'inspection_report')
            .toList();
        final report = reports.isEmpty ? null : reports.first;
        final reportStatus = report == null
            ? 'Report missing'
            : _reportAttachmentStatus(report.data());
        return _DetailFactCard(
          title: 'Inspection details',
          icon: Icons.fact_check_outlined,
          facts: facts,
          emptyText:
              'Inspection details will appear here after a public data refresh.',
          collapsedSummary: _joinNonEmpty([
            _displayText(inspection['inspectionType']),
            _dateText(inspection['inspectionDate']),
            _inspectionGradeText(inspection).isEmpty
                ? ''
                : 'Grade ${_inspectionGradeText(inspection)}',
            _inspectionScoreText(inspection).isEmpty
                ? ''
                : 'Score ${_inspectionScoreText(inspection)}',
            '$findingCount findings',
            reportStatus,
          ]),
          initiallyExpanded: false,
          footer: _InspectionReportAction(
            tenantId: tenantId,
            siteId: siteId,
            inspectionId: inspectionId,
            report: report == null
                ? null
                : {
                    '_id': report.id,
                    'attachmentType': 'document',
                    ...report.data(),
                  },
            isLoading: snapshot.connectionState == ConnectionState.waiting,
          ),
        );
      },
    );
  }
}

class _InspectionReportAction extends StatefulWidget {
  const _InspectionReportAction({
    required this.tenantId,
    required this.siteId,
    required this.inspectionId,
    required this.report,
    required this.isLoading,
  });

  final String tenantId;
  final String siteId;
  final String inspectionId;
  final Map<String, dynamic>? report;
  final bool isLoading;

  @override
  State<_InspectionReportAction> createState() =>
      _InspectionReportActionState();
}

class _InspectionReportActionState extends State<_InspectionReportAction> {
  bool _isWorking = false;

  Future<void> _viewReport() async {
    final report = widget.report;
    if (report == null) {
      return;
    }
    final storagePath = _firstAvailableText([
      report['viewablePath'],
      report['storagePath'],
    ]);
    if (storagePath.isEmpty) {
      return;
    }
    final contentType = _firstAvailableText([
      report['viewableContentType'],
      report['contentType'],
    ]).toLowerCase();
    if (contentType.startsWith('image/')) {
      _showAttachmentPreview(context, {
        ...report,
        'type': 'image',
        'storagePath': storagePath,
        'compressedPath': storagePath,
        'thumbnailPath': storagePath,
      });
      return;
    }
    setState(() {
      _isWorking = true;
    });
    try {
      final url = await FirebaseStorage.instance
          .ref(storagePath)
          .getDownloadURL();
      final launched = await launchUrl(
        Uri.parse(url),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!launched && mounted) {
        _showMediaSnack(context, 'Could not open the report.');
      }
    } catch (error) {
      debugPrint('Could not open inspection report $storagePath: $error');
      if (mounted) {
        _showMediaSnack(context, 'Could not open the report.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _uploadReport() async {
    setState(() {
      _isWorking = true;
    });
    try {
      await InspectionRepository().uploadReportAttachment(
        tenantId: widget.tenantId,
        siteId: widget.siteId,
        inspectionId: widget.inspectionId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Report uploaded.')));
      }
    } on AppException catch (error) {
      if (mounted) {
        _showMediaSnack(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMediaSnack(context, 'Could not upload the report.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Text(
        'Checking report...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
      );
    }

    final report = widget.report;
    final canView =
        report != null &&
        _firstAvailableText([
          report['viewablePath'],
          report['storagePath'],
        ]).isNotEmpty;
    final label = canView ? 'Open report' : 'Upload report';
    final icon = canView ? Icons.open_in_new : Icons.upload_file_outlined;

    return _InlineSectionAction(
      icon: icon,
      label: label,
      onPressed: _isWorking ? null : (canView ? _viewReport : _uploadReport),
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
    required this.onOpenViolation,
  });

  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> violations;
  final ValueChanged<String> onOpenViolation;

  @override
  Widget build(BuildContext context) {
    if (violations.isEmpty) {
      return _DashboardSection(
        title: title,
        trailing: '0',
        children: const [_InspectionEmptyRow()],
      );
    }

    return _DashboardSection(
      title: title,
      trailing: violations.length.toString(),
      children: [
        for (final doc in violations)
          _InspectionFindingRow(
            violation: doc.data(),
            onOpen: () => onOpenViolation(doc.id),
          ),
      ],
    );
  }
}

class _InspectionFindingRow extends StatelessWidget {
  const _InspectionFindingRow({
    required this.violation,
    required this.onOpen,
    this.rowContext = _ViolationRowContext.publicInspectionDetail,
  });

  final Map<String, dynamic> violation;
  final VoidCallback onOpen;
  final _ViolationRowContext rowContext;

  @override
  Widget build(BuildContext context) {
    return _ViolationListRow(
      data: _ViolationRowData.fromViolation(violation, context: rowContext),
      onOpen: onOpen,
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted),
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

String _reportAttachmentStatus(Map<String, dynamic> report) {
  final status = _displayText(report['status']);
  if (status == 'ready') {
    final source = _displayText(report['source']);
    return source == 'user_upload' ? 'Report uploaded' : 'Report available';
  }
  if (status.isNotEmpty) {
    return 'Report $status';
  }
  return 'Report available';
}
