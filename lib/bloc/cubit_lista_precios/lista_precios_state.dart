import 'package:equatable/equatable.dart';
import '../../models/lista_precio_model.dart';
import '../../models/productos_maestro.dart';


class ListaPreciosState extends Equatable {
  final List<Lista> currentList;

  ListaPreciosState({required this.currentList});

  ListaPreciosState copyWith({List<Lista>? currentList}) {
    return ListaPreciosState(
      currentList: currentList ?? this.currentList,
    );
  }

  @override
  List<Object?> get props => [currentList];
}