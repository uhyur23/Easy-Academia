import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/design_system.dart';
import '../../services/school_data_service.dart';

class AnnouncementFeed extends StatelessWidget {
  final String schoolId;

  const AnnouncementFeed({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context) {
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final notifications = service.getAnnouncementsForSchool(schoolId);

        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'School Announcements',
              style: AppTypography.label.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.take(5).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final dateStr = DateFormat(
                  'MMM d, y',
                ).format(notification.timestamp);

                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(
                                notification.type,
                              ).withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.type.toUpperCase(),
                              style: TextStyle(
                                color: _getTypeColor(notification.type),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dateStr,
                            style: AppTypography.body.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: AppTypography.body.copyWith(fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'event':
        return Colors.purpleAccent;
      case 'holiday':
        return Colors.greenAccent;
      default:
        return AppColors.primary;
    }
  }
}
