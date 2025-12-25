import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class DevToolScreen extends StatefulWidget {
  const DevToolScreen({super.key});

  @override
  State<DevToolScreen> createState() => _DevToolScreenState();
}

class _DevToolScreenState extends State<DevToolScreen> {
  final DatabaseService _db = DatabaseService();
  final Color primaryColor = const Color(0xFF7A0000);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Developer Tools', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(text: 'Clusters & Chapels'),
              Tab(text: 'Ministries'),
              Tab(text: 'Announcements & Activities'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClustersTab(),
            _buildMinistriesTab(),
            _buildAnnouncementsActivitiesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildClustersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getClusters(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final clusters = snapshot.data!;
        return ListView.builder(
          itemCount: clusters.length + 1,
          itemBuilder: (context, index) {
            if (index == clusters.length) {
              return ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Add New Cluster', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                onTap: () => _showAddEditDialog(context, type: 'Cluster'),
              );
            }
            final cluster = clusters[index];
            return ExpansionTile(
              title: Text(cluster['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showAddEditDialog(context, type: 'Cluster', id: cluster['id'], initialValue: cluster['name']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, 'Cluster', cluster['id']),
                  ),
                ],
              ),
              children: [
                _buildChapelList(cluster['id']),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildChapelList(String clusterId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getChapels(clusterId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final chapels = snapshot.data!;
        return Column(
          children: [
            ...chapels.map((chapel) => ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 16),
              title: Text(chapel['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showAddEditDialog(context, type: 'Chapel', id: chapel['id'], initialValue: chapel['name']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, 'Chapel', chapel['id']),
                  ),
                ],
              ),
            )),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 32),
              leading: const Icon(Icons.add, size: 20, color: Colors.blue),
              title: const Text('Add Chapel', style: TextStyle(color: Colors.blue, fontSize: 14)),
              onTap: () => _showAddEditDialog(context, type: 'Chapel', clusterId: clusterId),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMinistriesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getMinistries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final ministries = snapshot.data!;
        return ListView.builder(
          itemCount: ministries.length + 1,
          itemBuilder: (context, index) {
            if (index == ministries.length) {
              return ListTile(
                leading: const Icon(Icons.add, color: Colors.green),
                title: const Text('Add New Ministry', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                onTap: () => _showAddEditDialog(context, type: 'Ministry'),
              );
            }
            final ministry = ministries[index];
            return ListTile(
              title: Text(ministry['name']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showAddEditDialog(context, type: 'Ministry', id: ministry['id'], initialValue: ministry['name']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirm(context, 'Ministry', ministry['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsActivitiesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Announcements'),
        _buildAnnouncementsList(),
        const Divider(height: 32),
        _buildSectionTitle('Activities'),
        _buildActivitiesList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: () => _showAddActivityOrAnnDialog(title.substring(0, title.length - 1)),
          icon: const Icon(Icons.add, size: 18),
          label: Text('Add ${title.substring(0, title.length - 1)}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getAnnouncements(null, null), // Fetch all for dev tool
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final anns = snapshot.data!;
        if (anns.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('No announcements yet.'));
        return Column(
          children: anns.map((ann) => ListTile(
            title: Text(ann['title'] ?? ''),
            subtitle: Text('Scope: ${ann['scope']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showAddActivityOrAnnDialog('Announcement', data: ann)),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _showDeleteConfirm(context, 'Announcement', ann['id'])),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildActivitiesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getActivities(null, null), // Fetch all for dev tool
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final acts = snapshot.data!;
        if (acts.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('No activities yet.'));
        return Column(
          children: acts.map((act) => ListTile(
            title: Text(act['name'] ?? ''),
            subtitle: Text('Scope: ${act['scope']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showAddActivityOrAnnDialog('Activity', data: act)),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _showDeleteConfirm(context, 'Activity', act['id'])),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  void _showAddActivityOrAnnDialog(String type, {Map<String, dynamic>? data}) {
    final titleController = TextEditingController(text: data != null ? (type == 'Announcement' ? data['title'] : data['name']) : '');
    final infoController = TextEditingController(text: data != null ? (type == 'Announcement' ? data['content'] : data['information']) : '');
    final locationController = TextEditingController(text: data != null ? data['location'] : '');
    final timeController = TextEditingController(text: data != null ? data['time'] : '');
    String scope = data != null ? data['scope'] : 'parish';
    String? scopeId = data != null ? data['scopeId'] : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(data == null ? 'Add $type' : 'Edit $type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: InputDecoration(labelText: type == 'Announcement' ? 'Title' : 'Activity Name')),
                TextField(controller: infoController, decoration: InputDecoration(labelText: type == 'Announcement' ? 'Content' : 'Information'), maxLines: 2),
                if (type == 'Activity') ...[
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                  TextField(controller: timeController, decoration: const InputDecoration(labelText: 'Time (e.g. 10:00 AM)')),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: ['parish', 'cluster', 'chapel'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    setState(() {
                      scope = val!;
                      scopeId = null;
                    });
                  },
                ),
                if (scope == 'cluster')
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.getClusters(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return DropdownButtonFormField<String>(
                        value: scopeId,
                        decoration: const InputDecoration(labelText: 'Select Cluster'),
                        items: snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                        onChanged: (val) => setState(() => scopeId = val),
                      );
                    },
                  ),
                if (scope == 'chapel')
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.getClusters(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'Select Cluster First'),
                            items: snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                            onChanged: (val) {
                              setState(() {
                                scopeId = null; // Reset chapel when cluster changes
                                _currentClusterIdForChapel = val;
                              });
                            },
                          ),
                          if (_currentClusterIdForChapel != null)
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _db.getChapels(_currentClusterIdForChapel!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return DropdownButtonFormField<String>(
                                  value: scopeId,
                                  decoration: const InputDecoration(labelText: 'Select Chapel'),
                                  items: snapshot.data!.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['name']))).toList(),
                                  onChanged: (val) => setState(() => scopeId = val),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                Map<String, dynamic> itemData = {
                  'scope': scope,
                  'scopeId': scopeId,
                  'createdBy': user?.uid,
                };

                if (type == 'Announcement') {
                  itemData['title'] = titleController.text;
                  itemData['content'] = infoController.text;
                } else {
                  itemData['name'] = titleController.text;
                  itemData['information'] = infoController.text;
                  itemData['location'] = locationController.text;
                  itemData['time'] = timeController.text;
                  itemData['date'] = DateTime.now(); // For demo, use now. Real app might need a picker.
                  itemData['status'] = 'open';
                }

                if (data == null) {
                  type == 'Announcement' ? await _db.addAnnouncement(itemData) : await _db.addActivity(itemData);
                } else {
                  type == 'Announcement' ? await _db.updateAnnouncement(data['id'], itemData) : await _db.updateActivity(data['id'], itemData);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String? _currentClusterIdForChapel;

  void _showAddEditDialog(BuildContext context, {required String type, String? id, String? clusterId, String initialValue = ''}) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'Add $type' : 'Edit $type'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: '$type Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                if (type == 'Cluster') {
                  id == null ? await _db.addCluster(name) : await _db.updateCluster(id, name);
                } else if (type == 'Chapel') {
                  id == null ? await _db.addChapel(name, clusterId!) : await _db.updateChapel(id, name);
                } else if (type == 'Ministry') {
                  id == null ? await _db.addMinistry(name) : await _db.updateMinistry(id, name);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String type, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $type? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (type == 'Cluster') await _db.deleteCluster(id);
              if (type == 'Chapel') await _db.deleteChapel(id);
              if (type == 'Ministry') await _db.deleteMinistry(id);
              if (type == 'Announcement') await _db.deleteAnnouncement(id);
              if (type == 'Activity') await _db.deleteActivity(id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
