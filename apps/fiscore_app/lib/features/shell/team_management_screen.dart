part of '../../main.dart';

class _TeamManagementContent extends StatefulWidget {
  const _TeamManagementContent({
    required this.tenantId,
    required this.sites,
    required this.currentMember,
    required this.onBack,
  });

  final String tenantId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> sites;
  final Map<String, dynamic> currentMember;
  final VoidCallback onBack;

  @override
  State<_TeamManagementContent> createState() => _TeamManagementContentState();
}

class _TeamManagementContentState extends State<_TeamManagementContent> {
  final TeamRepository _teamRepository = TeamRepository();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'staff';
  String _siteAccessMode = 'all';
  final Set<String> _selectedSiteIds = {};
  bool _isInviting = false;
  bool _isManaging = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canManageTeam {
    final role = widget.currentMember['role'] as String?;
    return role == 'tenant_owner' || role == 'admin';
  }

  bool get _isTenantOwner => widget.currentMember['role'] == 'tenant_owner';

  List<String> get _assignableRoles => _isTenantOwner
      ? const ['admin', 'manager', 'auditor', 'staff']
      : const ['manager', 'auditor', 'staff'];

  Future<void> _sendInvite() async {
    final strings = AppLocalizations.of(context);
    final email = _emailController.text.trim().toLowerCase();
    final siteIds = _siteAccessMode == 'selected'
        ? _selectedSiteIds.toList()
        : <String>[];
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = strings.enterValidStaffEmail;
        _message = null;
      });
      return;
    }
    if (_siteAccessMode == 'selected' && siteIds.isEmpty) {
      setState(() {
        _error = strings.chooseAtLeastOneSiteForInvite;
        _message = null;
      });
      return;
    }

    setState(() {
      _isInviting = true;
      _message = null;
      _error = null;
    });

    try {
      await _teamRepository.createInvite(
        tenantId: widget.tenantId,
        email: email,
        role: _selectedRole,
        siteAccessMode: _siteAccessMode,
        siteIds: siteIds,
      );
      await _authService.sendEmailSignInLink(email);
      if (!mounted) return;
      setState(() {
        _message = strings.inviteSentTo(email);
        _emailController.clear();
        _selectedRole = 'staff';
        _siteAccessMode = 'all';
        _selectedSiteIds.clear();
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        final detail = error.message ?? '';
        _error = [
          strings.inviteSavedEmailFailed,
          detail,
        ].where((part) => part.trim().isNotEmpty).join(' ');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = strings.couldNotCreateInvite;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }

  Future<void> _resendInviteLink(String email) async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _message = null;
      _error = null;
    });
    try {
      await _authService.sendEmailSignInLink(email);
      if (!mounted) return;
      setState(() {
        _message = strings.signInLinkResentTo(email);
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? strings.couldNotResendSignInLink;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = strings.couldNotResendSignInLink;
      });
    }
  }

  Future<void> _cancelInvite(String inviteId, String email) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await _confirmTeamAction(
      context,
      title: strings.cancelInvitationQuestion,
      body: strings.cancelInvitationBody(email),
      actionLabel: strings.cancelInvite,
      dismissLabel: strings.keepInvitation,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isManaging = true;
      _message = null;
      _error = null;
    });
    try {
      await _teamRepository.cancelInvite(
        tenantId: widget.tenantId,
        inviteId: inviteId,
      );
      if (!mounted) return;
      setState(() {
        _message = strings.invitationCanceledFor(email);
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isManaging = false;
        });
      }
    }
  }

  Future<void> _deactivateMember(String userId, String name) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await _confirmTeamAction(
      context,
      title: strings.deactivateMemberQuestion(name),
      body: strings.deactivateMemberBody,
      actionLabel: strings.deactivate,
      dismissLabel: strings.keepAccess,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isManaging = true;
      _message = null;
      _error = null;
    });
    try {
      await _teamRepository.deactivateMember(
        tenantId: widget.tenantId,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _message = strings.memberDeactivated(name);
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isManaging = false;
        });
      }
    }
  }

  Future<void> _editMemberAccess(
    String userId,
    Map<String, dynamic> member,
  ) async {
    final strings = AppLocalizations.of(context);
    final update = await _showTeamAccessEditor(
      context,
      title: strings.editMember(_displayTeamName(member)),
      subtitle: member['emailSnapshot'] as String? ?? '',
      data: member,
      sites: widget.sites,
      assignableRoles: _assignableRoles,
    );
    if (update == null || !mounted) return;
    setState(() {
      _isManaging = true;
      _message = null;
      _error = null;
    });
    try {
      await _teamRepository.updateMemberAccess(
        tenantId: widget.tenantId,
        userId: userId,
        role: update.role,
        siteAccessMode: update.siteAccessMode,
        siteIds: update.siteIds,
      );
      if (!mounted) return;
      setState(() {
        _message = strings.accessUpdatedFor(_displayTeamName(member));
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isManaging = false;
        });
      }
    }
  }

  Future<void> _editInviteAccess(
    String inviteId,
    Map<String, dynamic> invite,
  ) async {
    final strings = AppLocalizations.of(context);
    final email = invite['email'] as String? ?? strings.teamMember;
    final update = await _showTeamAccessEditor(
      context,
      title: strings.editInvitation,
      subtitle: email,
      data: invite,
      sites: widget.sites,
      assignableRoles: _assignableRoles,
    );
    if (update == null || !mounted) return;
    setState(() {
      _isManaging = true;
      _message = null;
      _error = null;
    });
    try {
      await _teamRepository.updateInviteAccess(
        tenantId: widget.tenantId,
        inviteId: inviteId,
        role: update.role,
        siteAccessMode: update.siteAccessMode,
        siteIds: update.siteIds,
      );
      if (!mounted) return;
      setState(() {
        _message = strings.invitationUpdatedFor(email);
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isManaging = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.chevron_left),
          label: Text(strings.backToMore),
        ),
        const SizedBox(height: 8),
        Text(
          strings.team,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.teamIntro,
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
        if (_canManageTeam) _inviteTeamCard(),
        const SizedBox(height: 16),
        _TeamListCard(
          tenantId: widget.tenantId,
          teamRepository: _teamRepository,
          currentUserId: widget.currentMember['userId'] as String?,
          currentRole: widget.currentMember['role'] as String? ?? 'staff',
          canManage: _canManageTeam && !_isManaging,
          onResendInvite: _canManageTeam && !_isManaging
              ? _resendInviteLink
              : null,
          onCancelInvite: _canManageTeam && !_isManaging ? _cancelInvite : null,
          onEditInvite: _canManageTeam && !_isManaging
              ? _editInviteAccess
              : null,
          onEditMember: _canManageTeam && !_isManaging
              ? _editMemberAccess
              : null,
          onDeactivateMember: _canManageTeam && !_isManaging
              ? _deactivateMember
              : null,
        ),
        if (_canManageTeam) ...[
          const SizedBox(height: 16),
          _TeamActivityCard(
            tenantId: widget.tenantId,
            teamRepository: _teamRepository,
          ),
        ],
      ],
    );
  }

  Widget _inviteTeamCard() {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);
    return Container(
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
            strings.inviteTeammate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: strings.email,
              hintText: strings.emailAddressHint,
            ),
          ),
          _reactivationNotice(),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedRole),
            initialValue: _selectedRole,
            decoration: InputDecoration(labelText: strings.role),
            items: _assignableRoles
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(_roleLabel(role)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedRole = value;
                if (value == 'admin') {
                  _siteAccessMode = 'all';
                  _selectedSiteIds.clear();
                }
              });
            },
          ),
          const SizedBox(height: 12),
          _RoleGuidanceCard(role: _selectedRole),
          const SizedBox(height: 12),
          if (_selectedRole != 'admin')
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'all', label: Text(strings.allSites)),
                ButtonSegment(value: 'selected', label: Text(strings.selected)),
              ],
              selected: {_siteAccessMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _siteAccessMode = selection.first;
                });
              },
            ),
          if (_selectedRole != 'admin' && _siteAccessMode == 'selected') ...[
            const SizedBox(height: 10),
            ...widget.sites.map((siteDoc) {
              final site = siteDoc.data();
              final name = site['name'] as String? ?? 'Restaurant';
              return CheckboxListTile(
                value: _selectedSiteIds.contains(siteDoc.id),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(name),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedSiteIds.add(siteDoc.id);
                    } else {
                      _selectedSiteIds.remove(siteDoc.id);
                    }
                  });
                },
              );
            }),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isInviting ? null : _sendInvite,
              icon: _isInviting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(
                _isInviting ? strings.creatingInvite : strings.sendInvite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactivationNotice() {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _teamRepository.membersStream(widget.tenantId),
      builder: (context, snapshot) {
        final hasInactiveMatch = (snapshot.data?.docs ?? []).any((doc) {
          final member = doc.data();
          return member['status'] == 'inactive' &&
              _normalizedTeamEmail(member['emailSnapshot']) == email;
        });
        if (!hasInactiveMatch) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _softGreen,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _green.withValues(alpha: 0.18)),
          ),
          child: Text(
            'This teammate previously had access. Accepting this invitation will reactivate them with the selected role and site access.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _muted, height: 1.4),
          ),
        );
      },
    );
  }
}

