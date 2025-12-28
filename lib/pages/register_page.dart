import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onecummins/constants.dart';
import 'package:onecummins/animated_border_painter.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _clubNameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = false;
  String role = 'student';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _clubNameController.dispose();

    super.dispose();
  }

  bool _isCollegeEmail(String email) =>
      email.endsWith('@cumminscollege.edu.in');

  void _showSnack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _register() async {
    if (_loading) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final clubName = _clubNameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack('All fields are required');
      return;
    }

    if (role == 'student' && !_isCollegeEmail(email)) {
      _showSnack('Use @cumminscollege.edu.in email');
      return;
    }

    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    if (password != confirm) {
      _showSnack('Passwords do not match');
      return;
    }

    if (role == 'club_admin' && clubName.isEmpty) {
      _showSnack('Club name is required');
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      if (role == 'student') {
        await _db.collection('users').doc(uid).set({
          'uid': uid,
          'name': name,
          'email': email,
          'role': 'student',
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnack('Registration successful', error: false);
        Navigator.pushReplacementNamed(context, '/feed');
      } else {
        await _db.collection('club_join_requests').doc(uid).set({
          'userId': uid,
          'name': name,
          'email': email,
          'clubName': clubName,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _auth.signOut();

        _showSnack('Request sent. Wait for admin approval.', error: false);
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showSnack('Registration failed');
      debugPrint('Registration error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFF1F8E9),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return CustomPaint(
                painter: AnimatedBorderPainter(
                  progress: _controller.value,
                  colors: const [
                    AppColors.purple,
                    AppColors.orange,
                    AppColors.lime,
                    AppColors.teal,
                  ],
                ),
                child: Container(
                  width: 440,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text(
                          'OneCummins',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your account',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),

                        DropdownButtonFormField<String>(
                          initialValue: role,
                          decoration: _inputDecoration('Select Role'),
                          items: const [
                            DropdownMenuItem(
                                value: 'student', child: Text('Student')),
                            DropdownMenuItem(
                                value: 'club_admin',
                                child: Text('Club Admin')),
                          ],
                          onChanged: (v) => setState(() => role = v!),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _nameController,
                          decoration: _inputDecoration('Full Name'),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _emailController,
                          decoration: _inputDecoration('Email'),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration('Password'),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: _inputDecoration('Confirm Password'),
                        ),

                        if (role == 'club_admin') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _clubNameController,
                            decoration: _inputDecoration('Club Name'),
                          ),
                        ],

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Register',
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/login'),
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: AppColors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
