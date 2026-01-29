import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_state.dart';
import 'core/design_system.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/staff/staff_home.dart';
import 'features/parent/parent_home.dart';
import 'features/shared/splash_screen.dart';
import 'core/user_role.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/staff.dart';
import 'models/student.dart';
import 'models/activity.dart';
import 'models/grade_record.dart';
import 'services/school_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(StaffAdapter());
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(ActivityStatusAdapter());
  Hive.registerAdapter(ActivityAdapter());
  Hive.registerAdapter(GradeRecordAdapter());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProxyProvider<AppState, SchoolDataService>(
          create: (_) => SchoolDataService(),
          update: (context, appState, schoolService) {
            if (appState.schoolId != null) {
              schoolService!.startListening(appState.schoolId!);
            } else {
              schoolService!.clearData();
            }
            return schoolService;
          },
        ),
      ],
      child: const EasyAcademiaApp(),
    ),
  );
}

class EasyAcademiaApp extends StatelessWidget {
  const EasyAcademiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Academia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Consumer2<AppState, SchoolDataService>(
        builder: (context, appState, schoolService, _) {
          // 1. Show Branded Splash Screen while initializing Auth or mandatory delay
          if (!appState.isInitialized) {
            return const SplashScreen();
          }

          // 2. Gatekeeper: If no user, show login
          if (appState.activeRole == null) {
            return const LoginScreen();
          }

          // 3. Show Syncing Splash while data is loading (post-auth)
          if (!schoolService.isInitialized) {
            return const SplashScreen(message: 'Syncing school data...');
          }

          // 4. Navigate to appropriate Home
          switch (appState.activeRole!) {
            case UserRole.admin:
              return const AdminDashboard();
            case UserRole.staff:
              return const StaffHome();
            case UserRole.parent:
              return const ParentHome();
          }
        },
      ),
    );
  }
}
