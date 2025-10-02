import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for LogicalKeyboardKey
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pasada_admin_application/widgets/turnstile/turnstile_widget_stub.dart'
    if (dart.library.html) 'package:pasada_admin_application/widgets/turnstile/turnstile_widget_web.dart';
import './login_password_util.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:pasada_admin_application/services/session_service.dart';

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
  String? _captchaToken; // Web Turnstile token
  
  // Development mode check
  bool get isLocalDev => kIsWeb && 
      (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1' || Uri.base.host.contains('localhost'));

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

    // On web, ensure CAPTCHA is solved first (skip in development)
    if (kIsWeb && !isLocalDev && (_captchaToken == null || _captchaToken!.isEmpty)) {
      debugPrint('[Login] CAPTCHA token missing, blocking login');
      _showErrorSnackBar('Please complete the CAPTCHA.');
      return;
    }

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
          // Create secure session
          await AuthService().createSession(adminID);
          // Register single-session on server and start watch
          final auth = AuthService();
          final token = auth.sessionToken;
          final expiry = auth.sessionExpiry;
          if (token != null && expiry != null) {
            await SessionService().registerSingleSession(
              supabase: supabase,
              adminId: adminID,
              sessionToken: token,
              expiresAt: expiry,
            );
            SessionService().startSingleSessionWatch(
              supabase: supabase,
              adminId: adminID,
              sessionToken: token,
              onInvalidated: () async {
                await AuthService().clearSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You were logged out because your account was used on another device.')),
                  );
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            );
          }
          // Navigate to main navigation with dashboard as initial page
          Navigator.pushReplacementNamed(context, '/main', arguments: {'page': '/dashboard'});
        } else {
          _showErrorSnackBar('Invalid username or password.');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Login failed: ${e.toString()}');
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
              debugPrint('[Login] Enter key pressed');
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
                              'Username',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildModernTextField(
                              "Enter your username",
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

                            // CAPTCHA (Web only, skip in local dev)
                            if (kIsWeb && !isLocalDev)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TurnstileWidget(
                                    siteKey: dotenv.env['CLOUDFLARE_SITE_KEY'] ?? '',
                                    onVerified: (token) {
                                      setState(() {
                                        _captchaToken = token;
                                      });
                                      debugPrint('[Login] CAPTCHA verified, token set');
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            
                            // Development bypass message
                            if (kIsWeb && isLocalDev)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.build,
                                      size: 16,
                                      color: Colors.orange[300],
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Development Mode: CAPTCHA bypassed for localhost',
                                        style: TextStyle(
                                          color: Colors.orange[300],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

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
