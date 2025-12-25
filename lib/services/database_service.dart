import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CLOUDINARY CONFIGURATION ---
  // REPLACE THESE VALUES WITH YOUR OWN CLOUDINARY CREDENTIALS
  final String cloudinaryCloudName = "dubuem6e9";
  final String cloudinaryUploadPreset = "PYCCAttendance";
  // --------------------------------

  // Upload image to Cloudinary
  Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }

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
    // Force verification status to false on creation
    data['isVerified'] = false;
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
        .snapshots()
        .map((snapshot) {
          var list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
          return list;
        });
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

  // Legacy setup tool
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
