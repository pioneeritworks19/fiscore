part of '../../main.dart';

class _InternalAuditSessionView extends StatefulWidget {
  const _InternalAuditSessionView({
    required this.tenantId,
    required this.siteId,
    required this.auditId,
    required this.repository,
    required this.exitLabel,
    required this.onBack,
    required this.onOpenViolation,
  });

  final String tenantId;
  final String siteId;
  final String auditId;
  final InternalAuditRepository repository;
  final String exitLabel;
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
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(strings.takePhoto),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(strings.choosePhoto),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
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
                exitLabel: widget.exitLabel,
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
                  label: Text(widget.exitLabel),
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
                    AppLocalizations.of(context).continueAndFinishFromReview,
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
                        label: Text(AppLocalizations.of(context).previous),
                      )
                    else
                      TextButton(
                        onPressed: widget.onBack,
                        child: Text(AppLocalizations.of(context).saveAndExit),
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
                            ? AppLocalizations.of(context).done
                            : safeSectionIndex + 1 < sections.length
                            ? AppLocalizations.of(context).next
                            : AppLocalizations.of(context).review,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    AppLocalizations.of(context).responsesSaveAutomatically,
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
                child: Text(AppLocalizations.of(context).save),
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
            segments: [
              ButtonSegment(
                value: 'pass',
                label: Text(AppLocalizations.of(context).pass),
              ),
              ButtonSegment(
                value: 'needs_attention',
                label: Text(AppLocalizations.of(context).attention),
              ),
              ButtonSegment(
                value: 'not_applicable',
                label: Text(AppLocalizations.of(context).notApplicable),
              ),
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
              AppLocalizations.of(context).describeIssueBeforeSubmitting,
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
