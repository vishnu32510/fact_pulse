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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationBlocState>(
      listener: (context, state) {
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
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height / 4,
                        width: MediaQuery.of(context).size.width / 3,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/icon/icon.png'),
                            // image: NetworkImage(
                            //   "https://images.beta.cosmos.so/6e12791c-9c1a-42cf-89fc-85a20b059f14?format=jpeg",
                            // ),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height / 4,
                        width: MediaQuery.of(context).size.width / 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(15, 15, 15, 1).withOpacity(0.01),
                              Color.fromRGBO(30, 30, 30, 1).withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Fact Pulse⚡️',
                    textAlign: TextAlign.center,

                    // style: KCustomTextStyle.kBold(
                    //   context,
                    //   FontSize.header,
                    //   Color.fromRGBO(15, 15, 15, 1),
                    //   KConstantFonts.haskoyBold,
                    // ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // _buildLoginButton(
                  //   context,
                  //   'Continue with Apple',
                  //   Icons.apple,
                  //   Colors.white,
                  //   () => _handleLogin(context, 'Apple'),
                  // ),
                  const SizedBox(height: 24),
                  _buildLoginButton(
                    context,
                    'Continue with Email',
                    Icons.email_outlined,
                    Color.fromRGBO(15, 15, 15, 1),
                    () => _handleLogin(context, 'Email'),
                    backgroundColor: Colors.white,
                    borderColor: Colors.grey[300]!,
                    textColor: Colors.black,
                  ),
                  const SizedBox(height: 12),
                  _buildLoginButton(
                    context,
                    'Continue with Google ',
                    Icons.g_mobiledata,
                    Color.fromRGBO(15, 15, 15, 1),
                    () => _handleLogin(context, 'Google'),
                    backgroundColor: Colors.white,
                    borderColor: Colors.grey[300]!,
                    textColor: Colors.black,
                  ),
                  // const SizedBox(height: 16),
                  // TextButton(
                  //   onPressed: () => _showMoreOptions(context),
                  //   child: Text(
                  //     'Continue with more options',
                  //     // style: KCustomTextStyle.kMedium(
                  //     //   context,
                  //     //   FontSize.kMedium,
                  //     //   KConstantColors.faintBgColor,
                  //     //   KConstantFonts.haskoyMedium,
                  //     // ),
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                  // Text.rich(
                  //   TextSpan(
                  //     text: 'By continuing you agree to Todoist\'s ',
                  //     // style: KCustomTextStyle.kBold(
                  //     //   context,
                  //     //   FontSize.kMedium,
                  //     //   KConstantColors.faintBgColor,
                  //     //   KConstantFonts.haskoyBold,
                  //     // ),
                  //     children: [
                  //       TextSpan(
                  //         text: 'Terms of Service',
                  //         // style: KCustomTextStyle.kBold(
                  //         //   context,
                  //         //   FontSize.kMedium,
                  //         //   Color.fromRGBO(15, 15, 15, 1),
                  //         //   KConstantFonts.haskoyBold,
                  //         // ),
                  //         recognizer: TapGestureRecognizer()
                  //           ..onTap = () {
                  //             // Open Terms of Service
                  //           },
                  //       ),
                  //       TextSpan(
                  //         text: ' and ',
                  //         // style: KCustomTextStyle.kBold(
                  //         //   context,
                  //         //   FontSize.kMedium,
                  //         //   KConstantColors.faintBgColor,
                  //         //   KConstantFonts.haskoyBold,
                  //         // ),
                  //       ),
                  //       TextSpan(
                  //         text: 'Privacy Policy',
                  //         // style: KCustomTextStyle.kBold(
                  //         //   context,
                  //         //   FontSize.kMedium,
                  //         //   Color.fromRGBO(15, 15, 15, 1),
                  //         //   KConstantFonts.haskoyBold,
                  //         // ),
                  //         recognizer: TapGestureRecognizer()
                  //           ..onTap = () {
                  //             // Open Privacy Policy
                  //           },
                  //       ),
                  //       const TextSpan(text: '.'),
                  //     ],
                  //   ),
                  //   textAlign: TextAlign.center,
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    String text,
    IconData icon,
    Color iconColor,
    VoidCallback onPressed, {
    Color backgroundColor = Colors.black,
    Color? borderColor,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      // width: MediaQuery.of(context).size.width / 3,
      // height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(
              text,
              // style: KCustomTextStyle.kBold(
              //   context,
              //   FontSize.kMedium,
              //   iconColor,
              //   KConstantFonts.haskoyBold,
              // ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, String method) {
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
      }
      // bloc.add(
      //   const FirebaseContinueWithCredentials(email: 'vishnu32510@gamil.com', password: 'Test1234'),
      // );
    }
    // Navigate to the next screen after successful login
  }
}
