import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../services/local_storage_service.dart';

// Conditional import for web-specific code
import 'leads_exporter_stub.dart'
    if (dart.library.html) 'leads_exporter_web.dart';

/// Export leads to CSV and download/share
/// Platform-aware: uses dart:html on web, file system on mobile
class LeadsExporter {
  static Future<String?> exportToCsv() async {
    final leads = await LocalStorageService.loadLeads();
    
    if (leads.isEmpty) {
      return null;
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
    
    final csv = buffer.toString();
    
    if (kIsWeb) {
      // Web: download via blob - implemented in leads_exporter_web.dart
      return downloadCsvWeb(csv);
    } else {
      // Mobile: save to file
      return _saveToFile(csv);
    }
  }
  
  static Future<String> _saveToFile(String csv) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/float_financial_leads_${DateTime.now().toIso8601String().split('T')[0]}.csv');
      await file.writeAsString(csv);
      return 'Saved to: ${file.path}';
    } catch (e) {
      return 'Error saving file: $e';
    }
  }
  
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
