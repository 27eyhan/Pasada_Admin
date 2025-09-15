import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/screen/settings_pages/settings_utils.dart';
import 'package:pasada_admin_application/services/auth_service.dart';
import 'package:bcrypt/bcrypt.dart';

class SecurityContent extends StatefulWidget {
  final bool isDark;
  
  const SecurityContent({super.key, required this.isDark});

  @override
  _SecurityContentState createState() => _SecurityContentState();
}

class _SecurityContentState extends State<SecurityContent> {
  bool twoFactorAuth = false;
  bool biometricAuth = true;
  bool sessionTimeout = true;
  int sessionTimeoutMinutes = 30;
  
  // Password change variables
  bool isChangingPassword = false;
  bool isSavingPassword = false;
  bool _passwordsMatch = true;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  // Controllers for password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startPasswordChange() {
    if (!mounted) return;
    setState(() {
      isChangingPassword = true;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _passwordsMatch = true;
    });
  }

  void _cancelPasswordChange() {
    if (!mounted) return;
    setState(() {
      isChangingPassword = false;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _passwordsMatch = true;
    });
  }

  void _checkPasswordsMatch() {
    if (!mounted) return;
    setState(() {
      if (_newPasswordController.text.isEmpty && _confirmPasswordController.text.isEmpty) {
        _passwordsMatch = true;
      } else {
        _passwordsMatch = _newPasswordController.text == _confirmPasswordController.text;
      }
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_passwordsMatch) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSavingPassword = true;
    });

    try {
      final currentAdminID = AuthService().currentAdminID;
      if (currentAdminID == null) {
        throw Exception('Admin ID not found');
      }

      // Verify current password
      final response = await Supabase.instance.client
          .from('adminTable')
          .select('admin_password')
          .eq('admin_id', currentAdminID)
          .maybeSingle();

      if (response == null || response['admin_password'] == null) {
        throw Exception('Could not verify current password');
      }

      final currentHashedPassword = response['admin_password'];
      if (!BCrypt.checkpw(_currentPasswordController.text, currentHashedPassword)) {
        throw Exception('Current password is incorrect');
      }

      // Hash new password
      final String hashedPassword = BCrypt.hashpw(_newPasswordController.text.trim(), BCrypt.gensalt());

      // Update password
      await Supabase.instance.client
          .from('adminTable')
          .update({'admin_password': hashedPassword})
          .match({'admin_id': currentAdminID});

      if (!mounted) return;
      
      setState(() {
        isChangingPassword = false;
        isSavingPassword = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Palette.greenColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        isSavingPassword = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing password: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Authentication Methods
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Authentication Methods",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 16),
              
              SwitchTile(
                title: "Two-Factor Authentication",
                subtitle: "Add an extra layer of security to your account",
                value: twoFactorAuth,
                onChanged: (value) => setState(() => twoFactorAuth = value),
                isDark: widget.isDark,
              ),
              
              SwitchTile(
                title: "Biometric Authentication",
                subtitle: "Use fingerprint or face recognition",
                value: biometricAuth,
                onChanged: (value) => setState(() => biometricAuth = value),
                isDark: widget.isDark,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Session Management
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchTile(
                title: "Session Timeout",
                subtitle: "Automatically log out after inactivity",
                value: sessionTimeout,
                onChanged: (value) => setState(() => sessionTimeout = value),
                isDark: widget.isDark,
              ),
              
              if (sessionTimeout) ...[
                SizedBox(height: 16),
                Text(
                  "Timeout Duration: $sessionTimeoutMinutes minutes",
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                Slider(
                  value: sessionTimeoutMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  activeColor: Palette.greenColor,
                  onChanged: (value) => setState(() => sessionTimeoutMinutes = value.round()),
                ),
              ],
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Password Management
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? Palette.darkSurface : Palette.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Password Management",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Palette.darkText : Palette.lightText,
                  fontFamily: 'Inter',
                ),
              ),
              SizedBox(height: 16),
              
              if (!isChangingPassword) ...[
                ElevatedButton.icon(
                  onPressed: _startPasswordChange,
                  icon: Icon(Icons.lock, size: 18),
                  label: Text("Change Password"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Palette.greenColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 0,
                  ),
                ),
              ] else ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 300,
                        child: _buildPasswordField(
                          controller: _currentPasswordController,
                          label: "Current Password",
                          icon: Icons.lock_outline,
                          obscureText: !_showCurrentPassword,
                          onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter your current password'
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: 300,
                        child: _buildPasswordField(
                          controller: _newPasswordController,
                          label: "New Password",
                          icon: Icons.lock_outline,
                          obscureText: !_showNewPassword,
                          onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                          onChanged: (_) => _checkPasswordsMatch(),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter a new password'
                              : value.length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: 300,
                        child: _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: "Confirm New Password",
                          icon: Icons.lock_outline,
                          obscureText: !_showConfirmPassword,
                          onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                          onChanged: (_) => _checkPasswordsMatch(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (!_passwordsMatch && _newPasswordController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Passwords do not match',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _cancelPasswordChange,
                              icon: Icon(Icons.cancel, size: 18),
                              label: Text("Cancel"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[400],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isSavingPassword ? null : _savePassword,
                              icon: isSavingPassword 
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                    )
                                  : Icon(Icons.save, size: 18),
                              label: Text(isSavingPassword ? "Saving..." : "Save Password"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Palette.greenColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        

      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: widget.isDark ? Palette.darkText : Palette.lightText,
        fontFamily: 'Inter',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: widget.isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          fontFamily: 'Inter',
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: Palette.greenColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: widget.isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            size: 20,
          ),
          onPressed: onToggleVisibility,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(
            color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(
            color: widget.isDark ? Palette.darkBorder : Palette.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: Palette.greenColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: widget.isDark ? Palette.darkSurface : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
        hintStyle: TextStyle(
          color: widget.isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          fontFamily: 'Inter',
          fontSize: 13,
        ),
        isDense: true,
      ),
    );
  }
}
