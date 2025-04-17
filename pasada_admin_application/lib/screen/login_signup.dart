import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';

class LoginSignup extends StatefulWidget {
  @override
  _LoginSignupState createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  // Controllers for text fields
  final TextEditingController _adminIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isRememberMe = false;
  bool isObscure = true;

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _adminIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final String adminId = _adminIdController.text.trim();
    final String password = _passwordController.text.trim();

    // Check credentials
    if (adminId == 'admin' && password == 'admin1') {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully logged in.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2), // Optional: shorter duration for success message
        ),
      );
      // Navigate to dashboard on success
      Navigator.pushReplacementNamed(context, '/dashboard'); // Use pushReplacementNamed to prevent going back to login
    } else {
      // Show error message on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid Admin ID or Password.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3), // Set duration to 3 seconds
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = (screenWidth * 0.5).clamp(400, 800);
    final horizontalPadding = (screenWidth - containerWidth) / 2;

    return Scaffold(
      backgroundColor: Palette.whiteColor,
      body: Stack(
        children: [
          Positioned(
            top: 250,
            left: horizontalPadding,
            right: horizontalPadding,
            child: Container(
              height: 500,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Palette.whiteColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Palette.blackColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 51),
                    spreadRadius: 5,
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.circle, size: 58, color: Palette.blackColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Text(
                              "Novadeci Transport Cooperative",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 56),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            "Log-in to your account",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRichText('Enter your ', 'Admin ID'),
                                SizedBox(height: 8),
                                _buildTextField(
                                  "Enter your Admin ID",
                                  _adminIdController, // Pass controller
                                ),
                                SizedBox(height: 24),
                                _buildRichText('Enter your ', 'password.'),
                                SizedBox(height: 8),
                                _buildPasswordField(_passwordController), // Pass controller
                                SizedBox(height: 28),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: _login, // Call the login function
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      minimumSize: Size(170, 50),
                                    ),
                                    child: Text("Log-in"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RichText _buildRichText(String text, String boldText) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 16,
          letterSpacing: 1,
          color: Palette.blackColor,
        ),
        children: [
          TextSpan(
            text: boldText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TextField _buildTextField(String hintText, TextEditingController controller) {
    return TextField(
      controller: controller, // Assign controller
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
    );
  }

  TextField _buildPasswordField(TextEditingController controller) {
    return TextField(
      controller: controller, // Assign controller
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: "Enter your password",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                isObscure = !isObscure;
              });
            },
          ),
        ),
      ),
    );
  }
}
