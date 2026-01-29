import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../services/school_data_service.dart';
import '../../core/design_system.dart';

class ActivityListItem extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onDelete; // Callback for delete action

  const ActivityListItem({super.key, required this.activity, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: activity.status == ActivityStatus.completed
                  ? Colors.green.withAlpha(20)
                  : AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: activity.status == ActivityStatus.completed
                  ? const Icon(Icons.check, color: Colors.green, size: 28)
                  : Text(
                      '${activity.dateTime.hour}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTypography.label.copyWith(
                    decoration: activity.status == ActivityStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: activity.status == ActivityStatus.completed
                        ? Colors.white38
                        : Colors.white,
                  ),
                ),
                Text(
                  '${activity.location} • ${activity.status == ActivityStatus.completed ? "Done" : "Upcoming"}',
                  style: AppTypography.body.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Checkbox(
            value: activity.status == ActivityStatus.completed,
            activeColor: Colors.green,
            side: const BorderSide(color: Colors.white24, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: activity.status == ActivityStatus.completed
                ? null // Locked if completed
                : (val) {
                    final newStatus = val == true
                        ? ActivityStatus.completed
                        : ActivityStatus.upcoming;
                    Provider.of<SchoolDataService>(
                      context,
                      listen: false,
                    ).updateActivityStatus(activity.id, newStatus);
                  },
          ),
          if (onDelete != null && activity.status != ActivityStatus.completed)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38),
              onPressed: onDelete,
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
