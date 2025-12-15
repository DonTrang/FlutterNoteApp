import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Note> _deletedNotes = [];
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
  }

  Future<void> _loadDeletedNotes() async {
    final notes = await _dbHelper.getDeletedNotes();
    setState(() {
      _deletedNotes = notes;
      _selectedIds.clear();
    });
  }

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(Note note) {
    setState(() {
      if (note.id == null) return;
      if (_selectedIds.contains(note.id)) {
        _selectedIds.remove(note.id);
      } else {
        _selectedIds.add(note.id!);
      }
    });
  }

  Future<void> _restoreSelected() async {
    await _dbHelper.restoreMany(_selectedIds.toList());
    await _loadDeletedNotes();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã khôi phục ghi chú')));
    }
  }

  Future<void> _deleteSelectedPermanently() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa vĩnh viễn'),
        content: const Text(
          'Các ghi chú này sẽ bị xóa vĩnh viễn và không thể khôi phục. Bạn chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xóa vĩnh viễn',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in _selectedIds) {
        await _dbHelper.deleteNotePermanently(id);
      }
      await _loadDeletedNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa vĩnh viễn các ghi chú')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.restore_from_trash),
              tooltip: 'Khôi phục',
              onPressed: _restoreSelected,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Xóa vĩnh viễn',
              onPressed: _deleteSelectedPermanently,
            ),
          ],
        ],
      ),
      body: _deletedNotes.isEmpty
          ? const Center(child: Text('Thùng rác trống'))
          : RefreshIndicator(
              onRefresh: _loadDeletedNotes,
              child: ListView.builder(
                itemCount: _deletedNotes.length,
                itemBuilder: (context, index) {
                  final note = _deletedNotes[index];
                  final selected =
                      note.id != null && _selectedIds.contains(note.id);
                  return NoteCard(
                    note: note,
                    onTap: () => _toggleSelection(note),
                    onDelete: () {}, // Xóa vĩnh viễn xử lý ở AppBar
                    isSelectionMode: _isSelectionMode,
                    isSelected: selected,
                    onLongPress: () => _toggleSelection(note),
                    showPinIcon: false,
                    showDeleteIcon:
                        false, // tránh nhầm lẫn: không hiện icon thùng rác nhỏ
                  );
                },
              ),
            ),
    );
  }
}
