/// Stub for non-web platforms
/// This file is used when dart.library.html is NOT available (mobile, desktop)
String downloadCsvWeb(String csv) {
  throw UnsupportedError('CSV download is only supported on web');
}
