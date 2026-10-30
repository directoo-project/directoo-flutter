/// Public customer panel. Override for a local backend:
/// `flutter run --dart-define=API_BASE=http://127.0.0.1:8000`
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://app.directoo.ir',
);

const String siteUrl = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'https://directoo.ir',
);
