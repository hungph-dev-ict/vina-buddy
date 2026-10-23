// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Smart Inbox AI';

  @override
  String get authTagline =>
      'Trợ lý phân loại Gmail cá nhân bằng quy tắc AI ngôn ngữ tự nhiên, gắn nhãn an toàn có người dùng phê duyệt.';

  @override
  String get zeroPermanentStorageTitle => 'Không lưu trữ vĩnh viễn';

  @override
  String get zeroPermanentStorageSubtitle =>
      'Nội dung email không bao giờ bị lưu trữ hay ghi log trên máy chủ.';

  @override
  String get labelsOnlyTitle => 'Chỉ thao tác gắn nhãn';

  @override
  String get labelsOnlySubtitle =>
      'Tuyệt đối không xoá, không lưu trữ (archive), không gửi email.';

  @override
  String get explicitApprovalTitle => 'Cần bạn phê duyệt';

  @override
  String get explicitApprovalSubtitle =>
      'Bạn luôn xem trước và xác nhận từng hành động trước khi áp dụng.';

  @override
  String get connectGmail => 'Kết nối Gmail (Google OAuth)';

  @override
  String get continueDevMode => 'Tiếp tục ở chế độ Thử nghiệm / Sandbox';

  @override
  String get languageEn => 'English';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get selectLanguage => 'Ngôn ngữ';

  @override
  String get navInbox => 'Hộp thư';

  @override
  String get navBuildRule => 'Tạo quy tắc';

  @override
  String get navMyRules => 'Quy tắc của tôi';

  @override
  String get inboxFeedTitle => 'Hộp thư đến';

  @override
  String get syncEmails => 'Đồng bộ Email';

  @override
  String emailsSynced(int count) {
    return 'Đã đồng bộ $count email';
  }

  @override
  String updatedTime(String time) {
    return 'Cập nhật lúc: $time';
  }

  @override
  String get noEmailsFound => 'Chưa có email nào được đồng bộ.';

  @override
  String get pullToRefreshHint =>
      'Nhấn nút đồng bộ hoặc vuốt xuống để tải email mới nhất.';

  @override
  String userConnected(String email) {
    return 'Tài khoản: $email';
  }

  @override
  String get disconnect => 'Ngắt kết nối';

  @override
  String get labels => 'Nhãn';

  @override
  String get ruleBuilderTitle => 'Tạo quy tắc AI';

  @override
  String get describeRuleHint =>
      'Mô tả quy tắc hộp thư của bạn bằng tiếng Việt hoặc tiếng Anh:';

  @override
  String get ruleInputPlaceholder =>
      'Ví dụ: Gán nhãn tất cả email từ shopee.vn là Mua sắm';

  @override
  String get analyzeButton => 'Chuyển thành quy tắc có cấu trúc';

  @override
  String get analyzingButton => 'Đang phân tích ý định...';

  @override
  String get presetNewsletters => 'Chuyển các bản tin vào nhãn Newsletters';

  @override
  String get presetShopping =>
      'Gán nhãn email từ shopee.vn hoặc lazada là Mua sắm';

  @override
  String get presetSecurity => 'Gán nhãn cảnh báo bảo mật là Security';

  @override
  String get presetInvoices => 'Gán nhãn hoá đơn và biên lai là Tài chính';

  @override
  String get generatedRulePreview => 'Quy tắc được tạo';

  @override
  String get ruleName => 'Tên quy tắc';

  @override
  String get conditions => 'Điều kiện';

  @override
  String get targetActions => 'Hành động thực hiện';

  @override
  String confidenceLevel(int percent) {
    return 'Độ tin cậy: $percent%';
  }

  @override
  String get previewAndApply => 'Xem trước & Phê duyệt Email';

  @override
  String uncertaintyWarning(int percent) {
    return 'Độ tin cậy AI thấp ($percent%). Vui lòng kiểm tra kỹ quy tắc và xem trước các email khớp trước khi áp dụng.';
  }

  @override
  String get myRulesTitle => 'Quy tắc của tôi';

  @override
  String get refreshRules => 'Làm mới quy tắc';

  @override
  String get noRulesConfigured => 'Chưa có quy tắc nào được thiết lập.';

  @override
  String get noRulesSubtitle =>
      'Tạo quy tắc đầu tiên của bạn bằng ngôn ngữ tự nhiên.';

  @override
  String get createRuleButton => 'Tạo quy tắc';

  @override
  String get previewRule => 'Xem trước';

  @override
  String get ruleActive => 'Đang bật';

  @override
  String get ruleDisabled => 'Đang tắt';

  @override
  String get deleteRule => 'Xoá quy tắc';

  @override
  String get deleteRuleConfirmTitle => 'Xác nhận xoá';

  @override
  String get deleteRuleConfirmContent =>
      'Bạn có chắc chắn muốn xoá quy tắc này không?';

  @override
  String get cancel => 'Huỷ';

  @override
  String get delete => 'Xoá';

  @override
  String get previewTitle => 'Xem trước khớp quy tắc';

  @override
  String get previewSubtitle =>
      'Kiểm tra danh sách email khớp trước khi thực hiện gắn nhãn.';

  @override
  String matchedEmails(int count) {
    return 'Email trùng khớp ($count)';
  }

  @override
  String get noEmailsMatched => 'Không có email nào khớp với quy tắc này.';

  @override
  String approveAndApply(int count) {
    return 'Phê duyệt & Áp dụng ($count)';
  }

  @override
  String get applyingChanges => 'Đang áp dụng thay đổi...';

  @override
  String get confirmApplyTitle => 'Xác nhận gắn nhãn';

  @override
  String confirmApplyContent(int count) {
    return 'Áp dụng nhãn cho $count email đã phê duyệt?\n\nKhông có email nào bị xoá hoặc gửi đi.';
  }

  @override
  String get applySuccessTitle => 'Đã áp dụng thành công';

  @override
  String applySuccessContent(int count) {
    return 'Đã gắn nhãn thành công cho $count email.';
  }

  @override
  String get close => 'Đóng';

  @override
  String get statusSuccess => 'Thành công';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get deselectAll => 'Bỏ chọn tất cả';

  @override
  String subjectPrefix(String subject) {
    return 'Tiêu đề: $subject';
  }

  @override
  String fromPrefix(String from) {
    return 'Người gửi: $from';
  }

  @override
  String get reportToAdmin => 'Khiếu nại tới Admin';

  @override
  String get reportToAdminTitle => 'Gửi khiếu nại tới Admin';

  @override
  String get reportToAdminDesc =>
      'Nội dung yêu cầu của bạn hiện chưa được hỗ trợ xử lý. Bạn có thể gửi khiếu nại để admin kiểm tra thủ công.';

  @override
  String get reportInputLabel => 'Nội dung yêu cầu:';

  @override
  String get reportNotesLabel => 'Ghi chú thêm (tuỳ chọn):';

  @override
  String get reportNotesHint => 'Mô tả mong muốn của bạn...';

  @override
  String get reportSubmit => 'Gửi khiếu nại';

  @override
  String get reportSubmitting => 'Đang gửi...';

  @override
  String get reportSuccess => 'Đã gửi khiếu nại tới Admin thành công!';

  @override
  String get unsupportedContentNotice =>
      'Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin.';

  @override
  String multipleRulesGenerated(int count) {
    return 'Đã tách thành $count quy tắc độc lập';
  }

  @override
  String ruleIndex(int index) {
    return 'Quy tắc #$index';
  }
}
