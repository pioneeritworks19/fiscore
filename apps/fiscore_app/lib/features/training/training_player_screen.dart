part of '../../main.dart';

class _TrainingPlayerView extends StatefulWidget {
  const _TrainingPlayerView({
    required this.tenantId,
    required this.assignmentId,
    required this.assignment,
    required this.canComplete,
    required this.canManage,
    required this.onBack,
    required this.onCompleted,
  });
  final String tenantId;
  final String assignmentId;
  final Map<String, dynamic> assignment;
  final bool canComplete;
  final bool canManage;
  final VoidCallback onBack;
  final VoidCallback onCompleted;

  @override
  State<_TrainingPlayerView> createState() => _TrainingPlayerViewState();
}

class _TrainingPlayerViewState extends State<_TrainingPlayerView> {
  final TrainingRepository _repository = TrainingRepository();
  Map<String, dynamic>? _libraryTraining;
  int _page = 0;
  int _incorrectAnswerCount = 0;
  int? _selectedAnswer;
  bool _answerChecked = false;
  bool _checkedAnswerIsCorrect = false;
  String? _feedback;
  String? _completionError;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _completed = false;
  final Set<String> _completedRequiredMediaIds = {};

  String get _title =>
      widget.assignment['trainingTitleSnapshot'] as String? ?? 'Training';
  String get _description =>
      widget.assignment['trainingDescriptionSnapshot'] as String? ?? '';
  List<Map<String, dynamic>> get _sections => _mapsFrom(
    widget.assignment['trainingSectionsSnapshot'] ??
        _libraryTraining?['sections'],
  );
  List<Map<String, dynamic>> get _questions => _mapsFrom(
    widget.assignment['quickCheckQuestionsSnapshot'] ??
        _libraryTraining?['quickCheckQuestions'],
  );
  Map<String, Map<String, dynamic>> get _mediaAssets => _mediaAssetsFrom(
    widget.assignment['trainingMediaAssetsSnapshot'] ??
        _libraryTraining?['mediaAssets'],
  );
  bool get _isAlreadyComplete =>
      _completed || widget.assignment['status'] == 'completed';
  bool get _isCancelled => widget.assignment['status'] == 'cancelled';

  @override
  void initState() {
    super.initState();
    _completed = widget.assignment['status'] == 'completed';
    _loadLibraryFallback();
  }

