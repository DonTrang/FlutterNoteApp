import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;

  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEdited = false;
  bool _isPinned = false;

  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);

    final newText = text.replaceRange(
      start,
      end,
      '$prefix$selectedText$suffix',
    );
    _contentController.text = newText;
    final newSelectionEnd = end + prefix.length + suffix.length;
    _contentController.selection = TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: newSelectionEnd - suffix.length,
    );
  }

  void _insertBullet() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    final lines = text.split('\n');
    int charCount = 0;
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineStart = charCount;
      final lineEnd = charCount + line.length;
      if (selection.start >= lineStart && selection.start <= lineEnd) {
        final updatedLine = line.startsWith('- ')
            ? line
            : '- ${line.trimLeft()}';
        lines[i] = updatedLine;
        break;
      }
      charCount = lineEnd + 1;
    }
    final newText = lines.join('\n');
    _contentController.text = newText;
  }

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _isPinned = widget.note!.isPinned;
    }
    _titleController.addListener(() => setState(() => _isEdited = true));
    _contentController.addListener(() => setState(() => _isEdited = true));
  }

  Future<void> _saveNote() async {
    try {
      final now = DateTime.now();
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      // Cho phép lưu ngay cả khi title hoặc content rỗng
      // Nếu cả hai đều rỗng, sử dụng giá trị mặc định
      final finalTitle = title.isEmpty ? 'Ghi chú không có tiêu đề' : title;
      final finalContent = content.isEmpty ? '' : content;

      if (widget.note == null) {
        // Tạo ghi chú mới
        final newNote = Note(
          title: finalTitle,
          content: finalContent,
          createdAt: now,
          updatedAt: now,
          isPinned: _isPinned,
        );
        await _dbHelper.createNote(newNote);
      } else {
        // Cập nhật ghi chú
        final updatedNote = widget.note!.copyWith(
          title: finalTitle,
          content: finalContent,
          isPinned: _isPinned,
          updatedAt: now,
        );
        await _dbHelper.updateNote(updatedNote);
      }

      if (mounted) {
        Navigator.pop(context, true); // Trả về true để báo đã lưu thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.note == null
                  ? 'Đã tạo ghi chú mới'
                  : 'Đã cập nhật ghi chú',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Xử lý lỗi và hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu ghi chú: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isEdited,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isEdited) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Lưu thay đổi?'),
              content: const Text('Bạn có muốn lưu các thay đổi không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Không lưu'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Lưu'),
                ),
              ],
            ),
          );
          if (shouldSave == true) {
            await _saveNote();
          } else {
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.note == null ? 'Ghi chú mới' : 'Chỉnh sửa ghi chú',
          ),
          actions: [
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              tooltip: _isPinned ? 'Bỏ ghim' : 'Ghim ghi chú',
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _isEdited = true;
                });
              },
            ),
            // Luôn hiển thị nút lưu khi có thay đổi hoặc là ghi chú mới
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Lưu ghi chú',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề',
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold),
                    tooltip: 'In đậm',
                    onPressed: () => _wrapSelection('**', '**'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic),
                    tooltip: 'In nghiêng',
                    onPressed: () => _wrapSelection('*', '*'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted),
                    tooltip: 'Gạch đầu dòng',
                    onPressed: _insertBullet,
                  ),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Nội dung ghi chú...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
