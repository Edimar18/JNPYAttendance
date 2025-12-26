import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

class AddActivityScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final String scope; // 'chapel', 'cluster', or 'parish'
  const AddActivityScreen({super.key, required this.userProfile, required this.scope});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final Color primaryColor = const Color(0xFF1E5631);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedClusterId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.scope == 'cluster' && widget.userProfile['head'] == 'cluster') {
      _selectedClusterId = widget.userProfile['clusterId'];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      if (widget.userProfile['head'] == 'admin' && widget.scope == 'cluster' && _selectedClusterId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a cluster')));
        return;
      }

      setState(() => _isLoading = true);
      try {
        final String formattedTime = _selectedTime!.format(context);
        
        Map<String, dynamic> activityData = {
          'name': _nameController.text,
          'location': _locationController.text,
          'information': _descriptionController.text,
          'date': Timestamp.fromDate(_selectedDate!),
          'time': formattedTime,
          'scope': widget.scope,
          'status': 'upcoming',
          'isOpen': false,
          'registeredChapels': [],
          'createdBy': widget.userProfile['id'],
          'timeCreated': FieldValue.serverTimestamp(),
        };

        if (widget.scope == 'chapel') {
          activityData['scopeId'] = widget.userProfile['chapelId'];
          activityData['clusterId'] = widget.userProfile['clusterId'];
        } else if (widget.scope == 'cluster') {
          activityData['scopeId'] = _selectedClusterId;
          activityData['clusterId'] = _selectedClusterId;
        } else {
          activityData['scopeId'] = 'parish';
        }

        await _db.addActivity(activityData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity created successfully!')));
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Activity', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Event Details', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Plan a gathering', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 32),

              if (widget.userProfile['head'] == 'admin' && widget.scope == 'cluster') ...[
                _buildLabel('Target Cluster'),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getClusters(),
                  builder: (context, snapshot) {
                    return DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Select Cluster', Icons.groups),
                      items: snapshot.data?.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['name']),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedClusterId = val),
                      validator: (val) => val == null ? 'Required' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              _buildLabel('Activity Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('e.g., Weekly Prayer Meet', null),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Date'),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      _selectedDate == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(_selectedDate!),
                      Icons.calendar_today,
                    ),
                    validator: (val) => _selectedDate == null ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('Time'),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      _selectedTime == null ? '--:-- --' : _selectedTime!.format(context),
                      Icons.access_time,
                    ),
                    validator: (val) => _selectedTime == null ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('Location'),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Main Chapel Hall', Icons.location_on),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Add details about the agenda, speakers, or requirements...', null),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_circle_outline),
                label: const Text('Create Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155))),
  );

  InputDecoration _inputDecoration(String hint, IconData? icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400]),
    prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  );
}
