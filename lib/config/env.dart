class Env {
  static const bool isProduction = false;

  static String get baseUrl {
    if (isProduction) {
      return 'https://us-central1-project-30dd3c12-9d55-4261-bc5.cloudfunctions.net';
    }

    return 'http://127.0.0.1:5001/project-30dd3c12-9d55-4261-bc5/us-central1';
  }
}