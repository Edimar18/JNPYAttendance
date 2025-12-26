import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../manage_announcements_screen.dart';

class ActivitiesTab extends StatefulWidget {
  const ActivitiesTab({super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  final DatabaseService _db = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;
  
  String? _selectedViewClusterId;
  String? _selectedViewChapelId;
  bool _initialScopeSet = false;

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final userProfile = profileSnapshot.data!.data() as Map<String, dynamic>?;
        if (userProfile == null) return const Scaffold(body: Center(child: Text("Profile not found")));
        
        if (!_initialScopeSet) {
          _selectedViewClusterId = userProfile['clusterId'];
          _selectedViewChapelId = userProfile['chapelId'];
          _initialScopeSet = true;
        }

        String headType = userProfile['head'] ?? 'none';

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Activities', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(headType),
                const SizedBox(height: 24),
                _buildActionCards(context, headType, userProfile),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upcoming Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (headType == 'admin' || headType == 'cluster')
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showFilterDialog(context, headType, userProfile),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivitiesList(headType, userProfile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String headType) {
    String title = "Manage Events";
    String description = "";
    
    if (headType == 'chapel') {
      description = "As a Chapel Head, you can organize local gatherings or connect your members with the wider parish community.";
    } else if (headType == 'cluster') {
      description = "As a Cluster Head, you manage cluster-wide activities and oversee chapel events within your jurisdiction.";
    } else if (headType == 'admin') {
      description = "As a Parish Admin, you coordinate all activities across all clusters and chapels.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E5631))),
        const SizedBox(height: 8),
        Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, String headType, Map<String, dynamic> profile) {
    if (headType == 'chapel') {
      return Column(
        children: [
          _buildActionCard(
            icon: Icons.edit_calendar_sharp,
            title: "Create Chapel Activity",
            subtitle: "Schedule a new mass, prayer meeting, or community service event for your specific chapel.",
            onTap: () => _showCreateActivityDialog(context, 'chapel', profile),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.groups,
            title: "Join Cluster / Parish Activity",
            subtitle: "Browse upcoming events from the larger cluster or parish and register your chapel's participation.",
            onTap: () {
              // Navigation or action for joining
            },
          ),
        ],
      );
    } else if (headType == 'cluster') {
      return Column(
        children: [
          _buildActionCard(
            icon: Icons.edit_calendar_sharp,
            title: "Create Cluster Activity",
            subtitle: "Organize events that involve all chapels within your cluster.",
            onTap: () => _showCreateActivityDialog(context, 'cluster', profile),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.campaign,
            title: "Manage Announcements",
            subtitle: "Broadcast news or updates to your entire cluster or specific chapels.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageAnnouncementsScreen(userProfile: profile)),
              );
            },
          ),
        ],
      );
    } else if (headType == 'admin') {
      return Column(
        children: [
          _buildActionCard(
            icon: Icons.church,
            title: "Create Parish / Cluster Activity",
            subtitle: "Plan events for the entire parish community or specific clusters.",
            onTap: () => _showCreateActivityDialog(context, 'parish', profile),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.campaign,
            title: "Manage Announcements",
            subtitle: "Create and manage parish, cluster, or chapel announcements.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageAnnouncementsScreen(userProfile: profile)),
              );
            },
          ),
        ],
      );
    }
    return const SizedBox();
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: const Color(0xFF1E5631), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesList(String headType, Map<String, dynamic> profile) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getActivities(
        headType == 'chapel' ? profile['chapelId'] : _selectedViewChapelId,
        (headType == 'cluster' && _selectedViewChapelId == null) 
            ? profile['clusterId'] 
            : (headType == 'admin' && _selectedViewChapelId == null) ? _selectedViewClusterId : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No upcoming activities found.', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          );
        }

        final activities = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final act = activities[index];
            return _buildActivityBox(act);
          },
        );
      },
    );
  }

  Widget _buildActivityBox(Map<String, dynamic> act) {
    final DateTime date = (act['date'] as Timestamp).toDate();
    final String formattedDate = DateFormat('EEE, MMM d').format(date);
    final String status = act['status'] ?? 'upcoming';
    
    Color statusColor;
    switch (status) {
      case 'ongoing': statusColor = Colors.green; break;
      case 'attendance review': statusColor = Colors.orange; break;
      case 'open': statusColor = Colors.blue; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E5631))),
            ],
          ),
          const SizedBox(height: 12),
          Text(act['name'] ?? 'Untitled Activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(act['location'] ?? 'No Location', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(act['time'] ?? 'No Time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          if (act['information'] != null && act['information'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              act['information'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  void _showCreateActivityDialog(BuildContext context, String scope, Map<String, dynamic> profile) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening Create $scope Activity Screen...")));
  }

  void _showFilterDialog(BuildContext context, String headType, Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Activities'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (headType == 'admin')
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getClusters(),
                  builder: (context, snapshot) {
                    return DropdownButtonFormField<String>(
                      value: _selectedViewClusterId,
                      decoration: const InputDecoration(labelText: 'Cluster'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Clusters")),
                        if (snapshot.hasData)
                          ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          _selectedViewClusterId = val;
                          _selectedViewChapelId = null;
                        });
                      },
                    );
                  },
                ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _selectedViewClusterId != null ? _db.getChapels(_selectedViewClusterId!) : const Stream.empty(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: _selectedViewChapelId,
                    decoration: const InputDecoration(labelText: 'Chapel'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Chapels")),
                      if (snapshot.hasData)
                        ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                    ],
                    onChanged: (val) => setDialogState(() => _selectedViewChapelId = val),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
