import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import './login_password_util.dart'; // Import the password utility

class LoginSignup extends StatefulWidget {
  @override
  _LoginSignupState createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  // Controllers for text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final supabase = Supabase.instance.client; // Initialize Supabase client
  bool isRememberMe = false;
  bool isObscure = true;
  bool _isLoading = false; // Add loading state

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Get user input and trim spaces
    final String enteredUsername = _usernameController.text.trim();
    final String enteredPassword = _passwordController.text.trim();

    // Basic Input Validation
    if (enteredUsername.isEmpty) {
      _showErrorSnackBar('Username cannot be empty.'); // Updated message
      setState(() => _isLoading = false);
      return;
    }
    if (enteredPassword.isEmpty) {
      _showErrorSnackBar('Password cannot be empty.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Find potential user by username (case-insensitive initial lookup)
      //    We select the exact username and password stored in the DB for later comparison.
      final response = await supabase
          .from('adminTable')
          .select('admin_username, admin_password')
          .ilike('admin_username', enteredUsername) // Find potential match ignoring case
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // Username not found even case-insensitively
        _showErrorSnackBar('Username not found.');
      } else {

        final String dbUsername = response['admin_username'];
        final String dbHashedPassword = response['admin_password'];

        if (enteredUsername == dbUsername && 
            LoginPasswordUtil().checkPassword(enteredPassword, dbHashedPassword)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully logged in.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // FAILURE: EITHER username case didn't match OR password didn't match
          _showErrorSnackBar('Invalid username or password.');
        }
      }
    } catch (e) {
      print('Login Error: $e');
      _showErrorSnackBar('An error occurred during login. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text(message),
         backgroundColor: Colors.red,
         duration: Duration(seconds: 3),
       ),
     );
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
                        Image.asset('assets/novadeci.png', width: 58, height: 58),
                        SizedBox(width: 10),
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
                                _buildRichText('Enter your ', 'Username'),
                                SizedBox(height: 8),
                                _buildTextField(
                                  "Enter your username",
                                  _usernameController,
                                ),
                                SizedBox(height: 24),
                                _buildRichText('Enter your ', 'password.'),
                                SizedBox(height: 8),
                                _buildPasswordField(_passwordController),
                                SizedBox(height: 28),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      minimumSize: Size(170, 50),
                                    ),
                                    child: _isLoading 
                                           ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                           : Text("Log-in"),
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
      controller: controller,
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
      controller: controller,
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
