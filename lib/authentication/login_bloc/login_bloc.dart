import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../authentication_enums.dart';
import '../authentication_repository.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthenticationRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(const LoginState()) {
    on<LoginUsernameChanged>(_onUsernameChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<FirebaseLoginWithCredentials>(_loginWithCredentials);
    on<FirebaseSignUpWithCredentials>(_signUpWithCredentials);
    on<FirebaseContinueWithCredentials>(_submitEmailPassword);
    on<FirebaseLoginWithGoogle>(_logInWithGoogle);
    on<FirebaseLoginWithApple>(_logInWithApple);
    on<CredentialLoginSubmitted>(_onSubmitted);
  }

  final AuthenticationRepository _authenticationRepository;

  void _onUsernameChanged(LoginUsernameChanged event, Emitter<LoginState> emit) {
    final username = event.username;
    emit(state.copyWith(username: username, isValid: true));
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    final password = event.password;
    emit(state.copyWith(password: password, isValid: true));
  }

  Future<void> _loginWithCredentials(
    FirebaseLoginWithCredentials event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await (_authenticationRepository as FirebaseAuthenticationRepository)
          .logInWithEmailAndPassword(email: event.email, password: event.password);
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on LogInWithEmailAndPasswordFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message, status: FormzSubmissionStatus.failure));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _signUpWithCredentials(
    FirebaseSignUpWithCredentials event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await (_authenticationRepository as FirebaseAuthenticationRepository)
          .signUpWithEmailAndPassword(email: event.email, password: event.password);
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on SignUpWithEmailAndPasswordFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message, status: FormzSubmissionStatus.failure));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _submitEmailPassword(
    FirebaseContinueWithCredentials event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));

    final repo = _authenticationRepository as FirebaseAuthenticationRepository;
    final email = event.email;
    final password = event.password;

    try {
      await repo.signUpWithEmailAndPassword(email: email, password: password);
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on SignUpWithEmailAndPasswordFailure catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          await repo.logInWithEmailAndPassword(email: email, password: password);
          emit(state.copyWith(status: FormzSubmissionStatus.success));
        } on LogInWithEmailAndPasswordFailure catch (loginError) {
          emit(
            state.copyWith(errorMessage: loginError.message, status: FormzSubmissionStatus.failure),
          );
        }
      } else {
        emit(state.copyWith(errorMessage: e.message, status: FormzSubmissionStatus.failure));
      }
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _logInWithGoogle(FirebaseLoginWithGoogle event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await (_authenticationRepository as FirebaseAuthenticationRepository).logInWithGoogle();
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on LogInWithGoogleFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message, status: FormzSubmissionStatus.failure));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _logInWithApple(FirebaseLoginWithApple event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await (_authenticationRepository as FirebaseAuthenticationRepository).logInWithApple();
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on LogInWithGoogleFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message, status: FormzSubmissionStatus.failure));
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _onSubmitted(CredentialLoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.isValid) {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      try {
        await (_authenticationRepository as CredentialAuthenticationRepository).logIn(
          username: state.username,
          password: state.password,
        );
        emit(state.copyWith(status: FormzSubmissionStatus.success));
      } catch (_) {
        emit(state.copyWith(status: FormzSubmissionStatus.failure));
      }
    }
  }
}
