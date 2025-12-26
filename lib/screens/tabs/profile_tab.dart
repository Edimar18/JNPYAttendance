import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../dev_tool_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final profile = snapshot.data!.data() as Map<String, dynamic>?;
        if (profile == null) return const Scaffold(body: Center(child: Text("Profile not found")));

        String roleLabel = profile['head'] == 'admin' ? 'Parish Admin' : (profile['head'] == 'cluster' ? 'Cluster Head' : (profile['head'] == 'chapel' ? 'Chapel Head' : 'Member'));
        bool isAdmin = profile['head'] == 'admin';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('My Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 1. Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(profile['profileImageUrl'] ?? 'https://via.placeholder.com/150'),
                          ),
                          if (profile['isVerified'] == true)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.verified, color: Colors.white, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile['fullName'] ?? 'Unknown User',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roleLabel,
                        style: const TextStyle(color: Color(0xFF7A0000), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildProfileRow(Icons.email_outlined, user!.email ?? 'N/A'),
                      const SizedBox(height: 12),
                      _buildProfileRow(Icons.phone_outlined, profile['contactNumber'] ?? 'N/A'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // 2. Assignment Section
                _buildSectionHeader('Organization Assignment'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _buildAssignmentItem(Icons.groups, 'Cluster', profile['clusterId']),
                      const Divider(height: 24),
                      _buildAssignmentItem(Icons.church, 'Chapel', profile['chapelId']),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Ministries Section
                _buildSectionHeader('Ministries'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (profile['ministries'] as List? ?? []).map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(m.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 40),

                // 4. Admin Tools (Restricted)
                if (isAdmin) ...[
                  _buildSectionHeader('Administration'),
                  const SizedBox(height: 12),
                  ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DevToolScreen())),
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF7A0000)),
                    title: const Text('Developer Tools', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Configure hierarchy and content'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(height: 24),
                ],

                // 5. Logout
                ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF7A0000),
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF7A0000)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildProfileRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Text(value, style: TextStyle(color: Colors.grey[800], fontSize: 14)),
      ],
    );
  }

  Widget _buildAssignmentItem(IconData icon, String label, String? id) {
    if (id == null) return const SizedBox();
    
    // We use a FutureBuilder because we need to fetch the name from the ID
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(label.toLowerCase() + 's').doc(id).get(),
      builder: (context, snapshot) {
        String name = "Loading...";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
        }
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF7A0000), size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ],
        );
      },
    );
  }
}
