import 'package:flutter/material.dart';

class SidebarContent extends StatelessWidget {
  final String fullName;
  final String email;
  final List<String> history;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenSettings;
  final VoidCallback onNewSearch;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;

  const SidebarContent({
    super.key,
    required this.fullName,
    required this.email,
    required this.history,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenSettings,
    required this.onNewSearch,
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
            border: Border(top: BorderSide(color: borderColor)),
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