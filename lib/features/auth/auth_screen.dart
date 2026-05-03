import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool isLogin = true;
  bool obscure = true;
  bool loading = false;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

String _friendlyError(Object e) {
  debugPrint('AUTH ERROR TYPE: ${e.runtimeType}');
  debugPrint('AUTH ERROR: $e');

  if (e is FirebaseAuthException) {
    return '${e.code}: ${e.message ?? ''}';
  }

  return e.toString();
}

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      if (isLogin) {
        await _authService.signInWithEmail(
          email: emailCtrl.text,
          password: passCtrl.text,
        );
        _showMessage('Signed in successfully');
      } else {
        await _authService.registerWithEmail(
          name: nameCtrl.text,
          email: emailCtrl.text,
          password: passCtrl.text,
        );
        _showMessage('Account created successfully');
      }
    } catch (e) {
      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => loading = true);

    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _showMessage('Google sign-in successful');
      }
    } catch (e) {
      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (emailCtrl.text.trim().isEmpty) {
      _showMessage('Enter your email first');
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(emailCtrl.text);
      _showMessage('Password reset email sent');
    } catch (e) {
      _showMessage(_friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF09090D);
    const panel = Color(0xFF12121A);
    const border = Color(0xFF232331);
    const red = Color(0xFFFF5A52);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'ClawCart',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: red,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI Shopping Assistant',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: red.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: red,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLogin ? 'Welcome back' : 'Create your account',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell the assistant what you want — we’ll rank the best options for you.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.66),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthTab(
                        title: 'Sign in',
                        active: isLogin,
                        onTap: () => setState(() => isLogin = true),
                      ),
                    ),
                    Expanded(
                      child: _AuthTab(
                        title: 'Create account',
                        active: !isLogin,
                        onTap: () => setState(() => isLogin = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        TextFormField(
                          controller: nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            label: 'Full name',
                            hint: 'e.g. Michael Damoah',
                          ),
                          validator: (value) {
                            if (!isLogin &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          label: 'Email',
                          hint: 'you@example.com',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: obscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          label: 'Password',
                          hint: '••••••••',
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => obscure = !obscure),
                            icon: Icon(
                              obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password';
                          }
                          if (value.length < 6) {
                            return 'Minimum 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (isLogin)
                            TextButton(
                              onPressed: _forgotPassword,
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.74),
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            isLogin ? 'Secure sign in' : 'Create account',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isLogin
                                      ? Icons.lock_open
                                      : Icons.person_add_alt_1,
                                ),
                          label: Text(
                            isLogin ? 'Sign in' : 'Create account',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: loading ? null : _googleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to our Terms & Privacy Policy.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Widget? suffix,
  }) {
    const fill = Color(0xFF0D0D14);
    const border = Color(0xFF232331);
    const red = Color(0xFFFF5A52);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: red, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.3),
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _AuthTab({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF5A52);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? red.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? red.withValues(alpha: 0.45) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}