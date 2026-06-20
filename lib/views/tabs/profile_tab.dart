import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../components/glass_card.dart';
import '../register_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final sessionService = Provider.of<SessionService>(context, listen: false);

    try {
      // 1. Sign out of auth provider
      await authService.signOut();

      // 2. Clear SharedPreferences login session
      await sessionService.clearSession();

      if (!context.mounted) return;

      // 3. Clear stack and push Halaman Daftar (Register Screen)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          backgroundColor: Colors.blueGrey,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isFirebaseMode = authService.isFirebaseMode;
    
    // Obtain active user uid
    final user = authService.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traveler Profile'),
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text(
                'No user profile loaded.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : FutureBuilder<UserProfile?>(
              future: firestoreService.getUserProfile(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentNeonBlue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading profile: ${snapshot.error}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                // Fallback to active user cache if database is empty
                final profile = snapshot.data ?? user;

                if (profile == null) {
                  return const Center(
                    child: Text('Profile details not found.'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Dynamic Profile Pic with glowing neon border
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentNeonBlue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.accentNeonBlue,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: profile.profilePicUrl.startsWith('assets/')
                              ? AssetImage(profile.profilePicUrl) as ImageProvider
                              : NetworkImage(profile.profilePicUrl.isNotEmpty 
                                  ? profile.profilePicUrl 
                                  : 'assets/profil.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Full Name
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      // Email
                      Text(
                        profile.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      // Cloud/Offline status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isFirebaseMode ? Colors.green : AppTheme.accentNeonOrange).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isFirebaseMode ? Colors.green : AppTheme.accentNeonOrange).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFirebaseMode ? Icons.cloud_done : Icons.wifi_off_outlined,
                              color: isFirebaseMode ? Colors.green : AppTheme.accentNeonOrange,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFirebaseMode ? 'Cloud Firestore Synchronized' : 'Offline Local Storage Active',
                              style: TextStyle(
                                color: isFirebaseMode ? Colors.green : AppTheme.accentNeonOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      // User Data Cards (Email & Instagram)
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              value: profile.fullName,
                            ),
                            const Divider(color: Colors.white12, height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.email_outlined,
                              label: 'Email Address',
                              value: profile.email,
                            ),
                            const Divider(color: Colors.white12, height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.camera_alt_outlined,
                              label: 'Instagram Account',
                              value: profile.instagram.isNotEmpty ? profile.instagram : '@spacetraveler',
                              valueColor: AppTheme.accentNeonBlue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _showLogoutConfirmDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 10),
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentNeonBlue, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to end your cosmic session and sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _logout(context); // Perform logout
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
