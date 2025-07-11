import 'package:flutter/material.dart';
import 'forgot_password.dart';
import 'sign_up.dart';
import '../dashboard/dashboard.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Larger custom shield icon
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.asset(
                  'assets/images/shield.png',
                  height: 26,
                  width: 26,
                ),
              ),
              const SizedBox(height: 16),

              // Header image with "Welcome Back" text and border styling + blue overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/login_header.jpg',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 160,
                        width: double.infinity,
                        color: const Color(0xFF3A7BD5).withOpacity(0.5), // Blue overlay with 50% opacity
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'WELCOME BACK',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'RobotoSerif',
                              letterSpacing: 2.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your journey to well-being continues',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Center-aligned subtext
              const Center(
                child: Text(
                  'Please log in to access your\npersonalized mental wellness journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Email Field
              const Text("Email Address",
                  style: TextStyle(
                      fontWeight:FontWeight.bold, fontSize:16)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password Field
              const Text("Password",
                  style: TextStyle(
                  fontWeight:FontWeight.bold, fontSize:16)),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF3A7BD5), fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Log In Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  },
                  child: const Text(
                    "LOGIN",
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

              // Divider
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),

              const SizedBox(height: 16),

              // Google Login
              SocialLogoButton(
                imagePath: 'assets/images/google_logo.png',
                label: "Login with Google",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // NHS Login
              SocialLogoButton(
                imagePath: 'assets/images/nhs_logo.png',
                label: "Login with NHS",
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Sign up row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?  ",
                  style: TextStyle(color: Color(0xFF424242)),),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up Now",
                      style: TextStyle(color: Color(0xFF3A7BD5), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialLogoButton extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onPressed;

  const SocialLogoButton({
    super.key,
    required this.imagePath,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: Colors.black12),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 20),
          const SizedBox(width: 12),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
