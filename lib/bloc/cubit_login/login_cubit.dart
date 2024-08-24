import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/user.dart';
import '../../services/user_repository.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final UserRepository userRepository;

  LoginCubit(this.userRepository, {
    bool isLogin = false,
  }) : super(LoginState(isLogin: isLogin));

  // Método para realizar el logout y eliminar el usuario del estado
  void logoutBD() {
    emit(const LoginState(isLogin: false, user: null));
  }

  // Método para realizar el login desde la base de datos
  Future<void> loginBD(String username, String password) async {
    emit(const LoginState(isLogin: false, user: null)); // Emitir estado inicial sin usuario

    final user = User(username: username, password: password);

    try {
      final isAuthenticated = await userRepository.authenticate(user);

      if (isAuthenticated != null) {
        final authenticatedUser = await userRepository.fetchUserByUsername(username); // Obtener el usuario autenticado
        emit(LoginState(isLogin: true, user: authenticatedUser));
      } else {
        emit(const LoginState(isLogin: false, user: null)); // Usuario no autenticado
      }
    } catch (e) {
      print("Error during login: $e");
      emit(const LoginState(isLogin: false, user: null)); // Emitir estado de error
    }
  }
}