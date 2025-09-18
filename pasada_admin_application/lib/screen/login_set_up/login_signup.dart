import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for LogicalKeyboardKey
import 'package:supabase_flutter/supabase_flutter.dart';
import './login_password_util.dart';
import 'package:pasada_admin_application/services/auth_service.dart';

class LoginSignup extends StatefulWidget {
  const LoginSignup({super.key});

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

  // FocusNodes for text fields
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Add listener to focus nodes if needed for other purposes
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
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
      final response = await supabase
          .from('adminTable')
          .select('admin_id, admin_username, admin_password')
          .ilike('admin_username',
              enteredUsername) // Find potential match ignoring case
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // Username not found even case-insensitively
        _showErrorSnackBar('Username not found.');
      } else {
        final String dbUsername = response['admin_username'];
        final String dbHashedPassword = response['admin_password'];
        final int adminID = response['admin_id'];

        if (enteredUsername == dbUsername &&
            LoginPasswordUtil()
                .checkPassword(enteredPassword, dbHashedPassword)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully logged in.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Store the adminID in the AuthService
          await AuthService().setAdminID(adminID);
          // Navigate without arguments
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _showErrorSnackBar('Invalid username or password.');
        }
      }
    } catch (e) {
      throw Exception('Login Error: $e');
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: FocusNode(),
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent &&
              HardwareKeyboard.instance
                  .isLogicalKeyPressed(LogicalKeyboardKey.enter)) {
            if (!_isLoading) {
              _login();
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Color(0xFF1a1a1a),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back to Home link
                      // Logo and Title
                      Column(
                        children: [
                          // Logo
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/novadeci.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Title
                          Text(
                            'Log in to Pasada Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Login Form
                      Container(
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFF333333),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email Field
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildModernTextField(
                              "Enter your email",
                              _usernameController,
                              _usernameFocusNode,
                              Icons.email_outlined,
                            ),
                            
                            SizedBox(height: 24),
                            
                            // Password Field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildModernPasswordField(
                              _passwordController,
                              _passwordFocusNode,
                            ),
                            
                            SizedBox(height: 32),
                            
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF333333),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Terms and Privacy
                      Text(
                        'Made by Pasada Technologies in Partnership with Novadeci Transport Cooperative.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  TextField _buildModernTextField(
      String hintText, TextEditingController controller, FocusNode focusNode, IconData icon) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Color(0xFF2a2a2a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white, width: 1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  TextField _buildModernPasswordField(
      TextEditingController controller, FocusNode focusNode) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isObscure,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Enter your password",
        hintStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
        filled: true,
        fillColor: Color(0xFF2a2a2a),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF404040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white, width: 1),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: () {
            setState(() {
              isObscure = !isObscure;
            });
          },
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
