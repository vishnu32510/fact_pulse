part of 'signup_bloc.dart';

final class SignUpState extends Equatable {
  const SignUpState({
    this.status = FormzSubmissionStatus.initial,
    this.username = "",
    this.email = "",
    this.password = "",
    this.isValid = true,
    this.errorMessage,
  });

  final FormzSubmissionStatus status;
  final String username;
  final String password;
  final String email;
  final bool isValid;
  final String? errorMessage;

  SignUpState copyWith({
    FormzSubmissionStatus? status,
    String? username,
    String? password,
    String? email,
    bool? isValid,
    String? errorMessage,
  }) {
    return SignUpState(
      status: status ?? this.status,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [status, username, password,isValid,username, email];
}