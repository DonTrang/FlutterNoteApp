import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _dbHelper.getAllNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
    });
  }

  void _searchNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) {
          return note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _deleteNote(int id) async {
    await _dbHelper.deleteNote(id);
    await _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa ghi chú')));
    }
  }

  Future<void> _deleteSelectedNotes() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhiều ghi chú'),
        content: Text(
          'Bạn có chắc chắn muốn chuyển ${_selectedIds.length} ghi chú vào thùng rác?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteMany(_selectedIds.toList());
      _selectedIds.clear();
      await _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chuyển vào thùng rác')),
        );
      }
    }
  }

  void _toggleSelection(Note note) {
    if (note.id == null) return;
    setState(() {
      if (_selectedIds.contains(note.id)) {
        _selectedIds.remove(note.id);
      } else {
        _selectedIds.add(note.id!);
      }
    });
  }

  Future<void> _togglePin(Note note) async {
    await _dbHelper.togglePin(note);
    await _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm ghi chú...',
                  border: InputBorder.none,
                ),
                onChanged: _searchNotes,
              )
            : const Text('Ghi Chú Của Tôi'),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Xóa các ghi chú đã chọn',
              onPressed: _deleteSelectedNotes,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Thoát chế độ chọn',
              onPressed: () {
                setState(() => _selectedIds.clear());
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filteredNotes = _notes;
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Thùng rác',
              onPressed: () async {
                await Navigator.pushNamed(context, '/trash');
                _loadNotes();
              },
            ),
          ],
        ],
        elevation: 0,
      ),
      body: _filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching
                        ? 'Không tìm thấy ghi chú'
                        : 'Chưa có ghi chú nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: ListView.builder(
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  final note = _filteredNotes[index];
                  final selected =
                      note.id != null && _selectedIds.contains(note.id);
                  return NoteCard(
                    note: note,
                    isSelectionMode: _isSelectionMode,
                    isSelected: selected,
                    onTap: () async {
                      if (_isSelectionMode) {
                        _toggleSelection(note);
                      } else {
                        // Quay lại hành vi cũ: nhấn để mở màn hình sửa trực tiếp
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteDetailScreen(note: note),
                          ),
                        );
                        if (result == true) {
                          _loadNotes();
                        }
                      }
                    },
                    onLongPress: () => _toggleSelection(note),
                    onTogglePin: () => _togglePin(note),
                    onDelete: () => _deleteNote(note.id!),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteDetailScreen()),
          );
          // Chỉ reload nếu đã lưu thành công
          if (result == true) {
            _loadNotes();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
