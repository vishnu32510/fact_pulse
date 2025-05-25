import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/authentication/user.dart';

import '../authentication_repository.dart';
import '../user_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc extends Bloc<AuthenticationEvent, AuthenticationBlocState> {
  AuthenticationBloc({required AuthenticationRepository authenticationRepository,
  required UserRepository userRepository,})
      : _authenticationRepository = authenticationRepository,
      _userRepository = userRepository,
        super(const AuthenticationBlocState.unknown()
          // authenticationRepository.currentUser.isNotEmpty
          //     ? AppState.authenticated(authenticationRepository.currentUser)
          //     : const AppState.unauthenticated(),
        ) {
    on<_FirebaseAuthenticationUserChanged>(_onUserChanged);
    on<FirebaseAuthentcationLogoutRequested>(_onLogoutRequested);
    on<_CredentialAuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<CredentialAuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);
    if(_authenticationRepository is FirebaseAuthenticationRepository){
      _userSubscription = _authenticationRepository.user.listen(
      (user) => add(_FirebaseAuthenticationUserChanged(user)),
    );}
    if(_authenticationRepository is CredentialAuthenticationRepository){
      _authenticationStatusSubscription = _authenticationRepository.status.listen(
      (status) => add(_CredentialAuthenticationStatusChanged(status)),
    );
    }
  }

  final AuthenticationRepository _authenticationRepository;
  final UserRepository _userRepository;
  late final StreamSubscription<User> _userSubscription;
  late StreamSubscription<AuthenticationStatus>
      _authenticationStatusSubscription;

  void _onUserChanged(_FirebaseAuthenticationUserChanged event, Emitter<AuthenticationBlocState> emit) {
    emit(
      event.user.isNotEmpty
          ? AuthenticationBlocState.authenticated(event.user)
          : const AuthenticationBlocState.unauthenticated(),
    );
  }

  void _onLogoutRequested(FirebaseAuthentcationLogoutRequested event, Emitter<AuthenticationBlocState> emit) {
    unawaited((_authenticationRepository as FirebaseAuthenticationRepository).logOut());
  }

   Future<void> _onAuthenticationStatusChanged(
    _CredentialAuthenticationStatusChanged event,
    Emitter<AuthenticationBlocState> emit,
  ) async {
    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        return emit(const AuthenticationBlocState.unauthenticated());
      case AuthenticationStatus.authenticated:
        final user = await _tryGetUser();
        return emit(
          user != null
              ? AuthenticationBlocState.authenticated(user)
              : const AuthenticationBlocState.unauthenticated(),
        );
      case AuthenticationStatus.unknown:
        return emit(const AuthenticationBlocState.unknown());
    }
  }

  void _onAuthenticationLogoutRequested(
    CredentialAuthenticationLogoutRequested event,
    Emitter<AuthenticationBlocState> emit,
  ) {
    (_authenticationRepository as CredentialAuthenticationRepository).logOut();
  }

  Future<User?> _tryGetUser() async {
    try {
      final user = await _userRepository.getUser();
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _authenticationStatusSubscription.cancel();
    return super.close();
  }
}
