import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../add_participant_screen.dart';
import '../member_detail_screen.dart';

class MembersTab extends StatefulWidget {
  const MembersTab({super.key});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final DatabaseService _db = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userProfile;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedMinistry = "All Members";
  bool _isAscending = true;

  // For Admin/Cluster view switching
  String? _selectedViewClusterId;
  String? _selectedViewChapelId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user != null) {
      final profile = await _db.getUserProfile(user!.uid);
      if (mounted) {
        setState(() {
          userProfile = profile;
          if (profile != null) {
            userProfile!['id'] = user!.uid; // Ensure ID is present
            _selectedViewClusterId = profile['clusterId'];
            _selectedViewChapelId = profile['chapelId'];
          }
        });
      }
    }
  }

  List<Map<String, dynamic>> _filterAndSortMembers(List<Map<String, dynamic>> members) {
    List<Map<String, dynamic>> filtered = members.where((m) {
      final name = (m['fullName'] ?? '').toString().toLowerCase();
      final age = (m['age'] ?? '').toString().toLowerCase();
      final gender = (m['gender'] ?? '').toString().toLowerCase();
      final ministries = (m['ministries'] as List? ?? []).join(' ').toLowerCase();
      final query = _searchQuery.toLowerCase();

      bool matchesSearch = name.contains(query) ||
          age.contains(query) ||
          gender.contains(query) ||
          ministries.contains(query);

      bool matchesMinistry = _selectedMinistry == "All Members" ||
          (m['ministries'] as List? ?? []).contains(_selectedMinistry);

      return matchesSearch && matchesMinistry;
    }).toList();

    filtered.sort((a, b) {
      int cmp = (a['fullName'] ?? '').compareTo(b['fullName'] ?? '');
      return _isAscending ? cmp : -cmp;
    });

    return filtered;
  }

  Map<String, List<Map<String, dynamic>>> _groupMembers(List<Map<String, dynamic>> members) {
    Map<String, List<Map<String, dynamic>>> groups = {};
    for (var m in members) {
      String name = m['fullName'] ?? 'Unknown';
      String char = name.isNotEmpty ? name[0].toUpperCase() : '#';
      if (!groups.containsKey(char)) groups[char] = [];
      groups[char]!.add(m);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String headType = userProfile!['head'] ?? 'none';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Participants',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined,
              color: Colors.black54,
            ),
            onPressed: () => setState(() => _isAscending = !_isAscending),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddParticipantScreen(currentUserProfile: userProfile!),
            ),
          );
        },
        backgroundColor: const Color(0xFF1E5631),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Scope Selectors for Admin/Cluster Head
          if (headType == 'admin' || headType == 'cluster') _buildScopeSelector(headType),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Ministry Filters
          SizedBox(
            height: 50,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getMinistries(),
              builder: (context, snapshot) {
                List<String> ministries = ["All Members"];
                if (snapshot.hasData) {
                  ministries.addAll(snapshot.data!.map((m) => m['name'] as String));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: ministries.length,
                  itemBuilder: (context, index) {
                    final ministry = ministries[index];
                    final isSelected = _selectedMinistry == ministry;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(ministry),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedMinistry = ministry);
                        },
                        selectedColor: const Color(0xFFE2E8F0),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.black54,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Members List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getParticipants(
                chapelId: headType == 'chapel' ? userProfile!['chapelId'] : _selectedViewChapelId,
                clusterId: (headType == 'cluster' && _selectedViewChapelId == null) 
                    ? userProfile!['clusterId'] 
                    : (headType == 'admin' && _selectedViewChapelId == null) ? _selectedViewClusterId : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No added members yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        Text('Please add your first members.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }

                final filteredMembers = _filterAndSortMembers(snapshot.data!);
                if (filteredMembers.isEmpty) {
                  return const Center(child: Text('No members match your search.'));
                }

                final grouped = _groupMembers(filteredMembers);
                final sortedKeys = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final char = sortedKeys[index];
                    final members = grouped[char]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                          child: Text(char, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        ),
                        ...members.map((m) => _buildMemberCard(m)).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeSelector(String headType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              if (headType == 'admin')
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.getClusters(),
                    builder: (context, snapshot) {
                      return DropdownButtonFormField<String>(
                        value: _selectedViewClusterId,
                        decoration: const InputDecoration(labelText: 'Cluster', border: InputBorder.none),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All Clusters")),
                          if (snapshot.hasData)
                            ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedViewClusterId = val;
                            _selectedViewChapelId = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              if (headType == 'admin') const SizedBox(width: 16),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _selectedViewClusterId != null ? _db.getChapels(_selectedViewClusterId!) : const Stream.empty(),
                  builder: (context, snapshot) {
                    return DropdownButtonFormField<String>(
                      value: _selectedViewChapelId,
                      decoration: const InputDecoration(labelText: 'Chapel', border: InputBorder.none),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Chapels")),
                        if (snapshot.hasData)
                          ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                      ],
                      onChanged: _selectedViewClusterId == null && headType == 'admin' ? null : (val) {
                        setState(() => _selectedViewChapelId = val);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> m) {
    final String fullName = m['fullName'] ?? 'Unknown';
    final List ministries = m['ministries'] as List? ?? [];
    final String ministryText = ministries.isNotEmpty ? ministries.first : 'No Ministry';
    final String location = m['chapelName'] ?? m['clusterName'] ?? '';
    final bool isMe = m['id'] == user?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: isMe ? Border.all(color: const Color(0xFF7A0000), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue[50],
          backgroundImage: m['profileImageUrl'] != null ? NetworkImage(m['profileImageUrl']) : null,
          child: m['profileImageUrl'] == null
              ? Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isMe ? "$fullName (You)" : fullName,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: isMe ? const Color(0xFF7A0000) : Colors.black,
                ),
              ),
            ),
            if (m['head'] == 'admin')
              _buildBadge('ADMIN', Colors.blue)
            else if (m['head'] == 'cluster')
              _buildBadge('CLUSTER HEAD', Colors.orange)
            else if (m['head'] == 'chapel')
              _buildBadge('CHAPEL HEAD', Colors.green),
          ],
        ),
        subtitle: Text(
          '$ministryText • $location',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDetailScreen(member: m),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
