import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../manage_announcements_screen.dart';
import '../add_activity_screen.dart';

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

  DateTime _getEventDateTime(Timestamp date, String timeStr) {
    DateTime d = date.toDate();
    try {
      DateTime t = DateFormat.jm().parse(timeStr);
      return DateTime(d.year, d.month, d.day, t.hour, t.minute);
    } catch (e) {
      return d;
    }
  }

  String _getTimeLeft(DateTime eventTime) {
    final now = DateTime.now();
    final diff = eventTime.difference(now);
    if (diff.isNegative) return "Event time has reached";
    if (diff.inDays > 0) return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} left";
    if (diff.inHours > 0) return "${diff.inHours} hr${diff.inHours > 1 ? 's' : ''} left";
    if (diff.inMinutes > 0) return "${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} left";
    return "Starting soon";
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please login")));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final userProfile = profileSnapshot.data!.data() as Map<String, dynamic>?;
        if (userProfile == null) return const Scaffold(body: Center(child: Text("Profile not found")));
        userProfile['id'] = user!.uid;

        String headType = userProfile['head'] ?? 'none';

        if (!_initialScopeSet) {
          if (headType == 'admin') {
            _selectedViewClusterId = null;
            _selectedViewChapelId = null;
          } else if (headType == 'cluster') {
            _selectedViewClusterId = userProfile['clusterId'];
            _selectedViewChapelId = null;
          } else {
            _selectedViewClusterId = userProfile['clusterId'];
            _selectedViewChapelId = userProfile['chapelId'];
          }
          _initialScopeSet = true;
        }

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
                    const Text('Activities List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    String description = "";
    if (headType == 'chapel') {
      description = "As a Chapel Head, organize local gatherings or connect your members with the wider parish.";
    } else if (headType == 'cluster') {
      description = "As a Cluster Head, manage cluster-wide activities and oversee chapel events within your cluster.";
    } else if (headType == 'admin') {
      description = "As a Parish Admin, coordinate activities across all clusters and chapels.";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Manage Events", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E5631))),
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
            subtitle: "Schedule a new event for your specific chapel.",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddActivityScreen(userProfile: profile, scope: 'chapel'))),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.groups,
            title: "Join Cluster / Parish Activity",
            subtitle: "Browse and register your chapel's participation in wider events.",
            onTap: () {},
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddActivityScreen(userProfile: profile, scope: 'cluster'))),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.campaign,
            title: "Manage Announcements",
            subtitle: "Broadcast news or updates to your cluster or specific chapels.",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAnnouncementsScreen(userProfile: profile))),
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
            onTap: () => _showAdminActivityScopeDialog(context, profile),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.campaign,
            title: "Manage Announcements",
            subtitle: "Create and manage parish, cluster, or chapel announcements.",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageAnnouncementsScreen(userProfile: profile))),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  void _showAdminActivityScopeDialog(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Activity Scope', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.public, color: Color(0xFF1E5631)),
              title: const Text('Parish Wide Activity'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddActivityScreen(userProfile: profile, scope: 'parish')));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.groups, color: Color(0xFF1E5631)),
              title: const Text('Cluster Specific Activity'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddActivityScreen(userProfile: profile, scope: 'cluster')));
              },
            ),
          ],
        ),
      ),
    );
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
    String? chapelId;
    String? clusterId;
    bool all = false;

    if (headType == 'admin') {
      chapelId = _selectedViewChapelId;
      clusterId = _selectedViewClusterId;
      if (chapelId == null && clusterId == null) all = true;
    } else if (headType == 'cluster') {
      chapelId = _selectedViewChapelId;
      clusterId = profile['clusterId'];
    } else {
      chapelId = headType == 'chapel' ? profile['chapelId'] : _selectedViewChapelId ?? profile['chapelId'];
      clusterId = profile['clusterId'];
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getActivities(chapelId, clusterId, all: all),
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
                  Text('No activities found.', style: TextStyle(color: Colors.grey[600])),
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
            final actDate = (act['date'] as Timestamp).toDate();
            final today = DateTime.now();
            final isToday = actDate.year == today.year && actDate.month == today.month && actDate.day == today.day;
            
            return GestureDetector(
              onTap: () => _showActivityDetail(act, profile),
              child: _buildActivityBox(act, isToday ? 'TODAY' : 'UPCOMING')
            );
          },
        );
      },
    );
  }

  Widget _buildActivityBox(Map<String, dynamic> act, String label) {
    Color labelColor = label == 'TODAY' ? const Color(0xFF1E5631) : Colors.blueGrey;
    String scope = act['scope'] ?? 'chapel';
    Color scopeColor = scope == 'parish' ? Colors.green : (scope == 'cluster' ? Colors.orange : Colors.blue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.event_available, color: labelColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(label, style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scopeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            scope.toUpperCase(),
                            style: TextStyle(color: scopeColor, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('MMM d').format((act['date'] as Timestamp).toDate()),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(act['name'] ?? 'Untitled Activity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(act['time'] ?? 'No Time', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(act['location'] ?? 'No Location', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityDetail(Map<String, dynamic> act, Map<String, dynamic> profile) {
    String scope = act['scope'] ?? 'parish';
    Color scopeColor = scope == 'parish' ? Colors.green : (scope == 'cluster' ? Colors.orange : Colors.blue);
    bool isChapelHead = profile['head'] == 'chapel';
    List registeredChapels = act['registeredChapels'] ?? [];
    bool isRegistered = registeredChapels.contains(profile['chapelId']);
    bool isOpen = act['isOpen'] ?? false;
    DateTime eventDateTime = _getEventDateTime(act['date'], act['time'] ?? '12:00 AM');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scopeColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          scope.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        act['name'] ?? 'Activity',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildDetailIcon(Icons.calendar_today, scopeColor),
                          const SizedBox(width: 12),
                          Text(DateFormat('EEEE, MMMM d, yyyy').format((act['date'] as Timestamp).toDate()), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildDetailIcon(Icons.access_time, scopeColor),
                          const SizedBox(width: 12),
                          Text(act['time'] ?? 'TBA', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildDetailIcon(Icons.location_on, scopeColor),
                          const SizedBox(width: 12),
                          Text(act['location'] ?? 'TBA', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('INFORMATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(act['information'] ?? 'No description provided.', style: TextStyle(color: Colors.grey[800], height: 1.5)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _db.getUserProfile(act['createdBy'] ?? ''),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) return const SizedBox();
                          final creator = userSnap.data!;
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: creator['profileImageUrl'] != null ? NetworkImage(creator['profileImageUrl']) : null,
                                child: creator['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(creator['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    'EVENT CREATOR • ${creator['head']?.toUpperCase() ?? 'ADMIN'}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            ],
                          );
                        },
                      ),
                      if (scope != 'chapel') ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              const Icon(Icons.church, size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('${registeredChapels.length} Chapels Registered', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (isChapelHead && scope != 'chapel')
              TextButton.icon(
                onPressed: isRegistered ? null : () async {
                  await _db.registerChapel(act['id'], profile['chapelId']);
                  setDialogState(() {
                    isRegistered = true;
                    registeredChapels.add(profile['chapelId']);
                  });
                },
                icon: Icon(isRegistered ? Icons.check_circle : Icons.app_registration),
                label: Text(isRegistered ? 'REGISTERED' : 'REGISTER MY CHAPEL'),
                style: TextButton.styleFrom(foregroundColor: isRegistered ? Colors.green : scopeColor),
              ),
            if (isChapelHead)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isOpen)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                      child: Text(
                        "Attendance opens at set time: ${_getTimeLeft(eventDateTime)}",
                        style: TextStyle(fontSize: 10, color: scopeColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: isOpen ? () {
                      // TODO: Navigate to Attendance Recording
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scopeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text('ADD ATTENDANCE'),
                  ),
                ],
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16),
    );
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
                stream: (headType == 'admin') 
                  ? (_selectedViewClusterId != null ? _db.getChapels(_selectedViewClusterId!) : const Stream.empty())
                  : _db.getChapels(profile['clusterId']),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: _selectedViewChapelId,
                    decoration: const InputDecoration(labelText: 'Chapel'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Chapels")),
                      if (snapshot.hasData)
                        ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                    ],
                    onChanged: (headType == 'admin' && _selectedViewClusterId == null) ? null : (val) => setDialogState(() => _selectedViewChapelId = val),
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
