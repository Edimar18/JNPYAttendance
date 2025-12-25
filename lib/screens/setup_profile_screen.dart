import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String fullName = '';
  String age = '';
  String contactNumber = '';
  String gender = 'Male';
  String? selectedClusterId;
  String? selectedChapelId;
  List<String> selectedMinistries = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Your Profile', style: TextStyle(color: Colors.white)),
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
              // Gender Selection (Replacing Photo)
              const Text('Select Gender', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _genderButton('Male', Icons.male),
                  const SizedBox(width: 20),
                  _genderButton('Female', Icons.female),
                ],
              ),
              const SizedBox(height: 24),
              
              // Full Name
              _buildLabel('Full Name'),
              TextFormField(
                decoration: _inputDecoration('e.g. Juan Dela Cruz', Icons.person),
                onChanged: (val) => fullName = val,
                validator: (val) => val!.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 20),

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

              // Cluster Selection
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
                        selectedChapelId = null; // Reset chapel when cluster changes
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Chapel Selection (Dependent on Cluster)
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
                    disabledHint: const Text('Select Cluster First'),
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

              // Ministries (Multi-select)
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
                  : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderButton(String label, IconData icon) {
    bool isSelected = gender == label;
    return GestureDetector(
      onTap: () => setState(() => gender = label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? primaryColor : Colors.grey[300]!),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 30),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? primaryColor : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate() && selectedClusterId != null && selectedChapelId != null) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _db.saveUserProfile(user.uid, {
            'fullName': fullName,
            'age': age,
            'gender': gender,
            'contactNumber': contactNumber,
            'clusterId': selectedClusterId,
            'chapelId': selectedChapelId,
            'ministries': selectedMinistries,
            'badges': [],
            'role': 'Member',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields including Cluster and Chapel')));
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
