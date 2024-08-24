part of 'login_cubit.dart';
class LoginState extends Equatable {
 final bool isLogin;
 final User? user;

 const LoginState({required this.isLogin, this.user});

 @override
 List<Object?> get props => [isLogin, user];

 // Método de copia para facilitar la actualización de estado
 LoginState copyWith({
  bool? isLogin,
  User? user,
 }) {
  return LoginState(
   isLogin: isLogin ?? this.isLogin,
   user: user ?? this.user,
  );
 }
}