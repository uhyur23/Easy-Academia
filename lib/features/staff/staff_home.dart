import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_state.dart';
import '../../core/user_role.dart';
import '../../core/design_system.dart';
import '../../services/school_data_service.dart';
import '../../models/activity.dart';
import 'attendance_screen.dart';
import 'grade_entry_screen.dart';
import 'activity_history_screen.dart';
import 'activity_list_item.dart';

class StaffHome extends StatelessWidget {
  const StaffHome({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Logout Confirmation',
          style: AppTypography.header.copyWith(fontSize: 20),
        ),
        content: const SizedBox(
          width: 300,
          child: Text(
            'Are you sure you want to logout? You will need to sign in again to access the portal.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppState>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(200),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final state = context.watch<AppState>();
        final schoolId = state.schoolId ?? '';
        // If it's a staff login, userId should be set. If admin, userId might be the uid.
        // Activities for staff rely on staffId.
        final staffId = state.activeRole == UserRole.staff
            ? state.userId
            : null;

        final activities = service.getActivitiesForStaff(schoolId, staffId);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Staff Portal',
              style: AppTypography.header.copyWith(fontSize: 20),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(
                  context.read<AppState>().userName,
                  activities.length,
                ),
                const SizedBox(height: 32),
                _buildQuickActions(context),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Activities',
                      style: AppTypography.label.copyWith(fontSize: 18),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivityHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('View History'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActivityList(context, activities),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddActivityDialog(context, service),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showAddActivityDialog(BuildContext context, SchoolDataService service) {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Schedule Activity',
            style: AppTypography.header.copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Activity Title',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setDialogState(() => selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Time:', style: AppTypography.body),
                          Text(
                            selectedTime.format(context),
                            style: AppTypography.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final appState = context.read<AppState>();
                  final schoolId = appState.schoolId ?? '';
                  final staffId = appState.userId;
                  final now = DateTime.now();
                  final activityTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  service.addActivity(
                    Activity(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      description: descController.text,
                      location: locationController.text,
                      dateTime: activityTime,
                      status: ActivityStatus.upcoming,
                      schoolId: schoolId,
                      staffId: staffId,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(String? name, int activityCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${name ?? 'Staff Member'}',
          style: AppTypography.header.copyWith(fontSize: 28),
        ).animate().fadeIn().moveX(begin: -20),
        Text(
          'You have $activityCount activities scheduled for today.',
          style: AppTypography.body,
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Attendance',
            icon: Icons.how_to_reg_rounded,
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            title: 'Grades',
            icon: Icons.grade_rounded,
            color: AppColors.accent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GradeEntryScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList(BuildContext context, List<Activity> activities) {
    // Filter for TODAY only
    final today = DateTime.now();
    final todayActivities = activities.where((a) {
      return a.dateTime.year == today.year &&
          a.dateTime.month == today.month &&
          a.dateTime.day == today.day;
    }).toList();

    // Sort by time
    todayActivities.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (todayActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            "No activities scheduled for today.",
            style: AppTypography.body.copyWith(color: Colors.white54),
          ),
        ),
      ).animate().fadeIn();
    }

    return Column(
      children: List.generate(todayActivities.length, (index) {
        final activity = todayActivities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ActivityListItem(
            activity: activity,
            onDelete: () => _confirmDelete(context, activity),
          ),
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, Activity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Activity?', style: AppTypography.header),
        content: Text(
          'Are you sure you want to remove "${activity.title}" from your schedule?',
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

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.label),
          ],
        ),
      ),
    );
  }
}
