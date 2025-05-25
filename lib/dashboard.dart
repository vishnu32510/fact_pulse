import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/debate/debate_screen.dart';
import 'package:fact_pulse/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Fact Pulse',
            // style: KCustomTextStyle.kBold(
            //   context,
            //   FontSize.kMedium + 2,
            //   KConstantColors.bgColor,
            //   KConstantFonts.haskoyMedium,
            // ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                context.read<AuthenticationBloc>().add(
                  const FirebaseAuthentcationLogoutRequested(),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [buildFeaturedSection(context)],
          ),
        ),
        bottomNavigationBar: buildBottomNavBar(),
      ),
    );
  }

  Widget buildCategoryTab(BuildContext context, String label, {bool isSelected = false}) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: isSelected ? Colors.black : Colors.transparent, width: 2),
        ),
      ),
      child: Text(
        label,
        // style: KCustomTextStyle.kMedium(
        //   context,
        //   FontSize.kMedium,
        //   KConstantColors.bgColor,
        //   KConstantFonts.haskoyMedium,
        // ),
      ),
    );
  }

  Widget buildFeaturedSection(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      width: MediaQuery.of(context).size.width / 2,
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
        children: [
          buildFeaturedItem(context, 'Live Fact Check', 'assets/icon/mic_check.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DebateScreen()));
          }),
          buildFeaturedItem(context, 'Image Fact Check', 'assets/icon/scan_check.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SizedBox()));
          }),
        ],
      ),
    );
  }

  Widget buildFeaturedItem(
    BuildContext context,
    String title,
    String assetPath,
    VoidCallback onTab,
  ) {
    return GestureDetector(
      onTap: onTab,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(assetPath, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: SizedBox(), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Profile'),
      ],
    );
  }
}
