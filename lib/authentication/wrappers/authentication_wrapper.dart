import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_repository.dart';
import 'package:fact_pulse/authentication/login_bloc/login_bloc.dart';
import 'package:fact_pulse/authentication/user_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../firebase_options.dart';

class AuthenticationWrapper extends StatefulWidget {
  final Widget child;
  final bool firebase;
  const AuthenticationWrapper({super.key, required this.child, this.firebase = false});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  late final AuthenticationRepository _authenticationRepository;
  late final UserRepository _userRepository;
  late bool _isFirebase;

  @override
  void initState() {
    super.initState();
    _isFirebase = widget.firebase;
    // initialiseFirebase();
    _authenticationRepository =
        _isFirebase ? FirebaseAuthenticationRepository() : CredentialAuthenticationRepository();
    _userRepository = UserRepository();
  }

  Future<void> initialiseFirebase() async {
    if (_isFirebase) {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _authenticationRepository,
      child: MultiBlocProvider(providers: [
        BlocProvider(
          create: (context) => AuthenticationBloc(
              authenticationRepository: _authenticationRepository, userRepository: _userRepository),
        ),
        BlocProvider(
          create: (context) => LoginBloc(
            authenticationRepository: _authenticationRepository,
          ),
        ),
        // BlocProvider(
        //   create: (context) => LoginBloc(
        //     authenticationRepository: _authenticationRepository,
        //   ),
        // ),
      ], child: widget.child),
    );
  }
}
