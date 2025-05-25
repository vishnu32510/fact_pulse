part of 'authentication_bloc.dart';

sealed class AuthenticationEvent {
  const AuthenticationEvent();
}

final class FirebaseAuthentcationLogoutRequested extends AuthenticationEvent {
  const FirebaseAuthentcationLogoutRequested();
}

final class _FirebaseAuthenticationUserChanged extends AuthenticationEvent {
  const _FirebaseAuthenticationUserChanged(this.user);

  final User user;
}

//Without Firebase
final class _CredentialAuthenticationStatusChanged extends AuthenticationEvent {
  const _CredentialAuthenticationStatusChanged(this.status);

  final AuthenticationStatus status;
}

final class CredentialAuthenticationLogoutRequested extends AuthenticationEvent {}
