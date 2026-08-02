/// Web implementation using dart:html
/// This file is only compiled when dart.library.html is available
import 'dart:convert';
import 'dart:html' as html;

String downloadCsvWeb(String csv) {
  try {
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'float_financial_leads_${DateTime.now().toIso8601String().split('T')[0]}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
    return 'Download started';
  } catch (e) {
    return 'Error: $e';
  }
}
