import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/location_utils.dart';


import '../../shared/widgets/ghost_button.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/skeleton_card.dart';


import '../../app/app_settings.dart';
import '../../app/app_strings.dart';
import '../../providers/search_provider.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    if (!searchProvider.isInitialized) {
  return const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );
}

   final user = FirebaseAuth.instance.currentUser;

if (user == null) {
  return const Scaffold(
    body: Center(child: Text("User not logged in")),
  );
}
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

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  

  final data = snapshot.data?.data();

  final fullName =
      (data?['name'] ?? user.displayName ?? user.email ?? 'User').toString();
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
                onDeleteSession: searchProvider.deleteSession,
                onNewSearch: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  searchProvider.createNewSession();
                },
                fullName: fullName,
                email: email,
                history: searchProvider.sessions.map((s) => s.title).toList(),
                selectedIndex: searchProvider.selectedIndex,
                panelBg: panelBg,
                borderColor: borderColor,
                titleColor: titleColor,
                subColor: subColor,
                onSelect: (index) {
                  searchProvider.selectSession(index);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
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
                onDeleteSession: searchProvider.deleteSession,
                onNewSearch: searchProvider.createNewSession,
                fullName: fullName,
                email: email,
                history: searchProvider.sessions.map((s) => s.title).toList(),
                selectedIndex: searchProvider.selectedIndex,
                panelBg: panelBg,
                borderColor: borderColor,
                titleColor: titleColor,
                subColor: subColor,
                onSelect: searchProvider.selectSession,
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
              promptCtrl: searchProvider.promptCtrl,
              onSubmit: searchProvider.submitPrompt,
              showMenuButton: !showPermanentSidebar,
              panelBg: panelBg,
              borderColor: borderColor,
              titleColor: titleColor,
              subColor: subColor,
              isLoading: searchProvider.isLoading,
              aiResult: searchProvider.currentSession.aiResult,
              aiError: searchProvider.currentSession.aiError,
              selectedLocation: searchProvider.currentSession.location,
              selectedCity: searchProvider.currentSession.city,
              currencySymbol: LocationUtils.getCurrencySymbol(
                searchProvider.currentSession.location,
              ),
              selectedPriceRange: searchProvider.currentSession.priceRange,
              onLocationChanged: (value) async {
                searchProvider.updateLocation(value);
              },
              onCityChanged: (value) async {
                searchProvider.updateCity(value);
              },
              onPriceRangeChanged: (value) async {
                searchProvider.updatePriceRange(value);
              },
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
      await authService.signOut();

      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
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
final VoidCallback onNewSearch;
final Future<void> Function(int) onDeleteSession;
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
  required this.onNewSearch,
  required this.onDeleteSession,
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
                onPressed: onNewSearch,
                tooltip: 'New search',
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

        Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Text(
    'Long press a search to delete it',
    style: TextStyle(
      color: subColor,
      fontSize: 12,
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
  onLongPress: () async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete search'),
          content: Text('Do you want to delete "${history[index]}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await onDeleteSession(index);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search deleted')),
        );
      }
    }
  },
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
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),
);},
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

  final String selectedLocation;
  final String selectedCity;
  final String currencySymbol;
  final RangeValues selectedPriceRange;

  final ValueChanged<String> onLocationChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<RangeValues> onPriceRangeChanged;

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
    required this.selectedLocation,
    required this.selectedCity,
    required this.currencySymbol,
    required this.selectedPriceRange,
    required this.onLocationChanged,
    required this.onCityChanged,
    required this.onPriceRangeChanged,
  });

  Future<void> _openProductUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Map<String, dynamic>> _extractProducts() {
    if (aiResult == null) return [];

    final raw = aiResult!['products'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? _extractBestProduct() {
    if (aiResult == null) return null;

    final raw = aiResult!['bestProduct'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  String _textValue(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _priceValue(dynamic value) {
    if (value == null) return 'Price unavailable';
    return '$currencySymbol$value';
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5A52);
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    final availableCities =
        LocationUtils.countryCities[selectedLocation] ?? ['Accra'];

    final products = _extractProducts();
    final bestProduct = _extractBestProduct();

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
                        fontSize: isSmallScreen ? 30 : 40,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.t(context, 'home_subtitle'),
                      softWrap: true,
                      style: TextStyle(
                        color: subColor,
                        fontSize: isSmallScreen ? 15 : 17,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
                      decoration: BoxDecoration(
                        gradient: Theme.of(context).brightness == Brightness.dark
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF15151D),
                                  Color(0xFF12121A),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFF9FAFD),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.7),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
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
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF171720)
                                  : const Color(0xFFF8F9FC),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: borderColor.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: accent,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Country',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF171720)
                                  : const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.8),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedLocation,
                                isExpanded: true,
                                dropdownColor: panelBg,
                                iconEnabledColor: titleColor,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 16,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'GH',
                                    child: Text('Ghana'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UK',
                                    child: Text('United Kingdom'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'US',
                                    child: Text('United States'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) onLocationChanged(value);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'City',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF171720)
                                  : const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.8),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: availableCities.contains(selectedCity)
                                    ? selectedCity
                                    : availableCities.first,
                                isExpanded: true,
                                dropdownColor: panelBg,
                                iconEnabledColor: titleColor,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 16,
                                ),
                                items: availableCities
                                    .map(
                                      (city) => DropdownMenuItem<String>(
                                        value: city,
                                        child: Text(city),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) onCityChanged(value);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            'Price Range',
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            '$currencySymbol${selectedPriceRange.start.round()} - $currencySymbol${selectedPriceRange.end.round()}',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),

                          RangeSlider(
                            values: selectedPriceRange,
                            min: 1,
                            max: 1000,
                            divisions: 20,
                            labels: RangeLabels(
                              '$currencySymbol${selectedPriceRange.start.round()}',
                              '$currencySymbol${selectedPriceRange.end.round()}',
                            ),
                            onChanged: onPriceRangeChanged,
                          ),

                          const SizedBox(height: 16),

                          PrimaryButton(
                            label: AppStrings.t(context, 'find_best_options'),
                            isLoading: isLoading,
                            icon: Icons.search,
                            onPressed: onSubmit,
                          ),

                          const SizedBox(height: 18),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: isLoading
                                ? Column(
                                    key: const ValueKey('loading'),
                                    children: const [
                                      SkeletonCard(),
                                      SkeletonCard(),
                                      SkeletonCard(),
                                    ],
                                  )
                                : aiError != null
                                    ? Container(
                                        key: const ValueKey('error'),
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: panelBg,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              aiError!,
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            GhostButton(
                                              label: 'Retry',
                                              icon: Icons.refresh,
                                              onPressed: () => context
                                                  .read<SearchProvider>()
                                                  .retrySearch(),
                                            ),
                                          ],
                                        ),
                                      )
                                    : aiResult == null
                                        ? Container(
                                            key: const ValueKey('empty'),
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(28),
                                            decoration: BoxDecoration(
                                              color: panelBg,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border:
                                                  Border.all(color: borderColor),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.03),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: 68,
                                                  height: 68,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFF5A52,
                                                    ).withValues(alpha: 0.10),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.shopping_bag_outlined,
                                                    size: 32,
                                                    color: Color(0xFFFF5A52),
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  'Start a search',
                                                  style: TextStyle(
                                                    color: titleColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Describe what you want and ClawCart will suggest the best options for you.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: subColor,
                                                    fontSize: 14,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : _ResultsSection(
                                            aiResult: aiResult!,
                                            panelBg: panelBg,
                                            borderColor: borderColor,
                                            titleColor: titleColor,
                                            subColor: subColor,
                                            currencySymbol: currencySymbol,
                                            onOpenProductUrl: _openProductUrl,
                                          ),
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

class _ResultsSection extends StatelessWidget {
  final Map<String, dynamic> aiResult;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;
  final String currencySymbol;
  final Future<void> Function(String? url) onOpenProductUrl;

  const _ResultsSection({
    required this.aiResult,
    required this.panelBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
    required this.currencySymbol,
    required this.onOpenProductUrl,
  });

  List<Map<String, dynamic>> get products {
    final raw = aiResult['products'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? get bestProduct {
    final raw = aiResult['bestProduct'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('results'),
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
            _safeText(aiResult['category']),
          ),
          _resultRow(
            'Budget',
            aiResult['budget'] != null
                ? '$currencySymbol${aiResult['budget']}'
                : '-',
          ),
          _resultRow(
            'Priorities',
            aiResult['priorities'] is List
                ? (aiResult['priorities'] as List).join(', ')
                : '-',
          ),
          _resultRow(
            'Summary',
            _safeText(aiResult['summary']),
          ),

          if (bestProduct != null) ...[
            const SizedBox(height: 16),
            Text(
              'Best Pick',
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFF5A52),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A52).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFFF5A52),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _safeText(bestProduct!['name']),
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _safeText(bestProduct!['reason'], fallback: ''),
                    style: TextStyle(
                      color: subColor,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (products.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Fetched Items',
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            ...products.map((product) {
              final imageUrl = _safeText(product['image'], fallback: '');
              final productUrl = _safeText(product['url'], fallback: '');
              final rating = product['rating'];
              final price = product['price'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _fallbackImage(),
                                    )
                                  : _fallbackImage(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _safeText(product['name']),
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5A52)
                                              .withValues(alpha: 0.10),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          price != null
                                              ? '$currencySymbol$price'
                                              : 'Price unavailable',
                                          style: const TextStyle(
                                            color: Color(0xFFFF5A52),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          rating != null
                                              ? '⭐ $rating'
                                              : 'No rating',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sold by ${_safeText(product['store'], fallback: 'Unknown store')}',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _safeText(product['reason'], fallback: ''),
                          style: TextStyle(
                            color: subColor,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: GhostButton(
                                label: 'Save',
                                icon: Icons.favorite_border,
                                onPressed: () async {
                                  await context
                                      .read<SearchProvider>()
                                      .saveFavoriteProduct(product);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Saved to favorites'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: productUrl.isNotEmpty
                                    ? () => onOpenProductUrl(productUrl)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text(
                                  'View product',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: productUrl.isNotEmpty
                                    ? () => onOpenProductUrl(productUrl)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5A52),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.shopping_cart_checkout,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Buy now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          if (products.isEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'No products found in the response.',
              style: TextStyle(
                color: subColor,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
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

  Widget _fallbackImage() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5A52).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Color(0xFFFF5A52),
        size: 30,
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: const Center(
        child: Text('Help content here'),
      ),
    );
  }
}

                         

                          


