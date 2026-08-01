import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../services/local_storage_service.dart';
import '../services/lead_notification_service.dart';

/// Lead Capture Form for Float Financial consulting
/// Collects: name, email, TAO holdings range, message
class LeadCaptureForm extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const LeadCaptureForm({super.key, this.onSubmitted});

  @override
  State<LeadCaptureForm> createState() => _LeadCaptureFormState();
}

class _LeadCaptureFormState extends State<LeadCaptureForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRange = '0-10 TAO';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _taoRanges = [
    '0-10 TAO',
    '10-50 TAO',
    '50-100 TAO',
    '100-500 TAO',
    '500+ TAO',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Save to local storage (in production: send to Supabase/email)
    final lead = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'tao_range': _selectedRange,
      'message': _messageController.text.trim(),
      'submitted_at': DateTime.now().toIso8601String(),
    };

    await LocalStorageService.saveLead(lead);
    
    // Send notification (D7)
    try {
      await LeadNotificationService.sendLeadNotification(lead);
    } catch (_) {
      // Notification failed, but lead is saved
    }

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });

    widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_submitted) {
      return _buildSuccess(isDark);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.moonlightSurface, AppColors.moonlightSurfaceAlt]
              : [AppColors.primaryTeal.withOpacity(0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.moonlightSurfaceAlt : AppColors.primaryTeal.withOpacity(0.2),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rocket_launch, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Your Yield Strategy',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                        ),
                      ),
                      Text(
                        'Personalized Bittensor subnet allocation advice',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            _buildTextField(
              controller: _nameController,
              label: 'Your Name',
              hint: 'Paul Matt',
              icon: Icons.person,
              validator: (v) => v?.trim().isEmpty == true ? 'Name required' : null,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Email field
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty == true) return 'Email required';
                if (!v!.contains('@')) return 'Invalid email';
                return null;
              },
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // TAO holdings dropdown
            Text(
              'TAO Holdings',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.moonlightSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey[300]!,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRange,
                  isExpanded: true,
                  dropdownColor: isDark ? AppColors.moonlightSurface : Colors.white,
                  style: TextStyle(
                    color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
                  ),
                  items: _taoRanges.map((range) => DropdownMenuItem(
                    value: range,
                    child: Text(range),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedRange = v!),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Message field
            _buildTextField(
              controller: _messageController,
              label: 'What are your yield goals? (optional)',
              hint: 'e.g., Maximize monthly TAO yield, minimize risk, etc.',
              icon: Icons.message,
              maxLines: 3,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Get My Free Strategy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Privacy note
            Text(
              'No spam. We\'ll send you a personalized subnet allocation plan within 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.grey),
            filled: true,
            fillColor: isDark ? AppColors.moonlightSurface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'You\'re In! 🎉',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll review your TAO holdings and send a personalized yield strategy to your email within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _submitted = false),
            child: const Text('Submit Another Lead'),
          ),
        ],
      ),
    );
  }
}
