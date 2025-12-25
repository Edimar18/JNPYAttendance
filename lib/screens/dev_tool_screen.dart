import 'package:flutter/material.dart';
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Developer Tools', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Clusters & Chapels'),
              Tab(text: 'Ministries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClustersTab(),
            _buildMinistriesTab(),
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
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
