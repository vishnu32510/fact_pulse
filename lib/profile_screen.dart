import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/user.dart';
import 'package:fact_pulse/core/utils/app_extensions.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthenticationBloc, AuthenticationBlocState>(
        builder: (context, authState) {
          switch (authState.status) {
            case AuthenticationStatus.authenticated:
              final User user = authState.user;
              return _buildAuthenticatedProfile(context, user);
            case AuthenticationStatus.unauthenticated:
              return _buildUnauthenticatedState(context);
            case AuthenticationStatus.unknown:
              return _buildLoadingState(context);
          }
        },
      ),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, User user) {
    final theme = Theme.of(context);
    final isSmallScreen = context.width < 600;
    final avatarUrl = user.photo;
    final displayName = user.name ?? "User";
    final email = user.email;
    final uid = user.id;
    
    return CustomScrollView(
      slivers: [
        // App Bar with profile background
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemBuilder: (context, index) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            centerTitle: true,
          ),
        ),
        
        // Profile content
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main content container
              Container(
                margin: const EdgeInsets.only(top: 60),
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User name
                    Text(
                      displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    // User email
                    if (email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Stats cards
                    isSmallScreen
                        ? _buildVerticalStatsCards(context, uid)
                        : _buildHorizontalStatsCards(context, uid),
                    
                    const SizedBox(height: 32),
                    
                    // Account actions section
                    _buildAccountActions(context),
                    
                    const SizedBox(height: 32),
                    
                    // Logout button
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthenticationBloc>().add(
                          const FirebaseAuthentcationLogoutRequested(),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Avatar positioned on top
              Positioned(
                top: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            displayName[0],
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerticalStatsCards(BuildContext context, String uid) {
    final theme = Theme.of(context);
    final firestore = FirebaseFirestore.instance;
    
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('users').doc(uid).collection('debates').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
            return _buildStatCard(
              context,
              Icons.people,
              'Debates Analyzed',
              count,
              theme.colorScheme.primary,
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('users').doc(uid).collection('speechs').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
            return _buildStatCard(
              context,
              Icons.mic,
              'Speech Fact Checks',
              count,
              theme.colorScheme.secondary,
            );
          },
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('users').doc(uid).collection('images').snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
            return _buildStatCard(
              context,
              Icons.image,
              'Images Verified',
              count,
              theme.colorScheme.tertiary,
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildHorizontalStatsCards(BuildContext context, String uid) {
    final theme = Theme.of(context);
    final firestore = FirebaseFirestore.instance;
    
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('users').doc(uid).collection('debates').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
              return _buildStatCard(
                context,
                Icons.people,
                'Debates',
                count,
                theme.colorScheme.primary,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('users').doc(uid).collection('speechs').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
              return _buildStatCard(
                context,
                Icons.mic,
                'Speeches',
                count,
                theme.colorScheme.secondary,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('users').doc(uid).collection('images').snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
              return _buildStatCard(
                context,
                Icons.image,
                'Images',
                count,
                theme.colorScheme.tertiary,
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              value == '...' 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Account',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildActionTile(
                context,
                Icons.bookmark,
                'Saved Reports',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved reports coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  
  Widget _buildUnauthenticatedState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Not Logged In',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to view your profile',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to login screen
            },
            icon: const Icon(Icons.login),
            label: const Text('Log In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Profile',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your information',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
