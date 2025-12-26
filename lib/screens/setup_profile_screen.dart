import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final Color primaryColor = const Color(0xFF7A0000);

  File? _imageFile;
  String fullName = '';
  String age = '';
  String contactNumber = '';
  String gender = 'Male';
  String? selectedClusterId;
  String? selectedChapelId;
  List<String> selectedMinistries = [];
  bool _isLoading = false;

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // Force Square
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() => _imageFile = File(croppedFile.path));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Your Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profile Photo (Square Crop)
              Center(
                child: GestureDetector(
                  onTap: _pickAndCropImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12), // Square-ish with slight round
                      border: Border.all(color: primaryColor.withOpacity(0.5)),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Upload Photo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // 2. Full Name
              _buildLabel('Full Name'),
              TextFormField(
                decoration: _inputDecoration('e.g. Juan Dela Cruz', Icons.person),
                onChanged: (val) => fullName = val,
                validator: (val) => val!.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 20),

              // 3. Age & Contact
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Age'),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('00', null),
                          onChanged: (val) => age = val,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Contact Number'),
                        TextFormField(
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('09123456789', Icons.phone),
                          onChanged: (val) => contactNumber = val,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Gender (Move above Cluster)
              _buildLabel('Gender'),
              Row(
                children: [
                  Expanded(child: _genderButton('Male', Icons.male)),
                  const SizedBox(width: 12),
                  Expanded(child: _genderButton('Female', Icons.female)),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Cluster Selection
              _buildLabel('Cluster Group'),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getClusters(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Select Cluster', Icons.groups),
                    items: snapshot.data!.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name']),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedClusterId = val;
                        selectedChapelId = null;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // 6. Chapel Selection
              _buildLabel('Chapel Assignment'),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: selectedClusterId == null 
                  ? const Stream.empty() 
                  : _db.getChapels(selectedClusterId!),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    decoration: _inputDecoration(
                      selectedClusterId == null ? 'Select Cluster First' : 'Select Chapel', 
                      Icons.church
                    ),
                    value: selectedChapelId,
                    items: snapshot.data?.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name']),
                    )).toList(),
                    onChanged: selectedClusterId == null ? null : (val) {
                      setState(() => selectedChapelId = val);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // 7. Ministries
              _buildLabel('Ministries'),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getMinistries(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  return Wrap(
                    spacing: 8,
                    children: snapshot.data!.map((m) {
                      final name = m['name'] as String;
                      final isSelected = selectedMinistries.contains(name);
                      return FilterChip(
                        label: Text(name),
                        selected: isSelected,
                        selectedColor: primaryColor.withOpacity(0.2),
                        checkmarkColor: primaryColor,
                        onSelected: (selected) {
                          setState(() {
                            selected ? selectedMinistries.add(name) : selectedMinistries.remove(name);
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Complete Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String label, IconData icon) {
    bool isSelected = gender == label;
    return OutlinedButton.icon(
      onPressed: () => setState(() => gender = label),
      icon: Icon(icon, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : Colors.grey,
        side: BorderSide(color: isSelected ? primaryColor : Colors.grey[300]!),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate() && selectedClusterId != null && selectedChapelId != null) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a profile photo')));
        return;
      }

      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // 1. Upload to Cloudinary
          String? imageUrl = await _db.uploadToCloudinary(_imageFile!);
          
          if (imageUrl == null) {
            throw Exception("Failed to upload image. Please check Cloudinary config.");
          }

          // 2. Save to Firestore
          await _db.saveUserProfile(user.uid, {
            'fullName': fullName,
            'age': age,
            'gender': gender,
            'contactNumber': contactNumber,
            'clusterId': selectedClusterId,
            'chapelId': selectedChapelId,
            'ministries': selectedMinistries,
            'profileImageUrl': imageUrl,
            'badges': [],
            'role': 'Member',
            'isVerified': false,// Force false by default
            'head': 'chapel',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
    }
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  InputDecoration _inputDecoration(String hint, IconData? icon) => InputDecoration(
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
