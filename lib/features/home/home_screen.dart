import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_settings.dart';
import '../../app/app_strings.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();
  final TextEditingController promptCtrl = TextEditingController();

  final List<String> searchHistory = [
    'Best laptop under \$1000',
    'Affordable iPhone with good battery',
    'Best headphones for studying',
    'Gaming mouse under \$50',
    'Best smartwatch for fitness',
    'Cheap tablet for note taking',
  ];

  int selectedHistoryIndex = 0;

  @override
  void dispose() {
    promptCtrl.dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final text = promptCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      searchHistory.insert(0, text);
      selectedHistoryIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $text')),
    );

    promptCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final width = MediaQuery.of(context).size.width;
    final showPermanentSidebar = width >= 900;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pageBg = theme.scaffoldBackgroundColor;
    final sidebarBg = isDark ? const Color(0xFF111118) : const Color(0xFFF5F6FA);
    final panelBg = isDark ? const Color(0xFF12121A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF181821) : const Color(0xFFF4F5F9);
    final borderColor =
        isDark ? const Color(0xFF232331) : const Color(0xFFD9DCE5);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor =
        isDark ? Colors.white.withValues(alpha: 0.68) : Colors.black54;
    const accent = Color(0xFFFF5A52);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final fullName =
            data?['name'] ?? user.displayName ?? user.email ?? 'User';
        final email = data?['email'] ?? user.email ?? 'No email';

        return Scaffold(
          backgroundColor: pageBg,
          drawer: showPermanentSidebar
              ? null
              : Drawer(
                  backgroundColor: sidebarBg,
                  child: SafeArea(
                    child: _SidebarContent(
                      fullName: fullName,
                      email: email,
                      history: searchHistory,
                      selectedIndex: selectedHistoryIndex,
                      panelBg: panelBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                      onSelect: (index) {
                        setState(() {
                          selectedHistoryIndex = index;
                          promptCtrl.text = searchHistory[index];
                        });
                        Navigator.pop(context);
                      },
                      onOpenSettings: () {
                        Navigator.pop(context);
                        _showSettingsSheet(
                          context,
                          fullName: fullName,
                          email: email,
                        );
                      },
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (showPermanentSidebar)
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: sidebarBg,
                      border: Border(
                        right: BorderSide(color: borderColor),
                      ),
                    ),
                    child: _SidebarContent(
                      fullName: fullName,
                      email: email,
                      history: searchHistory,
                      selectedIndex: selectedHistoryIndex,
                      panelBg: panelBg,
                      borderColor: borderColor,
                      titleColor: titleColor,
                      subColor: subColor,
                      onSelect: (index) {
                        setState(() {
                          selectedHistoryIndex = index;
                          promptCtrl.text = searchHistory[index];
                        });
                      },
                      onOpenSettings: () {
                        _showSettingsSheet(
                          context,
                          fullName: fullName,
                          email: email,
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: _MainArea(
                    fullName: fullName,
                    promptCtrl: promptCtrl,
                    onSubmit: _submitPrompt,
                    showMenuButton: !showPermanentSidebar,
                    panelBg: panelBg,
                    borderColor: borderColor,
                    titleColor: titleColor,
                    subColor: subColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsSheet(
    BuildContext context, {
    required String fullName,
    required String email,
  }) {
    final settings = context.read<AppSettings>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF111118) : Colors.white;
    final card = isDark ? const Color(0xFF181821) : const Color(0xFFF4F5F9);
    final border = isDark ? const Color(0xFF232331) : const Color(0xFFD9DCE5);
    final text = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;
    const accent = Color(0xFFFF5A52);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedLanguage =
                context.watch<AppSettings>().languageLabel;
            final selectedAppearance =
                context.watch<AppSettings>().appearanceLabel;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.55,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: text.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppStrings.t(context, 'settings'),
                          style: TextStyle(
                            color: text,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _settingsTile(
                          title: AppStrings.t(context, 'full_name'),
                          value: fullName,
                          bg: card,
                          border: border,
                          titleColor: subText,
                          valueColor: text,
                        ),
                        _settingsTile(
                          title: AppStrings.t(context, 'email'),
                          value: email,
                          bg: card,
                          border: border,
                          titleColor: subText,
                          valueColor: text,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.t(context, 'language'),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _settingsChoice(
                          value: selectedLanguage,
                          options: const ['English', 'French', 'Spanish'],
                          bg: card,
                          border: border,
                          textColor: text,
                          onChanged: (value) {
                            settings.setLanguage(value);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.t(context, 'appearance'),
                          style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _settingsChoice(
                          value: selectedAppearance,
                          options: const ['Dark', 'Light', 'System'],
                          bg: card,
                          border: border,
                          textColor: text,
                          onChanged: (value) {
                            settings.setAppearance(value);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              await authService.signOut();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: text,
                              side: const BorderSide(color: accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: Text(
                              AppStrings.t(context, 'logout'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _settingsTile({
    required String title,
    required String value,
    required Color bg,
    required Color border,
    required Color titleColor,
    required Color valueColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsChoice({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    required Color bg,
    required Color border,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: bg,
          iconEnabledColor: textColor,
          style: TextStyle(color: textColor, fontSize: 16),
          items: options
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

class _SidebarContent extends StatelessWidget {
  final String fullName;
  final String email;
  final List<String> history;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenSettings;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;

  const _SidebarContent({
    required this.fullName,
    required this.email,
    required this.history,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenSettings,
    required this.panelBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5A52);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ClawCart',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.edit_square, color: subColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              readOnly: true,
              style: TextStyle(color: titleColor),
              decoration: InputDecoration(
                hintText: 'Search history',
                hintStyle: TextStyle(color: subColor),
                prefixIcon: Icon(Icons.search, color: subColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final active = index == selectedIndex;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: active ? panelBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? borderColor : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        color: subColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          history[index],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenSettings,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFFA000),
                    child: Text(
                      _initials(fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.settings, color: subColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _MainArea extends StatelessWidget {
  final String fullName;
  final TextEditingController promptCtrl;
  final VoidCallback onSubmit;
  final bool showMenuButton;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;

  const _MainArea({
    required this.fullName,
    required this.promptCtrl,
    required this.onSubmit,
    required this.showMenuButton,
    required this.panelBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5A52);

    return Column(
      children: [
        Builder(
          builder: (context) => Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                if (showMenuButton)
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: Icon(Icons.menu, color: titleColor),
                  ),
                Expanded(
                  child: Text(
                    'ClawCart',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.t(context, 'welcome')} $fullName',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tell ClawCart what you want, and it will help you compare and rank the best options.',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: accent),
                              const SizedBox(width: 10),
                              Text(
                                AppStrings.t(context, 'what_shopping_for'),
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: promptCtrl,
                            maxLines: 6,
                            minLines: 4,
                            style: TextStyle(color: titleColor),
                            decoration: InputDecoration(
                              hintText:
                                  'Example: Best laptop under \$1000 with good battery life and strong performance',
                              hintStyle: TextStyle(color: subColor),
                              filled: true,
                              fillColor: panelBg,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: accent,
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.search),
                              label: const Text(
                                'Find best options',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.t(context, 'how_clawcart_helps'),
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _infoRow(
                            'Understands your budget and preferences',
                            subColor,
                          ),
                          _infoRow(
                            'Compares products intelligently',
                            subColor,
                          ),
                          _infoRow(
                            'Ranks the best choices for you',
                            subColor,
                          ),
                          _infoRow(
                            'Prepares a smart checkout summary',
                            subColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String text, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFFFF5A52),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: subColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}