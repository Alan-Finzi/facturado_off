import 'package:bloc/bloc.dart';
import '../../models/lista_precio_model.dart';
import '../../services/user_repository.dart';
import 'lista_precios_state.dart';


class ListaPreciosCubit extends Cubit<ListaPreciosState> {
  final UserRepository userRepository;

  ListaPreciosCubit(this.userRepository)
      : super(ListaPreciosState(currentList: []));

  Future<void> getListasPreciosBD() async {
    try {
      // Llamamos al método del repositorio para obtener la lista de precios
      final list = await userRepository.fetchListaPrecios();

      // Emitimos un nuevo estado con la lista de precios obtenida
      emit(ListaPreciosState(currentList: list));
    } catch (e) {
      // Manejo de errores, podrías emitir un estado de error si lo consideras necesario
      print("Error al obtener listas de precios: $e");

      // También podrías emitir un estado de error, si tienes un estado definido para eso
      // emit(ListaPreciosStateError());
    }
  }

  void addListaPrecio(ListaPreciosModel listaPrecio) {
    final updatedList = List<ListaPreciosModel>.from(state.currentList);
    updatedList.add(listaPrecio);
    emit(state.copyWith(currentList: updatedList));
  }

  void removeListaPrecio(String nombre) {
    final updatedList = state.currentList.where((item) => item.nombre != nombre).toList();
    emit(state.copyWith(currentList: updatedList));
  }
}
