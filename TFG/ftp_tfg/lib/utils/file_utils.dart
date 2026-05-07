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

  static const videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  };

  static const documentExtensions = {
    'pdf',
    'doc',
    'docx',
    'txt',
    'md',
    'rtf',
    'odt',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'xml',
    'json',
    'csv',
  };

  static const archiveExtensions = {
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
  };

  static String extensionOf(String fileName) {
    if (!fileName.contains('.')) return '';
    return fileName.split('.').last.toLowerCase();
  }

  static bool isImage(String fileName) {
    return imageExtensions.contains(extensionOf(fileName));
  }

  static bool isVideo(String fileName) {
    return videoExtensions.contains(extensionOf(fileName));
  }

  static bool isDocument(String fileName) {
    return documentExtensions.contains(extensionOf(fileName));
  }

  static bool isArchive(String fileName) {
    return archiveExtensions.contains(extensionOf(fileName));
  }

  static String fileCategory(String fileName, {bool isDirectory = false}) {
    if (isDirectory) return 'Carpeta';
    if (isImage(fileName)) return 'Imagen';
    if (isVideo(fileName)) return 'Video';
    if (isDocument(fileName)) return 'Documento';
    if (isArchive(fileName)) return 'Archivo comprimido';
    return 'Otro';
  }
}
