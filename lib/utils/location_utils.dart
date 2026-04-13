class LocationUtils {
  static String getCurrencySymbol(String countryCode) {
    switch (countryCode) {
      case 'GH':
        return 'GH₵';
      case 'UK':
        return '£';
      case 'US':
      default:
        return '\$';
    }
  }

  static const Map<String, List<String>> countryCities = {
    'GH': ['Accra', 'Kumasi', 'Takoradi', 'Tamale', 'Cape Coast'],
    'UK': ['London', 'Manchester', 'Birmingham', 'Liverpool', 'Leeds'],
    'US': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Atlanta'],
  };
}