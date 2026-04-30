import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_colors.dart';

enum UserNavSection {
  dashboard,
  sos,
  needGuidance,
  volunteers,
  community,
  chatbot,
  helpRequests,
  requests,
  assignments,
  completedWork,
  availability,
  profile,
  settings,
  knowCommunity,
}

class UserNavItem {
  final String label;
  final IconData icon;
  final UserNavSection section;
  final VoidCallback onTap;

  const UserNavItem({
    required this.label,
    required this.icon,
    required this.section,
    required this.onTap,
  });
}

class UserShellLayout extends StatelessWidget {
  final UserNavSection selectedSection;
  final String title;
  final String subtitle;
  final String userName;
  final String accountRole;
  final String statusText;
  final String supportHeadline;
  final String supportMessage;
  final IconData supportIcon;
  final VoidCallback? onBrandTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final VoidCallback? onBackTap;
  final List<UserNavItem> navItems;
  final Widget child;

  const UserShellLayout({
    super.key,
    required this.selectedSection,
    required this.title,
    required this.subtitle,
    required this.userName,
    this.accountRole = 'User',
    this.statusText = 'Stay Safe',
    this.supportHeadline = 'You are not alone.',
    this.supportMessage = 'Help is just a tap away.\nStay aware. Stay safe.',
    this.supportIcon = Icons.volunteer_activism_rounded,
    this.onBrandTap,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onLogout,
    this.onBackTap,
    required this.navItems,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 980;
        final brandTap =
            onBrandTap ?? (navItems.isNotEmpty ? navItems.first.onTap : null);
        final notificationsTap = onNotificationsTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            };

        if (!isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              automaticallyImplyLeading: onBackTap != null,
              leading: onBackTap != null 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: onBackTap,
                  )
                : null,
              title: Text(title),
              centerTitle: false,
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: notificationsTap,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                PopupMenuButton<_ProfileMenuAction>(
                  tooltip: 'Profile menu',
                  onSelected: (action) {
                    if (action == _ProfileMenuAction.profile) {
                      onProfileTap?.call();
                      return;
                    }
                    onLogout?.call();
                  },
                  itemBuilder: (context) => [
                    if (onProfileTap != null)
                      const PopupMenuItem(
                        value: _ProfileMenuAction.profile,
                        child: Text('View Profile'),
                      ),
                    if (onLogout != null)
                      const PopupMenuItem(
                        value: _ProfileMenuAction.logout,
                        child: Text('Logout'),
                      ),
                  ],
                ),
              ],
            ),
            drawer: Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    _BrandHeader(compact: true, onTap: brandTap),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: navItems
                            .map(
                              (item) => _NavTile(
                                item: item,
                                selected: selectedSection == item.section,
                                compact: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileProfile(
                      userName: userName,
                      statusText: statusText,
                      onNotificationsTap: notificationsTap,
                      onProfileTap: onProfileTap,
                      onLogout: onLogout,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    child,
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              _DesktopSidebar(
                navItems: navItems,
                selectedSection: selectedSection,
                supportHeadline: supportHeadline,
                supportMessage: supportMessage,
                supportIcon: supportIcon,
                onBrandTap: brandTap,
              ),
              Expanded(
                child: Column(
                  children: [
                    _DesktopTopbar(
                      userName: userName,
                      accountRole: accountRole,
                      statusText: statusText,
                      onNotificationsTap: notificationsTap,
                      onProfileTap: onProfileTap,
                      onLogout: onLogout,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(34, 28, 34, 44),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1140),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (onBackTap != null) ...[
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back, size: 32),
                                        onPressed: onBackTap,
                                        padding: EdgeInsets.zero,
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 46,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          height: 1.08,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShellActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const ShellActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width >= 1200 ? 24.0 : 20.0;
    final subtitleSize = width >= 1200 ? 16.0 : 14.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A111933),
                  blurRadius: 18,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: iconColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final List<UserNavItem> navItems;
  final UserNavSection selectedSection;
  final String supportHeadline;
  final String supportMessage;
  final IconData supportIcon;
  final VoidCallback? onBrandTap;

  const _DesktopSidebar({
    required this.navItems,
    required this.selectedSection,
    required this.supportHeadline,
    required this.supportMessage,
    required this.supportIcon,
    required this.onBrandTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _BrandHeader(compact: false, onTap: onBrandTap),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                children: navItems
                    .map(
                      (item) => _NavTile(
                        item: item,
                        selected: selectedSection == item.section,
                        compact: false,
                      ),
                    )
                    .toList(),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softPurple,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supportHeadline,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    supportMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    supportIcon,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopTopbar extends StatelessWidget {
  final String userName;
  final String accountRole;
  final String statusText;
  final VoidCallback onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const _DesktopTopbar({
    required this.userName,
    required this.accountRole,
    required this.statusText,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        userName.trim().isEmpty ? 'U' : userName.trim()[0].toUpperCase();
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onNotificationsTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 30,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Consumer<NotificationProvider>(
                      builder: (context, notif, child) {
                        if (notif.unreadCount == 0) return const SizedBox.shrink();
                        return Positioned(
                          right: -1,
                          top: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE11D48),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${notif.unreadCount}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Container(width: 1, height: 36, color: AppColors.border),
              const SizedBox(width: 18),
              PopupMenuButton<_ProfileMenuAction>(
                tooltip: 'Profile menu',
                onSelected: (action) {
                  if (action == _ProfileMenuAction.profile) {
                    onProfileTap?.call();
                    return;
                  }
                  onLogout?.call();
                },
                itemBuilder: (context) => [
                  if (onProfileTap != null)
                    const PopupMenuItem(
                      value: _ProfileMenuAction.profile,
                      child: Text('View Profile'),
                    ),
                  if (onLogout != null)
                    const PopupMenuItem(
                      value: _ProfileMenuAction.logout,
                      child: Text('Logout'),
                    ),
                ],
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accountRole,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool compact;
  final VoidCallback? onTap;

  const _BrandHeader({required this.compact, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(compact ? 14 : 22, compact ? 14 : 18, 16, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 52,
                height: compact ? 36 : 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF4527D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compact
                          ? 'Women Safety & Support'
                          : 'WOMEN SAFETY & SUPPORT',
                      style: TextStyle(
                        fontSize: compact ? 12 : 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: compact ? 0 : .2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Together, We Protect',
                      style: TextStyle(
                        fontSize: compact ? 11 : 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final UserNavItem item;
  final bool selected;
  final bool compact;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: selected ? AppColors.softPurple : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (compact) {
              Navigator.of(context).pop();
            }
            item.onTap();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 10 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: compact ? 20 : 24,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileProfile extends StatelessWidget {
  final String userName;
  final String statusText;
  final VoidCallback onNotificationsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;

  const _MobileProfile({
    required this.userName,
    required this.statusText,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        userName.trim().isEmpty ? 'U' : userName.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.trim().isEmpty ? 'User' : userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  statusText,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotificationsTap,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<NotificationProvider>(
                  builder: (context, notif, child) {
                    if (notif.unreadCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '${notif.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          PopupMenuButton<_ProfileMenuAction>(
            tooltip: 'Profile menu',
            onSelected: (action) {
              if (action == _ProfileMenuAction.profile) {
                onProfileTap?.call();
                return;
              }
              onLogout?.call();
            },
            itemBuilder: (context) => [
              if (onProfileTap != null)
                const PopupMenuItem(
                  value: _ProfileMenuAction.profile,
                  child: Text('View Profile'),
                ),
              if (onLogout != null)
                const PopupMenuItem(
                  value: _ProfileMenuAction.logout,
                  child: Text('Logout'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ProfileMenuAction { profile, logout }
