// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FiScore';

  @override
  String get home => 'Home';

  @override
  String get violations => 'Violations';

  @override
  String get audits => 'Audits';

  @override
  String get training => 'Training';

  @override
  String get more => 'More';

  @override
  String get today => 'Today';

  @override
  String get dailyWork => 'Daily work';

  @override
  String get needsAction => 'Needs action';

  @override
  String get myWork => 'My work';

  @override
  String get teamFollowUp => 'Team follow-up';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get noActionNeeded => 'Nothing needs action now.';

  @override
  String get startInternalCheck => 'Start internal check';

  @override
  String get addSite => 'Add site';

  @override
  String get viewAudits => 'View audits';

  @override
  String get profileAndPreferences => 'Profile & preferences';

  @override
  String get language => 'Language';

  @override
  String get languagePreferenceHelp =>
      'FiScore uses your device language unless you choose one here.';

  @override
  String get useDeviceLanguage => 'Use device language';

  @override
  String get deviceLanguageDescription =>
      'Recommended for shared devices and first-time setup.';

  @override
  String get englishDescription => 'Show the app in English.';

  @override
  String get spanishDescription => 'Show the app in Spanish.';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusWorking => 'Working';

  @override
  String get statusReview => 'Review';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusUnknown => 'Unknown';

  @override
  String get severityCritical => 'Critical';

  @override
  String get severityMajor => 'Major';

  @override
  String get severityMinor => 'Minor';

  @override
  String get severityInformational => 'Informational';

  @override
  String get severityUnknown => 'Severity unknown';

  @override
  String get sourcePublicInspection => 'Public inspection';

  @override
  String get sourceInternalCheck => 'Internal check';

  @override
  String get sourceManualIssue => 'Manual issue';

  @override
  String get sourceViolation => 'Violation';

  @override
  String observed(Object value) {
    return 'Observed: $value';
  }

  @override
  String get assignedToYou => 'Assigned to you';

  @override
  String assignedTo(Object name) {
    return 'Assigned to $name';
  }

  @override
  String get teamMember => 'team member';

  @override
  String get readyForYourReview => 'Ready for your review';

  @override
  String get sentBackForUpdate => 'Sent back for an update';

  @override
  String get submitForReview => 'Submit for review';

  @override
  String get saveForLater => 'Save for later';

  @override
  String get cancel => 'Cancel';

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshPublicInspectionData => 'Refresh public inspection data';

  @override
  String get refreshPublicInspectionQuestion =>
      'Refresh public inspection data?';

  @override
  String get refreshPublicInspectionBody =>
      'FiScore will check for the latest public inspections and findings for this restaurant.';

  @override
  String get backToToday => 'Back to today';

  @override
  String get backToMore => 'Back to more';

  @override
  String get backToSites => 'Back to sites';

  @override
  String get backToViolations => 'Back to violations';

  @override
  String get backToChecks => 'Back to checks';

  @override
  String get roleOwner => 'Tenant owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAuditor => 'Auditor';

  @override
  String get roleStaff => 'Staff';

  @override
  String get requestFailed => 'The request failed. Please try again.';

  @override
  String get signInRequired => 'Sign in is required.';

  @override
  String get noEmailForSignedInUser => 'Signed-in user has no email.';

  @override
  String get tenantMembershipRequired => 'Tenant membership is required.';

  @override
  String get insufficientTenantRole => 'Insufficient tenant role.';

  @override
  String get siteAccessRequired => 'Access to this site is required.';

  @override
  String get unsupportedTeamRole => 'Unsupported team role.';

  @override
  String get chooseAtLeastOneSite => 'Choose at least one site.';

  @override
  String get chooseAtLeastOneTeammate => 'Choose at least one teammate.';

  @override
  String get chooseValidDueDate => 'Choose a valid due date.';

  @override
  String get activeSiteNotFound => 'Active site was not found.';

  @override
  String get teamMemberNotFound => 'Team member was not found.';

  @override
  String get inviteNotFound => 'Invite not found.';

  @override
  String get inviteNotValidForUser => 'Invite is not valid for this user.';

  @override
  String get workspaceNotActive => 'Workspace is not active.';

  @override
  String get violationNotFound => 'Violation was not found.';

  @override
  String get closedViolationCannotBeSubmitted =>
      'A closed violation cannot be submitted.';

  @override
  String get submittedWorkOnlySentBack =>
      'Only submitted work can be sent back.';

  @override
  String get submittedWorkOnlyClosed => 'Only submitted work can be closed.';

  @override
  String get closedViolationOnlyReopened =>
      'Only a closed violation can be reopened.';

  @override
  String get checklistTemplateNotFound => 'Checklist template was not found.';

  @override
  String get assignedCheckNotFound => 'Assigned check was not found.';

  @override
  String get checkAlreadyFinished => 'This check is already finished.';

  @override
  String get auditNotFound => 'Audit was not found.';

  @override
  String get libraryContentInvalid => 'Library content type is invalid.';

  @override
  String get libraryItemNotFound => 'Library item was not found.';

  @override
  String get masterRestaurantNotFound => 'Master restaurant was not found.';

  @override
  String get enterAtLeastTwoCharacters => 'Enter at least 2 characters.';

  @override
  String get trainingItemNotFound => 'Training item was not found.';

  @override
  String get trainingAssignmentNotFound => 'Training assignment was not found.';

  @override
  String get trainingAlreadyFinished => 'This assignment is already finished.';

  @override
  String get onlyAssignedCanCompleteTraining =>
      'Only the assigned teammate can complete training.';

  @override
  String get trainingAssignmentCancelled => 'This assignment was cancelled.';

  @override
  String get trainingCompletionSummaryRequired =>
      'Training completion summary is required.';

  @override
  String get cannotDeactivateYourself => 'You cannot deactivate yourself.';

  @override
  String get recordNotFound => 'The record was not found.';

  @override
  String get checkInformationAndTryAgain =>
      'Check the information and try again.';

  @override
  String get actionNotAvailableRightNow =>
      'This action is not available right now.';

  @override
  String get signInIntro =>
      'Review inspections, run checks, and keep corrective work on track.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String get emailSignIn => 'Email sign-in';

  @override
  String get signInWithEmail => 'Sign in with email';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressHint => 'name@example.com';

  @override
  String get emailMeSignInLink => 'Email me a sign-in link';

  @override
  String get sendSignInLink => 'Send sign-in link';

  @override
  String get checkYourEmail => 'Check your email';

  @override
  String get secureLinkSentTo => 'We sent a secure sign-in link to';

  @override
  String get openLinkOnDevice => 'Open the link on this device to continue.';

  @override
  String get resendLink => 'Resend link';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get emailSignInHelp =>
      'We will email you a secure sign-in link. No password required.';

  @override
  String get or => 'or';

  @override
  String get back => 'Back';

  @override
  String get continueAction => 'Continue';

  @override
  String get tryAgain => 'Try again';

  @override
  String get createWorkspace => 'Create workspace';

  @override
  String get workspaceName => 'Workspace name';

  @override
  String get workspaceNameHelp =>
      'Use the business, franchise, or restaurant group name.';

  @override
  String get workspaceNameHint => 'Example: Kannappan Hospitality';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get search => 'Search';

  @override
  String get link => 'Link';

  @override
  String get restaurantNameCityZip => 'Restaurant name, city, or ZIP';

  @override
  String get searchPublicRestaurantRecords =>
      'Search public restaurant records';

  @override
  String get restaurantName => 'Restaurant name';

  @override
  String get streetAddress => 'Street address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get zip => 'ZIP';

  @override
  String get addRestaurant => 'Add restaurant';

  @override
  String get addRestaurantManually => 'Add restaurant manually';

  @override
  String get backToSearch => 'Back to search';

  @override
  String get account => 'Account';

  @override
  String get manageTeammate => 'Manage teammate';

  @override
  String get email => 'Email';

  @override
  String get role => 'Role';

  @override
  String get allSites => 'All sites';

  @override
  String get selected => 'Selected';

  @override
  String get sendInvite => 'Send invite';

  @override
  String get creatingInvite => 'Creating invite...';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get resendInviteLink => 'Resend invite link';

  @override
  String get cancelInvite => 'Cancel invite';

  @override
  String get deactivateAccess => 'Deactivate access';

  @override
  String get couldNotLoadPendingInvites =>
      'We could not load your pending team invites. Please try again.';

  @override
  String get invitationLookupFailed => 'Invitation lookup failed.';

  @override
  String get teamAccessInactive => 'Team access inactive';

  @override
  String get inactiveAccessHelp =>
      'Your account is not active in this workspace. Ask your manager to send a new invitation if you need access again.';

  @override
  String welcomeUser(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get noTeamInvitesCreateWorkspace =>
      'No team invites were found for this email. Create a new FiScore workspace to get started.';

  @override
  String get joinYourTeam => 'Join your team';

  @override
  String get returnToYourTeam => 'Return to your team';

  @override
  String get removeAssignment => 'Remove assignment';

  @override
  String get loadMore => 'Load more';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get choosePhoto => 'Choose photo';

  @override
  String get chooseVideo => 'Choose video';

  @override
  String get processedAfterUpload => 'Processed after upload';

  @override
  String get shortClipsOnly => 'Short clips only, capped before upload';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get addVideo => 'Add video';

  @override
  String get moreActions => 'More';

  @override
  String get addTeamUpdate => 'Add a team update.';

  @override
  String get postNote => 'Post note';

  @override
  String get deletePost => 'Delete post';

  @override
  String get saveProgress => 'Save progress';

  @override
  String get savedForLater => 'Saved for later.';

  @override
  String get submittedForReview => 'Submitted for review.';

  @override
  String get trainingAssignedForViolation =>
      'Training assigned for this violation.';

  @override
  String get sendBack => 'Send back';

  @override
  String get closeViolation => 'Close violation';

  @override
  String get reopen => 'Reopen';

  @override
  String get addReviewFeedback => 'Add review feedback.';

  @override
  String get videoAttached => 'Video attached';

  @override
  String get backToPublicInspections => 'Back to public inspections';

  @override
  String get loadMoreInspections => 'Load more inspections';

  @override
  String get reportUploaded => 'Report uploaded.';

  @override
  String get reportStored => 'Report stored';

  @override
  String findingCount(Object count) {
    return '$count findings';
  }

  @override
  String gradeValue(Object value) {
    return 'Grade $value';
  }

  @override
  String scoreValue(Object value) {
    return 'Score $value';
  }

  @override
  String get inspectionDate => 'Inspection date';

  @override
  String get score => 'Score';

  @override
  String get grade => 'Grade';

  @override
  String get internal => 'Internal';

  @override
  String get public => 'Public';

  @override
  String get startCheck => 'Start check';

  @override
  String get assignCheck => 'Assign check';

  @override
  String get checkAssigned => 'Check assigned.';

  @override
  String get checkReassigned => 'Check reassigned.';

  @override
  String get assignedCheckCancelled => 'Assigned check cancelled.';

  @override
  String get checklistAddedToMyLibrary => 'Checklist added to My Library.';

  @override
  String get keep => 'Keep';

  @override
  String get cancelCheck => 'Cancel check';

  @override
  String get loadMoreActiveChecks => 'Load more active checks';

  @override
  String get viewMoreCompletedChecks => 'View more completed checks';

  @override
  String get loadMoreCompletedChecks => 'Load more completed checks';

  @override
  String get couldNotStartAssignedCheck =>
      'Could not start the assigned check. Try again.';

  @override
  String get couldNotStartCheck =>
      'Could not start this check. Please try again.';

  @override
  String get couldNotReassignCheck =>
      'Could not reassign this check. Try again.';

  @override
  String get couldNotCancelCheck => 'Could not cancel this check. Try again.';

  @override
  String get cancelThisCheckQuestion => 'Cancel this check?';

  @override
  String get cancelAssignedCheckQuestion => 'Cancel assigned check?';

  @override
  String get cancelSelfStartedCheckBody =>
      'This in-progress check will be cancelled and removed from your work list.';

  @override
  String get cancelAssignedCheckBody =>
      'The teammate will no longer need to complete this check.';

  @override
  String get assignedChecks => 'Assigned checks';

  @override
  String get assignedToMe => 'Assigned to me';

  @override
  String get inProgress => 'In progress';

  @override
  String get completedChecks => 'Completed checks';

  @override
  String get noCompletedChecksYet => 'No completed checks yet';

  @override
  String get runInternalCheckHelp =>
      'Run an internal check to identify issues before an inspection.';

  @override
  String get view => 'View';

  @override
  String get checklist => 'Checklist';

  @override
  String get assignTo => 'Assign to';

  @override
  String get dueDate => 'Due date';

  @override
  String get optionalNote => 'Optional note';

  @override
  String get auditOptionalNoteHint => 'Example: Complete before closing shift.';

  @override
  String get searchTeamMembers => 'Search team members';

  @override
  String get backToLastSection => 'Back to last section';

  @override
  String get backToReview => 'Back to review';

  @override
  String get completeMissingItems => 'Complete missing items';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitAudit => 'Submit audit';

  @override
  String get previous => 'Previous';

  @override
  String get saveAndExit => 'Save & exit';

  @override
  String get save => 'Save';

  @override
  String get pass => 'Pass';

  @override
  String get attention => 'Attention';

  @override
  String get notApplicable => 'N/A';

  @override
  String get myLibrary => 'My Library';

  @override
  String get exploreFiScore => 'Explore FiScore';

  @override
  String get exploreFiScoreLibrary => 'Explore FiScore Library';

  @override
  String get trainingAssigned => 'Training assigned.';

  @override
  String get cancelThisAssignmentQuestion => 'Cancel this assignment?';

  @override
  String get cancelThisAssignmentBody =>
      'This removes the training from the teammate\'s active list.';

  @override
  String get keepAssignment => 'Keep assignment';

  @override
  String get cancelAssignment => 'Cancel assignment';

  @override
  String get trainingAssignmentCancelledMessage =>
      'Training assignment cancelled.';

  @override
  String get loadMoreAssignedTraining => 'Load more assigned training';

  @override
  String get backToTraining => 'Back to training';

  @override
  String get loadMoreAssignments => 'Load more assignments';

  @override
  String get loadMoreActiveAssignments => 'Load more active assignments';

  @override
  String get couldNotUpdateTrainingLibrary =>
      'Could not update the Training library.';

  @override
  String get addLessonToMyLibrary => 'Add lesson to My Library';

  @override
  String get startTraining => 'Start training';

  @override
  String get done => 'Done';

  @override
  String get trainingLabel => 'Training';

  @override
  String get trainingOptionalNoteHint =>
      'Example: Complete before your next prep shift.';

  @override
  String get searchTraining => 'Search training';

  @override
  String get moreFilters => 'More filters';

  @override
  String get assignmentActions => 'Assignment actions';

  @override
  String get close => 'Close';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get playVideo => 'Play video';

  @override
  String get next => 'Next';

  @override
  String get review => 'Review';

  @override
  String get responsesSaveAutomatically => 'Responses save automatically.';

  @override
  String get continueAndFinishFromReview =>
      'You can continue now and finish open items from review.';

  @override
  String get describeIssueBeforeSubmitting =>
      'Describe this issue before submitting.';

  @override
  String get confirmYourEmail => 'Confirm your email';

  @override
  String get confirmEmailLinkHelp =>
      'For security, enter the email address that received this sign-in link.';

  @override
  String get emailLinkCouldNotBeUsed =>
      'This link could not be used. Request a new sign-in email.';

  @override
  String get setUpWorkspace => 'Set up your FiScore workspace';

  @override
  String signedInWorkspaceHelp(Object displayName) {
    return 'Signed in as $displayName. Create one workspace for the business or restaurant group that owns the locations you will manage.';
  }

  @override
  String get workspaceOwnerGuidance =>
      'Only an owner or administrator should create a workspace. Restaurant staff should join later through an invitation from the workspace owner.';

  @override
  String get findRestaurantToImportHistory =>
      'Find your restaurant to bring in public inspection history.';

  @override
  String get enterRestaurantToStartChecks =>
      'Enter the restaurant location to start running internal checks.';

  @override
  String get searchResults => 'Search results';

  @override
  String get noMatchingRestaurants =>
      'No matching restaurants found. Try another search or add this location manually.';

  @override
  String get publicInspectionHistoryCanBeLinkedLater =>
      'Public inspection history can be linked later.';

  @override
  String get restaurant => 'Restaurant';

  @override
  String inspectionCount(Object count) {
    return '$count inspections';
  }

  @override
  String inspectionCountLatest(Object count, Object date) {
    return '$count inspections - Latest $date';
  }

  @override
  String get team => 'Team';

  @override
  String get teamIntro =>
      'Invite staff and control which sites they can access.';

  @override
  String get inviteTeammate => 'Invite teammate';

  @override
  String get enterValidStaffEmail => 'Enter a valid staff email.';

  @override
  String get chooseAtLeastOneSiteForInvite =>
      'Choose at least one site for this invite.';

  @override
  String inviteSentTo(Object email) {
    return 'Invite sent to $email.';
  }

  @override
  String get inviteSavedEmailFailed =>
      'Invite saved, but the email could not be sent.';

  @override
  String get couldNotCreateInvite =>
      'Could not create the invite. Please try again.';

  @override
  String signInLinkResentTo(Object email) {
    return 'Sign-in link resent to $email.';
  }

  @override
  String get couldNotResendSignInLink => 'Could not resend the sign-in link.';

  @override
  String get cancelInvitationQuestion => 'Cancel invitation?';

  @override
  String cancelInvitationBody(Object email) {
    return '$email will no longer be able to join using this invitation.';
  }

  @override
  String get keepInvitation => 'Keep invitation';

  @override
  String invitationCanceledFor(Object email) {
    return 'Invitation canceled for $email.';
  }

  @override
  String deactivateMemberQuestion(Object name) {
    return 'Deactivate $name?';
  }

  @override
  String get deactivateMemberBody =>
      'They will lose access to this workspace. Their past activity will remain visible.';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get keepAccess => 'Keep access';

  @override
  String memberDeactivated(Object name) {
    return '$name has been deactivated.';
  }

  @override
  String editMember(Object name) {
    return 'Edit $name';
  }

  @override
  String get editInvitation => 'Edit invitation';

  @override
  String accessUpdatedFor(Object name) {
    return 'Access updated for $name.';
  }

  @override
  String invitationUpdatedFor(Object email) {
    return 'Invitation updated for $email.';
  }

  @override
  String get profile => 'Profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get fiScoreUser => 'FiScore user';

  @override
  String violationMovedToStatus(Object status) {
    return 'Violation moved to $status.';
  }

  @override
  String get couldNotUpdateViolation =>
      'Could not update the violation. Please try again.';

  @override
  String get couldNotSaveResponse =>
      'Could not save the response. Please try again.';

  @override
  String get enterFixBeforeSubmit =>
      'Enter what was fixed before submitting for review.';

  @override
  String get couldNotSubmitResponse =>
      'Could not submit the response. Please try again.';

  @override
  String get closedAfterManagerReview => 'Closed after manager review.';

  @override
  String get sendBackForChanges => 'Send back for changes';

  @override
  String get sendBackHelp => 'Tell the team what needs to be corrected.';

  @override
  String get couldNotAddChecklist =>
      'Could not add this checklist. Please try again.';

  @override
  String get chooseChecklist => 'Choose a checklist.';

  @override
  String get chooseTeammate => 'Choose a teammate.';

  @override
  String get couldNotAssignCheck => 'Could not assign this check. Try again.';

  @override
  String get assignCheckHelp =>
      'Choose a checklist and one teammate to complete it.';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get inThreeDays => 'In 3 days';

  @override
  String get inOneWeek => 'In 1 week';

  @override
  String get inTwoWeeks => 'In 2 weeks';

  @override
  String get inOneMonth => 'In 1 month';

  @override
  String get chooseDate => 'Choose date';

  @override
  String chooseDateWithDate(Object date) {
    return 'Choose date ($date)';
  }

  @override
  String get completeBeforeClosingShiftExample =>
      'Example: Complete before closing shift.';

  @override
  String get reassignCheck => 'Reassign check';

  @override
  String get reassign => 'Reassign';

  @override
  String get startedByYou => 'Started by you';

  @override
  String startedBy(Object name) {
    return 'Started by $name';
  }

  @override
  String get selfStarted => 'Self-started';

  @override
  String get overdue => 'Overdue';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String dueShortDate(Object date) {
    return 'Due $date';
  }

  @override
  String get completed => 'Completed';

  @override
  String completedShortDate(Object date) {
    return 'Completed $date';
  }

  @override
  String get start => 'Start';

  @override
  String get resume => 'Resume';

  @override
  String get assignTraining => 'Assign training';

  @override
  String get assignTrainingMyHelp =>
      'Choose coaching from your library, then assign it.';

  @override
  String get assignTrainingExploreHelp =>
      'Add curated FiScore training to your team library.';

  @override
  String get teamProgress => 'Team progress';

  @override
  String teamProgressSummary(Object open, Object overdue, Object completed) {
    return '$open open  |  $overdue overdue  |  $completed done';
  }

  @override
  String get openStatus => 'Open';

  @override
  String get cancelled => 'Cancelled';

  @override
  String cancelledCount(Object count) {
    return 'Cancelled ($count)';
  }

  @override
  String get all => 'All';

  @override
  String get nothingInThisView => 'Nothing in this view';

  @override
  String get noTrainingAssignmentsToFollowUp =>
      'There are no training assignments to follow up on.';

  @override
  String get noMatchingTraining => 'No matching training';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term.';

  @override
  String get noTrainingInMyLibrary => 'No training in My Library';

  @override
  String get exploreTrainingLibraryHelp =>
      'Explore FiScore Library to add coaching for your team.';

  @override
  String get couldNotLoadFiScoreLibrary => 'Could not load FiScore Library';

  @override
  String get pleaseTryAgainShortly => 'Please try again shortly.';

  @override
  String get update => 'Update';

  @override
  String get added => 'Added';

  @override
  String get add => 'Add';

  @override
  String get assign => 'Assign';

  @override
  String get createdByYourTeam => 'Created by your team';

  @override
  String get microLearning => 'Micro-learning';

  @override
  String get minUnit => 'min';

  @override
  String get updateAvailableInFiScoreLibrary =>
      'Update available in FiScore Library';

  @override
  String get completedLabel => 'Completed';

  @override
  String selectTeamMembers(Object count, Object pluralSuffix) {
    return 'Select $count team member$pluralSuffix';
  }

  @override
  String get noDueDate => 'No due date';

  @override
  String get chooseTrainingItemToAssign => 'Choose a training item to assign.';

  @override
  String get chooseAtLeastOneTeammateToAssign =>
      'Choose at least one teammate to assign.';

  @override
  String get couldNotAssignTraining =>
      'Could not assign training. Please try again.';

  @override
  String get forThisViolation => 'For this violation';

  @override
  String get noActiveTrainingItems => 'No active training items are available.';

  @override
  String get fixesReadyForReview => 'Fixes ready for review';

  @override
  String get myAssignedFixes => 'My assigned fixes';

  @override
  String get myChecks => 'My checks';

  @override
  String get myTraining => 'My training';

  @override
  String get overdueTraining => 'Overdue training';

  @override
  String get overdueChecks => 'Overdue checks';

  @override
  String get actionInbox => 'Action inbox';

  @override
  String get reviewSubmittedFixesHelp =>
      'Review submitted fixes and close the work loop.';

  @override
  String get completeAssignedFixesHelp =>
      'Complete resolutions assigned to you.';

  @override
  String get continueChecksHelp =>
      'Continue checks you started or were assigned.';

  @override
  String get completeAssignedCoachingHelp =>
      'Complete the coaching assigned to you.';

  @override
  String get followUpOverdueTrainingHelp =>
      'Follow up on training that has passed its due date.';

  @override
  String get followUpOverdueChecksHelp =>
      'Follow up on checks that have passed their due date.';

  @override
  String get workNeedsAttentionHelp => 'Work that needs your attention.';

  @override
  String get openSite => 'Open site';

  @override
  String get startACheck => 'Start a check';

  @override
  String get chooseChecklistForSite =>
      'Choose a checklist your team uses at this site.';

  @override
  String get addCuratedChecklistsHelp =>
      'Add curated FiScore checklists to your team library.';

  @override
  String get searchChecklists => 'Search checklists';

  @override
  String get noChecklistsInMyLibrary => 'No checklists in My Library';

  @override
  String get exploreChecklistLibraryHelp =>
      'Explore FiScore Library to add a checklist your team can use.';

  @override
  String get askManagerToAddChecklist =>
      'Ask a manager to add an internal checklist for this site.';

  @override
  String get noMatchingChecklists => 'No matching checklists';

  @override
  String get reviewChecklist => 'Review checklist';

  @override
  String get submitCheck => 'Submit check';

  @override
  String get couldNotAddTraining =>
      'Could not add this training. Please try again.';

  @override
  String get trainingAssignedMessage => 'Training assigned.';

  @override
  String get cancelTrainingAssignmentBody =>
      'The team member will no longer be expected to complete this training. The assignment stays in history.';

  @override
  String get couldNotCancelTraining =>
      'Could not cancel training. Please try again.';

  @override
  String get noTrainingAssigned => 'No training assigned';

  @override
  String get assignedLearningWillAppear =>
      'Assigned learning will appear here.';

  @override
  String get forManagers => 'For managers';

  @override
  String get assignAndMonitorTrainingHelp =>
      'Assign coaching and monitor completion.';

  @override
  String get trainingUnavailableManagerHelp =>
      'This assignment uses content that is not currently in My Library. Add its FiScore lesson, then reopen it or assign a new version.';

  @override
  String get trainingUnavailableStaffHelp =>
      'This training is not available yet. Please contact your manager.';

  @override
  String questionCheck(Object count) {
    return '$count question check';
  }

  @override
  String get assignedForFollowUp => 'Assigned for follow-up';

  @override
  String get youWillCover => 'You will cover';

  @override
  String assignedToName(Object name) {
    return 'Assigned to $name.';
  }

  @override
  String get watchRequiredVideo => 'Watch the required video to continue.';

  @override
  String get quickCheck => 'Quick check';

  @override
  String get complete => 'Complete';

  @override
  String quickCheckProgress(Object current, Object total) {
    return 'Quick check $current of $total';
  }

  @override
  String get checkAnswer => 'Check answer';

  @override
  String get finish => 'Finish';

  @override
  String get trainingComplete => 'Training complete';

  @override
  String get completedBy => 'Completed by';

  @override
  String get topicsCovered => 'Topics covered';

  @override
  String get quickCheckRecorded =>
      'Quick check completed. This completion is recorded.';
}
