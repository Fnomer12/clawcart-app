class AppLogger {
  static void log(String message) {
    print('[APP LOG] $message');
  }

  static void error(String message) {
    print('[APP ERROR] $message');
  }
}