part of '../../main.dart';

class SignedInHomeScreen extends StatefulWidget {
  const SignedInHomeScreen({super.key, required this.user});

  final User user;

  @override
  State<SignedInHomeScreen> createState() => _SignedInHomeScreenState();
}

class _SignedInHomeScreenState extends State<SignedInHomeScreen> {
  final AuthService _authService = AuthService();
  final TenantRepository _tenantRepository = TenantRepository();
  final TeamRepository _teamRepository = TeamRepository();
  final SiteRepository _siteRepository = SiteRepository();
  final MasterRestaurantRepository _masterRestaurantRepository =
      MasterRestaurantRepository();
  final TextEditingController _tenantNameController = TextEditingController();
  final TextEditingController _restaurantSearchController =
      TextEditingController();
  bool _isCreatingTenant = false;
  bool _isSearchingRestaurants = false;
  bool _isLinkingRestaurant = false;
  bool _isAddingSite = false;
  bool _isManagingTeam = false;
  bool _isShowingActionInbox = false;
  bool _isSyncingMasterData = false;
  String _actionInboxInitialFilter = 'all';
  int _selectedTabIndex = 1;
  String _violationInitialFilter = 'active';
  String? _violationInitialId;
  String? _violationDetailBackLabel;
  String? _violationReturnActionFilter;
  String _trainingInitialView = 'home';
  String? _trainingInitialAssignmentId;
  String? _auditInitialAssignmentId;
  String? _auditReturnActionFilter;
  bool _hasAppliedInitialLanding = false;
  String? _activeSiteId;
  String? _linkingRestaurantId;
  List<Map<String, dynamic>> _restaurantResults = [];
  String? _tenantMessage;
  String? _tenantError;
  String? _restaurantMessage;
  String? _restaurantError;
  String? _moreMessage;
  String? _moreError;

  @override
  void dispose() {
    _tenantNameController.dispose();
    _restaurantSearchController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  Future<void> _createTenant() async {
    final tenantName = _tenantNameController.text.trim();
    if (tenantName.isEmpty) {
      setState(() {
        _tenantError = 'Enter the restaurant group or business name.';
        _tenantMessage = null;
      });
      return;
    }

    setState(() {
      _isCreatingTenant = true;
      _tenantError = null;
      _tenantMessage = null;
    });

    try {
      await _tenantRepository.createTenantAndOwner(
        tenantName: tenantName,
        displayName: widget.user.displayName,
      );
      setState(() {
        _tenantMessage = 'Workspace created. Next, add the first location.';
        _restaurantError = null;
        _restaurantMessage = null;
      });
    } on AppException catch (error) {
      setState(() {
        _tenantError = error.message;
      });
    } catch (_) {
      setState(() {
        _tenantError = 'Tenant setup failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTenant = false;
        });
      }
    }
  }

