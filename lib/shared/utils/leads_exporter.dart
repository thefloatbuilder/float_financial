import 'dart:convert';
import 'dart:html' as html;
import '../services/local_storage_service.dart';

/// Export leads to CSV and download
class LeadsExporter {
  static Future<void> exportToCsv() async {
    final leads = await LocalStorageService.loadLeads();
    
    if (leads.isEmpty) {
      return;
    }
    
    // Build CSV
    final buffer = StringBuffer();
    buffer.writeln('Name,Email,TAO Range,Message,Submitted At');
    
    for (final lead in leads) {
      final name = _escapeCsv(lead['name'] as String? ?? '');
      final email = _escapeCsv(lead['email'] as String? ?? '');
      final range = _escapeCsv(lead['tao_range'] as String? ?? '');
      final message = _escapeCsv(lead['message'] as String? ?? '');
      final date = _escapeCsv(lead['saved_at'] as String? ?? '');
      buffer.writeln('$name,$email,$range,$message,$date');
    }
    
    // Download as file
    final csv = buffer.toString();
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'float_financial_leads_${DateTime.now().toIso8601String().split('T')[0]}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
  
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
