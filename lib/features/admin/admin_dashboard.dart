import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../services/school_data_service.dart';
import '../../models/staff.dart';
import '../../models/student.dart';
import '../../models/payment.dart';
import '../../models/subject.dart';
import '../shared/student_detail_screen.dart';

import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../utils/report_sheet_generator.dart';
import '../../models/grade_record.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isUploadingBadge = false;

  void _showAddAnnouncementDialog(
    BuildContext context,
    SchoolDataService service,
    String schoolId,
  ) {
    final messageController = TextEditingController();
    String selectedType = 'announcement';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Create School Announcement',
            style: AppTypography.header.copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Type',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'announcement',
                      child: Text('General Announcement'),
                    ),
                    DropdownMenuItem(
                      value: 'urgent',
                      child: Text('Urgent Update'),
                    ),
                    DropdownMenuItem(
                      value: 'event',
                      child: Text('School Event'),
                    ),
                    DropdownMenuItem(
                      value: 'holiday',
                      child: Text('Holiday/Break'),
                    ),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Message',
                    hintText: 'Enter the message for parents...',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (messageController.text.isNotEmpty) {
                  service.addAnnouncement(
                    message: messageController.text,
                    type: selectedType,
                    schoolId: schoolId,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement posted!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  late final List<Widget> _pages = [
    const _AdminOverview(),
    const StaffManagementSection(),
    const StudentDirectorySection(),
    const IncomeHistorySection(),
    const PerformanceReportsSection(),
    const SubjectManagementSection(),
  ];

  Future<void> _handleBadgeUpload() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image == null) return;

    setState(() => _isUploadingBadge = true);
    final error = await context.read<AppState>().uploadSchoolBadge(image);
    setState(() => _isUploadingBadge = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) _buildSidebar() else const SizedBox.shrink(),

          Expanded(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContents()),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppColors.surface,
      child: _buildSidebarContents(),
    );
  }

  Widget _buildSidebarContents() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Easy Academia',
                    style: AppTypography.header.copyWith(fontSize: 20),
                  ),
                  Text(
                    'Powered by Kuibit',
                    style: TextStyle(
                      color: Colors.white.withAlpha(80),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _SidebarItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          isSelected: _selectedIndex == 0,
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        _SidebarItem(
          icon: Icons.people_rounded,
          label: 'Staff Management',
          isSelected: _selectedIndex == 1,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        _SidebarItem(
          icon: Icons.person_rounded,
          label: 'Student Directory',
          isSelected: _selectedIndex == 2,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        _SidebarItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Income & Finance',
          isSelected: _selectedIndex == 3,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
        _SidebarItem(
          icon: Icons.analytics_rounded,
          label: 'Performance Reports',
          isSelected: _selectedIndex == 4,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
        _SidebarItem(
          icon: Icons.menu_book_rounded,
          label: 'Subject Management',
          isSelected: _selectedIndex == 5,
          onTap: () => setState(() => _selectedIndex = 5),
        ),
        const Spacer(),
        _SidebarItem(
          icon: Icons.logout_rounded,
          label: 'Logout',
          isSelected: false,
          onTap: () => _showLogoutDialog(context),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

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
            'Are you sure you want to logout? You will need to sign in again to access the dashboard.',
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

  Widget _buildHeader(BuildContext context) {
    final appState = context.watch<AppState>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width <= 900)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appState.schoolName ?? 'My School',
                style: AppTypography.label.copyWith(fontSize: 16),
              ),
              Text(
                appState.schoolId ?? 'Admin Dashboard',
                style: AppTypography.body.copyWith(
                  fontSize: 11,
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          _buildSchoolBadge(appState.badgeUrl),
        ],
      ),
    );
  }

  Widget _buildSchoolBadge(String? badgeUrl) {
    return InkWell(
      onTap: _isUploadingBadge ? null : _handleBadgeUpload,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: 'Click to upload school badge',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isUploadingBadge
                  ? AppColors.primary
                  : AppColors.primary.withAlpha(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _isUploadingBadge
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : _renderBadge(badgeUrl),
          ),
        ),
      ),
    );
  }

  Widget _renderBadge(String? badgeUrl) {
    if (badgeUrl == null) {
      return const Icon(Icons.school_rounded, color: AppColors.primary);
    }

    if (badgeUrl.startsWith('data:image')) {
      try {
        final base64String = badgeUrl.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image, color: AppColors.primary);
      }
    }

    return Image.network(
      badgeUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.school_rounded, color: AppColors.primary),
    );
  }

  Widget _buildMetricsGrid(SchoolDataService service, String schoolId) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);
        final students = service.getStudentsForSchool(schoolId);
        final staff = service.getStaffForSchool(schoolId);
        final activities = service.getActivitiesForSchool(schoolId);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _MetricCard(
              title: 'Total Students',
              value: students.length.toString(),
              icon: Icons.people,
              color: AppColors.primary,
            ),
            _MetricCard(
              title: 'Total Staff',
              value: staff.length.toString(),
              icon: Icons.badge,
              color: AppColors.accent,
            ),
            _MetricCard(
              title: 'Active Activities',
              value: activities.length.toString(),
              icon: Icons.bolt_rounded,
              color: AppColors.secondary,
            ),
            _MetricCard(
              title: 'Monthly Revenue',
              value:
                  '₦${service.calculateMonthlyRevenue(schoolId).toStringAsFixed(0)}',
              icon: Icons.monetization_on,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }

  void _showRecordIncomeDialog(
    BuildContext context,
    SchoolDataService service,
    String schoolId,
  ) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'School Fees';
    final categories = [
      'School Fees',
      'Exam Fee',
      'Excursion Fee',
      'Donation',
      'Sales',
      'Uniforms',
      'Books',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Record External Income',
            style: AppTypography.header.copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Income Category',
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₦)',
                    prefixText: '₦ ',
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  service.addPayment(
                    Payment(
                      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
                      category: selectedCategory,
                      description: descController.text,
                      amount: amount,
                      timestamp: DateTime.now(),
                      schoolId: schoolId,
                    ),
                  );
                  service.logActivity(
                    message: 'Income Recorded: ₦$amount ($selectedCategory)',
                    type: 'activity',
                    schoolId: schoolId,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList(
    SchoolDataService service,
    String schoolId,
  ) {
    final notifications = service.getNotificationsForSchool(schoolId);

    if (notifications.isEmpty) {
      return const GlassContainer(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history_rounded, color: Colors.white24, size: 48),
              SizedBox(height: 16),
              Text(
                'No recent activities yet.',
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      );
    }

    return GlassContainer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: notifications.length.clamp(0, 10), // Show last 10
        separatorBuilder: (_, __) => Divider(color: Colors.white.withAlpha(5)),
        itemBuilder: (context, index) {
          final n = notifications[index];

          IconData icon;
          Color color;
          switch (n.type) {
            case 'staff':
              icon = Icons.badge_rounded;
              color = AppColors.accent;
              break;
            case 'student':
              icon = Icons.person_add_rounded;
              color = AppColors.primary;
              break;
            case 'activity':
              icon = Icons.bolt_rounded;
              color = AppColors.secondary;
              break;
            default:
              icon = Icons.notifications_active;
              color = Colors.white70;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(20),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(n.message, style: AppTypography.label),
            subtitle: Text(
              _formatTimestamp(n.timestamp),
              style: AppTypography.body.copyWith(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class IncomeHistorySection extends StatelessWidget {
  const IncomeHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final payments = service.getPaymentsForSchool(schoolId);
        final totalRevenue = service.calculateMonthlyRevenue(schoolId);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Income & Finance', style: AppTypography.header),
                      Text(
                        'Total Monthly Revenue: ₦${totalRevenue.toStringAsFixed(0)}',
                        style: AppTypography.body.copyWith(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final state = context
                          .findAncestorStateOfType<_AdminDashboardState>()!;
                      state._showRecordIncomeDialog(context, service, schoolId);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: payments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              color: Colors.white12,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No transactions recorded yet.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          ],
                        ),
                      )
                    : GlassContainer(
                        child: ListView.separated(
                          itemCount: payments.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.white.withAlpha(5)),
                          itemBuilder: (context, index) {
                            final p = payments[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withAlpha(20),
                                child: const Icon(
                                  Icons.north_east_rounded,
                                  color: Colors.greenAccent,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '₦${p.amount.toStringAsFixed(0)}',
                                    style: AppTypography.label.copyWith(
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(10),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.category,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.description.isNotEmpty)
                                    Text(
                                      p.description,
                                      style: AppTypography.body.copyWith(
                                        fontSize: 12,
                                      ),
                                    ),
                                  Text(
                                    'Date: ${p.timestamp.day}/${p.timestamp.month}/${p.timestamp.year} ${p.timestamp.hour}:${p.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: AppTypography.body.copyWith(
                                      fontSize: 10,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                p.status.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AdminDashboardState>()!;
    final schoolId = context.watch<AppState>().schoolId ?? '';
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dashboard Overview', style: AppTypography.header),
                  ElevatedButton.icon(
                    onPressed: () {
                      final state = context
                          .findAncestorStateOfType<_AdminDashboardState>()!;
                      state._showAddAnnouncementDialog(
                        context,
                        service,
                        schoolId,
                      );
                    },
                    icon: const Icon(Icons.campaign_rounded),
                    label: const Text('Post Announcement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              state._buildMetricsGrid(service, schoolId),
              const SizedBox(height: 32),
              Text(
                'Recent Activities',
                style: AppTypography.label.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              state._buildRecentActivitiesList(service, schoolId),
            ],
          ),
        );
      },
    );
  }
}

class StaffManagementSection extends StatelessWidget {
  const StaffManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final staff = service.getStaffForSchool(schoolId);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Staff Management', style: AppTypography.header),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStaffDialog(context, service),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Staff'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GlassContainer(
                  child: ListView.separated(
                    itemCount: staff.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: Colors.white.withAlpha(5)),
                    itemBuilder: (context, index) {
                      final member = staff[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accent.withAlpha(20),
                          child: Text(
                            member.name[0],
                            style: const TextStyle(color: AppColors.accent),
                          ),
                        ),
                        title: Text(member.name, style: AppTypography.label),
                        subtitle: Row(
                          children: [
                            Text(
                              'Dept: ${member.department}',
                              style: AppTypography.body.copyWith(fontSize: 12),
                            ),
                            if (member.isFormMaster) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.primary.withAlpha(60),
                                  ),
                                ),
                                child: const Text(
                                  'FORM MASTER',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => service.removeStaff(member.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddStaffDialog(BuildContext context, SchoolDataService service) {
    final nameController = TextEditingController();
    final deptController = TextEditingController();
    final userController = TextEditingController();
    final pinController = TextEditingController();
    bool isFormMaster = false;
    final List<String> selectedSubjects = [];
    // FETCH SUBJECTS FROM SERVICE
    final List<Subject> availableSubjects = service.getSubjectsForSchool(
      context.read<AppState>().schoolId ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Add New Staff',
            style: AppTypography.header.copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setInnerState) {
                              return AlertDialog(
                                backgroundColor: AppColors.surface,
                                title: const Text('Select Subjects'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: availableSubjects.map((s) {
                                      final isSelected = selectedSubjects
                                          .contains(s.name);
                                      return CheckboxListTile(
                                        title: Text(
                                          s.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        value: isSelected,
                                        activeColor: AppColors.primary,
                                        checkColor: Colors.white,
                                        onChanged: (val) {
                                          setInnerState(() {
                                            if (val == true) {
                                              selectedSubjects.add(s.name);
                                            } else {
                                              selectedSubjects.remove(s.name);
                                            }
                                          });
                                          // Update outer dialog state
                                          setDialogState(() {});
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Done'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Teaching Subjects',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedSubjects.isEmpty
                            ? 'Select Subjects'
                            : selectedSubjects.join(', '),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: deptController,
                    decoration: const InputDecoration(labelText: 'Department'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: 'Login Username',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pinController,
                    decoration: const InputDecoration(
                      labelText: 'Login PIN (4-6 digits)',
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(20),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Assign as Form Master',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Can record attendance and manage class activities',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      value: isFormMaster,
                      activeColor: AppColors.primary,
                      checkColor: Colors.white,
                      onChanged: (val) =>
                          setDialogState(() => isFormMaster = val!),
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
                if (nameController.text.isNotEmpty &&
                    userController.text.isNotEmpty &&
                    pinController.text.isNotEmpty) {
                  final schoolId = context.read<AppState>().schoolId ?? '';
                  service.addStaff(
                    Staff(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameController.text,
                      department: deptController.text.isEmpty
                          ? 'General'
                          : deptController.text,
                      role: isFormMaster ? 'Form Master' : 'Teacher',
                      email:
                          '${nameController.text.replaceAll(' ', '.').toLowerCase()}@school.com',
                      schoolId: schoolId,
                      username: userController.text,
                      pin: pinController.text,
                      isFormMaster: isFormMaster,
                      subjects: selectedSubjects,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentDirectorySection extends StatelessWidget {
  const StudentDirectorySection({super.key});

  void _showAddStudentDialog(BuildContext context, SchoolDataService service) {
    final nameController = TextEditingController();
    String selectedSection = 'Primary';
    String selectedClass = 'Basic 1';
    String selectedArm = 'None';
    String? base64Image;
    bool isPicking = false;

    final Map<String, List<String>> sectionClasses = {
      'Creche': ['Creche', 'Pre-Nursery'],
      'Nursery': ['Nursery 1', 'Nursery 2', 'Nursery 3'],
      'Primary': [
        'Basic 1',
        'Basic 2',
        'Basic 3',
        'Basic 4',
        'Basic 5',
        'Basic 6',
      ],
      'JSS': ['JSS 1', 'JSS 2', 'JSS 3'],
      'SSS': ['SS 1', 'SS 2', 'SS 3'],
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Register Student',
            style: AppTypography.header.copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 400,
                        maxHeight: 400,
                      );
                      if (image != null) {
                        setDialogState(() => isPicking = true);
                        final bytes = await image.readAsBytes();
                        final base64 =
                            'data:image/jpeg;base64,${base64Encode(bytes)}';
                        setDialogState(() {
                          base64Image = base64;
                          isPicking = false;
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(30),
                        ),
                      ),
                      child: base64Image != null
                          ? ClipOval(
                              child: Image.memory(
                                base64Decode(base64Image!.split(',').last),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isPicking
                                      ? Icons.hourglass_empty
                                      : Icons.camera_alt_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: AppTypography.body.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Student Full Name',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: sectionClasses.keys
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedSection = val!;
                        selectedClass = sectionClasses[selectedSection]!.first;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Class / Grade',
                    ),
                    items: sectionClasses[selectedSection]!
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedClass = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedArm,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Class Arm (Subdivision)',
                    ),
                    items: ['A', 'B', 'C', 'D', 'E', 'None']
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedArm = val!),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Link code will be automatically generated.',
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      color: Colors.white38,
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
                if (nameController.text.isNotEmpty) {
                  final schoolId = context.read<AppState>().schoolId ?? '';
                  service.addStudent(
                    name: nameController.text,
                    grade: selectedClass,
                    section: selectedSection,
                    arm: selectedArm == 'None' ? '' : selectedArm,
                    schoolId: schoolId,
                    imageUrl: base64Image,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    final sections = ['All', 'Creche', 'Nursery', 'Primary', 'JSS', 'SSS'];

    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final allStudents = service.getStudentsForSchool(schoolId);

        return DefaultTabController(
          length: sections.length,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Student Directory', style: AppTypography.header),
                    ElevatedButton.icon(
                      onPressed: () => _showAddStudentDialog(context, service),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Register Student'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  dividerColor: Colors.white10,
                  labelStyle: AppTypography.label.copyWith(fontSize: 14),
                  unselectedLabelStyle: AppTypography.body.copyWith(
                    fontSize: 14,
                  ),
                  tabs: sections.map((s) => Tab(text: s)).toList(),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TabBarView(
                    children: sections.map((section) {
                      final filteredStudents = section == 'All'
                          ? allStudents
                          : allStudents
                                .where((s) => s.section == section)
                                .toList();

                      if (filteredStudents.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                color: Colors.white12,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No students in $section',
                                style: const TextStyle(color: Colors.white38),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 300,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailScreen(
                                    student: student,
                                    canEdit: true,
                                  ),
                                ),
                              );
                            },
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Hero(
                                    tag: 'student-avatar-${student.id}',
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withAlpha(
                                          20,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.secondary.withAlpha(
                                            30,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: _renderStudentAvatar(
                                          student.imageUrl,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    student.name,
                                    style: AppTypography.label,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'Link Code: ${student.linkCode}',
                                    style: AppTypography.body.copyWith(
                                      fontSize: 10,
                                      color: Colors.white38,
                                      letterSpacing: 1.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${student.grade} • ${student.isPresent ? "Present" : "Absent"}',
                                    style: AppTypography.body.copyWith(
                                      fontSize: 12,
                                      color: student.isPresent
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: student.performance,
                                    backgroundColor: Colors.white10,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _renderStudentAvatar(String? imageUrl) {
    if (imageUrl == null) {
      return const Icon(Icons.person, size: 40, color: AppColors.secondary);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image, color: AppColors.secondary);
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 40, color: AppColors.secondary),
    );
  }
}

class PerformanceReportsSection extends StatelessWidget {
  const PerformanceReportsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final grades = service.getGradesForSchool(schoolId);
        final students = service.getStudentsForSchool(schoolId);

        if (grades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'No performance data available yet.',
                  style: AppTypography.label,
                ),
                const SizedBox(height: 8),
                Text(
                  'Teachers need to input grades first.',
                  style: AppTypography.body.copyWith(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Academic Performance Reports', style: AppTypography.header),
              const SizedBox(height: 24),
              _buildSummaryCards(grades, students),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildClassAverageChart(grades, students),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _buildGradeDistributionChart(grades)),
                ],
              ),
              const SizedBox(height: 32),
              _buildTopPerformers(students),
              const SizedBox(height: 32),
              const _ReportGeneratorUI(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<GradeRecord> grades, List<Student> students) {
    final overallAvg = grades.isEmpty
        ? 0.0
        : grades.fold(0.0, (sum, g) => sum + g.totalScore) / grades.length;
    final passCount = grades.where((g) => g.totalScore >= 40).length;
    final passRate = grades.isEmpty ? 0.0 : (passCount / grades.length) * 100;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Overall Average',
            value: '${overallAvg.toStringAsFixed(1)}%',
            subtitle: 'Across all subjects',
            icon: Icons.auto_graph_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Pass Rate',
            value: '${passRate.toStringAsFixed(1)}%',
            subtitle: 'Scores above 40%',
            icon: Icons.check_circle_outline_rounded,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Active Students',
            value: '${students.length}',
            subtitle: 'With recorded grades',
            icon: Icons.people_outline_rounded,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildClassAverageChart(
    List<GradeRecord> grades,
    List<Student> students,
  ) {
    // Group grades by class and calculate averages
    final Map<String, List<double>> classScores = {};
    for (var grade in grades) {
      final student = students.firstWhere((s) => s.id == grade.studentId);
      classScores.putIfAbsent(student.grade, () => []).add(grade.totalScore);
    }

    final data = classScores.entries.map((e) {
      final avg = e.value.fold(0.0, (a, b) => a + b) / e.value.length;
      return _ChartData(e.key, avg);
    }).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Class Performance (Averages)', style: AppTypography.label),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<_ChartData, String>>[
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (_ChartData d, _) => d.label,
                  yValueMapper: (_ChartData d, _) => d.value,
                  name: 'Average Score',
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistributionChart(List<GradeRecord> grades) {
    final Map<String, int> distribution = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'E': 0,
      'F': 0,
    };
    for (var g in grades) {
      distribution[g.grade] = (distribution[g.grade] ?? 0) + 1;
    }

    final data = distribution.entries
        .map((e) => _ChartData(e.key, e.value.toDouble()))
        .toList();

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Grade Distribution', style: AppTypography.label),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: SfCircularChart(
              legend: Legend(isVisible: true, position: LegendPosition.bottom),
              series: <CircularSeries<_ChartData, String>>[
                PieSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (_ChartData d, _) => d.label,
                  yValueMapper: (_ChartData d, _) => d.value,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(List<Student> students) {
    final sortedStudents = List<Student>.from(students)
      ..sort((a, b) => b.performance.compareTo(a.performance));
    final topStudents = sortedStudents.take(5).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Performers Spotlight', style: AppTypography.label),
              const Icon(Icons.stars_rounded, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topStudents.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withAlpha(5)),
            itemBuilder: (context, index) {
              final student = topStudents[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withAlpha(20),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                title: Text(student.name, style: AppTypography.label),
                subtitle: Text(student.grade),
                trailing: Text(
                  '${(student.performance * 100).toStringAsFixed(1)}%',
                  style: AppTypography.header.copyWith(
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected
            ? AppColors.primary.withAlpha(30)
            : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textBody,
        ),
        title: Text(
          label,
          style: AppTypography.label.copyWith(
            color: isSelected ? AppColors.textHeader : AppColors.textBody,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTypography.body.copyWith(fontSize: 12)),
                Text(value, style: AppTypography.header.copyWith(fontSize: 20)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.body.copyWith(
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportGeneratorUI extends StatefulWidget {
  const _ReportGeneratorUI();

  @override
  State<_ReportGeneratorUI> createState() => _ReportGeneratorUIState();
}

class _ReportGeneratorUIState extends State<_ReportGeneratorUI> {
  String? selectedGrade;
  String? selectedArm;
  String selectedTerm = '1st Term';
  String selectedSession = '2025/2026';
  bool isGenerating = false;

  final List<String> terms = ['1st Term', '2nd Term', '3rd Term'];
  final List<String> sessions = ['2024/2025', '2025/2026', '2026/2027'];

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    final schoolName = context.watch<AppState>().schoolName ?? 'Easy Academia';
    final schoolLogo = context.watch<AppState>().badgeUrl;

    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final students = service.getStudentsForSchool(schoolId);
        final gradesList = students.map((s) => s.grade).toSet().toList()
          ..sort();

        final armsList =
            students
                .where((s) => s.grade == selectedGrade)
                .map((s) => s.arm)
                .where((a) => a.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        return GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  Text('Report Sheet Generator', style: AppTypography.label),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Select Class',
                      value: selectedGrade,
                      items: gradesList,
                      onChanged: (val) {
                        setState(() {
                          selectedGrade = val;
                          selectedArm = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Select Arm (Optional)',
                      value: selectedArm,
                      items: ['All Arms', ...armsList],
                      onChanged: (val) {
                        setState(
                          () => selectedArm = val == 'All Arms' ? null : val,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Select Term',
                      value: selectedTerm,
                      items: terms,
                      onChanged: (val) => setState(() => selectedTerm = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Select Session',
                      value: selectedSession,
                      items: sessions,
                      onChanged: (val) =>
                          setState(() => selectedSession = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedGrade == null || isGenerating
                          ? null
                          : () => _generateReports(
                              service,
                              schoolName,
                              schoolLogo,
                              isPrint: true,
                            ),
                      icon: isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print_rounded),
                      label: const Text('Print All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedGrade == null || isGenerating
                          ? null
                          : () => _generateReports(
                              service,
                              schoolName,
                              schoolLogo,
                              isPrint: false,
                            ),
                      icon: isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: const Text('Save PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              hint: const Text(
                'Choose',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateReports(
    SchoolDataService service,
    String schoolName,
    String? schoolLogo, {
    required bool isPrint,
  }) async {
    setState(() => isGenerating = true);

    try {
      final reports = service.getClassPerformanceReport(
        grade: selectedGrade!,
        arm: selectedArm,
        term: selectedTerm,
        session: selectedSession,
      );

      if (reports.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No records found for $selectedGrade ($selectedTerm, $selectedSession). Please ensure grades are recorded for this exact selection.',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final pdfBytes = await ReportSheetGenerator.generateClassReports(
        reports: reports,
        schoolLogoBase64: schoolLogo,
        schoolName: schoolName,
      );

      if (mounted) {
        final fileName = 'Report_Sheets_${selectedGrade}_$selectedTerm';
        if (isPrint) {
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: fileName,
          );
        } else {
          await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
        }
      }
    } catch (e) {
      debugPrint('Error generating reports: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isGenerating = false);
      }
    }
  }
}

class SubjectManagementSection extends StatelessWidget {
  const SubjectManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final subjects = service.getSubjectsForSchool(schoolId);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subject Management', style: AppTypography.header),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSubjectDialog(context, service),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 64,
                              color: Colors.white.withAlpha(20),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No subjects defined yet.',
                              style: TextStyle(color: Colors.white38),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add subjects to start grading.',
                              style: TextStyle(
                                color: Colors.white24,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GlassContainer(
                        child: ListView.separated(
                          itemCount: subjects.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.white.withAlpha(5)),
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.book_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                subject.name,
                                style: AppTypography.label,
                              ),
                              subtitle: subject.department != null
                                  ? Text(
                                      subject.department!,
                                      style: AppTypography.body.copyWith(
                                        fontSize: 12,
                                        color: Colors.white38,
                                      ),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () => _confirmDeleteSubject(
                                  context,
                                  service,
                                  subject,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSubjectDialog(BuildContext context, SchoolDataService service) {
    final nameController = TextEditingController();
    final deptController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add New Subject',
          style: AppTypography.header.copyWith(fontSize: 20),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  hintText: 'e.g. Mathematics, Robotics...',
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deptController,
                decoration: const InputDecoration(
                  labelText: 'Department (Optional)',
                  hintText: 'e.g. Science, Arts...',
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final schoolId = context.read<AppState>().schoolId ?? '';
                final subject = Subject(
                  id: 'SUB-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  schoolId: schoolId,
                  department: deptController.text.isEmpty
                      ? null
                      : deptController.text.trim(),
                  createdAt: DateTime.now(),
                );
                service.addSubject(subject);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Add Subject'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(
    BuildContext context,
    SchoolDataService service,
    Subject subject,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Subject',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? This might affect existing records if tests were already taken for this subject.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              service.removeSubject(subject.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