  Future<void> _searchRestaurants(String tenantId) async {
    final query = _restaurantSearchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _restaurantError =
            'Enter a restaurant name, city, ZIP code, or license number.';
        _restaurantMessage = null;
        _restaurantResults = [];
      });
      return;
    }

    setState(() {
      _isSearchingRestaurants = true;
      _restaurantError = null;
      _restaurantMessage = null;
    });

    try {
      final restaurants = await _masterRestaurantRepository.searchRestaurants(
        tenantId: tenantId,
        query: query,
      );
      setState(() {
        _restaurantResults = restaurants;
        _restaurantMessage = _restaurantResults.isEmpty
            ? 'No matching restaurants found. Try a different name, city, ZIP, or license number.'
            : null;
      });
    } on AppException catch (error) {
      setState(() {
        _restaurantError = error.message;
      });
    } catch (_) {
      setState(() {
        _restaurantError = 'Restaurant search failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingRestaurants = false;
        });
      }
    }
  }

  Future<void> _linkRestaurant(
    String tenantId,
    String masterRestaurantId,
    String restaurantName,
  ) async {
    setState(() {
      _isLinkingRestaurant = true;
      _linkingRestaurantId = masterRestaurantId;
      _restaurantError = null;
      _restaurantMessage = 'Linking $restaurantName to this workspace...';
    });

    try {
      final siteId = await _masterRestaurantRepository.linkRestaurantSite(
        tenantId: tenantId,
        masterRestaurantId: masterRestaurantId,
      );
      setState(() {
        _restaurantMessage =
            '$restaurantName is linked to this workspace. Site ID: $siteId';
        _restaurantResults = [];
        _isAddingSite = false;
        if (siteId is String) {
          _activeSiteId = siteId;
        }
        _selectedTabIndex = 1;
      });
    } on AppException catch (error) {
      setState(() {
        _restaurantError = error.message;
      });
    } catch (_) {
      setState(() {
        _restaurantError = 'Restaurant linking failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLinkingRestaurant = false;
          _linkingRestaurantId = null;
        });
      }
    }
  }

  Future<void> _refreshMasterData(String tenantId, String siteId) async {
    setState(() {
      _isSyncingMasterData = true;
      _moreMessage = null;
      _moreError = null;
    });
    try {
      final result = await _masterRestaurantRepository.syncLinkedSiteMasterData(
        tenantId: tenantId,
        siteId: siteId,
      );
      if (!mounted) return;
      setState(() {
        _moreMessage =
            'Master data refreshed. ${result.importedInspectionCount} inspections and ${result.importedFindingCount} findings available.';
      });
    } on AppException catch (error) {
      if (mounted) setState(() => _moreError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _moreError = 'Could not refresh master data. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSyncingMasterData = false);
    }
  }

  Widget _buildMainApp(
    String tenantId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sites,
    Map<String, dynamic> currentMember,
  ) {
    if (sites.length == 1 && _selectedTabIndex == 0) {
      _selectedTabIndex = 1;
    }

    if (!_hasAppliedInitialLanding && sites.length > 1) {
      _selectedTabIndex = 0;
      _hasAppliedInitialLanding = true;
    } else if (!_hasAppliedInitialLanding && sites.length == 1) {
      _selectedTabIndex = 1;
      _hasAppliedInitialLanding = true;
    }

    final effectiveTabIndex = _selectedTabIndex;
    QueryDocumentSnapshot<Map<String, dynamic>>? activeSiteDoc;
    if (sites.isNotEmpty) {
      activeSiteDoc = sites.first;
      for (final site in sites) {
        if (site.id == _activeSiteId) {
          activeSiteDoc = site;
          break;
        }
      }
    }

    Widget content;
    switch (effectiveTabIndex) {
      case 0:
        content = _SitesOverviewContent(
          sites: sites,
          onOpenSite: (siteId) {
            setState(() {
              _activeSiteId = siteId;
              _selectedTabIndex = 1;
            });
          },
          onAddSite: () {
            setState(() {
              _isAddingSite = true;
              _restaurantError = null;
              _restaurantMessage = null;
              _restaurantResults = [];
            });
          },
        );
        break;
      case 1:
        if (activeSiteDoc == null) {
          content = _SiteSetupContent(
            tenantId: tenantId,
            searchController: _restaurantSearchController,
            isSearching: _isSearchingRestaurants,
            isLinking: _isLinkingRestaurant,
            linkingRestaurantId: _linkingRestaurantId,
            results: _restaurantResults,
            message: _restaurantMessage,
            error: _restaurantError,
            onSearch: () => _searchRestaurants(tenantId),
            onCancel: sites.isEmpty
                ? null
                : () {
                    setState(() {
                      _isAddingSite = false;
                      _restaurantError = null;
                      _restaurantMessage = null;
                      _restaurantResults = [];
                    });
                  },
            onLinkRestaurant: (masterRestaurantId, restaurantName) =>
                _linkRestaurant(tenantId, masterRestaurantId, restaurantName),
          );
        } else {
          final activeSiteId = activeSiteDoc.id;
          content = _isShowingActionInbox
              ? _ActionInboxContent(
                  tenantId: tenantId,
                  siteId: activeSiteId,
                  currentUserId: widget.user.uid,
                  currentRole: currentMember['role'] as String? ?? 'staff',
                  initialFilter: _actionInboxInitialFilter,
                  onBack: () {
                    setState(() {
                      _isShowingActionInbox = false;
                    });
                  },
                  onOpenViolation: (siteId, violationId, statusFilter) {
                    setState(() {
                      _activeSiteId = siteId;
                      _isShowingActionInbox = false;
                      _violationInitialFilter = statusFilter;
                      _violationInitialId = violationId;
                      _violationReturnActionFilter = _actionInboxInitialFilter;
                      _violationDetailBackLabel =
                          _actionInboxInitialFilter == 'review'
                          ? 'Back to review queue'
                          : 'Back to my fixes';
                      _selectedTabIndex = 2;
                    });
                  },
                  onOpenTraining: (siteId, assignmentId) {
                    setState(() {
                      _activeSiteId = siteId;
                      _isShowingActionInbox = false;
                      _trainingInitialView = 'home';
                      _trainingInitialAssignmentId = assignmentId;
                      _selectedTabIndex = 4;
                    });
                  },
                  onOpenAudit: (siteId, assignmentId) {
                    setState(() {
                      _activeSiteId = siteId;
                      _isShowingActionInbox = false;
                      _auditInitialAssignmentId = assignmentId;
                      _auditReturnActionFilter = _actionInboxInitialFilter;
                      _selectedTabIndex = 3;
                    });
                  },
                )
              : _SiteDashboardContent(
                  tenantId: tenantId,
                  siteId: activeSiteId,
                  site: activeSiteDoc.data(),
                  currentUserId: widget.user.uid,
                  canManageTraining: _canAssignTraining(
                    currentMember['role'] as String?,
                  ),
                  onOpenUnassignedViolations: () {
                    setState(() {
                      _violationInitialFilter = 'unassigned';
                      _violationInitialId = null;
                      _violationReturnActionFilter = null;
                      _violationDetailBackLabel = null;
                      _selectedTabIndex = 2;
                    });
                  },
                  onOpenActions: (filter) {
                    setState(() {
                      _actionInboxInitialFilter = filter;
                      _isShowingActionInbox = true;
                    });
                  },
                  onOpenAudits: () {
                    setState(() {
                      _isShowingActionInbox = false;
                      _auditInitialAssignmentId = null;
                      _auditReturnActionFilter = null;
                      _selectedTabIndex = 3;
                    });
                  },
                  canStartAudit: const [
                    'tenant_owner',
                    'admin',
                    'manager',
                    'auditor',
                  ].contains(currentMember['role']),
                  onStartAudit: () {
                    setState(() {
                      _isShowingActionInbox = false;
                      _auditInitialAssignmentId = null;
                      _auditReturnActionFilter = null;
                      _selectedTabIndex = 3;
                    });
                  },
                  onAddSite: () {
                    setState(() {
                      _isShowingActionInbox = false;
                      _isAddingSite = true;
                      _restaurantError = null;
                      _restaurantMessage = null;
                      _restaurantResults = [];
                    });
                  },
                );
        }
        break;
      case 2:
        content = activeSiteDoc == null
            ? const _ModulePlaceholderContent(
                title: 'Violations',
                subtitle:
                    'Open a restaurant site before working its violation queue.',
                icon: Icons.report_problem_outlined,
              )
            : _ViolationsContent(
                tenantId: tenantId,
                siteId: activeSiteDoc.id,
                site: activeSiteDoc.data(),
                currentRole: currentMember['role'] as String? ?? 'staff',
                initialStatusFilter: _violationInitialFilter,
                initialViolationId: _violationInitialId,
                detailBackLabel: _violationDetailBackLabel,
                onBackFromDetail: _violationReturnActionFilter == null
                    ? null
                    : () {
                        setState(() {
                          _selectedTabIndex = 1;
                          _actionInboxInitialFilter =
                              _violationReturnActionFilter!;
                          _isShowingActionInbox = true;
                          _violationInitialId = null;
                          _violationDetailBackLabel = null;
                          _violationReturnActionFilter = null;
                        });
                      },
              );
        break;
      case 3:
        content = activeSiteDoc == null
            ? const _ModulePlaceholderContent(
                title: 'Audits',
                subtitle:
                    'Open a restaurant site before reviewing its inspection history.',
                icon: Icons.playlist_add_check_circle_outlined,
              )
            : _AuditsContent(
                tenantId: tenantId,
                siteId: activeSiteDoc.id,
                currentRole: currentMember['role'] as String? ?? 'staff',
                initialAssignmentId: _auditInitialAssignmentId,
                assignedCheckBackLabel: _auditReturnActionFilter == null
                    ? null
                    : 'Back to my checks',
                onBackFromAssignedCheck: _auditReturnActionFilter == null
                    ? null
                    : () {
                        setState(() {
                          _selectedTabIndex = 1;
                          _actionInboxInitialFilter = _auditReturnActionFilter!;
                          _isShowingActionInbox = true;
                          _auditInitialAssignmentId = null;
                          _auditReturnActionFilter = null;
                        });
                      },
              );
        break;
      case 4:
        content = activeSiteDoc == null
            ? const _ModulePlaceholderContent(
                title: 'Training',
                subtitle: 'Open a restaurant site before viewing training.',
                icon: Icons.school_outlined,
              )
            : _TrainingContent(
                tenantId: tenantId,
                siteId: activeSiteDoc.id,
                currentMember: currentMember,
                initialView: _trainingInitialView,
                initialAssignmentId: _trainingInitialAssignmentId,
              );
        break;
      default:
        content = _isManagingTeam
            ? _TeamManagementContent(
                tenantId: tenantId,
                sites: sites,
                currentMember: currentMember,
                onBack: () {
                  setState(() {
                    _isManagingTeam = false;
                  });
                },
              )
            : _MoreContent(
                isSyncingMasterData: _isSyncingMasterData,
                message: _moreMessage,
                error: _moreError,
                onRefreshMasterData:
                    activeSiteDoc != null &&
                        activeSiteDoc.data()['masterRestaurantId'] != null &&
                        const [
                          'tenant_owner',
                          'admin',
                          'manager',
                        ].contains(currentMember['role'])
                    ? () => _refreshMasterData(tenantId, activeSiteDoc!.id)
                    : null,
                onAddSite: () {
                  setState(() {
                    _isAddingSite = true;
                    _isManagingTeam = false;
                    _restaurantError = null;
                    _restaurantMessage = null;
                    _restaurantResults = [];
                  });
                },
                onManageTeam:
                    currentMember['role'] == 'tenant_owner' ||
                        currentMember['role'] == 'admin'
                    ? () {
                        setState(() {
                          _isManagingTeam = true;
                        });
                      }
                    : null,
              );
    }

    return _FiScoreAppScaffold(
      user: widget.user,
      activeSite: activeSiteDoc?.data(),
      siteCount: sites.length,
      onShowSites: sites.length > 1
          ? () {
              setState(() {
                _selectedTabIndex = 0;
              });
            }
          : null,
      showBottomNavigation: effectiveTabIndex != 0,
      selectedIndex: effectiveTabIndex,
      onSelectedIndexChanged: (index) {
        setState(() {
          _selectedTabIndex = index;
          _isShowingActionInbox = false;
          if (index == 2) {
            _violationInitialFilter = 'active';
            _violationInitialId = null;
            _violationDetailBackLabel = null;
            _violationReturnActionFilter = null;
          }
          if (index == 4) {
            _trainingInitialView = 'home';
            _trainingInitialAssignmentId = null;
          }
          if (index == 3) {
            _auditInitialAssignmentId = null;
            _auditReturnActionFilter = null;
          }
          if (index != 5) {
            _isManagingTeam = false;
          }
        });
      },
      onSignOut: _signOut,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.user.displayName ?? widget.user.email ?? 'FiScore user';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _siteRepository.userProfileStream(widget.user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data();
        // TODO: If users need membership in multiple independent tenants,
        // add an explicit workspace switcher rather than creating another
        // workspace from an invitation-acceptance screen.
        final tenantId = userData?['activeTenantId'] as String?;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (isLoading) {
          return _FiScoreSetupScaffold(
            user: widget.user,
            onSignOut: _signOut,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (tenantId == null) {
          return _FiScoreSetupScaffold(
            user: widget.user,
            onSignOut: _signOut,
            child: _InviteAcceptanceContent(
              displayName: displayName,
              onCreateWorkspace: (context) => _WorkspaceSetupContent(
                displayName: displayName,
                tenantNameController: _tenantNameController,
                isCreatingTenant: _isCreatingTenant,
                tenantMessage: _tenantMessage,
                tenantError: _tenantError,
                onCreateTenant: _createTenant,
              ),
            ),
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _teamRepository.memberStream(
            tenantId: tenantId,
            userId: widget.user.uid,
          ),
          builder: (context, memberSnapshot) {
            if (memberSnapshot.connectionState == ConnectionState.waiting) {
              return _FiScoreSetupScaffold(
                user: widget.user,
                onSignOut: _signOut,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final currentMember = memberSnapshot.data?.data();
            if (currentMember == null || currentMember['status'] != 'active') {
              return _FiScoreSetupScaffold(
                user: widget.user,
                onSignOut: _signOut,
                child: _InviteAcceptanceContent(
                  displayName: displayName,
                  reactivationTenantId: tenantId,
                  onCreateWorkspace: (context) => const SizedBox.shrink(),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _siteRepository.activeSitesStream(
                tenantId,
                member: currentMember,
              ),
              builder: (context, siteSnapshot) {
                if (siteSnapshot.connectionState == ConnectionState.waiting) {
                  return _FiScoreSetupScaffold(
                    user: widget.user,
                    onSignOut: _signOut,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final sites = siteSnapshot.data?.docs ?? [];
                if (sites.isEmpty || _isAddingSite) {
                  return _FiScoreSetupScaffold(
                    user: widget.user,
                    onSignOut: _signOut,
                    child: _SiteSetupContent(
                      tenantId: tenantId,
                      searchController: _restaurantSearchController,
                      isSearching: _isSearchingRestaurants,
                      isLinking: _isLinkingRestaurant,
                      linkingRestaurantId: _linkingRestaurantId,
                      results: _restaurantResults,
                      message: _restaurantMessage,
                      error: _restaurantError,
                      onSearch: () => _searchRestaurants(tenantId),
                      onCancel: sites.isEmpty
                          ? null
                          : () {
                              setState(() {
                                _isAddingSite = false;
                                _restaurantError = null;
                                _restaurantMessage = null;
                                _restaurantResults = [];
                              });
                            },
                      onLinkRestaurant: (masterRestaurantId, restaurantName) =>
                          _linkRestaurant(
                            tenantId,
                            masterRestaurantId,
                            restaurantName,
                          ),
                    ),
                  );
                }

                return _buildMainApp(tenantId, sites, currentMember);
              },
            );
          },
        );
      },
    );
  }
}
