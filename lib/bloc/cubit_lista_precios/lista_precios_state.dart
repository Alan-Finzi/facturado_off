import 'package:equatable/equatable.dart';
import '../../models/lista_precio_model.dart';


class ListaPreciosState extends Equatable {
  final List<ListaPreciosModel> currentList;

  ListaPreciosState({required this.currentList});

  ListaPreciosState copyWith({List<ListaPreciosModel>? currentList}) {
    return ListaPreciosState(
      currentList: currentList ?? this.currentList,
    );
  }

  @override
  List<Object?> get props => [currentList];
}