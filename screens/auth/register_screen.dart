import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscure       = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
    );
    if (ok && mounted) Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth  = context.watch<AuthProvider>();
    final busy  = auth.status == AuthStatus.loading;

    return LoadingOverlay(
      isLoading: busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Join Smart Transport',
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Track, plan and travel smarter',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 28),

                  AppTextField(controller: _nameCtrl, label: 'Full Name',
                      hint: 'John Doe', prefixIcon: Icons.person_outline,
                      validator: (v) => v == null || v.isEmpty ? 'Name is required' : null),
                  const SizedBox(height: 14),
                  AppTextField(controller: _emailCtrl, label: 'Email',
                      hint: 'you@example.com', prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  AppTextField(controller: _phoneCtrl, label: 'Phone',
                      hint: '+91 98765 43210', prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Phone is required' : null),
                  const SizedBox(height: 14),
                  AppTextField(controller: _passCtrl, label: 'Password',
                      hint: 'Min 6 characters', prefixIcon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      }),
                  const SizedBox(height: 14),
                  AppTextField(controller: _confirmCtrl, label: 'Confirm Password',
                      hint: 'Re-enter password', prefixIcon: Icons.lock_outline,
                      obscure: true,
                      validator: (v) =>
                      v != _passCtrl.text ? 'Passwords do not match' : null),

                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(auth.error!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 24),
                  AppButton(label: 'Create Account', onPressed: _register,
                      icon: Icons.person_add_rounded),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: theme.textTheme.bodyMedium),
                      TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Sign In')),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}