import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../core/user_role.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.admin;
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all email and password')),
      );
      return;
    }

    if (_selectedRole == UserRole.admin && _schoolNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your school name')),
      );
      return;
    }

    if (_selectedRole == UserRole.parent &&
        _schoolNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your School ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await context.read<AppState>().signUp(
      email: _emailController.text,
      password: _passwordController.text,
      schoolName: _selectedRole == UserRole.admin
          ? _schoolNameController.text
          : null,
      role: _selectedRole,
      existingSchoolId: _selectedRole == UserRole.parent
          ? _schoolNameController.text
          : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedRole == UserRole.admin
                ? 'School registered! Please check your inbox (and spam folder) for a verification link.'
                : 'Account created! Please verify your email (check spam folder) to log in.',
          ),
          duration: const Duration(seconds: 12),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } else {
      String message = 'Registration failed';
      if (error.contains('configuration-not-found')) {
        message =
            'Firebase Auth not configured. Please enable Email/Password in console.';
      } else if (error.contains('email-already-in-use')) {
        message = 'This email is already registered.';
      } else if (error.contains('weak-password')) {
        message = 'Password is too weak. Use at least 6 characters.';
      } else if (error.contains('permission-denied')) {
        message = 'Firestore permission denied. Check your security rules.';
      } else {
        message = error;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedRole == UserRole.admin
                        ? 'Register Your School'
                        : 'Parent Registration',
                    style: AppTypography.header.copyWith(fontSize: 32),
                  ).animate().fadeIn().moveY(begin: 20, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Join the next generation of school management',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 48),

                  // Role Selection Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildRoleToggle(
                            UserRole.admin,
                            'School Admin',
                            Icons.admin_panel_settings_rounded,
                          ),
                        ),
                        Expanded(
                          child: _buildRoleToggle(
                            UserRole.parent,
                            'Parent',
                            Icons.family_restroom_rounded,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),

                  GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: _schoolNameController,
                              label: _selectedRole == UserRole.admin
                                  ? 'School Name'
                                  : 'School ID',
                              icon: _selectedRole == UserRole.admin
                                  ? Icons.school_outlined
                                  : Icons.vpn_key_outlined,
                              hint: _selectedRole == UserRole.parent
                                  ? 'e.g. SCH-12345'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _selectedRole == UserRole.admin
                                          ? 'Register School'
                                          : 'Create Parent Account',
                                    ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Already have an account? Login',
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.label.copyWith(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white.withAlpha(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
