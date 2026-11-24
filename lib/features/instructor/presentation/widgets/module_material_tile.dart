import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';
import 'package:url_launcher/url_launcher.dart';

IconData materialKindIcon(MaterialKind kind) {
  switch (kind) {
    case MaterialKind.file:
      return Icons.insert_drive_file_outlined;
    case MaterialKind.link:
      return Icons.link_rounded;
    case MaterialKind.text:
      return Icons.sticky_note_2_outlined;
  }
}

/// Membuka materi: link/file di aplikasi eksternal, catatan di bottom sheet.
Future<void> openModuleMaterial(
  BuildContext context,
  ModuleMaterial material,
) async {
  final messenger = ScaffoldMessenger.of(context);

  if (material.kind == MaterialKind.text) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              material.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              material.content.isEmpty ? '-' : material.content,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
    return;
  }

  final uri = Uri.tryParse(material.url);
  var opened = false;
  if (uri != null && uri.hasScheme) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Materi tidak dapat dibuka. Periksa tautan atau koneksi Anda.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ModuleMaterialTile extends StatelessWidget {
  final ModuleMaterial material;
  final VoidCallback? onDelete;

  const ModuleMaterialTile({super.key, required this.material, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (material.kind) {
      MaterialKind.file =>
        material.fileName.isNotEmpty ? material.fileName : 'File',
      MaterialKind.link => material.url,
      MaterialKind.text => 'Catatan',
    };

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: () => openModuleMaterial(context, material),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.mintBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          materialKindIcon(material.kind),
          size: 20,
          color: AppColors.mintDark,
        ),
      ),
      title: Text(
        material.title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: onDelete == null
          ? const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.primary,
            )
          : IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.red.shade700,
              ),
              tooltip: 'Hapus materi',
              onPressed: onDelete,
            ),
    );
  }
}
