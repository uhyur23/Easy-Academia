import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../core/user_role.dart';
import '../../services/school_data_service.dart';
import '../../models/activity.dart';
import 'activity_list_item.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Activity History',
          style: AppTypography.header.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          Expanded(child: _buildActivityList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
                      surface: AppColors.surface,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Date',
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: AppTypography.header.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final state = context.watch<AppState>();
        final schoolId = state.schoolId ?? '';
        final staffId = state.activeRole == UserRole.staff
            ? state.userId
            : null;

        final allActivities = service.getActivitiesForStaff(schoolId, staffId);

        // Filter by selected date
        final dayActivities = allActivities.where((a) {
          return a.dateTime.year == _selectedDate.year &&
              a.dateTime.month == _selectedDate.month &&
              a.dateTime.day == _selectedDate.day;
        }).toList();

        // Sort by time
        dayActivities.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        if (dayActivities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy_rounded,
                  size: 60,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  'No activities for this date',
                  style: AppTypography.body.copyWith(color: Colors.white54),
                ),
              ],
            ),
          ).animate().fadeIn();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: dayActivities.length,
          itemBuilder: (context, index) {
            final activity = dayActivities[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActivityListItem(
                activity: activity,
                // We typically assume history is view-only or also editable?
                // ActivityListItem supports delete if callback provided.
                // Let's allow delete in history too.
                onDelete: () => _confirmDelete(context, activity),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Activity?', style: AppTypography.header),
        content: Text(
          'Are you sure you want to remove "${activity.title}"?',
          style: AppTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SchoolDataService>().deleteActivity(activity.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
