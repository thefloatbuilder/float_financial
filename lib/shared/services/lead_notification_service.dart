import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../services/local_storage_service.dart';

/// Email notification service for new leads
/// Uses device email client to send notification to Paul
class LeadNotificationService {
  static Future<void> sendLeadNotification(Map<String, dynamic> lead) async {
    final leadName = lead['name'] as String? ?? 'Unknown';
    final leadEmail = lead['email'] as String? ?? 'No email';
    final range = lead['tao_range'] as String? ?? 'Unknown';
    final message = lead['message'] as String? ?? 'No message';

    final email = Email(
      body: '''
New Float Financial Lead!

Name: $leadName
Email: $leadEmail
TAO Holdings: $range
Message: $message

Submitted: ${DateTime.now().toIso8601String()}

---
Sent from Float Financial App
''',
      subject: 'New Lead: $leadName ($range)',
      recipients: ['pault.matt@gmail.com'],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (e) {
      // Fallback: store notification locally
      await _storeNotificationLocally(lead);
    }
  }

  static Future<void> _storeNotificationLocally(Map<String, dynamic> lead) async {
    final notifications = await LocalStorageService.loadNotifications();
    notifications.insert(0, {
      'type': 'new_lead',
      'lead': lead,
      'timestamp': DateTime.now().toIso8601String(),
      'read': false,
    });
    await LocalStorageService.saveNotifications(notifications);
  }
}
