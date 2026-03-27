import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _role = '';
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  String _error = '';
  bool _obscure = true;

  void _pickRole(String r) => setState(() => _role = r);

  Future<void> _login() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final user = await FirebaseService.login(_emailCtrl.text, _passCtrl.text);
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(user: user)));
      } else {
        setState(() { _error = 'User not found.'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(color: AppTheme.ink),
      child: Stack(children: [
        // Background radial glows
        Positioned(top: -100, left: -80, child: _glow(AppTheme.purple.withOpacity(0.2), 300)),
        Positioned(bottom: -80, right: -60, child: _glow(AppTheme.blue.withOpacity(0.15), 250)),

        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(children: [
              // Brand
              Container(
                width: 60, height: 60, margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.purple, AppTheme.blue],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 14))],
                ),
                child: const Center(child: Text('🎓', style: TextStyle(fontSize: 28))),
              ),
              Text('EduTrack Portal',
                style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.02)),
              const SizedBox(height: 4),
              Text('Academic Progress Report System',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6B7D93))),
              const SizedBox(height: 28),

              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Role selector
                  _sectionLabel('I am a'),
                  const SizedBox(height: 8),
                  Row(children: [
                    _roleBtn('teacher', '👩‍🏫', 'Teacher'),
                    const SizedBox(width: 8),
                    _roleBtn('student', '🧑‍🎓', 'Student'),
                    const SizedBox(width: 8),
                    _roleBtn('parent', '👨‍👩‍👧', 'Parent'),
                  ]),
                  const SizedBox(height: 18),

                  // Email
                  _sectionLabel('Email'),
                  const SizedBox(height: 6),
                  _field(_emailCtrl, 'your@email.com', TextInputType.emailAddress),
                  const SizedBox(height: 12),

                  // Password
                  _sectionLabel('Password'),
                  const SizedBox(height: 6),
                  _passField(),
                  const SizedBox(height: 4),

                  // Error
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFFB7185))),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Sign in button
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.purple, AppTheme.blue],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Sign In →', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),

                  // Hint
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      '💡 Default accounts (after Firebase setup):\n'
                      '👩‍🏫 teacher@school.edu.my / teacher123\n'
                      '🧑‍🎓 sahil@student.edu.my / student123\n'
                      '👨‍👩‍👧 parent@sahil.com / parent123',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF6B7D93), height: 1.7)),
                  ),
                ]),
              ),
            ]),
          ),
        ))),
      ]),
    ),
  );

  Widget _glow(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _sectionLabel(String text) => Text(text.toUpperCase(),
    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700,
      color: const Color(0xFF8895A7), letterSpacing: 0.8));

  Widget _roleBtn(String role, String emoji, String label) => Expanded(
    child: GestureDetector(
      onTap: () => _pickRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _role == role ? AppTheme.purple.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: _role == role ? AppTheme.purple : Colors.white.withOpacity(0.1),
            width: 1.5),
          borderRadius: BorderRadius.circular(10),
          boxShadow: _role == role ? [BoxShadow(color: AppTheme.purple.withOpacity(0.15), blurRadius: 8)] : [],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: _role == role ? Colors.white : const Color(0xFF8895A7))),
        ]),
      ),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, TextInputType type) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF374151), fontSize: 13),
        filled: true, fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.purple, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

  Widget _passField() => TextField(
    controller: _passCtrl,
    obscureText: _obscure,
    onSubmitted: (_) => _login(),
    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      hintText: '••••••••',
      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF374151), fontSize: 13),
      filled: true, fillColor: Colors.white.withOpacity(0.07),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.purple, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.slate, size: 18),
        onPressed: () => setState(() => _obscure = !_obscure)),
    ),
  );
}
