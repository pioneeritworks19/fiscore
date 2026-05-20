part of '../../main.dart';

class _WorkspaceSetupContent extends StatelessWidget {
  const _WorkspaceSetupContent({
    required this.displayName,
    required this.tenantNameController,
    required this.isCreatingTenant,
    required this.tenantMessage,
    required this.tenantError,
    required this.onCreateTenant,
  });

  final String displayName;
  final TextEditingController tenantNameController;
  final bool isCreatingTenant;
  final String? tenantMessage;
  final String? tenantError;
  final VoidCallback onCreateTenant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set up your FiScore workspace',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Signed in as $displayName. Create one workspace for the business or restaurant group that owns the locations you will manage.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        _GuidancePanel(
          icon: Icons.info_outline,
          text:
              'Only an owner or administrator should create a workspace. Restaurant staff should join later through an invitation from the workspace owner.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: tenantNameController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Workspace name',
            helperText: 'Use the business, franchise, or restaurant group name.',
            hintText: 'Example: Kannappan Hospitality',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onCreateTenant(),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: isCreatingTenant ? null : onCreateTenant,
          icon: isCreatingTenant
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_outlined),
          label: const Text('Create workspace'),
        ),
        if (tenantMessage != null) ...[
          const SizedBox(height: 18),
          _StatusMessage(
            icon: Icons.check_circle_outline,
            color: colorScheme.primary,
            text: tenantMessage!,
          ),
        ],
        if (tenantError != null) ...[
          const SizedBox(height: 18),
          _StatusMessage(
            icon: Icons.error_outline,
            color: colorScheme.error,
            text: tenantError!,
          ),
        ],
      ],
    );
  }
}