class _TeamListCard extends StatelessWidget {
  const _TeamListCard({
    required this.tenantId,
    required this.teamRepository,
    required this.currentUserId,
    required this.currentRole,
    required this.canManage,
    required this.onResendInvite,
    required this.onCancelInvite,
    required this.onEditInvite,
    required this.onEditMember,
    required this.onDeactivateMember,
  });

  final String tenantId;
  final TeamRepository teamRepository;
  final String? currentUserId;
  final String currentRole;
  final bool canManage;
  final ValueChanged<String>? onResendInvite;
  final void Function(String inviteId, String email)? onCancelInvite;
  final void Function(String inviteId, Map<String, dynamic> invite)?
  onEditInvite;
  final void Function(String userId, Map<String, dynamic> member)? onEditMember;
  final void Function(String userId, String name)? onDeactivateMember;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
            'Members',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: teamRepository.membersStream(tenantId),
            builder: (context, snapshot) {
              final members = snapshot.data?.docs ?? [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final activeMembers = members
                  .where((doc) => doc.data()['status'] == 'active')
                  .toList();
              final inactiveMembers = members
                  .where((doc) => doc.data()['status'] == 'inactive')
                  .toList();
              final inactiveByEmail = {
                for (final doc in inactiveMembers)
                  _normalizedTeamEmail(doc.data()['emailSnapshot']): doc,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeMembers.isEmpty)
                    Text(
                      'No active members.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _muted,
                      ),
                    )
                  else
                    ...activeMembers.map(
                      (doc) => _TeamPersonRow(
                        data: doc.data(),
                        onEdit:
                            _canManagePerson(data: doc.data(), docId: doc.id) &&
                                onEditMember != null
                            ? () => onEditMember!(doc.id, doc.data())
                            : null,
                        onDeactivate:
                            _canManagePerson(data: doc.data(), docId: doc.id) &&
                                onDeactivateMember != null
                            ? () => onDeactivateMember!(
                                doc.id,
                                _displayTeamName(doc.data()),
                              )
                            : null,
                      ),
                    ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: teamRepository.invitesStream(tenantId),
                    builder: (context, inviteSnapshot) {
                      final pendingInvites = (inviteSnapshot.data?.docs ?? [])
                          .where(
                            (doc) =>
                                (doc.data()['status'] as String? ?? '') ==
                                'pending',
                          )
                          .toList();
                      final reInvitedEmails = pendingInvites
                          .map(
                            (doc) => _normalizedTeamEmail(doc.data()['email']),
                          )
                          .where(inactiveByEmail.containsKey)
                          .toSet();
                      final visibleInactiveMembers = inactiveMembers
                          .where(
                            (doc) => !reInvitedEmails.contains(
                              _normalizedTeamEmail(doc.data()['emailSnapshot']),
                            ),
                          )
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pendingInvites.isNotEmpty) ...[
                            const Divider(height: 22),
                            Text(
                              'Invited',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...pendingInvites.map((doc) {
                              final invite = doc.data();
                              final email = _normalizedTeamEmail(
                                invite['email'],
                              );
                              final inactiveMember = inactiveByEmail[email];
                              final canManageInvite = _canManagePerson(
                                data: invite,
                              );
                              return _TeamPersonRow(
                                data: {
                                  if (inactiveMember != null)
                                    'displayNameSnapshot': inactiveMember
                                        .data()['displayNameSnapshot'],
                                  ...invite,
                                },
                                invited: true,
                                reInvited: inactiveMember != null,
                                onEdit: canManageInvite && onEditInvite != null
                                    ? () => onEditInvite!(doc.id, invite)
                                    : null,
                                onResendInvite: canManageInvite
                                    ? onResendInvite
                                    : null,
                                onCancelInvite:
                                    !canManageInvite || onCancelInvite == null
                                    ? null
                                    : () => onCancelInvite!(
                                        doc.id,
                                        invite['email'] as String? ??
                                            'this teammate',
                                      ),
                              );
                            }),
                          ],
                          if (visibleInactiveMembers.isNotEmpty) ...[
                            const Divider(height: 22),
                            Text(
                              'Inactive',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...visibleInactiveMembers.map(
                              (doc) => _TeamPersonRow(data: doc.data()),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool _canManagePerson({required Map<String, dynamic> data, String? docId}) {
    if (!canManage || docId == currentUserId) {
      return false;
    }
    final role = data['role'] as String? ?? 'staff';
    if (role == 'tenant_owner') {
      return false;
    }
    return role != 'admin' || currentRole == 'tenant_owner';
  }
}

class _TeamActivityCard extends StatefulWidget {
  const _TeamActivityCard({
    required this.tenantId,
    required this.teamRepository,
  });

  final String tenantId;
  final TeamRepository teamRepository;

  @override
  State<_TeamActivityCard> createState() => _TeamActivityCardState();
}

class _TeamActivityCardState extends State<_TeamActivityCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.teamRepository.activityStream(widget.tenantId),
        builder: (context, snapshot) {
          final activity = snapshot.data?.docs ?? [];
          final visible = _expanded ? activity : activity.take(5).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recent invitation and access changes.',
                style: theme.textTheme.bodySmall?.copyWith(color: _muted),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (activity.isEmpty)
                Text(
                  'New team changes will appear here.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
                )
              else
                ...visible.map((doc) => _TeamActivityRow(data: doc.data())),
              if (activity.length > 5) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _expanded = !_expanded;
                  }),
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_outlined
                        : Icons.expand_more_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _expanded
                        ? 'Show fewer'
                        : 'View all ${activity.length} changes',
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TeamActivityRow extends StatelessWidget {
  const _TeamActivityRow({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = _teamActivityDetail(data);
    final actor =
        data['actorDisplayName'] as String? ??
        data['actorEmail'] as String? ??
        'FiScore';
    final time = _teamActivityTimeText(data['createdAt']);
    final metadata = time.isEmpty ? actor : '$actor | $time';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.history_outlined, size: 18, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _teamActivityTitle(data),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  metadata,
                  style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPersonRow extends StatelessWidget {
  const _TeamPersonRow({
    required this.data,
    this.invited = false,
    this.reInvited = false,
    this.onEdit,
    this.onResendInvite,
    this.onCancelInvite,
    this.onDeactivate,
  });

  final Map<String, dynamic> data;
  final bool invited;
  final bool reInvited;
  final VoidCallback? onEdit;
  final ValueChanged<String>? onResendInvite;
  final VoidCallback? onCancelInvite;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = data['displayNameSnapshot'] as String?;
    final email =
        (data['emailSnapshot'] as String?) ?? (data['email'] as String?);
    final role = _roleLabel(data['role'] as String? ?? 'staff');
    final status = invited
        ? reInvited
              ? 'Re-invited'
              : 'Invited'
        : _statusLabel(data['status'] as String?);
    final title = (name == null || name.isEmpty)
        ? email ?? 'Team member'
        : name;
    final accessMode = data['siteAccessMode'] as String? ?? 'all';
    final siteCount = (data['siteIds'] as List<dynamic>? ?? []).length;
    final accessText = accessMode == 'selected'
        ? '$siteCount ${siteCount == 1 ? 'site' : 'sites'}'
        : 'All sites';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: invited ? const Color(0xFFFFF4E5) : _softGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              invited ? Icons.mail_outline : Icons.person_outline,
              color: invited ? const Color(0xFFB65C00) : _green,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email != null && email != title) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '$role / $accessText / $status',
                  style: theme.textTheme.bodySmall?.copyWith(color: _muted),
                ),
              ],
            ),
          ),
          if (onEdit != null ||
              onDeactivate != null ||
              (invited && (onResendInvite != null || onCancelInvite != null)))
            PopupMenuButton<String>(
              tooltip: 'Manage teammate',
              icon: const Icon(Icons.more_horiz, color: _muted),
              onSelected: (selection) {
                switch (selection) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'resend':
                    if (email != null) onResendInvite?.call(email);
                    break;
                  case 'cancel':
                    onCancelInvite?.call();
                    break;
                  case 'deactivate':
                    onDeactivate?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      invited ? 'Edit invitation' : 'Edit role and access',
                    ),
                  ),
                if (invited && email != null && onResendInvite != null)
                  PopupMenuItem(
                    value: 'resend',
                    child: Text(AppLocalizations.of(context).resendInviteLink),
                  ),
                if (invited && onCancelInvite != null)
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(AppLocalizations.of(context).cancelInvite),
                  ),
                if (!invited && onDeactivate != null)
                  PopupMenuItem(
                    value: 'deactivate',
                    child: Text(AppLocalizations.of(context).deactivateAccess),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

String _displayTeamName(Map<String, dynamic> data) {
  final name = data['displayNameSnapshot'] as String?;
  final email = data['emailSnapshot'] as String?;
  return name == null || name.isEmpty ? email ?? 'This teammate' : name;
}

String _normalizedTeamEmail(Object? value) {
  return value is String ? value.trim().toLowerCase() : '';
}

String _teamActivityTitle(Map<String, dynamic> data) {
  final target =
      data['targetDisplayName'] as String? ??
      data['targetEmail'] as String? ??
      'Teammate';
  switch (data['action']) {
    case 'invite_created':
      return 'Invited $target';
    case 'invite_canceled':
      return 'Canceled invitation for $target';
    case 'invite_access_updated':
      return 'Updated invitation for $target';
    case 'invite_accepted':
      return '$target joined the team';
    case 'member_reactivated':
      return 'Restored access for $target';
    case 'member_access_updated':
      return 'Updated access for $target';
    case 'member_deactivated':
      return 'Deactivated $target';
    default:
      return 'Team access updated';
  }
}

String? _teamActivityDetail(Map<String, dynamic> data) {
  final after = data['after'];
  if (after is Map<String, dynamic>) {
    return _teamAccessSummary(after);
  }
  if (after is Map) {
    return _teamAccessSummary(Map<String, dynamic>.from(after));
  }
  final before = data['before'];
  if (data['action'] == 'member_deactivated' &&
      (before is Map<String, dynamic> || before is Map)) {
    final mapped = before is Map<String, dynamic>
        ? before
        : Map<String, dynamic>.from(before as Map);
    return _teamAccessSummary(mapped);
  }
  return null;
}

String _teamAccessSummary(Map<String, dynamic> data) {
  final role = _roleLabel(data['role'] as String? ?? 'staff');
  final siteAccessMode = data['siteAccessMode'] as String? ?? 'all';
  final siteCount = (data['siteIds'] as List<dynamic>? ?? []).length;
  if (siteAccessMode != 'selected') {
    return '$role / All sites';
  }
  return '$role / $siteCount ${siteCount == 1 ? 'site' : 'sites'}';
}

String _teamActivityTimeText(Object? value) {
  if (value is! Timestamp) {
    return '';
  }
  final date = value.toDate();
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} d ago';
  }
  return '${date.month}/${date.day}/${date.year}';
}

class _TeamAccessUpdate {
  const _TeamAccessUpdate({
    required this.role,
    required this.siteAccessMode,
    required this.siteIds,
  });

  final String role;
  final String siteAccessMode;
  final List<String> siteIds;
}

Future<_TeamAccessUpdate?> _showTeamAccessEditor(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Map<String, dynamic> data,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> sites,
  required List<String> assignableRoles,
}) {
  var role = data['role'] as String? ?? 'staff';
  if (!assignableRoles.contains(role)) {
    return Future.value(null);
  }
  var siteAccessMode = data['siteAccessMode'] as String? ?? 'all';
  final selectedSiteIds = (data['siteIds'] as List<dynamic>? ?? [])
      .whereType<String>()
      .toSet();
  String? error;

  return showModalBottomSheet<_TeamAccessUpdate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _muted),
                ),
              ],
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: assignableRoles
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_roleLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setSheetState(() {
                    role = value;
                    error = null;
                    if (role == 'admin') {
                      siteAccessMode = 'all';
                      selectedSiteIds.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              if (role == 'admin')
                Text(
                  'Admins have access to all sites.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _muted),
                )
              else ...[
                Text(
                  'Site access',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'all',
                      label: Text(AppLocalizations.of(context).allSites),
                    ),
                    ButtonSegment(
                      value: 'selected',
                      label: Text(AppLocalizations.of(context).selected),
                    ),
                  ],
                  selected: {siteAccessMode},
                  onSelectionChanged: (selection) {
                    setSheetState(() {
                      siteAccessMode = selection.first;
                      error = null;
                    });
                  },
                ),
                if (siteAccessMode == 'selected') ...[
                  const SizedBox(height: 8),
                  ...sites.map((siteDoc) {
                    final siteName =
                        siteDoc.data()['name'] as String? ?? 'Restaurant';
                    return CheckboxListTile(
                      value: selectedSiteIds.contains(siteDoc.id),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(siteName),
                      onChanged: (value) {
                        setSheetState(() {
                          error = null;
                          if (value ?? false) {
                            selectedSiteIds.add(siteDoc.id);
                          } else {
                            selectedSiteIds.remove(siteDoc.id);
                          }
                        });
                      },
                    );
                  }),
                ],
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFB42318),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (role != 'admin' &&
                        siteAccessMode == 'selected' &&
                        selectedSiteIds.isEmpty) {
                      setSheetState(() {
                        error = 'Choose at least one site.';
                      });
                      return;
                    }
                    Navigator.pop(
                      context,
                      _TeamAccessUpdate(
                        role: role,
                        siteAccessMode: role == 'admin'
                            ? 'all'
                            : siteAccessMode,
                        siteIds: role == 'admin' || siteAccessMode == 'all'
                            ? <String>[]
                            : selectedSiteIds.toList(),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context).saveChanges),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool> _confirmTeamAction(
  BuildContext context, {
  required String title,
  required String body,
  required String actionLabel,
  required String dismissLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(actionLabel),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(dismissLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

String _roleLabel(String role) {
  switch (role) {
    case 'tenant_owner':
      return 'Tenant owner';
    case 'admin':
      return 'Admin';
    case 'manager':
      return 'Manager';
    case 'auditor':
      return 'Auditor';
    case 'staff':
      return 'Staff';
    default:
      return role;
  }
}

class _RoleGuidanceCard extends StatelessWidget {
  const _RoleGuidanceCard({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final description = switch (role) {
      'admin' =>
        'Manages team access, sites, assignments, reviews, and operational setup. Admins have access to all sites.',
      'manager' =>
        'Assigns and reviews fixes, checks, and training for permitted sites.',
      'auditor' =>
        'Can independently run internal checks and record findings at permitted sites.',
      'staff' =>
        'Completes assigned fixes, checks, and training at permitted sites.',
      _ => 'Controls this teammate\'s access to FiScore work.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: _muted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'active':
      return 'Active';
    case 'inactive':
      return 'Inactive';
    case 'suspended':
      return 'Suspended';
    default:
      return status ?? 'Unknown';
  }
}
