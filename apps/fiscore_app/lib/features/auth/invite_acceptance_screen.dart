part of '../../main.dart';

class _InviteAcceptanceContent extends StatefulWidget {
  const _InviteAcceptanceContent({
    required this.displayName,
    required this.onCreateWorkspace,
    this.reactivationTenantId,
  });

  final String displayName;
  final WidgetBuilder onCreateWorkspace;
  final String? reactivationTenantId;

  @override
  State<_InviteAcceptanceContent> createState() =>
      _InviteAcceptanceContentState();
}

class _InviteAcceptanceContentState extends State<_InviteAcceptanceContent> {
  final TeamRepository _teamRepository = TeamRepository();
  late Future<List<Map<String, dynamic>>> _pendingInvites;
  String? _acceptingInviteId;
  String? _message;
  String? _error;
  bool _showCreateWorkspace = false;

  @override
  void initState() {
    super.initState();
    _pendingInvites = _teamRepository.listMyPendingInvites();
  }

  Future<void> _acceptInvite(Map<String, dynamic> invite) async {
    final tenantId = invite['tenantId'] as String?;
    final inviteId = invite['inviteId'] as String?;
    if (tenantId == null || inviteId == null) {
      setState(() {
        _error = 'This invite is missing required details.';
      });
      return;
    }

    setState(() {
      _acceptingInviteId = inviteId;
      _message = null;
      _error = null;
    });

    try {
      await _teamRepository.acceptInvite(
        tenantId: tenantId,
        inviteId: inviteId,
      );
      if (!mounted) return;
      setState(() {
        _message = widget.reactivationTenantId == null
            ? 'Invite accepted. Opening workspace...'
            : 'Access restored. Opening workspace...';
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not accept the invite. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _acceptingInviteId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_showCreateWorkspace) {
      return widget.onCreateWorkspace(context);
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pendingInvites,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final allInvites = snapshot.data ?? [];
        final invites = widget.reactivationTenantId == null
            ? allInvites
            : allInvites
                  .where(
                    (invite) =>
                        invite['tenantId'] == widget.reactivationTenantId,
                  )
                  .toList();
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not check invitations',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We could not load your pending team invites. Please try again.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _StatusMessage(
                icon: Icons.error_outline,
                color: const Color(0xFFB42318),
                text: snapshot.error is AppException
                    ? (snapshot.error! as AppException).message
                    : 'Invitation lookup failed.',
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _pendingInvites = _teamRepository.listMyPendingInvites();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          );
        }
        if (invites.isEmpty) {
          if (widget.reactivationTenantId != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team access inactive',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account is not active in this workspace. Ask your manager to send a new invitation if you need access again.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _muted,
                    height: 1.45,
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.displayName}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No team invites were found for this email. Create a new FiScore workspace to get started.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _showCreateWorkspace = true;
                  });
                },
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Create workspace'),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reactivationTenantId == null
                  ? 'Join your team'
                  : 'Return to your team',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.reactivationTenantId == null
                  ? 'Choose the FiScore workspace you were invited to join.'
                  : 'You have been invited back. Accept the invitation to restore your access with the updated permissions.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _muted,
                height: 1.45,
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              _StatusMessage(
                icon: Icons.check_circle_outline,
                color: _green,
                text: _message!,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 14),
              _StatusMessage(
                icon: Icons.error_outline,
                color: const Color(0xFFB42318),
                text: _error!,
              ),
            ],
            const SizedBox(height: 18),
            ...invites.map((invite) {
              final inviteId = invite['inviteId'] as String? ?? '';
              final tenantName =
                  invite['tenantName'] as String? ?? 'FiScore workspace';
              final role = _roleLabel(invite['role'] as String? ?? 'staff');
              final accessMode = invite['siteAccessMode'] as String? ?? 'all';
              final siteCount =
                  (invite['siteIds'] as List<dynamic>? ?? []).length;
              final isAccepting = _acceptingInviteId == inviteId;
              final accessText = accessMode == 'selected'
                  ? '$siteCount selected ${siteCount == 1 ? 'site' : 'sites'}'
                  : 'All sites';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$role / $accessText',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isAccepting
                            ? null
                            : () => _acceptInvite(invite),
                        icon: isAccepting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          isAccepting
                              ? 'Restoring access...'
                              : widget.reactivationTenantId == null
                              ? 'Join team'
                              : 'Restore access',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
