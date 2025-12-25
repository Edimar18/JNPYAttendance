import 'package:flutter/material.dart';

class ActivitiesTab extends StatelessWidget {
  const ActivitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activities')),
      body: const Center(child: Text('Activities Tab Content')),
    );
  }
}
