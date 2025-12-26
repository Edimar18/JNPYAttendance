import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final PageController _announcementController = PageController();
  int _currentAnnouncementPage = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
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
                        'JNPYA MONITORING SYSTEM',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
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
        
        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _announcementController,
                onPageChanged: (page) {
                  setState(() => _currentAnnouncementPage = page);
                },
                itemCount: anns.length,
                itemBuilder: (context, index) {
                  final ann = anns[index];
                  return GestureDetector(
                    onTap: () => _showAnnouncementDetail(ann),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          ann['scope']?.toUpperCase() ?? 'GENERAL',
                                          style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        ann['createdAt'] != null 
                                          ? DateFormat('h:mm a').format((ann['createdAt'] as Timestamp).toDate())
                                          : '',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ann['title'] ?? 'Announcement', 
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ann['content'] ?? '', 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: const TextStyle(color: Colors.grey, fontSize: 13)
                                  ),
                                  const Spacer(),
                                  FutureBuilder<Map<String, dynamic>?>(
                                    future: _db.getUserProfile(ann['createdBy'] ?? ''),
                                    builder: (context, userSnap) {
                                      if (!userSnap.hasData) return const SizedBox();
                                      final creator = userSnap.data!;
                                      return Row(
                                        children: [
                                          Icon(Icons.person_pin, size: 14, color: primaryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${creator['fullName']} • ${creator['head']?.toUpperCase() ?? 'MEMBER'}',
                                            style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (anns.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(anns.length, (index) {
                  return Container(
                    width: _currentAnnouncementPage == index ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentAnnouncementPage == index ? primaryColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
          ],
        );
      },
    );
  }

  void _showAnnouncementDetail(Map<String, dynamic> ann) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      ann['scope']?.toUpperCase() ?? 'PARISH',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ann['title'] ?? 'Announcement',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ann['content'] ?? '',
                    style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _db.getUserProfile(ann['createdBy'] ?? ''),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox();
                      final creator = userSnap.data!;
                      final date = ann['createdAt'] != null ? (ann['createdAt'] as Timestamp).toDate() : DateTime.now();
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: creator['profileImageUrl'] != null ? NetworkImage(creator['profileImageUrl']) : null,
                            child: creator['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(creator['fullName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '${creator['head']?.toUpperCase() ?? 'MEMBER'} • ${DateFormat('MMM d, h:mm a').format(date)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CLOSE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
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
      ),
    );
  }

  Widget _buildAttendanceGraph() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('94.2%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Average Consistency', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+5.2% vs last month',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[100]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                      reservedSize: 35,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Oct 3', 'Oct 10', 'Oct 17', 'Oct 24', 'Oct 31'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 85),
                      const FlSpot(1, 90),
                      const FlSpot(2, 88),
                      const FlSpot(3, 94),
                      const FlSpot(4, 96),
                    ],
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivities() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getActivities(userProfile?['chapelId'], userProfile?['clusterId']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // Filter: Strictly TODAY only
        final filteredActivities = snapshot.data!.where((act) {
          final actDate = (act['date'] as Timestamp).toDate();
          final actDay = DateTime(actDate.year, actDate.month, actDate.day);
          return actDay.isAtSameMomentAs(today);
        }).toList();

        filteredActivities.sort((a, b) => (a['date'] as Timestamp).compareTo(b['date'] as Timestamp));

        if (filteredActivities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No Activities Today', style: TextStyle(color: Colors.grey))),
          );
        }

        return Column(
          children: filteredActivities.map((act) => _activityCard(act, 'TODAY')).toList(),
        );
      },
    );
  }

  Widget _activityCard(Map<String, dynamic> act, String status) {
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available, color: Color(0xFF1E5631), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status, 
                  style: const TextStyle(
                    color: Color(0xFF1E5631), 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  act['name'] ?? 'Activity', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
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
          const Icon(Icons.chevron_right, color: Colors.grey)
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
