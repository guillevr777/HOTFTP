import '../entities/app_user.dart';
abstract class IObserveAuthStateUseCase {
  Stream<AppUser?> execute();
}





