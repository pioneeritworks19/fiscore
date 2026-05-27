part of '../../main.dart';

class FiScoreLogoMark extends StatelessWidget {
  const FiScoreLogoMark({super.key, this.size = 40, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _FiScoreLogoPainter(onDark: onDark),
    );
  }
}

class FiScoreLogoLockup extends StatelessWidget {
  const FiScoreLogoLockup({
    super.key,
    this.markSize = 88,
    this.centered = true,
    this.showTagline = true,
  });

  final double markSize;
  final bool centered;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        FiScoreLogoMark(size: markSize),
        SizedBox(height: markSize * 0.18),
        Text(
          'FiScore',
          textAlign: textAlign,
          style: theme.textTheme.displaySmall?.copyWith(
            color: _navy,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Safer Kitchens. Smarter Scores.',
            textAlign: textAlign,
            style: theme.textTheme.titleSmall?.copyWith(
              color: _muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

class FiScoreHeaderBrand extends StatelessWidget {
  const FiScoreHeaderBrand({
    super.key,
    this.markSize = 40,
    this.wordmarkHeight = 28,
  });

  final double markSize;
  final double wordmarkHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/branding/fiscore_mark.png',
          width: markSize,
          height: markSize,
          fit: BoxFit.contain,
          semanticLabel: 'FiScore',
        ),
        const SizedBox(width: 7),
        Image.asset(
          'assets/branding/fiscore_header.png',
          height: wordmarkHeight,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ],
    );
  }
}

class FiScoreAuthBrand extends StatelessWidget {
  const FiScoreAuthBrand({super.key, this.width = 330});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/fiscore_lockup.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'FiScore. Safer Kitchens. Smarter Scores.',
    );
  }
}

class _FiScoreLogoPainter extends CustomPainter {
  const _FiScoreLogoPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final navy = onDark ? Colors.white : _navy;
    final greenPaint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.060
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final navyPaint = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.090
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final barPaint = Paint()
      ..color = _green
      ..style = PaintingStyle.fill;
    final accentBarPaint = Paint()
      ..color = const Color(0xFF7FCB2B)
      ..style = PaintingStyle.fill;

    final shield = Path()
      ..moveTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.82, h * 0.20)
      ..quadraticBezierTo(w * 0.87, h * 0.22, w * 0.86, h * 0.29)
      ..lineTo(w * 0.81, h * 0.58)
      ..quadraticBezierTo(w * 0.76, h * 0.78, w * 0.50, h * 0.92)
      ..quadraticBezierTo(w * 0.24, h * 0.78, w * 0.19, h * 0.58)
      ..lineTo(w * 0.14, h * 0.29)
      ..quadraticBezierTo(w * 0.13, h * 0.22, w * 0.18, h * 0.20)
      ..close();
    canvas.drawPath(shield, greenPaint);

    final barRadius = Radius.circular(w * 0.025);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.52, w * 0.085, h * 0.18),
        barRadius,
      ),
      barPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, h * 0.43, w * 0.085, h * 0.27),
        barRadius,
      ),
      accentBarPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.30, w * 0.085, h * 0.40),
        barRadius,
      ),
      barPaint,
    );

    final check = Path()
      ..moveTo(w * 0.28, h * 0.62)
      ..lineTo(w * 0.45, h * 0.78)
      ..lineTo(w * 0.74, h * 0.42);
    canvas.drawPath(check, navyPaint);
  }

  @override
  bool shouldRepaint(covariant _FiScoreLogoPainter oldDelegate) {
    return oldDelegate.onDark != onDark;
  }
}
