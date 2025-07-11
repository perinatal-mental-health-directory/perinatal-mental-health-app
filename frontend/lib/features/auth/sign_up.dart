import 'package:flutter/material.dart';
import 'package:perinatal_app/features/auth/login_screen.dart';
import '../dashboard/dashboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController   = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int  _selectedRoleIndex = 0; // Default: Professional
  bool _agreedToTerms     = false;

  final List<String> _roles = ['Professional', 'Support Staff', 'Parent'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ───────────────────────────── Role Selector ──────────────────────────────
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: List.generate(_roles.length, (index) {
            final isSelected = _selectedRoleIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedRoleIndex = index),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3A7BD5)
                        : const Color(0xFFF0F0F0),
                    borderRadius: _roleBorder(index),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _roles[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF424242),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  BorderRadius _roleBorder(int index) {
    if (_roles.length == 1) return BorderRadius.circular(8);
    if (index == 0)               {
      return const BorderRadius.only(
        topLeft: Radius.circular(8),
        bottomLeft: Radius.circular(8),
      );
    }
    if (index == _roles.length - 1) {
      return const BorderRadius.only(
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    }
    return BorderRadius.zero;
  }

  // ───────────────────────────────── UI ──────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // App title
              const Center(
                child: Text(
                  'Perinatal Mental Health App',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3A7BD5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Full Name
              const Text('Full Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Email
              const Text('Email',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password
              const Text('Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Create your password',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Role selector
              const Text('Select Your Role',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildRoleSelector(),

              const SizedBox(height: 16),

              // Terms & Privacy
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (value) =>
                        setState(() => _agreedToTerms = value ?? false),
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text('I agree to the ',
                            style: TextStyle(fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            // TODO: open policy URLs
                          },
                          child: const Text(
                            'Privacy Policy and Terms of Use',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFC107),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sign‑Up button (enabled only when terms agreed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _agreedToTerms
                      ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      );
                  }
                      : null, // disables button when unchecked
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    disabledBackgroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Already have account
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Already have an account? Log in.',
                    style: TextStyle(
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}