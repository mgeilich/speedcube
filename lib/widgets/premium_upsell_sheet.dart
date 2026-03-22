import 'package:flutter/material.dart';
import '../utils/premium_manager.dart';

class PremiumUpsellSheet extends StatefulWidget {
  const PremiumUpsellSheet({super.key});

  @override
  State<PremiumUpsellSheet> createState() => _PremiumUpsellSheetState();
}

class _PremiumUpsellSheetState extends State<PremiumUpsellSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    PremiumManager().addListener(_onPremiumStatusChanged);
  }

  @override
  void dispose() {
    PremiumManager().removeListener(_onPremiumStatusChanged);
    super.dispose();
  }

  void _onPremiumStatusChanged() {
    final manager = PremiumManager();
    if (manager.isPremium && mounted) {
      Navigator.pop(context);
    } else if (manager.lastError != null && mounted) {
      setState(() {
        _errorMessage = manager.lastError;
        _isLoading = false; // Stop loading if error from stream
      });
      manager.clearError();
    }
  }

  Future<void> _handleUnlock() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      await PremiumManager().buyPremium();
      // Note: We don't pop immediately because the native IAP sheet 
      // may take time to appear or complete.
    } catch (e) {
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        
        setState(() {
          _errorMessage = message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await PremiumManager().restorePurchases();
      if (mounted) {
        if (!PremiumManager().isPremium) {
          setState(() {
            _errorMessage = "No previous purchases found to restore.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to restore: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

              // Icon/Title
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Upgrade to PRO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlock the full potential of your SpeedCube AR experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 30),

              // Features
              _buildFeatureRow(
                Icons.camera_alt,
                'Scan and solve a real cube',
                'Scan your physical cube in seconds using your camera and get an instant solution.',
              ),
              const SizedBox(height: 16),

              _buildFeatureRow(
                Icons.auto_awesome,
                'Step-by-step solution explanations',
                'Examine each step of a solution and understand its purpose',
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.school,
                'Layer-by-Layer tutorial',
                'Learn to solve a 3x3 cube from scratch with our step-by-step interactive tutorial.',
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(
                Icons.shuffle,
                'Pro Scrambler (50 moves)',
                'Challenge yourself with complex scrambles up to 50 moves and see step-by-step solutions.',
              ),

              const SizedBox(height: 40),

              // Error Message Section
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Buy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUnlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Unlock All Features',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : _handleRestore,
                child: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFF59E0B), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
