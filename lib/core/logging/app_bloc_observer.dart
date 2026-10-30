import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_log.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLog.bloc('event ${bloc.runtimeType} $event');
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    AppLog.bloc('${bloc.runtimeType} ${transition.event} → ${transition.nextState}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is Bloc) return;
    AppLog.bloc('change ${bloc.runtimeType}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLog.bloc('error ${bloc.runtimeType} $error');
    super.onError(bloc, error, stackTrace);
  }
}
