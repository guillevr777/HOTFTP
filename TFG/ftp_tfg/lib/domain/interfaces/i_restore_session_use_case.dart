import '../entities/app_user.dart';
abstract class IRestoreSessionUseCase {
  Future<AppUser?> execute();
}





