part of '../../main.dart';

class _ModulePlaceholderContent extends StatelessWidget {
  const _ModulePlaceholderContent({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        _OperationalBanner(
          icon: icon,
          title: 'Coming next',
          body:
              'This module is reserved in navigation so the app shape matches the FiScore v1 spec while we build each workflow in sequence.',
        ),
      ],
    );
  }
}

