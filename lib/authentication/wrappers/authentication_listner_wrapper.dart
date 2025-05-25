import 'package:fact_pulse/authentication/authentication_bloc/authentication_bloc.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthenticationListnerWrapper extends StatelessWidget {
  final Widget child;
  const AuthenticationListnerWrapper({super.key, required this.child});

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
              debugPrint(state.status.toString());
          }
        },
        child: child);
  }
}
