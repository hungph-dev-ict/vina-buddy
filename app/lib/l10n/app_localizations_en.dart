// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Smart Inbox AI';

  @override
  String get authTagline =>
      'Personal Gmail triage powered by natural-language AI rules with safe, user-approved label actions.';

  @override
  String get zeroPermanentStorageTitle => 'Zero Permanent Storage';

  @override
  String get zeroPermanentStorageSubtitle =>
      'Full email bodies are never stored or logged.';

  @override
  String get labelsOnlyTitle => 'Labels Only';

  @override
  String get labelsOnlySubtitle => 'Never deletes, archives, or sends emails.';

  @override
  String get explicitApprovalTitle => 'Explicit Approval';

  @override
  String get explicitApprovalSubtitle =>
      'You preview and approve every action.';

  @override
  String get connectGmail => 'Connect Gmail (Google OAuth)';

  @override
  String get continueDevMode => 'Continue in Dev/Sandbox Mode';

  @override
  String get languageEn => 'English';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get selectLanguage => 'Language';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navBuildRule => 'Build Rule';

  @override
  String get navMyRules => 'My Rules';

  @override
  String get inboxFeedTitle => 'Inbox Feed';

  @override
  String get syncEmails => 'Sync Emails';

  @override
  String emailsSynced(int count) {
    return '$count emails synced';
  }

  @override
  String updatedTime(String time) {
    return 'Updated: $time';
  }

  @override
  String get noEmailsFound => 'No emails synced yet.';

  @override
  String get pullToRefreshHint =>
      'Tap sync or pull to fetch your recent inbox messages.';

  @override
  String userConnected(String email) {
    return 'User: $email';
  }

  @override
  String get disconnect => 'Disconnect';

  @override
  String get labels => 'Labels';

  @override
  String get ruleBuilderTitle => 'AI Rule Builder';

  @override
  String get describeRuleHint =>
      'Describe your inbox rule in plain English or Vietnamese:';

  @override
  String get ruleInputPlaceholder =>
      'e.g. Label all emails from substack.com as Newsletters';

  @override
  String get analyzeButton => 'Convert to Structured Rule';

  @override
  String get analyzingButton => 'Analyzing Intent...';

  @override
  String get presetNewsletters => 'Move newsletters to Newsletters label';

  @override
  String get presetShopping => 'Label emails from amazon.com as Shopping';

  @override
  String get presetSecurity => 'Label security alerts as Security';

  @override
  String get presetInvoices => 'Label receipts and invoices as Finance';

  @override
  String get generatedRulePreview => 'Generated Rule';

  @override
  String get ruleName => 'Rule Name';

  @override
  String get conditions => 'Conditions';

  @override
  String get targetActions => 'Target Actions';

  @override
  String confidenceLevel(int percent) {
    return 'Confidence: $percent%';
  }

  @override
  String get previewAndApply => 'Preview & Approve Emails';

  @override
  String uncertaintyWarning(int percent) {
    return 'AI confidence is low ($percent%). Please carefully inspect the rule and preview matches before applying.';
  }

  @override
  String get myRulesTitle => 'My Rules';

  @override
  String get refreshRules => 'Refresh Rules';

  @override
  String get noRulesConfigured => 'No rules configured yet.';

  @override
  String get noRulesSubtitle => 'Create your first rule using plain English.';

  @override
  String get createRuleButton => 'Create Rule';

  @override
  String get previewRule => 'Preview Rule';

  @override
  String get ruleActive => 'Active';

  @override
  String get ruleDisabled => 'Disabled';

  @override
  String get deleteRule => 'Delete Rule';

  @override
  String get deleteRuleConfirmTitle => 'Delete Rule';

  @override
  String get deleteRuleConfirmContent =>
      'Are you sure you want to delete this rule?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get previewTitle => 'Rule Match Preview';

  @override
  String get previewSubtitle =>
      'Review emails matching this rule before applying changes.';

  @override
  String matchedEmails(int count) {
    return 'Matched Emails ($count)';
  }

  @override
  String get noEmailsMatched => 'No emails matched this rule.';

  @override
  String approveAndApply(int count) {
    return 'Approve & Apply ($count)';
  }

  @override
  String get applyingChanges => 'Applying changes...';

  @override
  String get confirmApplyTitle => 'Confirm Label Application';

  @override
  String confirmApplyContent(int count) {
    return 'Apply labels to $count approved email(s)?\n\nNo emails will be deleted or sent.';
  }

  @override
  String get applySuccessTitle => 'Actions Applied';

  @override
  String applySuccessContent(int count) {
    return 'Successfully applied labels to $count email(s).';
  }

  @override
  String get close => 'Close';

  @override
  String get statusSuccess => 'Success';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String subjectPrefix(String subject) {
    return 'Subject: $subject';
  }

  @override
  String fromPrefix(String from) {
    return 'From: $from';
  }

  @override
  String get reportToAdmin => 'Report to Admin';

  @override
  String get reportToAdminTitle => 'Submit Report to Admin';

  @override
  String get reportToAdminDesc =>
      'This request is not currently supported. You can send a report to the admin for manual review.';

  @override
  String get reportInputLabel => 'Request content:';

  @override
  String get reportNotesLabel => 'Additional notes (optional):';

  @override
  String get reportNotesHint =>
      'Describe what you need or why you requested this...';

  @override
  String get reportSubmit => 'Submit Report';

  @override
  String get reportSubmitting => 'Submitting...';

  @override
  String get reportSuccess => 'Report submitted to admin successfully!';

  @override
  String get unsupportedContentNotice =>
      'This content cannot be supported, please submit a report to the admin.';

  @override
  String multipleRulesGenerated(int count) {
    return 'Separated into $count independent rules';
  }

  @override
  String ruleIndex(int index) {
    return 'Rule #$index';
  }
}
