import 'package:flutter/material.dart';

class MentorSidebarShell extends StatelessWidget {
  final String activeMenuTitle;
  final Widget child;
  final void Function(String title) onMenuTap;

  const MentorSidebarShell({
    super.key,
    required this.activeMenuTitle,
    required this.child,
    required this.onMenuTap,
  });

  static const Color _sidebarBg = Color(0xFFF8FAFD);
  static const Color _sidebarBorder = Color(0xFFDDE4F0);
  static const Color _sidebarActive = Color(0xFF2A58F2);

  static const List<_SidebarMenuItem> _menuItems = [
    _SidebarMenuItem(title: 'Dashboard', icon: Icons.home_outlined),
    _SidebarMenuItem(
      title: 'Jadwal Mengajar',
      icon: Icons.calendar_month_outlined,
    ),
    _SidebarMenuItem(title: 'Absensi Kelas', icon: Icons.fact_check_outlined),
    _SidebarMenuItem(title: 'Soal Latihan', icon: Icons.menu_book_outlined),
    _SidebarMenuItem(title: 'Try Out', icon: Icons.rocket_launch_outlined),
    _SidebarMenuItem(
      title: 'Materi Pembelajaran',
      icon: Icons.video_library_outlined,
    ),
    _SidebarMenuItem(
      title: 'Olimpiade Akademik',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 820;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile
          ? Drawer(child: _buildSidebar(context, forDrawer: true))
          : null,
      body: SafeArea(
        child: isMobile
            ? child
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(context, forDrawer: false),
                  Expanded(child: child),
                ],
              ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool forDrawer}) {
    return Container(
      width: forDrawer ? double.infinity : 232,
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _sidebarBorder)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Image.asset('assets/images/BMC .png'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'BMC Mentor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _menuItems.map((item) {
                final active = item.title == activeMenuTitle;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: InkWell(
                    onTap: () {
                      if (forDrawer) {
                        Navigator.of(context).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onMenuTap(item.title);
                        });
                        return;
                      }
                      onMenuTap(item.title);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: active ? _sidebarActive : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 19,
                            color: active
                                ? Colors.white
                                : const Color(0xFF5B6578),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem {
  final String title;
  final IconData icon;

  const _SidebarMenuItem({required this.title, required this.icon});
}
