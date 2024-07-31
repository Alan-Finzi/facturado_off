import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'thema_state.dart';

class ThemaCubit extends Cubit<ThemaState> {
  ThemaCubit({
    final isDark =false
}) : super(ThemaState(isDark: false));

  void changeThema(){
    emit( ThemaState(isDark: !state.isDark));
  }
}
