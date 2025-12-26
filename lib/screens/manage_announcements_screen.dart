import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const ManageAnnouncementsScreen({super.key, required this.userProfile});

  @override
  State<ManageAnnouncementsScreen> createState() => _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final DatabaseService _db = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;

  // Filters for Admin
  String? _filterClusterId;
  String? _filterChapelId;

  @override
  Widget build(BuildContext context) {
    final String headType = widget.userProfile['head'] ?? 'none';
    final String userClusterId = widget.userProfile['clusterId'] ?? '';

    Query query = FirebaseFirestore.instance.collection('announcements');

    if (headType == 'admin') {
      if (_filterChapelId != null) {
        query = query.where('chapelIds', arrayContains: _filterChapelId);
      } else if (_filterClusterId != null) {
        query = query.where('clusterId', isEqualTo: _filterClusterId);
      }
    } else {
      // Cluster Head sees only their cluster's announcements
      query = query.where('clusterId', isEqualTo: userClusterId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Manage Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (headType == 'admin')
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAnnouncementDialog(),
        backgroundColor: const Color(0xFF7A0000),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No announcements found.'));
          }

          final announcements = snapshot.data!.docs.toList();
          // Sort in-memory to handle the lack of composite index for mixed queries
          announcements.sort((a, b) {
            Timestamp t1 = (a.data() as Map<String, dynamic>)['createdAt'] ?? Timestamp.now();
            Timestamp t2 = (b.data() as Map<String, dynamic>)['createdAt'] ?? Timestamp.now();
            return t2.compareTo(t1);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final ann = announcements[index].data() as Map<String, dynamic>;
              final docId = announcements[index].id;
              
              return Dismissible(
                key: Key(docId),
                background: Container(
                  color: Colors.blue,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await _showDeleteConfirm(docId);
                  } else {
                    _showAddEditAnnouncementDialog(docId: docId, data: ann);
                    return false;
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ann['scope']?.toString().toUpperCase() ?? 'GENERAL',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF1E5631), fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            ann['createdAt'] != null 
                              ? DateFormat('MMM d, yyyy').format((ann['createdAt'] as Timestamp).toDate())
                              : '',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(ann['title'] ?? 'No Title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(ann['content'] ?? '', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Announcements'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getClusters(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: _filterClusterId,
                    decoration: const InputDecoration(labelText: 'Cluster'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Clusters")),
                      if (snapshot.hasData)
                        ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        _filterClusterId = val;
                        _filterChapelId = null;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _filterClusterId != null ? _db.getChapels(_filterClusterId!) : const Stream.empty(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: _filterChapelId,
                    decoration: const InputDecoration(labelText: 'Chapel'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text("All Chapels")),
                      if (snapshot.hasData)
                        ...snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))),
                    ],
                    onChanged: _filterClusterId == null ? null : (val) => setDialogState(() => _filterChapelId = val),
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

  Future<bool?> _showDeleteConfirm(String docId) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
              Navigator.pop(context, true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddEditAnnouncementDialog({String? docId, Map<String, dynamic>? data}) {
    final titleController = TextEditingController(text: data?['title'] ?? '');
    final contentController = TextEditingController(text: data?['content'] ?? '');
    
    final String headType = widget.userProfile['head'] ?? 'none';
    
    // Initialize scope based on existing data or default
    String scope = data?['scope'] ?? (headType == 'admin' ? 'parish' : 'cluster');
    String? selectedClusterId = data?['clusterId'] ?? (headType == 'cluster' ? widget.userProfile['clusterId'] : null);
    List<String> selectedChapelIds = List<String>.from(data?['chapelIds'] ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(docId == null ? 'Add Announcement' : 'Edit Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content'), maxLines: 3),
                const SizedBox(height: 16),
                
                // Scope Dropdown
                DropdownButtonFormField<String>(
                  value: scope,
                  decoration: const InputDecoration(labelText: 'Target Scope'),
                  items: [
                    if (headType == 'admin')
                      const DropdownMenuItem(value: 'parish', child: Text('Parish Wide')),
                    const DropdownMenuItem(value: 'cluster', child: Text('Entire Cluster')),
                    const DropdownMenuItem(value: 'chapel', child: Text('Specific Chapels')),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      scope = val!;
                      // Reset selections when scope changes, unless admin choosing cluster/chapel
                      if (scope == 'parish') {
                        selectedClusterId = null;
                        selectedChapelIds = [];
                      }
                    });
                  },
                ),

                // Cluster Dropdown (Visible for Admin choosing Cluster/Chapel scope)
                if (headType == 'admin' && (scope == 'cluster' || scope == 'chapel')) ...[
                  const SizedBox(height: 16),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.getClusters(),
                    builder: (context, snapshot) {
                      return DropdownButtonFormField<String>(
                        value: selectedClusterId,
                        decoration: const InputDecoration(labelText: 'Select Cluster'),
                        items: snapshot.data?.map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(c['name']),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedClusterId = val;
                            selectedChapelIds = []; // Reset chapels when cluster changes
                          });
                        },
                      );
                    },
                  ),
                ],

                // Chapel Checkboxes (Visible if scope is Chapel)
                if (scope == 'chapel' && selectedClusterId != null) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Select Chapels:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.getChapels(selectedClusterId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      return Column(
                        children: snapshot.data!.map((chapel) {
                          return CheckboxListTile(
                            dense: true,
                            title: Text(chapel['name'], style: const TextStyle(fontSize: 14)),
                            value: selectedChapelIds.contains(chapel['id']),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val!) {
                                  selectedChapelIds.add(chapel['id']);
                                } else {
                                  selectedChapelIds.remove(chapel['id']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) return;
                
                // Validation for Cluster/Chapel scope
                if (scope != 'parish' && selectedClusterId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a cluster")));
                  return;
                }
                if (scope == 'chapel' && selectedChapelIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one chapel")));
                  return;
                }

                Map<String, dynamic> annData = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'scope': scope,
                  'createdBy': user?.uid,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                if (scope == 'parish') {
                  annData['clusterId'] = null;
                  annData['scopeId'] = 'parish';
                  annData['chapelIds'] = [];
                } else if (scope == 'cluster') {
                  annData['clusterId'] = selectedClusterId;
                  annData['scopeId'] = selectedClusterId;
                  annData['chapelIds'] = [];
                } else if (scope == 'chapel') {
                  annData['clusterId'] = selectedClusterId;
                  annData['chapelIds'] = selectedChapelIds;
                  // Set scopeId to first chapel for basic filtering
                  if (selectedChapelIds.isNotEmpty) {
                    annData['scopeId'] = selectedChapelIds.first;
                  }
                }

                if (docId == null) {
                  await FirebaseFirestore.instance.collection('announcements').add(annData);
                } else {
                  await FirebaseFirestore.instance.collection('announcements').doc(docId).update(annData);
                }
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
