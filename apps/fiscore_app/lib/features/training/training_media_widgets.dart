part of '../../main.dart';

List<Map<String, dynamic>> _trainingContentBlocks(
  Map<String, dynamic> section,
) {
  final blocks = (section['blocks'] as List? ?? const [])
      .whereType<Map>()
      .map((block) => Map<String, dynamic>.from(block))
      .toList();
  if (blocks.isNotEmpty) return blocks;
  return [
    if ((section['body'] as String? ?? '').isNotEmpty)
      {'type': 'text', 'body': section['body']},
    if ((section['actionTip'] as String? ?? '').isNotEmpty)
      {'type': 'tip', 'body': section['actionTip']},
  ];
}

class _TrainingContentBlock extends StatelessWidget {
  const _TrainingContentBlock({
    required this.block,
    this.mediaAsset,
    this.onRequiredMediaCompleted,
  });

  final Map<String, dynamic> block;
  final Map<String, dynamic>? mediaAsset;
  final ValueChanged<String>? onRequiredMediaCompleted;

  @override
  Widget build(BuildContext context) {
    final content = {...?mediaAsset, ...block};
    return switch (content['type']) {
      'image' => _TrainingImageBlock(block: content),
      'video' => _TrainingVideoBlock(
        block: content,
        onRequirementMet: onRequiredMediaCompleted,
      ),
      'tip' => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _TrainingInfoBlock(
          title: 'Remember',
          body: content['body'] as String? ?? '',
        ),
      ),
      _ => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          content['body'] as String? ?? '',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: _ink, height: 1.45),
        ),
      ),
    };
  }
}

class _TrainingImageBlock extends StatefulWidget {
  const _TrainingImageBlock({required this.block});

  final Map<String, dynamic> block;

  @override
  State<_TrainingImageBlock> createState() => _TrainingImageBlockState();
}

class _TrainingImageBlockState extends State<_TrainingImageBlock> {
  late Future<String> _url;

  String get _path => widget.block['storagePath'] as String? ?? '';
  String get _caption => widget.block['caption'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    _url = _downloadUrl(_path);
  }

  @override
  void didUpdateWidget(covariant _TrainingImageBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block['storagePath'] != widget.block['storagePath']) {
      _url = _downloadUrl(_path);
    }
  }

  Future<String> _downloadUrl(String path) {
    return FirebaseStorage.instance.ref(path).getDownloadURL();
  }

  void _showImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton.filledTonal(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: FutureBuilder<String>(
        future: _url,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _TrainingMediaLoading(label: 'Loading image...');
          }
          if (!snapshot.hasData) {
            return _TrainingMediaUnavailable(
              icon: Icons.image_outlined,
              label: 'Training image unavailable',
              caption: _caption,
            );
          }
          return InkWell(
            onTap: () => _showImage(snapshot.data!),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const _TrainingMediaUnavailable(
                            icon: Icons.broken_image_outlined,
                            label: 'Could not display image',
                          ),
                    ),
                  ),
                  if (_caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _caption,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _muted,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrainingVideoBlock extends StatefulWidget {
  const _TrainingVideoBlock({required this.block, this.onRequirementMet});

  final Map<String, dynamic> block;
  final ValueChanged<String>? onRequirementMet;

  @override
  State<_TrainingVideoBlock> createState() => _TrainingVideoBlockState();
}

class _TrainingVideoBlockState extends State<_TrainingVideoBlock> {
  VideoPlayerController? _controller;
  bool _loading = false;
  String? _error;
  bool _requirementMet = false;

  String get _path => widget.block['storagePath'] as String? ?? '';
  String get _mediaId => widget.block['mediaId'] as String? ?? '';
  String get _caption => widget.block['caption'] as String? ?? '';
  String get _duration => widget.block['durationLabel'] as String? ?? '';
  bool get _optional => widget.block['optional'] == true;
  bool get _required => widget.block['required'] == true;

  @override
  void didUpdateWidget(covariant _TrainingVideoBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block['storagePath'] != widget.block['storagePath']) {
      final oldController = _controller;
      _controller = null;
      _loading = false;
      _error = null;
      _requirementMet = false;
      oldController?.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_controller != null) {
      final controller = _controller!;
      controller.value.isPlaying
          ? await controller.pause()
          : await controller.play();
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = await FirebaseStorage.instance.ref(_path).getDownloadURL();
      debugPrint('Loading training video $_mediaId from $_path');
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      controller.addListener(_handleProgress);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error, stackTrace) {
      debugPrint('Could not load training video $_mediaId from $_path: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _error = 'Training video unavailable');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleProgress() {
    final controller = _controller;
    if (!_required ||
        _requirementMet ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    final duration = controller.value.duration;
    final remaining = duration - controller.value.position;
    if (duration > Duration.zero && remaining <= const Duration(seconds: 1)) {
      _requirementMet = true;
      widget.onRequirementMet?.call(_mediaId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _navy.withValues(alpha: 0.04),
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller != null && controller.value.isInitialized)
              AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(controller),
                    IconButton.filled(
                      tooltip: controller.value.isPlaying ? 'Pause' : 'Play',
                      onPressed: _play,
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: !_required,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 142,
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : IconButton.filled(
                          tooltip: 'Play video',
                          onPressed: _play,
                          icon: const Icon(Icons.play_arrow),
                          iconSize: 30,
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 18,
                        color: _navy,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _caption,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (_duration.isNotEmpty)
                        Text(
                          _duration,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: _muted),
                        ),
                    ],
                  ),
                  if (_optional) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Optional reference video',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: _muted),
                    ),
                  ],
                  if (_required) ...[
                    const SizedBox(height: 5),
                    Text(
                      _requirementMet
                          ? 'Completed - required video watched'
                          : 'Required - watch to continue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _requirementMet ? _green : _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingMediaLoading extends StatelessWidget {
  const _TrainingMediaLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.04),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted),
      ),
    );
  }
}

class _TrainingMediaUnavailable extends StatelessWidget {
  const _TrainingMediaUnavailable({
    required this.icon,
    required this.label,
    this.caption = '',
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.04),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: _muted),
          const SizedBox(height: 7),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _muted),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _muted, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}
