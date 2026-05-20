import 'package:flutter/material.dart';

import '../../../domain/entities/local_file.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/file_utils.dart';

class LocalBrowserFileGridTile extends StatelessWidget {
  final LocalFile file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const LocalBrowserFileGridTile({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _LocalBrowserGridPreview(file: file)),
                  const SizedBox(height: 6),
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.isDirectory
                              ? 'Carpeta'
                              : FileUtils.fileCategory(file.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceMuted,
                          ),
                        ),
                      ),
                      if (!file.isDirectory) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              file.extension?.isEmpty ?? true
                                  ? 'FILE'
                                  : file.extension!.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: FileUtils.fileColor(
                                  file.name,
                                  isDirectory: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.lastModified == null
                        ? 'Sin fecha'
                        : '${file.lastModified!.day.toString().padLeft(2, '0')}/${file.lastModified!.month.toString().padLeft(2, '0')}/${file.lastModified!.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) const _SelectionOverlay(),
          ],
        ),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.22),
          border: Border.all(color: AppTheme.primary, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.check_circle, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}

class _LocalBrowserGridPreview extends StatelessWidget {
  final LocalFile file;

  const _LocalBrowserGridPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final icon = FileUtils.fileIcon(file.name, isDirectory: file.isDirectory);
    final color = FileUtils.fileColor(file.name, isDirectory: file.isDirectory);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            AppTheme.surfaceVariant.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(icon, size: file.isDirectory ? 58 : 52, color: color),
      ),
    );
  }
}
