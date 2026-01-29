part of 'login_cubit.dart';

class LoginState extends Equatable {
 final bool isLogin;        // Usuario ha iniciado sesión correctamente
 final bool isPreference;   // Datos ya sincronizados (omitir sincronización)
 final bool needsOnlineAuth; // Requiere autenticación online (para sincronización explícita)
 final User? user;
 final String? userToken;

 const LoginState({
   required this.isLogin,
   this.user,
   this.userToken,
   required this.isPreference,
   this.needsOnlineAuth = false,
 });

 @override
 List<Object?> get props => [isLogin, user, isPreference, needsOnlineAuth];

 // Método de copia para facilitar la actualización de estado
 LoginState copyWith({
  bool? isLogin,
  User? user,
  bool? isPreference,
  bool? needsOnlineAuth,
  String? userToken,
 }) {
  return LoginState(
   isLogin: isLogin ?? this.isLogin,
   user: user ?? this.user,
   userToken: userToken ?? this.userToken,
   isPreference: isPreference ?? this.isPreference,
   needsOnlineAuth: needsOnlineAuth ?? this.needsOnlineAuth,
  );
 }
}