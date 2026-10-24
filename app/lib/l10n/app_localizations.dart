import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'vnverse'**
  String get appName;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Personal Gmail triage powered by natural-language AI rules with safe, user-approved label actions.'**
  String get authTagline;

  /// No description provided for @zeroPermanentStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero Permanent Storage'**
  String get zeroPermanentStorageTitle;

  /// No description provided for @zeroPermanentStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full email bodies are never stored or logged.'**
  String get zeroPermanentStorageSubtitle;

  /// No description provided for @labelsOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Labels Only'**
  String get labelsOnlyTitle;

  /// No description provided for @labelsOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never deletes, archives, or sends emails.'**
  String get labelsOnlySubtitle;

  /// No description provided for @explicitApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Explicit Approval'**
  String get explicitApprovalTitle;

  /// No description provided for @explicitApprovalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You preview and approve every action.'**
  String get explicitApprovalSubtitle;

  /// No description provided for @connectGmail.
  ///
  /// In en, this message translates to:
  /// **'Connect Gmail (Google OAuth)'**
  String get connectGmail;

  /// No description provided for @continueDevMode.
  ///
  /// In en, this message translates to:
  /// **'Continue in Dev/Sandbox Mode'**
  String get continueDevMode;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageVi.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVi;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get selectLanguage;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navBuildRule.
  ///
  /// In en, this message translates to:
  /// **'Build Rule'**
  String get navBuildRule;

  /// No description provided for @navMyRules.
  ///
  /// In en, this message translates to:
  /// **'My Rules'**
  String get navMyRules;

  /// No description provided for @inboxFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox Feed'**
  String get inboxFeedTitle;

  /// No description provided for @syncEmails.
  ///
  /// In en, this message translates to:
  /// **'Sync Emails'**
  String get syncEmails;

  /// No description provided for @emailsSynced.
  ///
  /// In en, this message translates to:
  /// **'{count} emails synced'**
  String emailsSynced(int count);

  /// No description provided for @updatedTime.
  ///
  /// In en, this message translates to:
  /// **'Updated: {time}'**
  String updatedTime(String time);

  /// No description provided for @noEmailsFound.
  ///
  /// In en, this message translates to:
  /// **'No emails synced yet.'**
  String get noEmailsFound;

  /// No description provided for @pullToRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Tap sync or pull to fetch your recent inbox messages.'**
  String get pullToRefreshHint;

  /// No description provided for @userConnected.
  ///
  /// In en, this message translates to:
  /// **'User: {email}'**
  String userConnected(String email);

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labels;

  /// No description provided for @ruleBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Rule Builder'**
  String get ruleBuilderTitle;

  /// No description provided for @describeRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your inbox rule in plain English or Vietnamese:'**
  String get describeRuleHint;

  /// No description provided for @ruleInputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Label all emails from substack.com as Newsletters'**
  String get ruleInputPlaceholder;

  /// No description provided for @analyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Convert to Structured Rule'**
  String get analyzeButton;

  /// No description provided for @analyzingButton.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Intent...'**
  String get analyzingButton;

  /// No description provided for @presetNewsletters.
  ///
  /// In en, this message translates to:
  /// **'Move newsletters to Newsletters label'**
  String get presetNewsletters;

  /// No description provided for @presetShopping.
  ///
  /// In en, this message translates to:
  /// **'Label emails from amazon.com as Shopping'**
  String get presetShopping;

  /// No description provided for @presetSecurity.
  ///
  /// In en, this message translates to:
  /// **'Label security alerts as Security'**
  String get presetSecurity;

  /// No description provided for @presetInvoices.
  ///
  /// In en, this message translates to:
  /// **'Label receipts and invoices as Finance'**
  String get presetInvoices;

  /// No description provided for @generatedRulePreview.
  ///
  /// In en, this message translates to:
  /// **'Generated Rule'**
  String get generatedRulePreview;

  /// No description provided for @ruleName.
  ///
  /// In en, this message translates to:
  /// **'Rule Name'**
  String get ruleName;

  /// No description provided for @conditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// No description provided for @targetActions.
  ///
  /// In en, this message translates to:
  /// **'Target Actions'**
  String get targetActions;

  /// No description provided for @confidenceLevel.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {percent}%'**
  String confidenceLevel(int percent);

  /// No description provided for @previewAndApply.
  ///
  /// In en, this message translates to:
  /// **'Preview & Approve Emails'**
  String get previewAndApply;

  /// No description provided for @uncertaintyWarning.
  ///
  /// In en, this message translates to:
  /// **'AI confidence is low ({percent}%). Please carefully inspect the rule and preview matches before applying.'**
  String uncertaintyWarning(int percent);

  /// No description provided for @myRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Rules'**
  String get myRulesTitle;

  /// No description provided for @refreshRules.
  ///
  /// In en, this message translates to:
  /// **'Refresh Rules'**
  String get refreshRules;

  /// No description provided for @noRulesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No rules configured yet.'**
  String get noRulesConfigured;

  /// No description provided for @noRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first rule using plain English.'**
  String get noRulesSubtitle;

  /// No description provided for @createRuleButton.
  ///
  /// In en, this message translates to:
  /// **'Create Rule'**
  String get createRuleButton;

  /// No description provided for @previewRule.
  ///
  /// In en, this message translates to:
  /// **'Preview Rule'**
  String get previewRule;

  /// No description provided for @ruleActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get ruleActive;

  /// No description provided for @ruleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get ruleDisabled;

  /// No description provided for @deleteRule.
  ///
  /// In en, this message translates to:
  /// **'Delete Rule'**
  String get deleteRule;

  /// No description provided for @deleteRuleConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Rule'**
  String get deleteRuleConfirmTitle;

  /// No description provided for @deleteRuleConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this rule?'**
  String get deleteRuleConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Rule Match Preview'**
  String get previewTitle;

  /// No description provided for @previewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review emails matching this rule before applying changes.'**
  String get previewSubtitle;

  /// No description provided for @matchedEmails.
  ///
  /// In en, this message translates to:
  /// **'Matched Emails ({count})'**
  String matchedEmails(int count);

  /// No description provided for @noEmailsMatched.
  ///
  /// In en, this message translates to:
  /// **'No emails matched this rule.'**
  String get noEmailsMatched;

  /// No description provided for @approveAndApply.
  ///
  /// In en, this message translates to:
  /// **'Approve & Apply ({count})'**
  String approveAndApply(int count);

  /// No description provided for @applyingChanges.
  ///
  /// In en, this message translates to:
  /// **'Applying changes...'**
  String get applyingChanges;

  /// No description provided for @confirmApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Label Application'**
  String get confirmApplyTitle;

  /// No description provided for @confirmApplyContent.
  ///
  /// In en, this message translates to:
  /// **'Apply labels to {count} approved email(s)?\n\nNo emails will be deleted or sent.'**
  String confirmApplyContent(int count);

  /// No description provided for @applySuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions Applied'**
  String get applySuccessTitle;

  /// No description provided for @applySuccessContent.
  ///
  /// In en, this message translates to:
  /// **'Successfully applied labels to {count} email(s).'**
  String applySuccessContent(int count);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @statusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get statusSuccess;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @subjectPrefix.
  ///
  /// In en, this message translates to:
  /// **'Subject: {subject}'**
  String subjectPrefix(String subject);

  /// No description provided for @fromPrefix.
  ///
  /// In en, this message translates to:
  /// **'From: {from}'**
  String fromPrefix(String from);

  /// No description provided for @reportToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Report to Admin'**
  String get reportToAdmin;

  /// No description provided for @reportToAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Report to Admin'**
  String get reportToAdminTitle;

  /// No description provided for @reportToAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'This request is not currently supported. You can send a report to the admin for manual review.'**
  String get reportToAdminDesc;

  /// No description provided for @reportInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Request content:'**
  String get reportInputLabel;

  /// No description provided for @reportNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional):'**
  String get reportNotesLabel;

  /// No description provided for @reportNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need or why you requested this...'**
  String get reportNotesHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get reportSubmitting;

  /// No description provided for @reportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted to admin successfully!'**
  String get reportSuccess;

  /// No description provided for @unsupportedContentNotice.
  ///
  /// In en, this message translates to:
  /// **'This content cannot be supported, please submit a report to the admin.'**
  String get unsupportedContentNotice;

  /// No description provided for @multipleRulesGenerated.
  ///
  /// In en, this message translates to:
  /// **'Separated into {count} independent rules'**
  String multipleRulesGenerated(int count);

  /// No description provided for @ruleIndex.
  ///
  /// In en, this message translates to:
  /// **'Rule #{index}'**
  String ruleIndex(int index);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterLabeled.
  ///
  /// In en, this message translates to:
  /// **'With Labels'**
  String get filterLabeled;

  /// No description provided for @filterStarred.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get filterStarred;

  /// No description provided for @newRuleAction.
  ///
  /// In en, this message translates to:
  /// **'New Rule'**
  String get newRuleAction;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'VinaBuddy Assistant'**
  String get assistantTitle;

  /// No description provided for @assistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Email AI Companion'**
  String get assistantSubtitle;

  /// No description provided for @assistantWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am VinaBuddy, your email AI assistant. I can help you with Email Statistics, Email Classification, and Auto-Labeling.'**
  String get assistantWelcome;

  /// No description provided for @actionStats.
  ///
  /// In en, this message translates to:
  /// **'Email Stats'**
  String get actionStats;

  /// No description provided for @actionClassify.
  ///
  /// In en, this message translates to:
  /// **'Classify Emails'**
  String get actionClassify;

  /// No description provided for @actionLabel.
  ///
  /// In en, this message translates to:
  /// **'Label Emails'**
  String get actionLabel;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask VinaBuddy to stats, classify, or label...'**
  String get chatInputHint;

  /// No description provided for @statsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox Overview'**
  String get statsSummaryTitle;

  /// No description provided for @totalEmails.
  ///
  /// In en, this message translates to:
  /// **'Total emails'**
  String get totalEmails;

  /// No description provided for @unreadEmails.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unreadEmails;

  /// No description provided for @topSenders.
  ///
  /// In en, this message translates to:
  /// **'Top Senders'**
  String get topSenders;

  /// No description provided for @categoriesOverview.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesOverview;

  /// No description provided for @classificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Classification'**
  String get classificationTitle;

  /// No description provided for @proposalTitle.
  ///
  /// In en, this message translates to:
  /// **'Labeling Proposal'**
  String get proposalTitle;

  /// No description provided for @approveAndApplyBtn.
  ///
  /// In en, this message translates to:
  /// **'Approve & Apply'**
  String get approveAndApplyBtn;

  /// No description provided for @appliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Label applied successfully!'**
  String get appliedSuccessfully;

  /// No description provided for @navAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get navAssistant;

  /// No description provided for @navPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get navPersonal;

  /// No description provided for @personalTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Profile'**
  String get personalTitle;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Connected Account'**
  String get accountSection;

  /// No description provided for @statusSandbox.
  ///
  /// In en, this message translates to:
  /// **'Dev / Sandbox Mode'**
  String get statusSandbox;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Google OAuth Connected'**
  String get statusConnected;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Display Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @privacySection.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySection;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Zero permanent storage • Read & label only • Explicit approval'**
  String get privacySubtitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Vina Buddy v1.0.0 (PoC)'**
  String get appVersionLabel;

  /// No description provided for @disconnectAccount.
  ///
  /// In en, this message translates to:
  /// **'Log Out / Disconnect'**
  String get disconnectAccount;

  /// No description provided for @disconnectConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Account?'**
  String get disconnectConfirmTitle;

  /// No description provided for @disconnectConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the onboarding screen.'**
  String get disconnectConfirmMsg;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
