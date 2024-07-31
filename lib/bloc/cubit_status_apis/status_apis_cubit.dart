import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
part 'status_apis_state.dart';

class StatusApisCubit extends Cubit<StatusApisState> {
StatusApisCubit({ bool isConnected =false,}) : super(StatusApisState(isConnected: isConnected));




Future<void> checkUrl( String url) async {
  emit(const StatusApisState(isConnected: false)); // Emitir estado de carga o no login

  try {
    final response = await http.get(Uri.parse(url));

    // Verifica si el código de estado es 200
    if (response.statusCode == 200) {
      emit(const StatusApisState(isConnected: true));
    } else {
      emit(const StatusApisState(isConnected: true));
    }
  } catch (e) {
    // Puedes manejar el error aquí si es necesario
    print('Error: $e');
    emit(const StatusApisState(isConnected: true));
  }

}

}
