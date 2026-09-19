import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Enhancement 3
  final _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    // Enhancement 1
    Navigator.pushNamedAndRemoveUntil(context, '/splash', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.id == 0) {
          return const Center(child: Text('Unable to load profile'));
        }

        final user = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _userFuture = _userService.getUser()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: user.image.isEmpty ? null : NetworkImage(user.image),
                  child: user.image.isEmpty ? const Icon(Icons.person, size: 48) : null,
                ),
              ),
              const SizedBox(height: 14),
              Text(user.displayName, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('@${user.username}', textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 28),
              Card(
                child: Column(
                  children: [
                    ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(user.email)),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.wc_outlined), title: const Text('Gender'), subtitle: Text(user.gender)),
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('User ID'), subtitle: Text('#${user.id}')),
                  ],
                ),
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
