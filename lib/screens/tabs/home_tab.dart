import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final DatabaseService _db = DatabaseService();
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userProfile;
  final Color primaryColor = const Color(0xFF7A0000);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (user != null) {
      final profile = await _db.getUserProfile(user!.uid);
      if (mounted) setState(() => userProfile = profile);
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.church, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DANSOLIHON PARISH',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 18),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      const Icon(Icons.notifications_none, size: 28),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      )
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Greeting Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(userProfile?['profileImageUrl'] ?? 'https://via.placeholder.com/150'),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userProfile?['fullName'] ?? 'User',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: TextStyle(color: Colors.blue[300], fontSize: 14),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Announcements Slider
              _buildAnnouncements(),

              const SizedBox(height: 32),
              _buildSectionHeader('Top Clusters', 'SEE ALL'),
              const SizedBox(height: 16),
              _buildRankingCard(),

              const SizedBox(height: 32),
              _buildSectionHeader('Attendance Summary', 'View Report'),
              const SizedBox(height: 16),
              _buildAttendanceGraph(),

              const SizedBox(height: 32),
              _buildSectionHeader('Today\'s Activities', ''),
              _buildActivities(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncements() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getAnnouncements(userProfile?['chapelId'], userProfile?['clusterId']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
        final anns = snapshot.data!;
        
        return SizedBox(
          height: 120,
          child: PageView.builder(
            itemCount: anns.length,
            itemBuilder: (context, index) {
              final ann = anns[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                      child: Icon(Icons.campaign, color: Colors.blue[400]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(ann['title'] ?? 'Announcement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(ann['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRankingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _rankingItem('01', 'Cluster 1', '342', '98%', Colors.orange),
          const Divider(height: 24),
          _rankingItem('02', 'Cluster 3', '285', '95%', Colors.blue),
          const Divider(height: 24),
          _rankingItem('03', 'Cluster 2', '156', '92%', Colors.green),
        ],
      ),
    );
  }

  Widget _rankingItem(String rank, String name, String count, String consistency, Color color) {
    return Row(
      children: [
        Text(rank, style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('$consistency CONSISTENCY', style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(count, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
            const Text('↗ 12%', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildAttendanceGraph() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 3),
                const FlSpot(1, 1),
                const FlSpot(2, 4),
                const FlSpot(3, 2),
                const FlSpot(4, 5),
              ],
              isCurved: true,
              color: primaryColor,
              barWidth: 4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: primaryColor.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivities() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getActivities(userProfile?['chapelId'], userProfile?['clusterId']),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No Activities Today', style: TextStyle(color: Colors.grey))),
          );
        }
        return Column(
          children: snapshot.data!.map((act) => _activityCard(act)).toList(),
        );
      },
    );
  }

  Widget _activityCard(Map<String, dynamic> act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(image: NetworkImage('https://via.placeholder.com/80'), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPCOMING', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(act['name'] ?? 'Activity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(act['time'] ?? 'TBA', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(act['location'] ?? 'Location TBA', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: Colors.grey)
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(action, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
