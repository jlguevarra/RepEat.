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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      Navigator.pop(context);
      return;
    }

    try {
      final response = await http.get(Uri.parse(
        'http://192.168.0.11/repEatApi/get_profile.php?user_id=$userId',
      ));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];
        originalName = profile['name'] ?? '';
        nameController.text = originalName;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load account settings.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
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
    // If editing name only
    if (hasValidNameChanges && !hasPasswordChanges) return true;

    // If editing password only
    if (!hasValidNameChanges && hasValidPasswordChanges) return true;

    // If editing both
    if (hasValidNameChanges && hasValidPasswordChanges) return true;

    return false;
  }

  Future<void> _saveData() async {
    setState(() => isSaving = true);

    try {
      final Map<String, dynamic> requestData = {
        'user_id': userId,
      };

      // Only include name if it's changed
      if (hasValidNameChanges) {
        requestData['name'] = nameController.text.trim();
      }

      // Only include password fields if we're changing password
      if (hasValidPasswordChanges) {
        requestData['current_password'] = currentPasswordController.text.trim();
        requestData['new_password'] = newPasswordController.text.trim();
      }

      final response = await http.post(
        Uri.parse('http://192.168.0.11/repEatApi/update_account.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (hasValidNameChanges) {
          await prefs.setString('user_name', nameController.text.trim());
          originalName = nameController.text.trim();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Account updated successfully.')),
        );

        // Clear password fields and exit edit mode
        setState(() {
          isEditing = false;
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update account.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!hasValidNameChanges && !hasPasswordChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit),
            onPressed: () async {
              if (isEditing && await _confirmDiscardChanges()) {
                setState(() {
                  isEditing = false;
                  nameController.text = originalName;
                  currentPasswordController.clear();
                  newPasswordController.clear();
                  confirmPasswordController.clear();
                });
              } else if (!isEditing) {
                setState(() => isEditing = true);
              }
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          if (isEditing) return await _confirmDiscardChanges();
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              _textInput('Full Name', nameController, isEditing),
              const SizedBox(height: 24),

              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
              ),
              const SizedBox(height: 8),
              if (!isEditing)
                _readOnlyPasswordField('Current Password'),
              if (isEditing)
                _passwordInput(
                  'Current Password',
                  currentPasswordController,
                  obscureCurrentPassword,
                      () => setState(() => obscureCurrentPassword = !obscureCurrentPassword),
                ),
              const SizedBox(height: 12),
              if (!isEditing)
                _readOnlyPasswordField('New Password'),
              if (isEditing)
                _passwordInput(
                  'New Password',
                  newPasswordController,
                  obscureNewPassword,
                      () => setState(() => obscureNewPassword = !obscureNewPassword),
                ),
              const SizedBox(height: 12),
              if (!isEditing)
                _readOnlyPasswordField('Confirm New Password'),
              if (isEditing)
                _passwordInput(
                  'Confirm New Password',
                  confirmPasswordController,
                  obscureConfirmPassword,
                      () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                ),

              if (isEditing) ...[
                if (newPasswordController.text.isNotEmpty && newPasswordController.text.length < 8)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Password must be at least 8 characters',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                if (newPasswordController.text.isNotEmpty &&
                    confirmPasswordController.text.isNotEmpty &&
                    newPasswordController.text != confirmPasswordController.text)
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
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 30),
              if (isEditing)
                Center(
                  child: ElevatedButton(
                    onPressed: canSaveChanges && !isSaving ? _saveData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size(200, 50),
                    ),
                    child: isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller, bool enabled) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

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
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isEditing ? Colors.white : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _readOnlyPasswordField(String label) {
    return TextFormField(
      enabled: false,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: const Icon(Icons.lock, color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.black54),
    );
  }
}