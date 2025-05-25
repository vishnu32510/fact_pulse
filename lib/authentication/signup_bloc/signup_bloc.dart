import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fact_pulse/authentication/authentication_enums.dart';
import 'package:fact_pulse/authentication/authentication_repository.dart';
part 'signup_event.dart';
part 'signup_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc({
    required AuthenticationRepository authenticationRepository,
  })  : _authenticationRepository = authenticationRepository,
        super(const SignUpState()) {
    on<SignUpUsernameChanged>(_onUsernameChanged);
    on<SignUpPasswordChanged>(_onPasswordChanged);
    on<FirebaseSignUpWithCredentials>(_signupWithCredentials);
    on<CredentialSignUpSubmitted>(_onSubmitted);
  }

  final AuthenticationRepository _authenticationRepository;

  void _onUsernameChanged(
    SignUpUsernameChanged event,
    Emitter<SignUpState> emit,
  ) {
    final username = event.username;
    emit(
      state.copyWith(
        username: username,
        isValid: true,
      ),
    );
  }

  void _onPasswordChanged(
    SignUpPasswordChanged event,
    Emitter<SignUpState> emit,
  ) {
    final password = event.password;
    emit(
      state.copyWith(
        password: password,
        isValid: true,
      ),
    );
  }

  Future<void> _signupWithCredentials(
    FirebaseSignUpWithCredentials event,
    Emitter<SignUpState> emit,
  ) async {
    if (!state.isValid) return;
    emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
    try {
      await (_authenticationRepository as FirebaseAuthenticationRepository).signUpWithEmailAndPassword(
        email: state.username,
        password: state.password,
      );
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on SignUpWithEmailAndPasswordFailure catch (e) {
      emit(
        state.copyWith(
          errorMessage: e.message,
          status: FormzSubmissionStatus.failure,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: FormzSubmissionStatus.failure));
    }
  }

  Future<void> _onSubmitted(
    CredentialSignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    if (state.isValid) {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      try {
        await (_authenticationRepository as CredentialAuthenticationRepository).signUp(
          username: state.username,
          password: state.password,
          email: state.email,
        );
        emit(state.copyWith(status: FormzSubmissionStatus.success));
      } catch (_) {
        emit(state.copyWith(status: FormzSubmissionStatus.failure));
      }
    }
  }
}
