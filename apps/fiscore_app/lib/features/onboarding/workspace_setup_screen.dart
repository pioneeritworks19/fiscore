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
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.setUpWorkspace,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          strings.signedInWorkspaceHelp(displayName),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: _muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        _GuidancePanel(
          icon: Icons.info_outline,
          text: strings.workspaceOwnerGuidance,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: tenantNameController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: strings.workspaceName,
            helperText: strings.workspaceNameHelp,
            hintText: strings.workspaceNameHint,
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
          label: Text(strings.createWorkspace),
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
