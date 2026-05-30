part of '../main.dart';

extension AppLocalizationsFunctionErrors on AppLocalizations {
  String functionErrorMessage(String? code, String? message) {
    final normalized = (message ?? '').trim();
    if (normalized.isEmpty) {
      return functionFallback(code);
    }
    return switch (normalized) {
      'Sign in is required.' => signInRequired,
      'Signed-in user has no email.' => noEmailForSignedInUser,
      'Tenant membership is required.' => tenantMembershipRequired,
      'Insufficient tenant role.' => insufficientTenantRole,
      'Access to this site is required.' => siteAccessRequired,
      'Unsupported team role.' => unsupportedTeamRole,
      'Choose at least one site.' => chooseAtLeastOneSite,
      'Choose at least one teammate.' => chooseAtLeastOneTeammate,
      'Choose a valid due date.' => chooseValidDueDate,
      'Active site was not found.' => activeSiteNotFound,
      'Team member was not found.' => teamMemberNotFound,
      'Team member not found.' => teamMemberNotFound,
      'Invite not found.' => inviteNotFound,
      'Invite is not valid for this user.' => inviteNotValidForUser,
      'Workspace is not active.' => workspaceNotActive,
      'Violation was not found.' => violationNotFound,
      'A closed violation cannot be submitted.' =>
        closedViolationCannotBeSubmitted,
      'Only submitted work can be sent back.' => submittedWorkOnlySentBack,
      'Only submitted work can be closed.' => submittedWorkOnlyClosed,
      'Only a closed violation can be reopened.' => closedViolationOnlyReopened,
      'Checklist template was not found.' => checklistTemplateNotFound,
      'Assigned check was not found.' => assignedCheckNotFound,
      'This check is already finished.' => checkAlreadyFinished,
      'Audit was not found.' => auditNotFound,
      'Library content type is invalid.' => libraryContentInvalid,
      'Library item was not found.' => libraryItemNotFound,
      'Master restaurant was not found.' => masterRestaurantNotFound,
      'Enter at least 2 characters.' => enterAtLeastTwoCharacters,
      'Training item was not found.' => trainingItemNotFound,
      'Training assignment was not found.' => trainingAssignmentNotFound,
      'This assignment is already finished.' => trainingAlreadyFinished,
      'Only the assigned teammate can complete training.' =>
        onlyAssignedCanCompleteTraining,
      'This assignment was cancelled.' => trainingAssignmentCancelled,
      'Training completion summary is required.' =>
        trainingCompletionSummaryRequired,
      'You cannot deactivate yourself.' => cannotDeactivateYourself,
      _ => functionFallback(code),
    };
  }

  String functionFallback(String? code) {
    return switch (code) {
      'unauthenticated' => signInRequired,
      'permission-denied' => insufficientTenantRole,
      'not-found' => recordNotFound,
      'invalid-argument' => checkInformationAndTryAgain,
      'failed-precondition' => actionNotAvailableRightNow,
      _ => requestFailed,
    };
  }
}
