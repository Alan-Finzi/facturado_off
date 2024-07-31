part of 'status_apis_cubit.dart';

 class StatusApisState extends Equatable {

   final bool isConnected;
   const StatusApisState({required this.isConnected});

  @override
  // TODO: implement props
  List<Object?> get props => [isConnected];
}

