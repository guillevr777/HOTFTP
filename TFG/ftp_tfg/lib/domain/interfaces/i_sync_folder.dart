abstract class ISyncFolder {
  Future<void> call(String local, String remote);
}
  