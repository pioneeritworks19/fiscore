import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FiScore'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @violations.
  ///
  /// In en, this message translates to:
  /// **'Violations'**
  String get violations;

  /// No description provided for @audits.
  ///
  /// In en, this message translates to:
  /// **'Audits'**
  String get audits;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @dailyWork.
  ///
  /// In en, this message translates to:
  /// **'Daily work'**
  String get dailyWork;

  /// No description provided for @needsAction.
  ///
  /// In en, this message translates to:
  /// **'Needs action'**
  String get needsAction;

  /// No description provided for @myWork.
  ///
  /// In en, this message translates to:
  /// **'My work'**
  String get myWork;

  /// No description provided for @teamFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Team follow-up'**
  String get teamFollowUp;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get recentActivity;

  /// No description provided for @noActionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs action now.'**
  String get noActionNeeded;

  /// No description provided for @startInternalCheck.
  ///
  /// In en, this message translates to:
  /// **'Start internal check'**
  String get startInternalCheck;

  /// No description provided for @addSite.
  ///
  /// In en, this message translates to:
  /// **'Add site'**
  String get addSite;

  /// No description provided for @viewAudits.
  ///
  /// In en, this message translates to:
  /// **'View audits'**
  String get viewAudits;

  /// No description provided for @profileAndPreferences.
  ///
  /// In en, this message translates to:
  /// **'Profile & preferences'**
  String get profileAndPreferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languagePreferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'FiScore uses your device language unless you choose one here.'**
  String get languagePreferenceHelp;

  /// No description provided for @useDeviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get useDeviceLanguage;

  /// No description provided for @deviceLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Recommended for shared devices and first-time setup.'**
  String get deviceLanguageDescription;

  /// No description provided for @englishDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the app in English.'**
  String get englishDescription;

  /// No description provided for @spanishDescription.
  ///
  /// In en, this message translates to:
  /// **'Show the app in Spanish.'**
  String get spanishDescription;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusWorking.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get statusWorking;

  /// No description provided for @statusReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get statusReview;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statusUnknown;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @severityMajor.
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get severityMajor;

  /// No description provided for @severityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get severityMinor;

  /// No description provided for @severityInformational.
  ///
  /// In en, this message translates to:
  /// **'Informational'**
  String get severityInformational;

  /// No description provided for @severityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Severity unknown'**
  String get severityUnknown;

  /// No description provided for @sourcePublicInspection.
  ///
  /// In en, this message translates to:
  /// **'Public inspection'**
  String get sourcePublicInspection;

  /// No description provided for @sourceInternalCheck.
  ///
  /// In en, this message translates to:
  /// **'Internal check'**
  String get sourceInternalCheck;

  /// No description provided for @sourceManualIssue.
  ///
  /// In en, this message translates to:
  /// **'Manual issue'**
  String get sourceManualIssue;

  /// No description provided for @sourceViolation.
  ///
  /// In en, this message translates to:
  /// **'Violation'**
  String get sourceViolation;

  /// No description provided for @observed.
  ///
  /// In en, this message translates to:
  /// **'Observed: {value}'**
  String observed(Object value);

  /// No description provided for @assignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get assignedToYou;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String assignedTo(Object name);

  /// No description provided for @teamMember.
  ///
  /// In en, this message translates to:
  /// **'team member'**
  String get teamMember;

  /// No description provided for @readyForYourReview.
  ///
  /// In en, this message translates to:
  /// **'Ready for your review'**
  String get readyForYourReview;

  /// No description provided for @sentBackForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Sent back for an update'**
  String get sentBackForUpdate;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;

  /// No description provided for @saveForLater.
  ///
  /// In en, this message translates to:
  /// **'Save for later'**
  String get saveForLater;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshPublicInspectionData.
  ///
  /// In en, this message translates to:
  /// **'Refresh public inspection data'**
  String get refreshPublicInspectionData;

  /// No description provided for @refreshPublicInspectionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Refresh public inspection data?'**
  String get refreshPublicInspectionQuestion;

  /// No description provided for @refreshPublicInspectionBody.
  ///
  /// In en, this message translates to:
  /// **'FiScore will check for the latest public inspections and findings for this restaurant.'**
  String get refreshPublicInspectionBody;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get backToToday;

  /// No description provided for @backToMore.
  ///
  /// In en, this message translates to:
  /// **'Back to more'**
  String get backToMore;

  /// No description provided for @backToSites.
  ///
  /// In en, this message translates to:
  /// **'Back to sites'**
  String get backToSites;

  /// No description provided for @backToViolations.
  ///
  /// In en, this message translates to:
  /// **'Back to violations'**
  String get backToViolations;

  /// No description provided for @backToChecks.
  ///
  /// In en, this message translates to:
  /// **'Back to checks'**
  String get backToChecks;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Tenant owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleAuditor.
  ///
  /// In en, this message translates to:
  /// **'Auditor'**
  String get roleAuditor;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'The request failed. Please try again.'**
  String get requestFailed;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in is required.'**
  String get signInRequired;

  /// No description provided for @noEmailForSignedInUser.
  ///
  /// In en, this message translates to:
  /// **'Signed-in user has no email.'**
  String get noEmailForSignedInUser;

  /// No description provided for @tenantMembershipRequired.
  ///
  /// In en, this message translates to:
  /// **'Tenant membership is required.'**
  String get tenantMembershipRequired;

  /// No description provided for @insufficientTenantRole.
  ///
  /// In en, this message translates to:
  /// **'Insufficient tenant role.'**
  String get insufficientTenantRole;

  /// No description provided for @siteAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Access to this site is required.'**
  String get siteAccessRequired;

  /// No description provided for @unsupportedTeamRole.
  ///
  /// In en, this message translates to:
  /// **'Unsupported team role.'**
  String get unsupportedTeamRole;

  /// No description provided for @chooseAtLeastOneSite.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one site.'**
  String get chooseAtLeastOneSite;

  /// No description provided for @chooseAtLeastOneTeammate.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one teammate.'**
  String get chooseAtLeastOneTeammate;

  /// No description provided for @chooseValidDueDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid due date.'**
  String get chooseValidDueDate;

  /// No description provided for @activeSiteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Active site was not found.'**
  String get activeSiteNotFound;

  /// No description provided for @teamMemberNotFound.
  ///
  /// In en, this message translates to:
  /// **'Team member was not found.'**
  String get teamMemberNotFound;

  /// No description provided for @inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invite not found.'**
  String get inviteNotFound;

  /// No description provided for @inviteNotValidForUser.
  ///
  /// In en, this message translates to:
  /// **'Invite is not valid for this user.'**
  String get inviteNotValidForUser;

  /// No description provided for @workspaceNotActive.
  ///
  /// In en, this message translates to:
  /// **'Workspace is not active.'**
  String get workspaceNotActive;

  /// No description provided for @violationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Violation was not found.'**
  String get violationNotFound;

  /// No description provided for @closedViolationCannotBeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'A closed violation cannot be submitted.'**
  String get closedViolationCannotBeSubmitted;

  /// No description provided for @submittedWorkOnlySentBack.
  ///
  /// In en, this message translates to:
  /// **'Only submitted work can be sent back.'**
  String get submittedWorkOnlySentBack;

  /// No description provided for @submittedWorkOnlyClosed.
  ///
  /// In en, this message translates to:
  /// **'Only submitted work can be closed.'**
  String get submittedWorkOnlyClosed;

  /// No description provided for @closedViolationOnlyReopened.
  ///
  /// In en, this message translates to:
  /// **'Only a closed violation can be reopened.'**
  String get closedViolationOnlyReopened;

  /// No description provided for @checklistTemplateNotFound.
  ///
  /// In en, this message translates to:
  /// **'Checklist template was not found.'**
  String get checklistTemplateNotFound;

  /// No description provided for @assignedCheckNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assigned check was not found.'**
  String get assignedCheckNotFound;

  /// No description provided for @checkAlreadyFinished.
  ///
  /// In en, this message translates to:
  /// **'This check is already finished.'**
  String get checkAlreadyFinished;

  /// No description provided for @auditNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audit was not found.'**
  String get auditNotFound;

  /// No description provided for @libraryContentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Library content type is invalid.'**
  String get libraryContentInvalid;

  /// No description provided for @libraryItemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Library item was not found.'**
  String get libraryItemNotFound;

  /// No description provided for @masterRestaurantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Master restaurant was not found.'**
  String get masterRestaurantNotFound;

  /// No description provided for @enterAtLeastTwoCharacters.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters.'**
  String get enterAtLeastTwoCharacters;

  /// No description provided for @trainingItemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Training item was not found.'**
  String get trainingItemNotFound;

  /// No description provided for @trainingAssignmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Training assignment was not found.'**
  String get trainingAssignmentNotFound;

  /// No description provided for @trainingAlreadyFinished.
  ///
  /// In en, this message translates to:
  /// **'This assignment is already finished.'**
  String get trainingAlreadyFinished;

  /// No description provided for @onlyAssignedCanCompleteTraining.
  ///
  /// In en, this message translates to:
  /// **'Only the assigned teammate can complete training.'**
  String get onlyAssignedCanCompleteTraining;

  /// No description provided for @trainingAssignmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'This assignment was cancelled.'**
  String get trainingAssignmentCancelled;

  /// No description provided for @trainingCompletionSummaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Training completion summary is required.'**
  String get trainingCompletionSummaryRequired;

  /// No description provided for @cannotDeactivateYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot deactivate yourself.'**
  String get cannotDeactivateYourself;

  /// No description provided for @recordNotFound.
  ///
  /// In en, this message translates to:
  /// **'The record was not found.'**
  String get recordNotFound;

  /// No description provided for @checkInformationAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check the information and try again.'**
  String get checkInformationAndTryAgain;

  /// No description provided for @actionNotAvailableRightNow.
  ///
  /// In en, this message translates to:
  /// **'This action is not available right now.'**
  String get actionNotAvailableRightNow;

  /// No description provided for @signInIntro.
  ///
  /// In en, this message translates to:
  /// **'Review inspections, run checks, and keep corrective work on track.'**
  String get signInIntro;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// No description provided for @emailSignIn.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in'**
  String get emailSignIn;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInWithEmail;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailAddressHint;

  /// No description provided for @emailMeSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Email me a sign-in link'**
  String get emailMeSignInLink;

  /// No description provided for @sendSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Send sign-in link'**
  String get sendSignInLink;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkYourEmail;

  /// No description provided for @secureLinkSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a secure sign-in link to'**
  String get secureLinkSentTo;

  /// No description provided for @openLinkOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Open the link on this device to continue.'**
  String get openLinkOnDevice;

  /// No description provided for @resendLink.
  ///
  /// In en, this message translates to:
  /// **'Resend link'**
  String get resendLink;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// No description provided for @emailSignInHelp.
  ///
  /// In en, this message translates to:
  /// **'We will email you a secure sign-in link. No password required.'**
  String get emailSignInHelp;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @createWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create workspace'**
  String get createWorkspace;

  /// No description provided for @workspaceName.
  ///
  /// In en, this message translates to:
  /// **'Workspace name'**
  String get workspaceName;

  /// No description provided for @workspaceNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the business, franchise, or restaurant group name.'**
  String get workspaceNameHelp;

  /// No description provided for @workspaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Kannappan Hospitality'**
  String get workspaceNameHint;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @restaurantNameCityZip.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name, city, or ZIP'**
  String get restaurantNameCityZip;

  /// No description provided for @searchPublicRestaurantRecords.
  ///
  /// In en, this message translates to:
  /// **'Search public restaurant records'**
  String get searchPublicRestaurantRecords;

  /// No description provided for @restaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name'**
  String get restaurantName;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get streetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @zip.
  ///
  /// In en, this message translates to:
  /// **'ZIP'**
  String get zip;

  /// No description provided for @addRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add restaurant'**
  String get addRestaurant;

  /// No description provided for @addRestaurantManually.
  ///
  /// In en, this message translates to:
  /// **'Add restaurant manually'**
  String get addRestaurantManually;

  /// No description provided for @backToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get backToSearch;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @manageTeammate.
  ///
  /// In en, this message translates to:
  /// **'Manage teammate'**
  String get manageTeammate;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @allSites.
  ///
  /// In en, this message translates to:
  /// **'All sites'**
  String get allSites;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get sendInvite;

  /// No description provided for @creatingInvite.
  ///
  /// In en, this message translates to:
  /// **'Creating invite...'**
  String get creatingInvite;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @resendInviteLink.
  ///
  /// In en, this message translates to:
  /// **'Resend invite link'**
  String get resendInviteLink;

  /// No description provided for @cancelInvite.
  ///
  /// In en, this message translates to:
  /// **'Cancel invite'**
  String get cancelInvite;

  /// No description provided for @deactivateAccess.
  ///
  /// In en, this message translates to:
  /// **'Deactivate access'**
  String get deactivateAccess;

  /// No description provided for @couldNotLoadPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'We could not load your pending team invites. Please try again.'**
  String get couldNotLoadPendingInvites;

  /// No description provided for @invitationLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Invitation lookup failed.'**
  String get invitationLookupFailed;

  /// No description provided for @teamAccessInactive.
  ///
  /// In en, this message translates to:
  /// **'Team access inactive'**
  String get teamAccessInactive;

  /// No description provided for @inactiveAccessHelp.
  ///
  /// In en, this message translates to:
  /// **'Your account is not active in this workspace. Ask your manager to send a new invitation if you need access again.'**
  String get inactiveAccessHelp;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(Object name);

  /// No description provided for @noTeamInvitesCreateWorkspace.
  ///
  /// In en, this message translates to:
  /// **'No team invites were found for this email. Create a new FiScore workspace to get started.'**
  String get noTeamInvitesCreateWorkspace;

  /// No description provided for @joinYourTeam.
  ///
  /// In en, this message translates to:
  /// **'Join your team'**
  String get joinYourTeam;

  /// No description provided for @returnToYourTeam.
  ///
  /// In en, this message translates to:
  /// **'Return to your team'**
  String get returnToYourTeam;

  /// No description provided for @removeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Remove assignment'**
  String get removeAssignment;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get choosePhoto;

  /// No description provided for @chooseVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose video'**
  String get chooseVideo;

  /// No description provided for @processedAfterUpload.
  ///
  /// In en, this message translates to:
  /// **'Processed after upload'**
  String get processedAfterUpload;

  /// No description provided for @shortClipsOnly.
  ///
  /// In en, this message translates to:
  /// **'Short clips only, capped before upload'**
  String get shortClipsOnly;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @addTeamUpdate.
  ///
  /// In en, this message translates to:
  /// **'Add a team update.'**
  String get addTeamUpdate;

  /// No description provided for @postNote.
  ///
  /// In en, this message translates to:
  /// **'Post note'**
  String get postNote;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get deletePost;

  /// No description provided for @saveProgress.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get saveProgress;

  /// No description provided for @savedForLater.
  ///
  /// In en, this message translates to:
  /// **'Saved for later.'**
  String get savedForLater;

  /// No description provided for @submittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review.'**
  String get submittedForReview;

  /// No description provided for @trainingAssignedForViolation.
  ///
  /// In en, this message translates to:
  /// **'Training assigned for this violation.'**
  String get trainingAssignedForViolation;

  /// No description provided for @sendBack.
  ///
  /// In en, this message translates to:
  /// **'Send back'**
  String get sendBack;

  /// No description provided for @closeViolation.
  ///
  /// In en, this message translates to:
  /// **'Close violation'**
  String get closeViolation;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @addReviewFeedback.
  ///
  /// In en, this message translates to:
  /// **'Add review feedback.'**
  String get addReviewFeedback;

  /// No description provided for @videoAttached.
  ///
  /// In en, this message translates to:
  /// **'Video attached'**
  String get videoAttached;

  /// No description provided for @backToPublicInspections.
  ///
  /// In en, this message translates to:
  /// **'Back to public inspections'**
  String get backToPublicInspections;

  /// No description provided for @loadMoreInspections.
  ///
  /// In en, this message translates to:
  /// **'Load more inspections'**
  String get loadMoreInspections;

  /// No description provided for @reportUploaded.
  ///
  /// In en, this message translates to:
  /// **'Report uploaded.'**
  String get reportUploaded;

  /// No description provided for @reportStored.
  ///
  /// In en, this message translates to:
  /// **'Report stored'**
  String get reportStored;

  /// No description provided for @findingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} findings'**
  String findingCount(Object count);

  /// No description provided for @gradeValue.
  ///
  /// In en, this message translates to:
  /// **'Grade {value}'**
  String gradeValue(Object value);

  /// No description provided for @scoreValue.
  ///
  /// In en, this message translates to:
  /// **'Score {value}'**
  String scoreValue(Object value);

  /// No description provided for @inspectionDate.
  ///
  /// In en, this message translates to:
  /// **'Inspection date'**
  String get inspectionDate;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @internal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get internal;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @startCheck.
  ///
  /// In en, this message translates to:
  /// **'Start check'**
  String get startCheck;

  /// No description provided for @assignCheck.
  ///
  /// In en, this message translates to:
  /// **'Assign check'**
  String get assignCheck;

  /// No description provided for @checkAssigned.
  ///
  /// In en, this message translates to:
  /// **'Check assigned.'**
  String get checkAssigned;

  /// No description provided for @checkReassigned.
  ///
  /// In en, this message translates to:
  /// **'Check reassigned.'**
  String get checkReassigned;

  /// No description provided for @assignedCheckCancelled.
  ///
  /// In en, this message translates to:
  /// **'Assigned check cancelled.'**
  String get assignedCheckCancelled;

  /// No description provided for @checklistAddedToMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Checklist added to My Library.'**
  String get checklistAddedToMyLibrary;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @cancelCheck.
  ///
  /// In en, this message translates to:
  /// **'Cancel check'**
  String get cancelCheck;

  /// No description provided for @loadMoreActiveChecks.
  ///
  /// In en, this message translates to:
  /// **'Load more active checks'**
  String get loadMoreActiveChecks;

  /// No description provided for @viewMoreCompletedChecks.
  ///
  /// In en, this message translates to:
  /// **'View more completed checks'**
  String get viewMoreCompletedChecks;

  /// No description provided for @loadMoreCompletedChecks.
  ///
  /// In en, this message translates to:
  /// **'Load more completed checks'**
  String get loadMoreCompletedChecks;

  /// No description provided for @couldNotStartAssignedCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not start the assigned check. Try again.'**
  String get couldNotStartAssignedCheck;

  /// No description provided for @couldNotStartCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not start this check. Please try again.'**
  String get couldNotStartCheck;

  /// No description provided for @couldNotReassignCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not reassign this check. Try again.'**
  String get couldNotReassignCheck;

  /// No description provided for @couldNotCancelCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel this check. Try again.'**
  String get couldNotCancelCheck;

  /// No description provided for @cancelThisCheckQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel this check?'**
  String get cancelThisCheckQuestion;

  /// No description provided for @cancelAssignedCheckQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel assigned check?'**
  String get cancelAssignedCheckQuestion;

  /// No description provided for @cancelSelfStartedCheckBody.
  ///
  /// In en, this message translates to:
  /// **'This in-progress check will be cancelled and removed from your work list.'**
  String get cancelSelfStartedCheckBody;

  /// No description provided for @cancelAssignedCheckBody.
  ///
  /// In en, this message translates to:
  /// **'The teammate will no longer need to complete this check.'**
  String get cancelAssignedCheckBody;

  /// No description provided for @assignedChecks.
  ///
  /// In en, this message translates to:
  /// **'Assigned checks'**
  String get assignedChecks;

  /// No description provided for @assignedToMe.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get assignedToMe;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @completedChecks.
  ///
  /// In en, this message translates to:
  /// **'Completed checks'**
  String get completedChecks;

  /// No description provided for @noCompletedChecksYet.
  ///
  /// In en, this message translates to:
  /// **'No completed checks yet'**
  String get noCompletedChecksYet;

  /// No description provided for @runInternalCheckHelp.
  ///
  /// In en, this message translates to:
  /// **'Run an internal check to identify issues before an inspection.'**
  String get runInternalCheckHelp;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get checklist;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get assignTo;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get optionalNote;

  /// No description provided for @auditOptionalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Complete before closing shift.'**
  String get auditOptionalNoteHint;

  /// No description provided for @searchTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Search team members'**
  String get searchTeamMembers;

  /// No description provided for @backToLastSection.
  ///
  /// In en, this message translates to:
  /// **'Back to last section'**
  String get backToLastSection;

  /// No description provided for @backToReview.
  ///
  /// In en, this message translates to:
  /// **'Back to review'**
  String get backToReview;

  /// No description provided for @completeMissingItems.
  ///
  /// In en, this message translates to:
  /// **'Complete missing items'**
  String get completeMissingItems;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @submitAudit.
  ///
  /// In en, this message translates to:
  /// **'Submit audit'**
  String get submitAudit;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @saveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get saveAndExit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notApplicable;

  /// No description provided for @myLibrary.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibrary;

  /// No description provided for @exploreFiScore.
  ///
  /// In en, this message translates to:
  /// **'Explore FiScore'**
  String get exploreFiScore;

  /// No description provided for @exploreFiScoreLibrary.
  ///
  /// In en, this message translates to:
  /// **'Explore FiScore Library'**
  String get exploreFiScoreLibrary;

  /// No description provided for @trainingAssigned.
  ///
  /// In en, this message translates to:
  /// **'Training assigned.'**
  String get trainingAssigned;

  /// No description provided for @cancelThisAssignmentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel this assignment?'**
  String get cancelThisAssignmentQuestion;

  /// No description provided for @cancelThisAssignmentBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the training from the teammate\'s active list.'**
  String get cancelThisAssignmentBody;

  /// No description provided for @keepAssignment.
  ///
  /// In en, this message translates to:
  /// **'Keep assignment'**
  String get keepAssignment;

  /// No description provided for @cancelAssignment.
  ///
  /// In en, this message translates to:
  /// **'Cancel assignment'**
  String get cancelAssignment;

  /// No description provided for @trainingAssignmentCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Training assignment cancelled.'**
  String get trainingAssignmentCancelledMessage;

  /// No description provided for @loadMoreAssignedTraining.
  ///
  /// In en, this message translates to:
  /// **'Load more assigned training'**
  String get loadMoreAssignedTraining;

  /// No description provided for @backToTraining.
  ///
  /// In en, this message translates to:
  /// **'Back to training'**
  String get backToTraining;

  /// No description provided for @loadMoreAssignments.
  ///
  /// In en, this message translates to:
  /// **'Load more assignments'**
  String get loadMoreAssignments;

  /// No description provided for @loadMoreActiveAssignments.
  ///
  /// In en, this message translates to:
  /// **'Load more active assignments'**
  String get loadMoreActiveAssignments;

  /// No description provided for @couldNotUpdateTrainingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Could not update the Training library.'**
  String get couldNotUpdateTrainingLibrary;

  /// No description provided for @addLessonToMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add lesson to My Library'**
  String get addLessonToMyLibrary;

  /// No description provided for @startTraining.
  ///
  /// In en, this message translates to:
  /// **'Start training'**
  String get startTraining;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @trainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get trainingLabel;

  /// No description provided for @trainingOptionalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Example: Complete before your next prep shift.'**
  String get trainingOptionalNoteHint;

  /// No description provided for @searchTraining.
  ///
  /// In en, this message translates to:
  /// **'Search training'**
  String get searchTraining;

  /// No description provided for @moreFilters.
  ///
  /// In en, this message translates to:
  /// **'More filters'**
  String get moreFilters;

  /// No description provided for @assignmentActions.
  ///
  /// In en, this message translates to:
  /// **'Assignment actions'**
  String get assignmentActions;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideo;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @responsesSaveAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Responses save automatically.'**
  String get responsesSaveAutomatically;

  /// No description provided for @continueAndFinishFromReview.
  ///
  /// In en, this message translates to:
  /// **'You can continue now and finish open items from review.'**
  String get continueAndFinishFromReview;

  /// No description provided for @describeIssueBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Describe this issue before submitting.'**
  String get describeIssueBeforeSubmitting;

  /// No description provided for @confirmYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email'**
  String get confirmYourEmail;

  /// No description provided for @confirmEmailLinkHelp.
  ///
  /// In en, this message translates to:
  /// **'For security, enter the email address that received this sign-in link.'**
  String get confirmEmailLinkHelp;

  /// No description provided for @emailLinkCouldNotBeUsed.
  ///
  /// In en, this message translates to:
  /// **'This link could not be used. Request a new sign-in email.'**
  String get emailLinkCouldNotBeUsed;

  /// No description provided for @setUpWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Set up your FiScore workspace'**
  String get setUpWorkspace;

  /// No description provided for @signedInWorkspaceHelp.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {displayName}. Create one workspace for the business or restaurant group that owns the locations you will manage.'**
  String signedInWorkspaceHelp(Object displayName);

  /// No description provided for @workspaceOwnerGuidance.
  ///
  /// In en, this message translates to:
  /// **'Only an owner or administrator should create a workspace. Restaurant staff should join later through an invitation from the workspace owner.'**
  String get workspaceOwnerGuidance;

  /// No description provided for @findRestaurantToImportHistory.
  ///
  /// In en, this message translates to:
  /// **'Find your restaurant to bring in public inspection history.'**
  String get findRestaurantToImportHistory;

  /// No description provided for @enterRestaurantToStartChecks.
  ///
  /// In en, this message translates to:
  /// **'Enter the restaurant location to start running internal checks.'**
  String get enterRestaurantToStartChecks;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @noMatchingRestaurants.
  ///
  /// In en, this message translates to:
  /// **'No matching restaurants found. Try another search or add this location manually.'**
  String get noMatchingRestaurants;

  /// No description provided for @publicInspectionHistoryCanBeLinkedLater.
  ///
  /// In en, this message translates to:
  /// **'Public inspection history can be linked later.'**
  String get publicInspectionHistoryCanBeLinkedLater;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @inspectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} inspections'**
  String inspectionCount(Object count);

  /// No description provided for @inspectionCountLatest.
  ///
  /// In en, this message translates to:
  /// **'{count} inspections - Latest {date}'**
  String inspectionCountLatest(Object count, Object date);

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @teamIntro.
  ///
  /// In en, this message translates to:
  /// **'Invite staff and control which sites they can access.'**
  String get teamIntro;

  /// No description provided for @inviteTeammate.
  ///
  /// In en, this message translates to:
  /// **'Invite teammate'**
  String get inviteTeammate;

  /// No description provided for @enterValidStaffEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid staff email.'**
  String get enterValidStaffEmail;

  /// No description provided for @chooseAtLeastOneSiteForInvite.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one site for this invite.'**
  String get chooseAtLeastOneSiteForInvite;

  /// No description provided for @inviteSentTo.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {email}.'**
  String inviteSentTo(Object email);

  /// No description provided for @inviteSavedEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Invite saved, but the email could not be sent.'**
  String get inviteSavedEmailFailed;

  /// No description provided for @couldNotCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Could not create the invite. Please try again.'**
  String get couldNotCreateInvite;

  /// No description provided for @signInLinkResentTo.
  ///
  /// In en, this message translates to:
  /// **'Sign-in link resent to {email}.'**
  String signInLinkResentTo(Object email);

  /// No description provided for @couldNotResendSignInLink.
  ///
  /// In en, this message translates to:
  /// **'Could not resend the sign-in link.'**
  String get couldNotResendSignInLink;

  /// No description provided for @cancelInvitationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation?'**
  String get cancelInvitationQuestion;

  /// No description provided for @cancelInvitationBody.
  ///
  /// In en, this message translates to:
  /// **'{email} will no longer be able to join using this invitation.'**
  String cancelInvitationBody(Object email);

  /// No description provided for @keepInvitation.
  ///
  /// In en, this message translates to:
  /// **'Keep invitation'**
  String get keepInvitation;

  /// No description provided for @invitationCanceledFor.
  ///
  /// In en, this message translates to:
  /// **'Invitation canceled for {email}.'**
  String invitationCanceledFor(Object email);

  /// No description provided for @deactivateMemberQuestion.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String deactivateMemberQuestion(Object name);

  /// No description provided for @deactivateMemberBody.
  ///
  /// In en, this message translates to:
  /// **'They will lose access to this workspace. Their past activity will remain visible.'**
  String get deactivateMemberBody;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @keepAccess.
  ///
  /// In en, this message translates to:
  /// **'Keep access'**
  String get keepAccess;

  /// No description provided for @memberDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} has been deactivated.'**
  String memberDeactivated(Object name);

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editMember(Object name);

  /// No description provided for @editInvitation.
  ///
  /// In en, this message translates to:
  /// **'Edit invitation'**
  String get editInvitation;

  /// No description provided for @accessUpdatedFor.
  ///
  /// In en, this message translates to:
  /// **'Access updated for {name}.'**
  String accessUpdatedFor(Object name);

  /// No description provided for @invitationUpdatedFor.
  ///
  /// In en, this message translates to:
  /// **'Invitation updated for {email}.'**
  String invitationUpdatedFor(Object email);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @fiScoreUser.
  ///
  /// In en, this message translates to:
  /// **'FiScore user'**
  String get fiScoreUser;

  /// No description provided for @violationMovedToStatus.
  ///
  /// In en, this message translates to:
  /// **'Violation moved to {status}.'**
  String violationMovedToStatus(Object status);

  /// No description provided for @couldNotUpdateViolation.
  ///
  /// In en, this message translates to:
  /// **'Could not update the violation. Please try again.'**
  String get couldNotUpdateViolation;

  /// No description provided for @couldNotSaveResponse.
  ///
  /// In en, this message translates to:
  /// **'Could not save the response. Please try again.'**
  String get couldNotSaveResponse;

  /// No description provided for @enterFixBeforeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Enter what was fixed before submitting for review.'**
  String get enterFixBeforeSubmit;

  /// No description provided for @couldNotSubmitResponse.
  ///
  /// In en, this message translates to:
  /// **'Could not submit the response. Please try again.'**
  String get couldNotSubmitResponse;

  /// No description provided for @closedAfterManagerReview.
  ///
  /// In en, this message translates to:
  /// **'Closed after manager review.'**
  String get closedAfterManagerReview;

  /// No description provided for @sendBackForChanges.
  ///
  /// In en, this message translates to:
  /// **'Send back for changes'**
  String get sendBackForChanges;

  /// No description provided for @sendBackHelp.
  ///
  /// In en, this message translates to:
  /// **'Tell the team what needs to be corrected.'**
  String get sendBackHelp;

  /// No description provided for @couldNotAddChecklist.
  ///
  /// In en, this message translates to:
  /// **'Could not add this checklist. Please try again.'**
  String get couldNotAddChecklist;

  /// No description provided for @chooseChecklist.
  ///
  /// In en, this message translates to:
  /// **'Choose a checklist.'**
  String get chooseChecklist;

  /// No description provided for @chooseTeammate.
  ///
  /// In en, this message translates to:
  /// **'Choose a teammate.'**
  String get chooseTeammate;

  /// No description provided for @couldNotAssignCheck.
  ///
  /// In en, this message translates to:
  /// **'Could not assign this check. Try again.'**
  String get couldNotAssignCheck;

  /// No description provided for @assignCheckHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose a checklist and one teammate to complete it.'**
  String get assignCheckHelp;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @inThreeDays.
  ///
  /// In en, this message translates to:
  /// **'In 3 days'**
  String get inThreeDays;

  /// No description provided for @inOneWeek.
  ///
  /// In en, this message translates to:
  /// **'In 1 week'**
  String get inOneWeek;

  /// No description provided for @inTwoWeeks.
  ///
  /// In en, this message translates to:
  /// **'In 2 weeks'**
  String get inTwoWeeks;

  /// No description provided for @inOneMonth.
  ///
  /// In en, this message translates to:
  /// **'In 1 month'**
  String get inOneMonth;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDate;

  /// No description provided for @chooseDateWithDate.
  ///
  /// In en, this message translates to:
  /// **'Choose date ({date})'**
  String chooseDateWithDate(Object date);

  /// No description provided for @completeBeforeClosingShiftExample.
  ///
  /// In en, this message translates to:
  /// **'Example: Complete before closing shift.'**
  String get completeBeforeClosingShiftExample;

  /// No description provided for @reassignCheck.
  ///
  /// In en, this message translates to:
  /// **'Reassign check'**
  String get reassignCheck;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @startedByYou.
  ///
  /// In en, this message translates to:
  /// **'Started by you'**
  String get startedByYou;

  /// No description provided for @startedBy.
  ///
  /// In en, this message translates to:
  /// **'Started by {name}'**
  String startedBy(Object name);

  /// No description provided for @selfStarted.
  ///
  /// In en, this message translates to:
  /// **'Self-started'**
  String get selfStarted;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueShortDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueShortDate(Object date);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @completedShortDate.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String completedShortDate(Object date);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @assignTraining.
  ///
  /// In en, this message translates to:
  /// **'Assign training'**
  String get assignTraining;

  /// No description provided for @assignTrainingMyHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose coaching from your library, then assign it.'**
  String get assignTrainingMyHelp;

  /// No description provided for @assignTrainingExploreHelp.
  ///
  /// In en, this message translates to:
  /// **'Add curated FiScore training to your team library.'**
  String get assignTrainingExploreHelp;

  /// No description provided for @teamProgress.
  ///
  /// In en, this message translates to:
  /// **'Team progress'**
  String get teamProgress;

  /// No description provided for @teamProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{open} open  |  {overdue} overdue  |  {completed} done'**
  String teamProgressSummary(Object open, Object overdue, Object completed);

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cancelledCount.
  ///
  /// In en, this message translates to:
  /// **'Cancelled ({count})'**
  String cancelledCount(Object count);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @nothingInThisView.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this view'**
  String get nothingInThisView;

  /// No description provided for @noTrainingAssignmentsToFollowUp.
  ///
  /// In en, this message translates to:
  /// **'There are no training assignments to follow up on.'**
  String get noTrainingAssignmentsToFollowUp;

  /// No description provided for @noMatchingTraining.
  ///
  /// In en, this message translates to:
  /// **'No matching training'**
  String get noMatchingTraining;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get tryDifferentSearchTerm;

  /// No description provided for @noTrainingInMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No training in My Library'**
  String get noTrainingInMyLibrary;

  /// No description provided for @exploreTrainingLibraryHelp.
  ///
  /// In en, this message translates to:
  /// **'Explore FiScore Library to add coaching for your team.'**
  String get exploreTrainingLibraryHelp;

  /// No description provided for @couldNotLoadFiScoreLibrary.
  ///
  /// In en, this message translates to:
  /// **'Could not load FiScore Library'**
  String get couldNotLoadFiScoreLibrary;

  /// No description provided for @pleaseTryAgainShortly.
  ///
  /// In en, this message translates to:
  /// **'Please try again shortly.'**
  String get pleaseTryAgainShortly;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @createdByYourTeam.
  ///
  /// In en, this message translates to:
  /// **'Created by your team'**
  String get createdByYourTeam;

  /// No description provided for @microLearning.
  ///
  /// In en, this message translates to:
  /// **'Micro-learning'**
  String get microLearning;

  /// No description provided for @minUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minUnit;

  /// No description provided for @updateAvailableInFiScoreLibrary.
  ///
  /// In en, this message translates to:
  /// **'Update available in FiScore Library'**
  String get updateAvailableInFiScoreLibrary;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @selectTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'Select {count} team member{pluralSuffix}'**
  String selectTeamMembers(Object count, Object pluralSuffix);

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @chooseTrainingItemToAssign.
  ///
  /// In en, this message translates to:
  /// **'Choose a training item to assign.'**
  String get chooseTrainingItemToAssign;

  /// No description provided for @chooseAtLeastOneTeammateToAssign.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one teammate to assign.'**
  String get chooseAtLeastOneTeammateToAssign;

  /// No description provided for @couldNotAssignTraining.
  ///
  /// In en, this message translates to:
  /// **'Could not assign training. Please try again.'**
  String get couldNotAssignTraining;

  /// No description provided for @forThisViolation.
  ///
  /// In en, this message translates to:
  /// **'For this violation'**
  String get forThisViolation;

  /// No description provided for @noActiveTrainingItems.
  ///
  /// In en, this message translates to:
  /// **'No active training items are available.'**
  String get noActiveTrainingItems;

  /// No description provided for @fixesReadyForReview.
  ///
  /// In en, this message translates to:
  /// **'Fixes ready for review'**
  String get fixesReadyForReview;

  /// No description provided for @myAssignedFixes.
  ///
  /// In en, this message translates to:
  /// **'My assigned fixes'**
  String get myAssignedFixes;

  /// No description provided for @myChecks.
  ///
  /// In en, this message translates to:
  /// **'My checks'**
  String get myChecks;

  /// No description provided for @myTraining.
  ///
  /// In en, this message translates to:
  /// **'My training'**
  String get myTraining;

  /// No description provided for @overdueTraining.
  ///
  /// In en, this message translates to:
  /// **'Overdue training'**
  String get overdueTraining;

  /// No description provided for @overdueChecks.
  ///
  /// In en, this message translates to:
  /// **'Overdue checks'**
  String get overdueChecks;

  /// No description provided for @actionInbox.
  ///
  /// In en, this message translates to:
  /// **'Action inbox'**
  String get actionInbox;

  /// No description provided for @reviewSubmittedFixesHelp.
  ///
  /// In en, this message translates to:
  /// **'Review submitted fixes and close the work loop.'**
  String get reviewSubmittedFixesHelp;

  /// No description provided for @completeAssignedFixesHelp.
  ///
  /// In en, this message translates to:
  /// **'Complete resolutions assigned to you.'**
  String get completeAssignedFixesHelp;

  /// No description provided for @continueChecksHelp.
  ///
  /// In en, this message translates to:
  /// **'Continue checks you started or were assigned.'**
  String get continueChecksHelp;

  /// No description provided for @completeAssignedCoachingHelp.
  ///
  /// In en, this message translates to:
  /// **'Complete the coaching assigned to you.'**
  String get completeAssignedCoachingHelp;

  /// No description provided for @followUpOverdueTrainingHelp.
  ///
  /// In en, this message translates to:
  /// **'Follow up on training that has passed its due date.'**
  String get followUpOverdueTrainingHelp;

  /// No description provided for @followUpOverdueChecksHelp.
  ///
  /// In en, this message translates to:
  /// **'Follow up on checks that have passed their due date.'**
  String get followUpOverdueChecksHelp;

  /// No description provided for @workNeedsAttentionHelp.
  ///
  /// In en, this message translates to:
  /// **'Work that needs your attention.'**
  String get workNeedsAttentionHelp;

  /// No description provided for @openSite.
  ///
  /// In en, this message translates to:
  /// **'Open site'**
  String get openSite;

  /// No description provided for @startACheck.
  ///
  /// In en, this message translates to:
  /// **'Start a check'**
  String get startACheck;

  /// No description provided for @chooseChecklistForSite.
  ///
  /// In en, this message translates to:
  /// **'Choose a checklist your team uses at this site.'**
  String get chooseChecklistForSite;

  /// No description provided for @addCuratedChecklistsHelp.
  ///
  /// In en, this message translates to:
  /// **'Add curated FiScore checklists to your team library.'**
  String get addCuratedChecklistsHelp;

  /// No description provided for @searchChecklists.
  ///
  /// In en, this message translates to:
  /// **'Search checklists'**
  String get searchChecklists;

  /// No description provided for @noChecklistsInMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'No checklists in My Library'**
  String get noChecklistsInMyLibrary;

  /// No description provided for @exploreChecklistLibraryHelp.
  ///
  /// In en, this message translates to:
  /// **'Explore FiScore Library to add a checklist your team can use.'**
  String get exploreChecklistLibraryHelp;

  /// No description provided for @askManagerToAddChecklist.
  ///
  /// In en, this message translates to:
  /// **'Ask a manager to add an internal checklist for this site.'**
  String get askManagerToAddChecklist;

  /// No description provided for @noMatchingChecklists.
  ///
  /// In en, this message translates to:
  /// **'No matching checklists'**
  String get noMatchingChecklists;

  /// No description provided for @reviewChecklist.
  ///
  /// In en, this message translates to:
  /// **'Review checklist'**
  String get reviewChecklist;

  /// No description provided for @submitCheck.
  ///
  /// In en, this message translates to:
  /// **'Submit check'**
  String get submitCheck;

  /// No description provided for @couldNotAddTraining.
  ///
  /// In en, this message translates to:
  /// **'Could not add this training. Please try again.'**
  String get couldNotAddTraining;

  /// No description provided for @trainingAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'Training assigned.'**
  String get trainingAssignedMessage;

  /// No description provided for @cancelTrainingAssignmentBody.
  ///
  /// In en, this message translates to:
  /// **'The team member will no longer be expected to complete this training. The assignment stays in history.'**
  String get cancelTrainingAssignmentBody;

  /// No description provided for @couldNotCancelTraining.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel training. Please try again.'**
  String get couldNotCancelTraining;

  /// No description provided for @noTrainingAssigned.
  ///
  /// In en, this message translates to:
  /// **'No training assigned'**
  String get noTrainingAssigned;

  /// No description provided for @assignedLearningWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Assigned learning will appear here.'**
  String get assignedLearningWillAppear;

  /// No description provided for @forManagers.
  ///
  /// In en, this message translates to:
  /// **'For managers'**
  String get forManagers;

  /// No description provided for @assignAndMonitorTrainingHelp.
  ///
  /// In en, this message translates to:
  /// **'Assign coaching and monitor completion.'**
  String get assignAndMonitorTrainingHelp;

  /// No description provided for @trainingUnavailableManagerHelp.
  ///
  /// In en, this message translates to:
  /// **'This assignment uses content that is not currently in My Library. Add its FiScore lesson, then reopen it or assign a new version.'**
  String get trainingUnavailableManagerHelp;

  /// No description provided for @trainingUnavailableStaffHelp.
  ///
  /// In en, this message translates to:
  /// **'This training is not available yet. Please contact your manager.'**
  String get trainingUnavailableStaffHelp;

  /// No description provided for @questionCheck.
  ///
  /// In en, this message translates to:
  /// **'{count} question check'**
  String questionCheck(Object count);

  /// No description provided for @assignedForFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Assigned for follow-up'**
  String get assignedForFollowUp;

  /// No description provided for @youWillCover.
  ///
  /// In en, this message translates to:
  /// **'You will cover'**
  String get youWillCover;

  /// No description provided for @assignedToName.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}.'**
  String assignedToName(Object name);

  /// No description provided for @watchRequiredVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch the required video to continue.'**
  String get watchRequiredVideo;

  /// No description provided for @quickCheck.
  ///
  /// In en, this message translates to:
  /// **'Quick check'**
  String get quickCheck;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @quickCheckProgress.
  ///
  /// In en, this message translates to:
  /// **'Quick check {current} of {total}'**
  String quickCheckProgress(Object current, Object total);

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check answer'**
  String get checkAnswer;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @trainingComplete.
  ///
  /// In en, this message translates to:
  /// **'Training complete'**
  String get trainingComplete;

  /// No description provided for @completedBy.
  ///
  /// In en, this message translates to:
  /// **'Completed by'**
  String get completedBy;

  /// No description provided for @topicsCovered.
  ///
  /// In en, this message translates to:
  /// **'Topics covered'**
  String get topicsCovered;

  /// No description provided for @quickCheckRecorded.
  ///
  /// In en, this message translates to:
  /// **'Quick check completed. This completion is recorded.'**
  String get quickCheckRecorded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
