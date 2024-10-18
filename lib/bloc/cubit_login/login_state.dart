part of 'login_cubit.dart';

class LoginState extends Equatable {
 final bool isLogin;
 final bool isPreference;
 final User? user;
 final String? userToken;

 const LoginState( {required this.isLogin, this.user, this.userToken,required this.isPreference,});

 @override
 List<Object?> get props => [isLogin, user];

 // Método de copia para facilitar la actualización de estado
 LoginState copyWith({
  bool? isLogin,
  User? user,
  bool? isPreference
 }) {
  return LoginState(
   isLogin: isLogin ?? this.isLogin,
   user: user ?? this.user,
   userToken: userToken?? this.userToken,
   isPreference: isPreference?? this.isPreference,
  );
 }
}