import 'package:fact_pulse/authentication/authentication.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isSmallScreen = size.width < 600;

    return BlocListener<AuthenticationBloc, AuthenticationBlocState>(
      listener: (context, state) {
        setState(() => _isLoading = false);
        
        switch (state.status) {
          case AuthenticationStatus.unknown:
            debugPrint(state.status.toString());
          case AuthenticationStatus.authenticated:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          case AuthenticationStatus.unauthenticated:
            debugPrint(state.status.toString());
        }
      },
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          setState(() => _isLoading = state.status == FormzSubmissionStatus.inProgress);
          
          if (state.status == FormzSubmissionStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo and app name
                        _buildLogoSection(context, isSmallScreen),
                        
                        SizedBox(height: isSmallScreen ? 18 : 24),
                        
                        // Form section
                        _buildFormSection(context, isSmallScreen),
                        
                        SizedBox(height: isSmallScreen ? 10 : 18),
                        
                        // Social login buttons
                        _buildSocialLoginButtons(context, isSmallScreen),
                        
                        const SizedBox(height: 24),
                        
                        // _buildTermsSection(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isSmallScreen) {
    final size = MediaQuery.of(context).size;
    final logoSize = isSmallScreen 
        ? size.width * 0.2 
        : size.width * 0.1;
    
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            height: logoSize,
            width: logoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Image.asset(
                    'assets/icon/icon.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Facts Dynamics',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verify facts, build trust',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final formWidth = isSmallScreen ? size.width : size.width * 0.4;
    
    return Container(
      width: formWidth,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign In',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'your.email@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) 
                  ? 'Please enter a valid email' 
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible 
                        ? Icons.visibility_off_outlined 
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.length < 6) 
                  ? 'Password must be at least 6 characters' 
                  : null,
            ),
            // const SizedBox(height: 8),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: () {
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //           content: Text('Password reset coming soon'),
            //           behavior: SnackBarBehavior.floating,
            //         ),
            //       );
            //     },
            //     style: TextButton.styleFrom(
            //       foregroundColor: theme.colorScheme.primary,
            //       padding: EdgeInsets.zero,
            //       minimumSize: const Size(0, 36),
            //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //     ),
            //     child: const Text('Forgot Password?'),
            //   ),
            // ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading 
                    ? null 
                    : () => _handleLogin(context, 'Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue with Email',
                        style: TextStyle(
                          fontSize: 16,
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

  Widget _buildSocialLoginButtons(BuildContext context, bool isSmallScreen) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final buttonWidth = isSmallScreen ? size.width : size.width * 0.4;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.5))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: buttonWidth,
          child: _buildLoginButton(
            context,
            'Continue with Google',
            Icons.g_mobiledata,
            Colors.red,
            () => _handleLogin(context, 'Google'),
            backgroundColor: theme.colorScheme.surface,
            borderColor: theme.colorScheme.outline.withOpacity(0.5),
            textColor: theme.colorScheme.onSurface,
            isSmallScreen: isSmallScreen,
          ),
        ),
        // const SizedBox(height: 16),
        // SizedBox(
        //   width: buttonWidth,
        //   child: _buildLoginButton(
        //     context,
        //     'Continue with Apple',
        //     Icons.apple,
        //     theme.colorScheme.onSurface,
        //     () => _handleLogin(context, 'Apple'),
        //     backgroundColor: theme.colorScheme.surface,
        //     borderColor: theme.colorScheme.outline.withOpacity(0.5),
        //     textColor: theme.colorScheme.onSurface,
        //     isSmallScreen: isSmallScreen,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildTermsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onBackground.withOpacity(0.7),
        ),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            // Add GestureRecognizer here if needed
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            // Add GestureRecognizer here if needed
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    String text,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed, {
    required Color backgroundColor,
    required Color? borderColor,
    required Color textColor,
    required bool isSmallScreen,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor != null 
              ? BorderSide(color: borderColor) 
              : BorderSide.none,
        ),
        disabledBackgroundColor: backgroundColor.withOpacity(0.7),
        disabledForegroundColor: textColor.withOpacity(0.7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: _isLoading ? iconColor.withOpacity(0.7) : iconColor,
            size: isSmallScreen ? 24 : 28,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin(BuildContext context, String method) {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    final bloc = context.read<LoginBloc>();

    if (method == 'Google') {
      bloc.add(const FirebaseLoginWithGoogle());
    } else if (method == 'Apple') {
      bloc.add(const FirebaseLoginWithApple());
    } else if (method == 'Email') {
      if (_formKey.currentState?.validate() ?? false) {
        bloc.add(
          FirebaseContinueWithCredentials(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          ),
        );
      } else {
        setState(() => _isLoading = false);
      }
    }
  }
}
