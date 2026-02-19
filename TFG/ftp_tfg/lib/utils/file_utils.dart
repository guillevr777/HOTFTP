class FileUtils {
  static const imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'tiff',
  };

  static bool isImage(String fileName) {
    if (!fileName.contains('.')) return false;
    final ext = fileName.split('.').last.toLowerCase();
    return imageExtensions.contains(ext);
  }

  static bool isVideo(String fileName) {
    if (!fileName.contains('.')) return false;
    final ext = fileName.split('.').last.toLowerCase();
    return ext == 'mp4' || ext == 'mov' || ext == 'avi' || ext == 'mkv';
  }
}
