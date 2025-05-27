import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/core/utils/app_constants.dart';
import 'package:fact_pulse/core/utils/app_enums.dart';
import 'package:fact_pulse/core/utils/app_extensions.dart';
import 'package:fact_pulse/debate/debate_list_screen.dart';
import 'package:fact_pulse/image_fact/imege_list_screen.dart';
import 'package:fact_pulse/login_screen.dart';
import 'package:fact_pulse/profile_screen.dart';
import 'package:fact_pulse/speech/speech_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Dashboard extends StatefulWidget implements PreferredSizeWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
  
  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.appBarHeight);
}

class _DashboardState extends State<Dashboard> {
  int _navigationIndex = 0;
  bool _isSidebarExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile device
    final isMobile = context.width <= DeviceType.ipad.getMaxWidth();
    
    return BlocListener<AuthenticationBloc, AuthenticationBlocState>(
      listener: (context, state) {
        switch (state.status) {
          case AuthenticationStatus.unknown:
            debugPrint(state.status.toString());
          case AuthenticationStatus.authenticated:
            debugPrint(state.status.toString());
          case AuthenticationStatus.unauthenticated:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
        }
      },
      child: isMobile 
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _navigationIndex,
        children: [
          _buildHomeContent(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: buildBottomNavBar(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          // _buildCollapsibleSidebar(),
          Expanded(
            child: IndexedStack(
              index: _navigationIndex,
              children: [
                _buildHomeContent(),
                const ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
            children: [
              Image.asset(
                'assets/icon/icon.png',
                height: 32,
                width: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Facts Dynamics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
      titleSpacing: _getHorizontalPadding(context),
      actions: [
        if (context.width > DeviceType.ipad.getMaxWidth()) ...[
          TextButton(
            onPressed: () {
              setState(() {
                _navigationIndex = 0;
              });
            },
            child: Text(
              'Home',
              style: TextStyle(
                color: _navigationIndex == 0 ? Colors.black : Colors.grey,
                fontWeight: _navigationIndex == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _navigationIndex = 1;
              });
            },
            child: Text(
              'Profile',
              style: TextStyle(
                color: _navigationIndex == 1 ? Colors.black : Colors.grey,
                fontWeight: _navigationIndex == 1 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: _getHorizontalPadding(context)),
        ],
      ],
    );
  }

  Widget _buildCollapsibleSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarExpanded ? 250 : 70,
      color: Colors.white,
      child: Column(
        children: [
          // _buildSidebarHeader(),
          _buildSidebarItem(0, Icons.home, 'Home'),
          _buildSidebarItem(1, Icons.people, 'Profile'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(_isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _isSidebarExpanded = !_isSidebarExpanded;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      alignment: Alignment.centerLeft,
      child: _isSidebarExpanded
          ? Text(
              'Fact Pulse',
              style: Theme.of(context).textTheme.titleLarge,
            )
          : const Icon(Icons.fact_check),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _navigationIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _navigationIndex = index;
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFeaturedSection(context)
        ],
      ),
    );
  }

  Widget buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      currentIndex: _navigationIndex,
      onTap: (value) {
        setState(() {
          _navigationIndex = value;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Profile'),
      ],
    );
  }

  Widget buildFeaturedSection(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.width <= DeviceType.mobile.getMaxWidth();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(context),
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.explore,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Explore Features',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Select a feature to start fact-checking content',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : context.width <= DeviceType.ipad.getMaxWidth() ? 2 : 3,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: isMobile ? 1.5 : 1.2,
            children: [
              buildFeaturedItem(
                context, 
                'Live Debate Fact Check', 
                'Analyze claims made during debates in real-time',
                'assets/icon/debate_check.png',
                Icons.people, 
                theme.colorScheme.primary,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DebatesListScreen()),
                  );
                }
              ),
              buildFeaturedItem(
                context, 
                'Speech Fact Check', 
                'Verify claims made in speeches and presentations',
                'assets/icon/mic_check.png',
                Icons.mic, 
                theme.colorScheme.secondary,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SpeechListScreen()),
                  );
                }
              ),
              buildFeaturedItem(
                context, 
                'Image Fact Check', 
                'Detect manipulated images and verify visual claims',
                'assets/icon/scan_check.png',
                Icons.image_search, 
                theme.colorScheme.tertiary,
                () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const ImageReportListScreen())
                  );
                }
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFeaturedItem(
    BuildContext context,
    String title,
    String description,
    String assetPath,
    IconData icon,
    Color accentColor,
    VoidCallback onTab,
  ) {
    final theme = Theme.of(context);
    final isMobile = context.width <= DeviceType.mobile.getMaxWidth();
    
    return GestureDetector(
      onTap: onTab,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image with overlay
              Image.asset(
                assetPath, 
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withOpacity(0.7),
                      accentColor.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon in circle
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Title and description
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        height: 1.3,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // "Get Started" button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Get Started',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  double _getHorizontalPadding(BuildContext context) {
    if (context.width < DeviceType.ipad.getMaxWidth()) {
      return context.width * .03;
    } else {
      return context.width * .08;
    }
  }
}