  List<Map<String, dynamic>> _mapsFrom(Object? value) {
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, Map<String, dynamic>> _mediaAssetsFrom(Object? value) {
    final items = value as Map? ?? const {};
    return items.map(
      (key, asset) =>
          MapEntry(key.toString(), Map<String, dynamic>.from(asset as Map)),
    );
  }

  List<String> _requiredMediaIds(Map<String, dynamic> section) {
    return _trainingContentBlocks(section)
        .where((block) => block['type'] == 'video')
        .map((block) => block['mediaId'] as String? ?? '')
        .where((id) => id.isNotEmpty && _mediaAssets[id]?['required'] == true)
        .toList();
  }

  Future<void> _loadLibraryFallback() async {
    if (_sections.isNotEmpty) return;
    final trainingId = widget.assignment['trainingId'] as String?;
    if (trainingId == null) return;
    setState(() => _isLoading = true);
    try {
      final training = await _repository.trainingById(
        tenantId: widget.tenantId,
        trainingId: trainingId,
      );
      if (mounted) setState(() => _libraryTraining = training);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTrainingContent() async {
    final trainingId = widget.assignment['trainingId'] as String?;
    if (trainingId == null) return;
    setState(() => _isLoading = true);
    try {
      await _repository.addLibraryTraining(
        tenantId: widget.tenantId,
        libraryItemId: trainingId,
      );
      await _loadLibraryFallback();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not update the Training library.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _start() async {
    if (!widget.canComplete) return;
    if (widget.assignment['status'] == 'assigned') {
      await _repository.startAssignment(
        tenantId: widget.tenantId,
        assignmentId: widget.assignmentId,
      );
    }
    if (mounted) setState(() => _page = 1);
  }

  Future<void> _nextTopic() async {
    if (_page == _sections.length && _questions.isEmpty) {
      await _complete();
      return;
    }
    setState(() {
      _feedback = null;
      _completionError = null;
      _selectedAnswer = null;
      _answerChecked = false;
      _checkedAnswerIsCorrect = false;
      _page += 1;
    });
  }

  void _previousPage() {
    if (_page <= 1) {
      setState(() => _page = 0);
      return;
    }
    setState(() {
      _feedback = null;
      _completionError = null;
      _selectedAnswer = null;
      _answerChecked = false;
      _checkedAnswerIsCorrect = false;
      _page -= 1;
    });
  }

  Future<void> _checkAnswer(Map<String, dynamic> question) async {
    if (_selectedAnswer == null) return;
    if (_answerChecked) {
      if (_page < _sections.length + _questions.length) {
        await _nextTopic();
      } else {
        await _complete();
      }
      return;
    }
    final correctAnswer = question['correctOptionIndex'] as int? ?? -1;
    final correct = _selectedAnswer == correctAnswer;
    setState(() {
      _answerChecked = true;
      _checkedAnswerIsCorrect = correct;
      _completionError = null;
      if (!correct) _incorrectAnswerCount += 1;
      _feedback =
          question['explanation'] as String? ??
          'Review this practice before continuing.';
    });
  }

  Future<void> _complete() async {
    setState(() => _isSaving = true);
    try {
      await _repository.completeAssignment(
        tenantId: widget.tenantId,
        assignmentId: widget.assignmentId,
        incorrectAnswerCount: _incorrectAnswerCount,
        completedTopicCount: _sections.length,
        completionSummary: {
          'trainingTitle': _title,
          'trainingVersion': widget.assignment['trainingVersion'],
          'topics': _sections
              .map((section) => section['title'] as String? ?? '')
              .where((title) => title.isNotEmpty)
              .toList(),
          'linkedViolationId': widget.assignment['linkedViolationId'],
          'linkedViolationTitleSnapshot':
              widget.assignment['linkedViolationTitleSnapshot'],
        },
      );
      if (mounted) {
        setState(() => _completed = true);
        widget.onCompleted();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _completionError =
              'Could not record your completion. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) return _buildCancelled(context);
    if (_isAlreadyComplete) return _buildSummary(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_page == 0) return _buildOverview(context);
    if (_page <= _sections.length) {
      return _buildTopic(context, _sections[_page - 1]);
    }
    if (_questions.isNotEmpty) {
      return _buildQuestion(context, _questions[_page - _sections.length - 1]);
    }
    return _buildOverview(context);
  }

  Widget _buildCancelled(BuildContext context) {
    return _shell(
      context,
      children: [
        Text(
          _title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const _StatusMessage(
          icon: Icons.block_outlined,
          color: _muted,
          text:
              'This training assignment was cancelled and no longer needs to be completed.',
        ),
      ],
    );
  }

  Widget _shell(BuildContext context, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Back to training'),
        ),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }

  Widget _buildOverview(BuildContext context) {
    final linkedTitle =
        widget.assignment['linkedViolationTitleSnapshot'] as String?;
    if (_sections.isEmpty) {
      return _shell(
        context,
        children: [
          Text(
            _title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _StatusMessage(
            icon: Icons.info_outline,
            color: _navy,
            text: widget.canManage
                ? 'This assignment uses content that is not currently in My Library. Add its FiScore lesson, then reopen it or assign a new version.'
                : 'This training is not available yet. Please contact your manager.',
          ),
          if (widget.canManage) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _updateTrainingContent,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add lesson to My Library'),
            ),
          ],
        ],
      );
    }
    return _shell(
      context,
      children: [
        Text(
          _title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _TrainingPill(
              label:
                  '${widget.assignment['durationMinutes'] ?? _sections.length} min',
            ),
            const SizedBox(width: 8),
            _TrainingPill(label: '${_questions.length} question check'),
          ],
        ),
        if (linkedTitle != null && linkedTitle.isNotEmpty) ...[
          const SizedBox(height: 18),
          _TrainingInfoBlock(
            title: 'Assigned for follow-up',
            body: linkedTitle,
          ),
        ],
        const SizedBox(height: 18),
        _TrainingInfoBlock(
          title: 'You will cover',
          body: _sections
              .map((section) => section['title'] as String? ?? '')
              .where((title) => title.isNotEmpty)
              .join(' | '),
        ),
        const SizedBox(height: 22),
        if (widget.canComplete)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sections.isEmpty ? null : _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start training'),
            ),
          )
        else
          _StatusMessage(
            icon: Icons.info_outline,
            color: _navy,
            text:
                'Assigned to ${widget.assignment['assignedToNameSnapshot'] ?? 'team member'}.',
          ),
      ],
    );
  }

  Widget _buildTopic(BuildContext context, Map<String, dynamic> section) {
    final requiredMediaIds = _requiredMediaIds(section);
    final pendingRequiredMedia = requiredMediaIds
        .where((id) => !_completedRequiredMediaIds.contains(id))
        .toList();
    return _shell(
      context,
      children: [
        Text(
          'Topic $_page of ${_sections.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _page / (_sections.length + _questions.length),
          color: _green,
          backgroundColor: _line,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 22),
        Text(
          section['title'] as String? ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        for (final block in _trainingContentBlocks(section))
          _TrainingContentBlock(
            block: block,
            mediaAsset: _mediaAssets[block['mediaId']],
            onRequiredMediaCompleted: (mediaId) {
              if (_completedRequiredMediaIds.add(mediaId)) {
                setState(() {});
              }
            },
          ),
        const SizedBox(height: 24),
        if (pendingRequiredMedia.isNotEmpty) ...[
          const _StatusMessage(
            icon: Icons.play_circle_outline,
            color: _navy,
            text: 'Watch the required video to continue.',
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            TextButton(onPressed: _previousPage, child: const Text('Previous')),
            const Spacer(),
            FilledButton.icon(
              onPressed: _isSaving || pendingRequiredMedia.isNotEmpty
                  ? null
                  : _nextTopic,
              icon: const Icon(Icons.chevron_right),
              label: Text(
                _page == _sections.length
                    ? _questions.isNotEmpty
                          ? 'Quick check'
                          : 'Complete'
                    : 'Next',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final questionNumber = _page - _sections.length;
    final options = List<String>.from(question['options'] as List? ?? const []);
    final correctAnswer = question['correctOptionIndex'] as int? ?? -1;
    return _shell(
      context,
      children: [
        Text(
          'Quick check $questionNumber of ${_questions.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: _page / (_sections.length + _questions.length),
          color: _green,
          backgroundColor: _line,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 22),
        Text(
          question['prompt'] as String? ?? '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 15),
        for (var index = 0; index < options.length; index++)
          _TrainingAnswerOption(
            label: options[index],
            selected: _selectedAnswer == index,
            answerChecked: _answerChecked,
            isCorrect: index == correctAnswer,
            onTap: _answerChecked
                ? null
                : () => setState(() {
                    _selectedAnswer = index;
                    _feedback = null;
                  }),
          ),
        if (_feedback != null) ...[
          const SizedBox(height: 8),
          _TrainingAnswerFeedback(
            correct: _checkedAnswerIsCorrect,
            correctAnswer: correctAnswer >= 0 && correctAnswer < options.length
                ? options[correctAnswer]
                : '',
            explanation: _feedback!,
          ),
        ],
        if (_completionError != null) ...[
          const SizedBox(height: 10),
          _StatusMessage(
            icon: Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            text: _completionError!,
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            TextButton(onPressed: _previousPage, child: const Text('Previous')),
            const Spacer(),
            FilledButton(
              onPressed: _isSaving || _selectedAnswer == null
                  ? null
                  : () => _checkAnswer(question),
              child: Text(
                !_answerChecked
                    ? 'Check answer'
                    : questionNumber == _questions.length
                    ? 'Finish'
                    : 'Continue',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final completedAt = widget.assignment['completedAt'];
    final completedDate = completedAt is Timestamp
        ? completedAt.toDate()
        : DateTime.now();
    final completionDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(completedDate);
    final summary = widget.assignment['completionSummarySnapshot'] as Map?;
    final topicNames =
        summary?['topics'] as List? ??
        _sections.map((section) => section['title']).toList();
    return _shell(
      context,
      children: [
        const Icon(Icons.check_circle_outline, color: _green, size: 34),
        const SizedBox(height: 12),
        Text(
          'Training complete',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 20),
        _TrainingInfoBlock(
          title: 'Completed by',
          body:
              '${widget.assignment['assignedToNameSnapshot'] ?? 'Team member'} | $completionDate',
        ),
        const SizedBox(height: 12),
        _TrainingInfoBlock(
          title: 'Topics covered',
          body: topicNames.whereType<String>().join(' | '),
        ),
        const SizedBox(height: 12),
        _StatusMessage(
          icon: Icons.verified_outlined,
          color: _green,
          text: 'Quick check completed. This completion is recorded.',
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: widget.onBack,
            style: _greenFilledButtonStyle(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}

class _TrainingInfoBlock extends StatelessWidget {
  const _TrainingInfoBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TrainingAnswerOption extends StatelessWidget {
  const _TrainingAnswerOption({
    required this.label,
    required this.selected,
    required this.answerChecked,
    required this.isCorrect,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool answerChecked;
  final bool isCorrect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showsCorrect = answerChecked && isCorrect;
    final showsIncorrect = answerChecked && selected && !isCorrect;
    final borderColor = showsCorrect
        ? _green
        : showsIncorrect
        ? Theme.of(context).colorScheme.error
        : selected
        ? _navy
        : _line;
    final fillColor = showsCorrect
        ? _softGreen
        : showsIncorrect
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08)
        : selected
        ? _navy.withValues(alpha: 0.06)
        : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              showsCorrect
                  ? Icons.check_circle
                  : showsIncorrect
                  ? Icons.cancel_outlined
                  : selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: showsCorrect
                  ? _green
                  : showsIncorrect
                  ? Theme.of(context).colorScheme.error
                  : selected
                  ? _navy
                  : _muted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _TrainingAnswerFeedback extends StatelessWidget {
  const _TrainingAnswerFeedback({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
  });

  final bool correct;
  final String correctAnswer;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _green.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: _green, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Correct' : 'Correct answer',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!correct) ...[
                  const SizedBox(height: 3),
                  Text(
                    correctAnswer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _ink, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
