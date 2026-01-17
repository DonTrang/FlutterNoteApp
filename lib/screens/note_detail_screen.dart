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
  bool _isPreview = false;

  int _backgroundColor = 0xFFFFFFFF;

  // Color options
  final List<Color> _colorOptions = [
    Colors.white,
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.yellow.shade50,
    Colors.orange.shade50,
    Colors.pink.shade50,
    Colors.purple.shade50,
    Colors.red.shade50,
    Colors.cyan.shade50,
    Colors.teal.shade50,
    Colors.indigo.shade50,
    Colors.amber.shade50,
  ];

  // ================= Undo / Redo =================
  final List<String> _titleHistory = [];
  int _titleHistoryIndex = -1;

  final List<String> _contentHistory = [];
  int _contentHistoryIndex = -1;

  void _saveTitleState() {
    final text = _titleController.text;
    if (_titleHistoryIndex >= 0 &&
        _titleHistoryIndex < _titleHistory.length &&
        _titleHistory[_titleHistoryIndex] == text)
      return;

    if (_titleHistoryIndex < _titleHistory.length - 1) {
      _titleHistory.removeRange(_titleHistoryIndex + 1, _titleHistory.length);
    }

    _titleHistory.add(text);
    _titleHistoryIndex = _titleHistory.length - 1;
  }

  void _saveContentState() {
    final text = _contentController.text;
    if (_contentHistoryIndex >= 0 &&
        _contentHistoryIndex < _contentHistory.length &&
        _contentHistory[_contentHistoryIndex] == text)
      return;

    if (_contentHistoryIndex < _contentHistory.length - 1) {
      _contentHistory.removeRange(
        _contentHistoryIndex + 1,
        _contentHistory.length,
      );
    }

    _contentHistory.add(text);
    _contentHistoryIndex = _contentHistory.length - 1;
  }

  void _undoTitle() {
    if (_titleHistoryIndex > 0) {
      _titleHistoryIndex--;
      _titleController.text = _titleHistory[_titleHistoryIndex];
      _titleController.selection = TextSelection.collapsed(
        offset: _titleController.text.length,
      );
    }
  }

  void _redoTitle() {
    if (_titleHistoryIndex < _titleHistory.length - 1) {
      _titleHistoryIndex++;
      _titleController.text = _titleHistory[_titleHistoryIndex];
      _titleController.selection = TextSelection.collapsed(
        offset: _titleController.text.length,
      );
    }
  }

  void _undoContent() {
    if (_contentHistoryIndex > 0) {
      _contentHistoryIndex--;
      _contentController.text = _contentHistory[_contentHistoryIndex];
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    }
  }

  void _redoContent() {
    if (_contentHistoryIndex < _contentHistory.length - 1) {
      _contentHistoryIndex++;
      _contentController.text = _contentHistory[_contentHistoryIndex];
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    }
  }

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _isPinned = widget.note!.isPinned;
      _backgroundColor = widget.note!.backgroundColor;
    }

    _titleController.addListener(() {
      _isEdited = true;
      _saveTitleState();
    });

    _contentController.addListener(() {
      _isEdited = true;
      _saveContentState();
    });
  }

  // ================= Word / Char count =================
  int _getWordCount() {
    final text = '${_titleController.text} ${_contentController.text}';
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  int _getCharacterCount() {
    return '${_titleController.text} ${_contentController.text}'.length;
  }

  // ================= Color picker =================
  Future<void> _showColorPicker() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn màu nền'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((color) {
            final isSelected = _backgroundColor == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _backgroundColor = color.value;
                  _isEdited = true;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ================= Save =================
  Future<void> _saveNote() async {
    final now = DateTime.now();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final finalTitle = title.isEmpty ? 'Ghi chú không có tiêu đề' : title;

    if (widget.note == null) {
      await _dbHelper.createNote(
        Note(
          title: finalTitle,
          content: content,
          createdAt: now,
          updatedAt: now,
          isPinned: _isPinned,
          backgroundColor: _backgroundColor,
        ),
      );
    } else {
      await _dbHelper.updateNote(
        widget.note!.copyWith(
          title: finalTitle,
          content: content,
          isPinned: _isPinned,
          updatedAt: now,
          backgroundColor: _backgroundColor,
        ),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  // ================= Text formatting =================
  void _wrapSelection(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    final start = selection.start;
    final end = selection.end;
    final selectedText = start != end ? text.substring(start, end) : '';
    final newText = text.replaceRange(
      start,
      end,
      '$prefix$selectedText$suffix',
    );

    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: start + prefix.length + selectedText.length,
    );
    _isEdited = true;
  }

  void _insertBullet() => _insertPrefix('- ');
  void _insertNumbered() => _insertPrefix('1. ');

  void _insertPrefix(String prefix) {
    final selection = _contentController.selection;
    if (!selection.isValid) return;

    _contentController.text = _contentController.text.replaceRange(
      selection.start,
      selection.start,
      prefix,
    );
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + prefix.length,
    );
    _isEdited = true;
  }

  // ================= Markdown parser =================
  List<TextSpan> _parseInline(String text) {
    final List<TextSpan> spans = [];
    final regex = RegExp(r'(\*\*.+?\*\*|\*.+?\*|~~.+?~~)');
    int index = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: text.substring(index, match.start)));
      }
      final m = match.group(0)!;

      if (m.startsWith('**')) {
        spans.add(
          TextSpan(
            text: m.substring(2, m.length - 2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (m.startsWith('*')) {
        spans.add(
          TextSpan(
            text: m.substring(1, m.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (m.startsWith('~~')) {
        spans.add(
          TextSpan(
            text: m.substring(2, m.length - 2),
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
        );
      }
      index = match.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }
    return spans;
  }

  List<TextSpan> _buildContentSpans(String content) {
    final List<TextSpan> spans = [];
    for (final line in content.split('\n')) {
      if (line.startsWith('- ')) {
        spans.add(
          const TextSpan(
            text: '• ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
        spans.addAll(_parseInline(line.substring(2)));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\.\s').firstMatch(line)!;
        spans.add(
          TextSpan(
            text: '${match.group(1)}. ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
        spans.addAll(_parseInline(line.substring(match.end)));
      } else {
        spans.addAll(_parseInline(line));
      }
      spans.add(const TextSpan(text: '\n'));
    }
    return spans;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isEdited) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Lưu thay đổi?'),
              content: const Text('Bạn có muốn lưu ghi chú không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Không'),
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
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(_backgroundColor),
        appBar: AppBar(
          title: Text(
            widget.note == null ? 'Ghi chú mới' : 'Chỉnh sửa ghi chú',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.color_lens),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () => setState(() => _isPinned = !_isPinned),
            ),
            IconButton(
              icon: Icon(_isPreview ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _isPreview = !_isPreview),
            ),
            IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _isPreview ? _buildPreview() : _buildEditor(),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        // Title field + Undo/Redo
        Row(
          children: [
            Expanded(
              child: TextField(
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
            ),
            IconButton(icon: const Icon(Icons.undo), onPressed: _undoTitle),
            IconButton(icon: const Icon(Icons.redo), onPressed: _redoTitle),
          ],
        ),
        const Divider(),

        // Formatting buttons
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: () => _wrapSelection('**', '**'),
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: () => _wrapSelection('*', '*'),
            ),
            IconButton(
              icon: const Icon(Icons.strikethrough_s),
              onPressed: () => _wrapSelection('~~', '~~'),
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: _insertBullet,
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: _insertNumbered,
            ),
            IconButton(icon: const Icon(Icons.undo), onPressed: _undoContent),
            IconButton(icon: const Icon(Icons.redo), onPressed: _redoContent),
            const Spacer(),
            Text(
              '${_getWordCount()} từ • ${_getCharacterCount()} ký tự',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),

        // Content field
        Expanded(
          child: TextField(
            controller: _contentController,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: 'Nội dung ghi chú...',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: _buildContentSpans(_contentController.text),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_getWordCount()} từ • ${_getCharacterCount()} ký tự',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
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
