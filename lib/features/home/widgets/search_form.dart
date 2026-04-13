import 'package:flutter/material.dart';

class SearchForm extends StatelessWidget {
  final TextEditingController promptCtrl;
  final String selectedLocation;
  final RangeValues selectedPriceRange;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<RangeValues> onPriceRangeChanged;
  final Future<void> Function() onSubmit;
  final bool isLoading;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color subColor;

  const SearchForm({
    super.key,
    required this.promptCtrl,
    required this.selectedLocation,
    required this.selectedPriceRange,
    required this.onLocationChanged,
    required this.onPriceRangeChanged,
    required this.onSubmit,
    required this.isLoading,
    required this.panelBg,
    required this.borderColor,
    required this.titleColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF5A52);
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return Container(
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
                  'What are you shopping for?',
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
              hintText: 'Example: iPhone 14 Pro Max under \$900',
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
          Text(
            'Location',
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
              color: panelBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocation,
                isExpanded: true,
                dropdownColor: panelBg,
                iconEnabledColor: titleColor,
                style: TextStyle(color: titleColor, fontSize: 16),
                items: const [
                  DropdownMenuItem(
                    value: 'US',
                    child: Text('United States'),
                  ),
                  DropdownMenuItem(
                    value: 'UK',
                    child: Text('United Kingdom'),
                  ),
                  DropdownMenuItem(
                    value: 'GH',
                    child: Text('Ghana'),
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
            'Price Range',
            style: TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${selectedPriceRange.start.round()} - \$${selectedPriceRange.end.round()}',
            style: TextStyle(
              color: subColor,
              fontSize: 13,
            ),
          ),
          RangeSlider(
            values: selectedPriceRange,
            min: 1,
            max: 1000,
            divisions: 20,
            labels: RangeLabels(
              '\$${selectedPriceRange.start.round()}',
              '\$${selectedPriceRange.end.round()}',
            ),
            onChanged: onPriceRangeChanged,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accent.withValues(alpha: 0.7),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                isLoading ? 'Searching...' : 'Find best options',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}