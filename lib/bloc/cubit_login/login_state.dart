part of 'login_cubit.dart';

 class LoginState extends Equatable {


  final bool isLogin;
  const LoginState({required this.isLogin});

  @override
  List<Object> get props => [isLogin];
}


