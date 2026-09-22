import 'package:flutter/material.dart';

import '../services/user_service.dart';
import '../widgets/app_message.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  late Future<Map<String, dynamic>> _userFuture;
  String? _updatedUsername;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUserData();
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  Future<void> _updateUsername(String currentUsername) async {
    final username = await showDialog<String>(
      context: context,
      builder: (_) => _UsernameDialog(currentUsername: currentUsername),
    );
    if (username == null || username.isEmpty) return;
    try {
      await _userService.updateUsername(
        username: username,
      );
      if (!mounted) return;
      setState(() {
        _updatedUsername = username;
        _userFuture = _userService.getUserData();
      });
      _showMessage('Username updated.', isError: false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(UserService.messageForError(error));
    }
  }

  Future<void> _changePassword(String email) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (values == null || values[0].isEmpty || values[1].length < 6) {
      if (values != null) {
        _showMessage('Your new password must be at least 6 characters.');
      }
      return;
    }
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: values[0],
        newPassword: values[1],
        email: email,
      );
      if (!mounted) return;
      _showMessage('Password updated.', isError: false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(UserService.messageForError(error));
    }
  }

  Future<void> _deleteAccount(String email) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (password == null || password.isEmpty) return;
    try {
      await _userService.deleteAccount(email: email, password: password);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
    } catch (error) {
      if (!mounted) return;
      _showMessage(UserService.messageForError(error));
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (isError) {
      AppMessage.error(context, message);
    } else {
      AppMessage.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Unable to load profile'));
        }
        final data = snapshot.data!;
        final username = _updatedUsername ?? data['username'] as String;
        final loginType = data['loginType'] == LoginType.firebase.name
            ? LoginType.firebase
            : LoginType.dummyJson;
        final name = '${data['firstName']} ${data['lastName']}'.trim();
        final displayName = name.isEmpty ? data['username'] as String : name;
        final email = data['email'] as String;
        return RefreshIndicator(
          onRefresh: () async =>
              setState(() => _userFuture = _userService.getUserData()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 48,
                  child: Icon(Icons.person, size: 48),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '@$username',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cake_outlined),
                      title: const Text('Age'),
                      subtitle: Text('${data['age']}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Contact'),
                      subtitle: Text(data['phone'] as String),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('Login type'),
                      subtitle: Text(
                        loginType == LoginType.firebase
                            ? 'Firebase Auth'
                            : 'DummyJSON',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _updateUsername(username),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Update username'),
              ),
              OutlinedButton.icon(
                onPressed: loginType == LoginType.firebase
                    ? () => _changePassword(email)
                    : null,
                icon: const Icon(Icons.lock_reset_outlined),
                label: const Text('Change password'),
              ),
              OutlinedButton.icon(
                onPressed: loginType == LoginType.firebase
                    ? () => _deleteAccount(email)
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete account'),
              ),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UsernameDialog extends StatefulWidget {
  const _UsernameDialog({required this.currentUsername});

  final String currentUsername;

  @override
  State<_UsernameDialog> createState() => _UsernameDialogState();
}

class _UsernameDialogState extends State<_UsernameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentUsername,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update username'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Username'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, [
            _currentController.text,
            _newController.text,
          ]),
          child: const Text('Change'),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Current password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _passwordController.text),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
