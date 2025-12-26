import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- CLOUDINARY CONFIGURATION ---
  final String cloudinaryCloudName = "dubuem6e9";
  final String cloudinaryUploadPreset = "PYCCAttendance";

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

  // User Profile
  Future<bool> profileExists(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    data['isVerified'] = data['isVerified'] ?? false;
    data['head'] = data['head'] ?? 'none';
    await _db.collection('users').doc(uid).set(data);
  }

  // Announcements
  Stream<List<Map<String, dynamic>>> getAnnouncements(String? chapelId, String? clusterId, {bool all = false}) {
    return _db.collection('announcements').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (all) return list;
      return list.where((ann) {
        String scope = ann['scope'] ?? 'parish';
        String? scopeId = ann['scopeId'];
        if (scope == 'parish') return true;
        if (scope == 'cluster' && scopeId == clusterId) return true;
        if (scope == 'chapel' && scopeId == chapelId) return true;
        return false;
      }).toList();
    });
  }

  Future<void> addAnnouncement(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('announcements').add(data);
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _db.collection('announcements').doc(id).update(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  // Activities
  Stream<List<Map<String, dynamic>>> getActivities(String? chapelId, String? clusterId, {bool all = false}) {
    // We order by date ascending for the home screen (upcoming first)
    return _db.collection('activities').orderBy('date', descending: false).snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (all) return list;
      return list.where((act) {
        String scope = act['scope'] ?? 'parish';
        String? scopeId = act['scopeId'];
        if (scope == 'parish') return true;
        if (scope == 'cluster' && scopeId == clusterId) return true;
        if (scope == 'chapel' && scopeId == chapelId) return true;
        return false;
      }).toList();
    });
  }

  Future<void> addActivity(Map<String, dynamic> data) async {
    await _db.collection('activities').add(data);
  }

  Future<void> updateActivity(String id, Map<String, dynamic> data) async {
    await _db.collection('activities').doc(id).update(data);
  }

  Future<void> deleteActivity(String id) async {
    await _db.collection('activities').doc(id).delete();
  }

  // Clusters & Chapels
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

  Stream<List<Map<String, dynamic>>> getChapels(String clusterId) {
    return _db.collection('chapels').where('clusterId', isEqualTo: clusterId).snapshots().map((snapshot) {
      var list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return list;
    });
  }

  Future<void> addChapel(String name, String clusterId) async {
    await _db.collection('chapels').add({'name': name, 'clusterId': clusterId});
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

  // Participants (Fetched from 'users' collection as per user feedback)
  Stream<List<Map<String, dynamic>>> getParticipants({String? chapelId, String? clusterId}) {
    Query query = _db.collection('users');
    
    if (chapelId != null) {
      query = query.where('chapelId', isEqualTo: chapelId);
    } else if (clusterId != null) {
      query = query.where('clusterId', isEqualTo: clusterId);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList());
  }

  Future<void> addParticipant(Map<String, dynamic> data) async {
    // Note: If adding people without accounts, this might still go to a 'participants' collection
    // or we can flag them in the 'users' collection as 'unregistered'.
    await _db.collection('users').add(data);
  }

  Future<void> updateParticipant(String id, Map<String, dynamic> data) async {
    await _db.collection('users').doc(id).update(data);
  }

  Future<void> deleteParticipant(String id) async {
    await _db.collection('users').doc(id).delete();
  }
}
