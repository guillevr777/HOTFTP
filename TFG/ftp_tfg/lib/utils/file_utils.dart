import 'package:flutter/material.dart';

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

  static IconData fileIcon(String fileName, {bool isDirectory = false}) {
    if (isDirectory) return Icons.folder;
    if (isImage(fileName)) return Icons.image_outlined;
    if (isVideo(fileName)) return Icons.videocam_outlined;

    final ext = extensionOf(fileName);
    return switch (ext) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' || 'odt' || 'rtf' => Icons.description_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'txt' || 'md' => Icons.text_snippet_outlined,
      'json' || 'xml' => Icons.data_object_outlined,
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  static Color fileColor(String fileName, {bool isDirectory = false}) {
    if (isDirectory) return const Color(0xFF00B4D8);
    if (isImage(fileName)) return const Color(0xFF3FB950);
    if (isVideo(fileName)) return const Color(0xFFF2C94C);

    final ext = extensionOf(fileName);
    return switch (ext) {
      'pdf' => const Color(0xFFF85149),
      'doc' || 'docx' || 'odt' || 'rtf' => const Color(0xFF5B8DEF),
      'xls' || 'xlsx' || 'csv' => const Color(0xFF2EA043),
      'ppt' || 'pptx' => const Color(0xFFFF9D00),
      'txt' || 'md' => const Color(0xFF8B949E),
      'json' || 'xml' => const Color(0xFF9C6ADE),
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => const Color(0xFFDA7A1F),
      _ => const Color(0xFF8B949E),
    };
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const suffixes = ['KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var index = -1;
    do {
      value /= 1024;
      index++;
    } while (value >= 1024 && index < suffixes.length - 1);
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${suffixes[index]}';
  }
}
