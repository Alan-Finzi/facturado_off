import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../services/user_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this.userRepository, {
    bool islogin = false,
  }) : super(LoginState(isLogin: islogin));


  void logoutBD(){
    emit(const LoginState(isLogin: false));
  }

  final UserRepository userRepository;

  Future<void> loginBD(String username, String password) async {
    emit(const LoginState(isLogin: false)); // Emitir estado de carga o no login

    // Crea un objeto Usuario
    final user = User(username: username, password: password);

    // Llama al método authenticate
    final isAuthenticated = await userRepository.authenticate(user);

    // Actualiza el estado en función del resultado
    if (isAuthenticated) {
      emit(const LoginState(isLogin: true));
    } else {
      emit(const LoginState(isLogin: false));
    }
  }

}