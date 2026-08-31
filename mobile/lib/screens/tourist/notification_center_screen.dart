import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// ForestGuard - Notification Center (Image 5)
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'SOS Reported - Ranger Res...',
      'subtitle': 'Emergency signal triggered in Sector 7. Unit Charlie is en route...',
      'tag': 'CRITICAL',
      'tagColor': const Color(0xFFBA1A1A),
      'tagBg': const Color(0xFFFFDAD6),
      'borderColor': const Color(0xFFBA1A1A),
      'icon': Icons.warning_amber_rounded,
      'iconBg': const Color(0xFFFFDAD6),
      'iconColor': const Color(0xFFBA1A1A),
      'time': 'Just now',
    },
    {
      'title': 'Danger Zone Updated',
      'subtitle': 'Tracked animal (ID: T-44) has moved into Sector 5. Recommen...',
      'tag': 'WARNING',
      'tagColor': const Color(0xFF7D5200),
      'tagBg': const Color(0xFFFFDEA1),
      'borderColor': const Color(0xFFD98200),
      'icon': Icons.priority_high_rounded,
      'iconBg': const Color(0xFF5D4000),
      'iconColor': Colors.amber,
      'time': '12m ago',
    },
    {
      'title': 'Alert Closed - North Trail is ...',
      'subtitle': 'Fallen debris cleared by...',
      'tag': 'INFO',
      'tagColor': const Color(0xFF003822),
      'tagBg': const Color(0xFFA0F4C8),
      'borderColor': const Color(0xFF0E6C4A),
      'icon': Icons.check_circle_rounded,
      'iconBg': const Color(0xFF0E6C4A),
      'iconColor': Colors.white,
      'time': '1h ago',
    },
    {
      'title': 'New Sighting: Mule Deer ve...',
      'subtitle': 'Camera trap C-12 captured...',
      'tag': 'SIGHTING',
      'tagColor': const Color(0xFF005234),
      'tagBg': const Color(0xFFA0F4C8),
      'borderColor': const Color(0xFFA0F4C8),
      'icon': Icons.visibility_rounded,
      'iconBg': const Color(0xFFA0F4C8),
      'iconColor': const Color(0xFF005234),
      'time': '3h ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.primary),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80'),
            ),
            const SizedBox(width: 8),
            const Text(
              'ForestGuard',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.primary),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.primary),
                onPressed: () {},
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA1A1A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header Row with Title & MARK ALL READ (Image 5)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Center',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitoring sector activity and alerts.',
                    style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'MARK ALL\nREAD',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Notification Items List with Left Color Bars (Image 5)
          ..._notifications.map((item) => _buildNotificationCard(item)),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: item['borderColor'] as Color, width: 5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item['iconBg'] as Color,
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item['tagBg'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '• ${item['tag']}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: item['tagColor'] as Color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        item['time'] as String,
                        style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle'] as String,
                    style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.3),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
