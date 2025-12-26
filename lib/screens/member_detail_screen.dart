import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class MemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final DatabaseService _db = DatabaseService();
  late Map<String, dynamic> memberData;
  String? chapelName;
  String? clusterName;
  bool _isLoadingNames = true;

  @override
  void initState() {
    super.initState();
    memberData = Map.from(widget.member);
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      if (memberData['chapelId'] != null) {
        var chapelDoc = await FirebaseFirestore.instance
            .collection('chapels')
            .doc(memberData['chapelId'])
            .get();
        if (chapelDoc.exists) chapelName = chapelDoc.data()?['name'];
      }
      if (memberData['clusterId'] != null) {
        var clusterDoc = await FirebaseFirestore.instance
            .collection('clusters')
            .doc(memberData['clusterId'])
            .get();
        if (clusterDoc.exists) clusterName = clusterDoc.data()?['name'];
      }
    } catch (e) {
      print("Error loading names: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNames = false);
    }
  }

  Future<void> _editPhoneNumber() async {
    TextEditingController phoneController =
        TextEditingController(text: memberData['contactNumber']);
    
    final newPhone = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, phoneController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newPhone != null && newPhone != memberData['contactNumber']) {
      try {
        await _db.updateParticipant(memberData['id'], {'contactNumber': newPhone});
        setState(() {
          memberData['contactNumber'] = newPhone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating phone: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = memberData['fullName'] ?? 'Unknown';
    final bool isVerified = memberData['isVerified'] ?? false;
    final String gender = memberData['gender'] ?? 'N/A';
    final String age = memberData['age'] ?? 'N/A';
    final List ministries = memberData['ministries'] as List? ?? [];
    final DateTime? createdAt = memberData['createdAt'] is Timestamp 
        ? (memberData['createdAt'] as Timestamp).toDate() 
        : null;
    final String joinedDate = createdAt != null ? DateFormat('MMM yyyy').format(createdAt) : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit', style: TextStyle(color: Color(0xFF1E5631), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E5631), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blue[50],
                          backgroundImage: memberData['profileImageUrl'] != null
                              ? NetworkImage(memberData['profileImageUrl'])
                              : null,
                          child: memberData['profileImageUrl'] == null
                              ? Text(fullName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1E5631)))
                              : null,
                        ),
                      ),
                      if (isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0, // Moved to right bottom
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Color(0xFF1E5631), size: 28),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active Member',
                          style: TextStyle(color: Color(0xFF1E5631), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Joined $joinedDate',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Personal Details
            _buildSectionHeader(Icons.person, 'Personal Details'),
            _buildDetailCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildInfoGridItem('AGE', age),
                      _buildInfoGridItem('BIRTHDAY', 'Oct 12'), // Placeholder as in image
                    ],
                  ),
                  const Divider(height: 1),
                  Row(
                    children: [
                      _buildInfoGridItem('GENDER', gender),
                    ],
                  ),
                ],
              ),
            ),

            // Contact Info
            _buildSectionHeader(Icons.contact_phone, 'Contact Info'),
            _buildDetailCard(
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.phone_outlined,
                    title: memberData['contactNumber'] ?? 'N/A',
                    subtitle: 'Mobile',
                    onTap: _editPhoneNumber,
                  ),
                  const Divider(height: 1, indent: 50),
                  _buildListTile(
                    icon: Icons.location_on_outlined,
                    title: chapelName ?? (memberData['chapelId'] ?? 'N/A'),
                    subtitle: 'Location',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Church Data
            _buildSectionHeader(Icons.church, 'Church Data'),
            _buildDetailCard(
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.store_outlined,
                    title: chapelName ?? 'Loading...',
                    subtitle: 'CHAPEL',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 50),
                  _buildListTile(
                    icon: Icons.groups_outlined,
                    title: clusterName ?? 'Loading...',
                    subtitle: 'CLUSTER',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Ministries
            _buildSectionHeader(Icons.volunteer_activism, 'Ministries'),
            _buildDetailCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ministries.map((m) => _buildMinistryChip(m)).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Assign'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1E5631),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E5631)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoGridItem(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF1E5631), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
    );
  }

  Widget _buildMinistryChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E5631).withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 14, color: Color(0xFF1E5631)),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(color: Color(0xFF1E5631), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
