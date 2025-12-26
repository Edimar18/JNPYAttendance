import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class AddParticipantScreen extends StatefulWidget {
  final Map<String, dynamic> currentUserProfile;
  const AddParticipantScreen({super.key, required this.currentUserProfile});

  @override
  State<AddParticipantScreen> createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final Color primaryColor = const Color(0xFF7A0000);

  File? _imageFile;
  String fullName = '';
  String age = '';
  String contactNumber = '';
  String gender = 'Male';
  DateTime? birthDate;
  String? selectedClusterId;
  String? selectedChapelId;
  List<String> selectedMinistries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    String headType = widget.currentUserProfile['head'] ?? 'none';
    if (headType == 'chapel') {
      selectedClusterId = widget.currentUserProfile['clusterId'];
      selectedChapelId = widget.currentUserProfile['chapelId'];
    } else if (headType == 'cluster') {
      selectedClusterId = widget.currentUserProfile['clusterId'];
    }
  }

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
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

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != birthDate) {
      setState(() {
        birthDate = picked;
        // Calculate age automatically
        age = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String headType = widget.currentUserProfile['head'] ?? 'none';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add New Participant', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo
              Center(
                child: GestureDetector(
                  onTap: _pickAndCropImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
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
              
              _buildLabel('Full Name'),
              TextFormField(
                decoration: _inputDecoration('e.g. Juan Dela Cruz', Icons.person),
                onChanged: (val) => fullName = val,
                validator: (val) => val!.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 20),

              // Birth Date & Age
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Birth Date'),
                        GestureDetector(
                          onTap: () => _selectBirthDate(context),
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: _inputDecoration(
                                birthDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(birthDate!),
                                Icons.calendar_today,
                              ),
                              validator: (val) => birthDate == null ? 'Required' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Age'),
                        TextFormField(
                          key: Key(age),
                          initialValue: age,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('00', null),
                          onChanged: (val) => age = val,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildLabel('Contact Number'),
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('09123456789', Icons.phone),
                onChanged: (val) => contactNumber = val,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              _buildLabel('Gender'),
              Row(
                children: [
                  Expanded(child: _genderButton('Male', Icons.male)),
                  const SizedBox(width: 12),
                  Expanded(child: _genderButton('Female', Icons.female)),
                ],
              ),
              const SizedBox(height: 24),

              // Cluster Selection
              _buildLabel('Cluster Group'),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getClusters(),
                builder: (context, snapshot) {
                  return DropdownButtonFormField<String>(
                    value: selectedClusterId,
                    decoration: _inputDecoration('Select Cluster', Icons.groups),
                    items: snapshot.data?.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['name']),
                    )).toList(),
                    onChanged: (headType == 'admin') ? (val) {
                      setState(() {
                        selectedClusterId = val;
                        selectedChapelId = null;
                      });
                    } : null,
                    validator: (val) => val == null ? 'Select cluster' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Chapel Selection
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
                    onChanged: (headType == 'admin' || headType == 'cluster') ? (val) {
                      setState(() => selectedChapelId = val);
                    } : null,
                    validator: (val) => val == null ? 'Select chapel' : null,
                  );
                },
              ),
              const SizedBox(height: 24),

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
                onPressed: _isLoading ? null : _saveParticipant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Add Participant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _saveParticipant() async {
    if (_formKey.currentState!.validate() && selectedClusterId != null && selectedChapelId != null) {
      setState(() => _isLoading = true);
      try {
        String? imageUrl;
        if (_imageFile != null) {
          imageUrl = await _db.uploadToCloudinary(_imageFile!);
        }

        await _db.addParticipant({
          'fullName': fullName,
          'age': age,
          'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
          'gender': gender,
          'contactNumber': contactNumber,
          'clusterId': selectedClusterId,
          'chapelId': selectedChapelId,
          'ministries': selectedMinistries,
          'profileImageUrl': imageUrl,
          'badges': [],
          'role': 'Member',
          'head': 'none',
          'isVerified': true,
          'isManual': true,
          'createdAt': FieldValue.serverTimestamp(),
          'addedBy': widget.currentUserProfile['fullName'],
          'addedByUid': widget.currentUserProfile['id'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Participant added successfully!')));
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
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
