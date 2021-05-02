import 'package:town_game/core/current_user.dart';
import 'current_game.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setup() {
  getIt.registerSingleton(CurrentGame());
  getIt.registerSingleton(CurrentUser());
}
