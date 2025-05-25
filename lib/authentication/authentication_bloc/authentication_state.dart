part of 'authentication_bloc.dart';

final class AuthenticationBlocState extends Equatable {
  const AuthenticationBlocState._({
    required this.status,
    this.user = User.empty,
  });

  const AuthenticationBlocState.unknown() : this._(status: AuthenticationStatus.unknown);

  const AuthenticationBlocState.authenticated(User user)
      : this._(status: AuthenticationStatus.authenticated, user: user);

  const AuthenticationBlocState.unauthenticated() : this._(status: AuthenticationStatus.unauthenticated);

  final AuthenticationStatus status;
  final User user;

  @override
  List<Object> get props => [status, user];
}
