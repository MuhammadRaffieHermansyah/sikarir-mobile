import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';
import 'package:sikarir/features/instructor/presentation/widgets/module_material_tile.dart';

/// Daftar modul & materi dikelompokkan per pertemuan.
///
/// Mode baca (peserta): hanya pertemuan yang punya modul.
/// Mode edit (instruktur): semua pertemuan 1..[totalSessions] dengan aksi tambah/hapus.
class MeetingModuleList extends StatelessWidget {
  final List<ClassModule> modules;
  final int totalSessions;
  final bool editable;
  final void Function(int meetingNumber)? onAddModule;
  final void Function(ClassModule module)? onAddMaterial;
  final void Function(ClassModule module)? onDeleteModule;
  final void Function(ClassModule module, ModuleMaterial material)?
  onDeleteMaterial;

  const MeetingModuleList({
    super.key,
    required this.modules,
    this.totalSessions = 0,
    this.editable = false,
    this.onAddModule,
    this.onAddMaterial,
    this.onDeleteModule,
    this.onDeleteMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final byMeeting = <int, List<ClassModule>>{};
    for (final m in modules) {
      byMeeting.putIfAbsent(m.meetingNumber, () => []).add(m);
    }

    final meetings = editable
        ? List<int>.generate(
            _max(totalSessions, byMeeting.keys.fold(0, _max)),
            (i) => i + 1,
          )
        : (byMeeting.keys.toList()..sort());

    return Column(
      children: [
        for (final n in meetings)
          _MeetingSection(
            meetingNumber: n,
            modules: byMeeting[n] ?? const [],
            editable: editable,
            initiallyExpanded: !editable || (byMeeting[n]?.isNotEmpty ?? false),
            onAddModule: onAddModule,
            onAddMaterial: onAddMaterial,
            onDeleteModule: onDeleteModule,
            onDeleteMaterial: onDeleteMaterial,
          ),
      ],
    );
  }

  static int _max(int a, int b) => a > b ? a : b;
}

class _MeetingSection extends StatelessWidget {
  final int meetingNumber;
  final List<ClassModule> modules;
  final bool editable;
  final bool initiallyExpanded;
  final void Function(int meetingNumber)? onAddModule;
  final void Function(ClassModule module)? onAddMaterial;
  final void Function(ClassModule module)? onDeleteModule;
  final void Function(ClassModule module, ModuleMaterial material)?
  onDeleteMaterial;

  const _MeetingSection({
    required this.meetingNumber,
    required this.modules,
    required this.editable,
    required this.initiallyExpanded,
    this.onAddModule,
    this.onAddMaterial,
    this.onDeleteModule,
    this.onDeleteMaterial,
  });

  @override
  Widget build(BuildContext context) {
    final hasModules = modules.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('meeting-$meetingNumber'),
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasModules ? AppColors.mint : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$meetingNumber',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: hasModules ? AppColors.mintDark : AppColors.textMuted,
              ),
            ),
          ),
          title: Text(
            'Pertemuan $meetingNumber',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hasModules ? '${modules.length} modul' : 'Belum ada modul',
              style: TextStyle(
                fontSize: 11.5,
                color: hasModules
                    ? AppColors.mintDark
                    : AppColors.textSecondary,
                fontWeight: hasModules ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          children: [
            for (final module in modules)
              _ModuleCard(
                module: module,
                editable: editable,
                onAddMaterial: onAddMaterial,
                onDeleteModule: onDeleteModule,
                onDeleteMaterial: onDeleteMaterial,
              ),
            if (editable)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => onAddModule?.call(meetingNumber),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Tambah Modul',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.mintBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ClassModule module;
  final bool editable;
  final void Function(ClassModule module)? onAddMaterial;
  final void Function(ClassModule module)? onDeleteModule;
  final void Function(ClassModule module, ModuleMaterial material)?
  onDeleteMaterial;

  const _ModuleCard({
    required this.module,
    required this.editable,
    this.onAddMaterial,
    this.onDeleteModule,
    this.onDeleteMaterial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (editable)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Hapus modul',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  onPressed: () => onDeleteModule?.call(module),
                ),
            ],
          ),
          if (module.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                module.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          if (module.materials.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Belum ada materi.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            )
          else
            for (final material in module.materials)
              ModuleMaterialTile(
                material: material,
                onDelete: editable
                    ? () => onDeleteMaterial?.call(module, material)
                    : null,
              ),
          if (editable)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton.icon(
                onPressed: () => onAddMaterial?.call(module),
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: const Text(
                  'Tambah Materi',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
