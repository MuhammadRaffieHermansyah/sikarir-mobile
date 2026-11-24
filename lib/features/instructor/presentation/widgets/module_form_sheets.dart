import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sikarir/core/constants/app_theme.dart';
import 'package:sikarir/features/instructor/data/models/class_module_model.dart';

class ModuleInput {
  final String title;
  final String description;
  final int meetingNumber;
  const ModuleInput(this.title, this.description, this.meetingNumber);
}

class MaterialInput {
  final String title;
  final MaterialKind kind;
  final String? url;
  final String? content;
  final String? filePath;
  const MaterialInput({
    required this.title,
    required this.kind,
    this.url,
    this.content,
    this.filePath,
  });
}

Future<ModuleInput?> showModuleFormSheet(
  BuildContext context, {
  required int meetingCount,
  required int initialMeeting,
}) {
  return showModalBottomSheet<ModuleInput>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ModuleForm(meetingCount: meetingCount, initialMeeting: initialMeeting),
  );
}

Future<MaterialInput?> showMaterialFormSheet(BuildContext context) {
  return showModalBottomSheet<MaterialInput>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _MaterialForm(),
  );
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetFrame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
);

class _ModuleForm extends StatefulWidget {
  final int meetingCount;
  final int initialMeeting;
  const _ModuleForm({required this.meetingCount, required this.initialMeeting});

  @override
  State<_ModuleForm> createState() => _ModuleFormState();
}

class _ModuleFormState extends State<_ModuleForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late int _meeting = widget.initialMeeting;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ModuleInput(_title.text.trim(), _description.text.trim(), _meeting),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Tambah Modul',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _meeting,
                decoration: _decoration('Pertemuan'),
                items: [
                  for (var i = 1; i <= widget.meetingCount; i++)
                    DropdownMenuItem(value: i, child: Text('Pertemuan $i')),
                ],
                onChanged: (v) => setState(() => _meeting = v ?? _meeting),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: _decoration('Judul modul'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul modul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: _decoration('Deskripsi (opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Simpan Modul'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaterialForm extends StatefulWidget {
  const _MaterialForm();

  @override
  State<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends State<_MaterialForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _content = TextEditingController();
  MaterialKind _kind = MaterialKind.file;
  PlatformFile? _file;
  String? _fileError;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'zip',
        'mp4',
        'jpg',
        'jpeg',
        'png',
      ],
    );
    if (picked == null || picked.path == null) return;
    setState(() {
      _file = picked;
      _fileError = null;
      if (_title.text.trim().isEmpty) _title.text = picked.name;
    });
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (_kind == MaterialKind.file && _file == null) {
      setState(() => _fileError = 'Pilih file terlebih dahulu');
      return;
    }
    if (!valid) return;
    Navigator.pop(
      context,
      MaterialInput(
        title: _title.text.trim(),
        kind: _kind,
        url: _kind == MaterialKind.link ? _url.text.trim() : null,
        content: _kind == MaterialKind.text ? _content.text.trim() : null,
        filePath: _kind == MaterialKind.file ? _file?.path : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Tambah Materi',
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<MaterialKind>(
            segments: [
              for (final k in MaterialKind.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: _decoration('Judul materi'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Judul materi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              if (_kind == MaterialKind.file) ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _file?.name ?? 'Pilih file (PDF, PPT, DOC, video, dll.)',
                  ),
                ),
                if (_fileError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _fileError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
              if (_kind == MaterialKind.link)
                TextFormField(
                  controller: _url,
                  decoration: _decoration('Link (YouTube, Drive, dll.)'),
                  keyboardType: TextInputType.url,
                  validator: (v) {
                    final uri = Uri.tryParse((v ?? '').trim());
                    final ok =
                        uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https') &&
                        uri.host.isNotEmpty;
                    return ok
                        ? null
                        : 'Masukkan link yang valid (diawali http/https)';
                  },
                ),
              if (_kind == MaterialKind.text)
                TextFormField(
                  controller: _content,
                  decoration: _decoration('Isi catatan'),
                  maxLines: 6,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Isi catatan wajib diisi'
                      : null,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Simpan Materi'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
