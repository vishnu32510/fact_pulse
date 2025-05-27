import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthenticationBloc, AuthenticationBlocState>(
        builder: (context, authState) {
          switch (authState.status) {
            case AuthenticationStatus.authenticated:
              final User user = authState.user;
              return _buildProfile(context, user);
            case AuthenticationStatus.unauthenticated:
              return const Center(child: Text('Please log in.'));
            case AuthenticationStatus.unknown:
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    final avatarUrl = user.photo;       // or however you exposed these
    final displayName = user.name;  // in your User model
    final email       = user.email;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    displayName != null ? displayName[0] : '',
                    style: const TextStyle(fontSize: 24),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            displayName ??"",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              // trigger your logout flow
              context.read<AuthenticationBloc>().add(
                    const FirebaseAuthentcationLogoutRequested(),
                  );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
