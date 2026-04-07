import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_settings.dart';
import '../../app/app_strings.dart';
import '../../services/api_service.dart';
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
  bool isLoading = false;
  Map<String, dynamic>? aiResult;
  String? aiError;

  @override
  void dispose() {
    promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPrompt() async {
    final text = promptCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (!searchHistory.contains(text)) {
        searchHistory.insert(0, text);
      } else {
        searchHistory.remove(text);
        searchHistory.insert(0, text);
      }
      selectedHistoryIndex = 0;
      isLoading = true;
      aiResult = null;
      aiError = null;
    });

    try {
      final response = await ApiService.getRecommendation(text);

      if (!mounted) return;

      setState(() {
        isLoading = false;
        final result = response['result'];
        if (result is Map<String, dynamic>) {
          aiResult = result;
        } else {
          aiError = 'Invalid response format';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
       aiError = 'AI is temporarily unavailable. Please try again later.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
    final borderColor =
        isDark ? const Color(0xFF232331) : const Color(0xFFD9DCE5);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor =
        isDark ? Colors.white.withValues(alpha: 0.68) : Colors.black54;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final fullName =
            (data?['name'] ?? user.displayName ?? user.email ?? 'User')
                .toString();
        final email =
            (data?['email'] ?? user.email ?? 'No email').toString();

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
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
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
                          isLoading: isLoading,
                          aiResult: aiResult,
                          aiError: aiError,
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
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedLanguage = context.watch<AppSettings>().languageLabel;
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
                        const SizedBox(height: 16),
                        _actionTile(
                          title: AppStrings.t(context, 'help'),
                          subtitle: AppStrings.t(context, 'help_subtitle'),
                          bg: card,
                          border: border,
                          titleColor: text,
                          subColor: subText,
                          icon: Icons.help_outline,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HelpPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.pop(sheetContext);
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
            softWrap: true,
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
          isExpanded: true,
          dropdownColor: bg,
          iconEnabledColor: textColor,
          style: TextStyle(color: textColor, fontSize: 16),
          items: options
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
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

  Widget _actionTile({
    required String title,
    required String subtitle,
    required Color bg,
    required Color border,
    required Color titleColor,
    required Color subColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF5A52)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    softWrap: true,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    softWrap: true,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subColor),
          ],
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                hintText: AppStrings.t(context, 'search_history'),
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
            separatorBuilder: (_, _) => const SizedBox(height: 6),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
  final Future<void> Function() onSubmit;
  final bool showMenuButton;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;
  final bool isLoading;
  final Map<String, dynamic>? aiResult;
  final String? aiError;

  const _MainArea({
    required this.fullName,
    required this.promptCtrl,
    required this.onSubmit,
    required this.showMenuButton,
    required this.panelBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
    required this.isLoading,
    required this.aiResult,
    required this.aiError,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5A52);
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 16 : 24,
              24,
              isSmallScreen ? 16 : 24,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.t(context, 'welcome')} $fullName 👋',
                      softWrap: true,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: isSmallScreen ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.t(context, 'home_subtitle'),
                      softWrap: true,
                      style: TextStyle(
                        color: subColor,
                        fontSize: isSmallScreen ? 16 : 17,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.auto_awesome, color: accent),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  AppStrings.t(context, 'what_shopping_for'),
                                  softWrap: true,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: isSmallScreen ? 20 : 22,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
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
                              hintText: AppStrings.t(context, 'prompt_example'),
                              hintStyle: TextStyle(
                                color: subColor,
                                fontSize: isSmallScreen ? 15 : 16,
                              ),
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
                              contentPadding: const EdgeInsets.all(18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    accent.withValues(alpha: 0.7),
                                minimumSize: const Size.fromHeight(56),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.search),
                              label: Text(
                                isLoading
                                    ? 'Searching...'
                                    : AppStrings.t(context, 'find_best_options'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (aiError != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: panelBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: Text(
                                aiError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],

                          if (aiResult != null) ...[
  const SizedBox(height: 18),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: panelBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Recommendation',
          style: TextStyle(
            color: titleColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        _resultRow(
          'Category',
          aiResult!['category']?.toString() ?? '-',
          titleColor,
          subColor,
        ),
        _resultRow(
          'Budget',
          aiResult!['budget'] != null ? '\$${aiResult!['budget']}' : '-',
          titleColor,
          subColor,
        ),
        _resultRow(
          'Priorities',
          (aiResult!['priorities'] as List?)?.join(', ') ?? '-',
          titleColor,
          subColor,
        ),
        _resultRow(
          'Summary',
          aiResult!['summary']?.toString() ?? '-',
          titleColor,
          subColor,
        ),
        const SizedBox(height: 16),
        if ((aiResult!['suggestedProducts'] as List?) != null &&
            (aiResult!['suggestedProducts'] as List).isNotEmpty) ...[
          Text(
            'Suggested Products',
            style: TextStyle(
              color: titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...(aiResult!['suggestedProducts'] as List)
              .map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5A52).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFFF5A52),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            product.toString(),
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ],
    ),
  ),
],
                          
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

  Widget _resultRow(
    String label,
    String value,
    Color titleColor,
    Color subColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: subColor,
            fontSize: 15,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final card = isDark ? const Color(0xFF181821) : const Color(0xFFF4F5F9);
    final border = isDark ? const Color(0xFF232331) : const Color(0xFFD9DCE5);
    final text = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.black54;
    const accent = Color(0xFFFF5A52);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: text),
        ),
        title: Text(
          AppStrings.t(context, 'help'),
          style: TextStyle(
            color: text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: accent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.t(context, 'how_clawcart_helps'),
                        style: TextStyle(
                          color: text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _helpItem(
                  AppStrings.t(context, 'help_budget_preferences'),
                  subText,
                ),
                _helpItem(
                  AppStrings.t(context, 'help_compare_products'),
                  subText,
                ),
                _helpItem(
                  AppStrings.t(context, 'help_rank_choices'),
                  subText,
                ),
                _helpItem(
                  AppStrings.t(context, 'help_checkout_summary'),
                  subText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _helpItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle,
              color: Color(0xFFFF5A52),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: TextStyle(
                color: color,
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}