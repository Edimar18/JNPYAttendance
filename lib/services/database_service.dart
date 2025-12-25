import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if profile exists for UID
  Future<bool> profileExists(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Save User Profile
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data);
  }

  // Clusters
  Stream<List<Map<String, dynamic>>> getClusters() {
    return _db.collection('clusters').orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addCluster(String name) async {
    await _db.collection('clusters').add({'name': name});
  }

  Future<void> updateCluster(String id, String name) async {
    await _db.collection('clusters').doc(id).update({'name': name});
  }

  Future<void> deleteCluster(String id) async {
    // Also delete chapels in this cluster
    var chapels = await _db.collection('chapels').where('clusterId', isEqualTo: id).get();
    for (var doc in chapels.docs) {
      await doc.reference.delete();
    }
    await _db.collection('clusters').doc(id).delete();
  }

  // Chapels
  Stream<List<Map<String, dynamic>>> getChapels(String clusterId) {
    return _db
        .collection('chapels')
        .where('clusterId', isEqualTo: clusterId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addChapel(String name, String clusterId) async {
    await _db.collection('chapels').add({
      'name': name,
      'clusterId': clusterId,
    });
  }

  Future<void> updateChapel(String id, String name) async {
    await _db.collection('chapels').doc(id).update({'name': name});
  }

  Future<void> deleteChapel(String id) async {
    await _db.collection('chapels').doc(id).delete();
  }

  // Ministries
  Stream<List<Map<String, dynamic>>> getMinistries() {
    return _db.collection('ministries').orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addMinistry(String name) async {
    await _db.collection('ministries').add({'name': name});
  }

  Future<void> updateMinistry(String id, String name) async {
    await _db.collection('ministries').doc(id).update({'name': name});
  }

  Future<void> deleteMinistry(String id) async {
    await _db.collection('ministries').doc(id).delete();
  }

  // Legacy (Keep for one-click setup if needed)
  Future<void> generateInitialData() async {
    List<String> clusterNames = ['Cluster 1', 'Cluster 2', 'Cluster 3'];
    for (var name in clusterNames) {
      var ref = await _db.collection('clusters').add({'name': name});
      for (int i = 1; i <= 3; i++) {
        await _db.collection('chapels').add({
          'name': 'Chapel $i of $name',
          'clusterId': ref.id,
        });
      }
    }
    List<String> ministries = ['Worship', 'Kids', 'Technical', 'Ushering', 'Media'];
    for (var m in ministries) {
      await _db.collection('ministries').add({'name': m});
    }
  }
}
