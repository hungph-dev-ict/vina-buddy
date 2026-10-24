import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_inbox_ai/models/email_item.dart';
import 'package:smart_inbox_ai/theme/app_colors.dart';
import 'package:smart_inbox_ai/theme/app_spacing.dart';
import 'package:smart_inbox_ai/widgets/app_badge.dart';

/// Platform-adaptive email list item card:
/// - Android: Material 3 container with sender initials avatar, ripple feedback, M3 typography.
/// - iOS: Apple HIG grouped list tile with unread dot indicator, chevron disclosure, and SF-style typography.
class EmailCard extends StatelessWidget {
  final EmailItem email;
  final VoidCallback? onTap;
  final bool? isIosOverride;

  const EmailCard({
    super.key,
    required this.email,
    this.onTap,
    this.isIosOverride,
  });

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final hour = dt.hour.toString().padLeft(2, '0');
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }
      return '${_monthName(dt.month)} ${dt.day}';
    } catch (_) {
      if (rawDate.length >= 10) {
        return rawDate.substring(5, 10);
      }
      return rawDate;
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _getInitials() {
    if (email.fromName.isNotEmpty) {
      final parts = email.fromName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return email.fromName[0].toUpperCase();
    }
    if (email.fromEmail.isNotEmpty) {
      return email.fromEmail[0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIos =
        isIosOverride ?? (Theme.of(context).platform == TargetPlatform.iOS);
    final displayName = email.fromName.isNotEmpty
        ? email.fromName
        : email.fromEmail;
    final formattedDate = _formatDate(email.date);
    final isUnread = email.labels.contains('UNREAD');

    if (isIos) {
      return _buildIosRow(
        context,
        isDark,
        displayName,
        formattedDate,
        isUnread,
      );
    }

    return _buildMaterialCard(
      context,
      isDark,
      displayName,
      formattedDate,
      isUnread,
    );
  }

  Widget _buildIosRow(
    BuildContext context,
    bool isDark,
    String displayName,
    String formattedDate,
    bool isUnread,
  ) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF000000);
    final secondaryTextColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      pressedOpacity: 0.65,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // iOS unread indicator dot
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: SizedBox(
                width: 10,
                height: 10,
                child: isUnread
                    ? Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF007AFF),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ),

            // Main Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Sender Name + Timestamp + Chevron
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontFamily: '.SF Pro Text',
                            fontSize: 15,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: primaryTextColor,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 13,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isUnread
                              ? const Color(0xFF007AFF)
                              : secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        size: 13,
                        color: secondaryTextColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Email Subject
                  Text(
                    email.subject,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                      color: primaryTextColor.withValues(alpha: 0.95),
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Snippet
                  if (email.snippet.isNotEmpty)
                    Text(
                      email.snippet,
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 13,
                        color: secondaryTextColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Labels
                  if (email.labels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: email.labels.map((lbl) {
                        return AppBadge(label: lbl);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(
    BuildContext context,
    bool isDark,
    String displayName,
    String formattedDate,
    bool isUnread,
  ) {
    final initials = _getInitials();

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedSm,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender Avatar with M3 container styling
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.35)
                      : AppColors.primaryLight.withValues(alpha: 0.25),
                  width: 1.4,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.primaryDark
                        : AppColors.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Sender Name + Timestamp
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Sender Email
                  Text(
                    email.fromEmail,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Email Subject
                  Text(
                    email.subject,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Snippet
                  if (email.snippet.isNotEmpty)
                    Text(
                      email.snippet,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Labels
                  if (email.labels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: email.labels.map((lbl) {
                        return AppBadge(label: lbl);
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
