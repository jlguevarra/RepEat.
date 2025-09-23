import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final nameController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;
  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  int? userId;
  String originalName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Custom Snackbar method - Improved Design
  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return; // Guard against state changes if widget is disposed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      _showCustomSnackBar('User ID not found. Please log in again.', false); // Updated SnackBar
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final response = await http.get(Uri.parse(
        'http://192.168.100.79/repEatApi/get_profile.php?user_id=$userId',
      ));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        originalName = profile['name'] ?? '';
        if (mounted) { // Check if mounted before setState
          setState(() {
            nameController.text = originalName;
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to load account settings.', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Error: $e', false); // Updated SnackBar
    } finally {
      if (mounted) { // Check if mounted before setState
        setState(() => isLoading = false);
      }
    }
  }

  bool get hasValidNameChanges {
    return nameController.text.trim().isNotEmpty &&
        nameController.text.trim() != originalName;
  }

  bool get hasPasswordChanges {
    return currentPasswordController.text.isNotEmpty ||
        newPasswordController.text.isNotEmpty ||
        confirmPasswordController.text.isNotEmpty;
  }

  bool get isNewPasswordDifferent {
    return newPasswordController.text.isNotEmpty &&
        newPasswordController.text != currentPasswordController.text;
  }

  bool get hasValidPasswordChanges {
    if (!hasPasswordChanges) return false;

    return currentPasswordController.text.isNotEmpty &&
        newPasswordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        newPasswordController.text == confirmPasswordController.text &&
        newPasswordController.text.length >= 8 &&
        isNewPasswordDifferent;
  }

  bool get canSaveChanges {
    if (hasValidNameChanges && !hasPasswordChanges) return true;
    if (!hasValidNameChanges && hasValidPasswordChanges) return true;
    if (hasValidNameChanges && hasValidPasswordChanges) return true;
    return false;
  }

  bool get hasUnsavedChanges {
    return hasValidNameChanges || hasPasswordChanges;
  }

  Future<void> _saveData() async {
    setState(() => isSaving = true);

    try {
      final Map<String, dynamic> requestData = {
        'user_id': userId,
      };

      if (hasValidNameChanges) {
        requestData['name'] = nameController.text.trim();
      }

      if (hasValidPasswordChanges) {
        requestData['current_password'] = currentPasswordController.text.trim();
        requestData['new_password'] = newPasswordController.text.trim();
      }

      final response = await http.post(
        Uri.parse('http://192.168.100.79/repEatApi/update_account.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (hasValidNameChanges) {
          await prefs.setString('user_name', nameController.text.trim());
          if (mounted) { // Check if mounted before setState
            setState(() {
              originalName = nameController.text.trim();
            });
          }
        }

        _showCustomSnackBar(data['message'] ?? 'Account updated successfully.', true); // Updated SnackBar

        if (mounted) { // Check if mounted before setState
          setState(() {
            isEditing = false;
            currentPasswordController.clear();
            newPasswordController.clear();
            confirmPasswordController.clear();
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to update account.', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Error: $e', false); // Updated SnackBar
    } finally {
      if (mounted) { // Check if mounted before setState
        setState(() => isSaving = false);
      }
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!hasUnsavedChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Changes?'),
        content: const Text('Any unsaved changes will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _onWillPop() async {
    if (!isEditing || !hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple, // Match app bar color
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Account Settings...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50, // Softer background - Improved Design
        appBar: AppBar(
          title: const Text('Account Settings'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            IconButton(
              icon: Icon(isEditing ? Icons.cancel : Icons.edit), // Changed icon for clarity
              onPressed: () async {
                if (isEditing && await _confirmDiscardChanges()) {
                  if (mounted) { // Check if mounted before setState
                    setState(() {
                      isEditing = false;
                      nameController.text = originalName;
                      currentPasswordController.clear();
                      newPasswordController.clear();
                      confirmPasswordController.clear();
                    });
                  }
                } else if (!isEditing) {
                  setState(() => isEditing = true);
                }
              },
              tooltip: isEditing ? 'Cancel' : 'Edit', // Added tooltip
            ),
          ],
        ),
        body: SafeArea( // Improved Design
          child: SingleChildScrollView( // Improved Design
            padding: const EdgeInsets.all(16), // Improved Design
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Improved Design
              children: [
                // Header Section - Improved Design
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 40,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your profile information and password',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Basic Information Section - Improved Design (Card)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _textInput('Full Name', nameController, isEditing),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Section - Improved Design (Card)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (!isEditing)
                          _readOnlyPasswordField('Password not shown') // Improved read-only display
                        else
                          _passwordInput(
                            'Current Password',
                            currentPasswordController,
                            obscureCurrentPassword,
                                () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                          ),
                        const SizedBox(height: 16),
                        if (!isEditing)
                          _readOnlyPasswordField('Password not shown') // Improved read-only display
                        else
                          _passwordInput(
                            'New Password',
                            newPasswordController,
                            obscureNewPassword,
                                () => setState(() => obscureNewPassword = !obscureNewPassword),
                          ),
                        const SizedBox(height: 16),
                        if (!isEditing)
                          _readOnlyPasswordField('Password not shown') // Improved read-only display
                        else
                          _passwordInput(
                            'Confirm New Password',
                            confirmPasswordController,
                            obscureConfirmPassword,
                                () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                          ),
                        // Password validation messages
                        if (isEditing) ...[
                          if (newPasswordController.text.isNotEmpty &&
                              newPasswordController.text.length < 8)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Password must be at least 8 characters',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          if (newPasswordController.text.isNotEmpty &&
                              confirmPasswordController.text.isNotEmpty &&
                              newPasswordController.text !=
                                  confirmPasswordController.text)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Passwords do not match',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          if (newPasswordController.text.isNotEmpty &&
                              currentPasswordController.text.isNotEmpty &&
                              !isNewPasswordDifferent)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'New password must be different from current password',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button (only visible when editing) - Improved Design
                if (isEditing)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canSaveChanges && !isSaving ? _saveData : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Improved Text Input - Better Design Consistency
  Widget _textInput(String label, TextEditingController controller, bool enabled) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Colors.black87),
      decoration: _inputDecoration().copyWith(
        labelText: label,
        labelStyle: TextStyle(
            color: enabled ? Colors.deepPurple : Colors.grey),
      ),
      onChanged: (_) {
        if (enabled) setState(() {}); // Only trigger rebuild if enabled
      },
    );
  }

  // Improved Password Input - Better Design Consistency
  Widget _passwordInput(
      String label,
      TextEditingController controller,
      bool obscureText,
      VoidCallback onToggleVisibility,
      ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: isEditing,
      style: const TextStyle(color: Colors.black87),
      decoration: _inputDecoration().copyWith(
        labelText: label,
        labelStyle: TextStyle(
            color: isEditing ? Colors.deepPurple : Colors.grey),
        suffixIcon: isEditing // Only show icon when editing
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade600, // Fixed potential null color
          ),
          onPressed: onToggleVisibility,
        )
            : null, // No suffix icon when not editing
      ),
      onChanged: (_) {
        if (isEditing) setState(() {}); // Only trigger rebuild if editing
      },
    );
  }

  // Improved Read-Only Password Field Display
  Widget _readOnlyPasswordField(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, // Softer background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.deepPurple.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.deepPurple.shade700,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Improved Input Decoration - Better Design Consistency
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.deepPurple.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}