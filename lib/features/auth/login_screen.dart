import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../core/user_role.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  UserRole? _selectedRole;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _schoolCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all credentials including School ID'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<AppState>().login(
      _usernameController.text,
      _passwordController.text,
      _schoolCodeController.text.toUpperCase(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final error = context.read<AppState>().authError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Invalid credentials or School ID'),
          backgroundColor: error != null ? Colors.redAccent : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'images/background-image.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              color: Colors.black.withAlpha(150),
              colorBlendMode: BlendMode.darken,
            ),
          ).animate().fadeIn(duration: 1000.ms),

          // Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(30),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(duration: 1000.ms),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Easy Academia',
                    style: AppTypography.header.copyWith(fontSize: 40),
                  ).animate().fadeIn().moveY(begin: 20, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    'Precision Management for Modern Schools',
                    style: AppTypography.body,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 48),

                  AnimatedCrossFade(
                    firstChild: _buildRoleSelection(),
                    secondChild: _buildLoginForm(),
                    crossFadeState: _selectedRole == null
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: 500.ms,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome! Who are you?',
            style: AppTypography.label,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _RoleButton(
            role: UserRole.admin,
            icon: Icons.admin_panel_settings_rounded,
            color: AppColors.primary,
            onTap: () => setState(() => _selectedRole = UserRole.admin),
          ),
          const SizedBox(height: 12),
          _RoleButton(
            role: UserRole.staff,
            icon: Icons.badge_rounded,
            color: AppColors.accent,
            onTap: () => setState(() => _selectedRole = UserRole.staff),
          ),
          const SizedBox(height: 12),
          _RoleButton(
            role: UserRole.parent,
            icon: Icons.family_restroom_rounded,
            color: AppColors.secondary,
            onTap: () => setState(() => _selectedRole = UserRole.parent),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            ),
            child: const Text('Need an account? Register Here'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedRole = null),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: Colors.white70,
              ),
              Text(
                '${_selectedRole?.name} Login',
                style: AppTypography.label.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _schoolCodeController,
            label: 'School ID',
            hint: 'e.g. EASY123',
            icon: Icons.school_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline_rounded,
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
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                : const Text('Sign In'),
          ),
        ],
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

class _RoleButton extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.role,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
          color: color.withAlpha(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(role.name, style: AppTypography.label.copyWith(fontSize: 16)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withAlpha(128)),
          ],
        ),
      ),
    );
  }
}
