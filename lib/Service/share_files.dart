// lib/Service/share_files.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class ShareFilesPage extends StatefulWidget {
  final Locale locale;
  ShareFilesPage({required this.locale});

  @override
  _ShareFilesPageState createState() => _ShareFilesPageState();
}

class _ShareFilesPageState extends State<ShareFilesPage> {
  List<File> _allFiles = [];
  Set<File> _selected = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    if (dir == null) return;

    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.gz')).toList();

    setState(() {
      _allFiles = files;
      _selected.clear();
      _selectAll = false;
    });
  }

  void _toggleSelectAll(bool? v) {
    setState(() {
      _selectAll = v ?? false;
      _selected = _selectAll ? Set.from(_allFiles) : {};
    });
  }

  Future<void> _share() async {
    if (_selected.isEmpty) return;
    final lang = widget.locale.languageCode;

    final xfiles = _selected.map((f) => XFile(f.path)).toList();
    await Share.shareXFiles(
      xfiles,
      text:
          lang == 'en' ? 'Here are my pending data files.' : 'Aquí están mis archivos pendientes.',
    );

    final keep = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang == 'en' ? 'Delete after sharing?' : '¿Borrar después de compartir?'),
        content: Text(lang == 'en'
            ? 'Do you want to delete the shared files from local storage?'
            : '¿Deseas eliminar los archivos compartidos del almacenamiento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang == 'en' ? 'Keep' : 'Conservar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(lang == 'en' ? 'Delete' : 'Borrar')),
        ],
      ),
    );

    if (keep == true) {
      for (var f in _selected) {
        try {
          await f.delete();
        } catch (_) {}
      }
      await _loadFiles();
    }
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final lang = widget.locale.languageCode;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang == 'en' ? 'Delete files?' : '¿Borrar archivos?'),
        content: Text(lang == 'en'
            ? 'Permanently delete ${_selected.length} files?'
            : '¿Eliminar permanentemente ${_selected.length} archivos?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(lang == 'en' ? 'Cancel' : 'Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(lang == 'en' ? 'Delete' : 'Borrar')),
        ],
      ),
    );

    if (confirm == true) {
      for (var f in _selected) {
        try {
          await f.delete();
        } catch (_) {}
      }
      await _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en'
            ? 'Pending Files (${_allFiles.length})'
            : 'Archivos pendientes (${_allFiles.length})'),
      ),
      body: Column(
        children: [
          CheckboxListTile(
            title: Text(lang == 'en' ? 'Select All' : 'Seleccionar todo'),
            value: _selectAll,
            onChanged: _toggleSelectAll,
          ),
          Expanded(
            child: ListView(
              children: _allFiles.map((f) {
                final name = f.path.split('/').last;
                return CheckboxListTile(
                  title: Text(name),
                  value: _selected.contains(f),
                  onChanged: (v) {
                    setState(() {
                      if (v == true)
                        _selected.add(f);
                      else
                        _selected.remove(f);
                      _selectAll = _selected.length == _allFiles.length;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text(lang == 'en' ? 'Share' : 'Compartir'),
                  onPressed: _selected.isEmpty ? null : _share,
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text(lang == 'en' ? 'Delete' : 'Borrar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _selected.isEmpty ? null : _deleteSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
