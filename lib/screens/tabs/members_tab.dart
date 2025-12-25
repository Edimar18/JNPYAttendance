import 'package:flutter/material.dart';

class MembersTab extends StatelessWidget {
  const MembersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: const Center(child: Text('Members Tab Content')),
    );
  }
}
