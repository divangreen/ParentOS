/// Backend API base URL. Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8000/v1
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://parentos-backend.onrender.com/v1',
);
