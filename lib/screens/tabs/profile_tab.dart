import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../dev_tool_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                user?.email ?? 'No Email',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'ADMINISTRATION',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF7A0000)),
                title: const Text('Developer / Admin Tools'),
                subtitle: const Text('Manage Clusters, Chapels, and Ministries'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DevToolScreen()),
                  );
                },
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await authService.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A0000),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
