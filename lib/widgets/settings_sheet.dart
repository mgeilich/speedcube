import 'package:flutter/material.dart';
import '../utils/premium_manager.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _isRestoring = false;
  String? _restoreMessage;

  Future<void> _handleRestore() async {
    setState(() {
      _isRestoring = true;
      _restoreMessage = null;
    });

    try {
      await PremiumManager().restorePurchases();
      if (mounted) {
        if (!PremiumManager().isPremium) {
          setState(() {
            _restoreMessage = "No previous purchases found to restore.";
          });
        } else {
          setState(() {
            _restoreMessage = "Purchases restored successfully!";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restoreMessage = "Failed to restore: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Restore Purchases Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restore, color: Color(0xFF6366F1)),
                ),
                title: const Text(
                  'Restore Purchases',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Restore previously purchased Pro unlock.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                trailing: _isRestoring
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: _isRestoring ? null : _handleRestore,
              ),

              if (_restoreMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _restoreMessage!,
                  style: TextStyle(
                    color: _restoreMessage!.contains("successfully")
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Colors.white12),
              ),

              // Contact/Support Tile (Optional, good for App Store)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.help_outline, color: Colors.white70),
                ),
                title: const Text(
                  'Support & Feedback',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  // In a real app, open an email or a support website.
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
