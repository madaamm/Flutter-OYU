import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class ModeratorAudioBooksScreen extends StatefulWidget {
  const ModeratorAudioBooksScreen({super.key});

  @override
  State<ModeratorAudioBooksScreen> createState() => _ModeratorAudioBooksScreenState();
}

class _ModeratorAudioBooksScreenState extends State<ModeratorAudioBooksScreen> {
  static const Color purple = Color(0xFF5A008B);
  static const List<String> genres = [
    'General',
    'Romance',
    'Comedy',
    'Horror',
    'Drama',
    'Fantasy',
    'History',
    'Adventure',
    'Poetry',
    'Kids',
  ];
  static const List<String> levels = ['A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  final String apiUrl = '${AuthService.baseUrl}/admin/audio-books';
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> audioBooks = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchAudioBooks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final token = await AuthService().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Login required');
    }

    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<void> fetchAudioBooks() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          audioBooks = decoded is List
              ? decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
        });
      } else {
        showMessage('Failed to load audio books: ${response.statusCode}');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _inferFormat(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.m4a')) return 'm4a';
    if (lower.endsWith('.wav')) return 'wav';
    if (lower.endsWith('.ogg')) return 'ogg';
    if (lower.endsWith('.flac')) return 'flac';
    if (lower.endsWith('.aac')) return 'aac';
    return 'mp3';
  }

  Future<void> addAudioBook({
    PlatformFile? file,
    required String title,
    required String author,
    required String genre,
    required String level,
    String? externalUrl,
  }) async {
    setState(() => loading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll(await _authHeaders());

      if (file != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      }

      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['genre'] = genre;
      request.fields['level'] = level;
      request.fields['format'] = file != null ? _inferFormat(file.name) : 'mp3';

      if (externalUrl != null && externalUrl.trim().isNotEmpty) {
        request.fields['externalUrl'] = externalUrl.trim();
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchAudioBooks();
        final existsInList = audioBooks.any(
          (book) => '${book['title'] ?? ''}'.trim().toLowerCase() == title.trim().toLowerCase(),
        );

        if (existsInList) {
          showMessage('Audio book added successfully');
        } else {
          showDetailedError(
            action: 'Upload looked successful, but the book was not found after refresh',
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      } else {
        showDetailedError(
          action: 'Upload failed',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateAudioBookById({
    required String id,
    required String title,
    required String author,
    required String genre,
    required String level,
    String? externalUrl,
  }) async {
    setState(() => loading = true);

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/$id'),
        headers: await _authHeaders(json: true),
        body: jsonEncode({
          'title': title,
          'author': author,
          'genre': genre,
          'level': level,
          'externalUrl': externalUrl?.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchAudioBooks();
        showMessage('Audio book updated successfully');
      } else {
        showDetailedError(
          action: 'Update failed',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteAudioBookById(String id) async {
    setState(() => loading = true);
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchAudioBooks();
        showMessage('Audio book deleted successfully');
      } else {
        showDetailedError(
          action: 'Delete failed',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      showMessage('Error: ' + e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void showDetailedError({
    required String action,
    required int statusCode,
    required String body,
  }) {
    var message = body.trim();

    if (message.isEmpty) {
      message = 'Empty response body';
    } else {
      try {
        final decoded = jsonDecode(message);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
    }

    if (message.length > 220) {
      message = '${message.substring(0, 220)}...';
    }

    showMessage('$action ($statusCode): $message');
  }

  List<Map<String, dynamic>> get filteredAudioBooks {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return audioBooks;

    return audioBooks.where((book) {
      final title = '${book['title'] ?? ''}'.toLowerCase();
      final author = '${book['author'] ?? ''}'.toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();
  }

  void openAddAudioBookSheet() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final externalUrlController = TextEditingController();
    PlatformFile? selectedFile;
    String? fileName;
    String selectedGenre = genres.first;
    String selectedLevel = levels.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottom = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(22, 22, 22, bottom + 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Add audio book',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    _Input(controller: titleController, hint: 'Audio book title'),
                    const SizedBox(height: 12),
                    _Input(controller: authorController, hint: 'Author'),
                    const SizedBox(height: 12),
                    _Input(
                      controller: externalUrlController,
                      hint: 'External audio URL (optional)',
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Genre',
                      value: selectedGenre,
                      items: genres,
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedGenre = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Level',
                      value: selectedLevel,
                      items: levels,
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedLevel = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['mp3', 'm4a', 'wav', 'ogg', 'flac', 'aac'],
                          withData: true,
                        );
                        if (picked == null) return;
                        selectedFile = picked.files.single;
                        fileName = selectedFile!.name;
                        setModalState(() {});
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F7F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.audiotrack_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName ?? 'Choose audio file (or use link above)',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final author = authorController.text.trim();
                          final externalUrl = externalUrlController.text.trim();

                          if (title.isEmpty || author.isEmpty) {
                            showMessage('Fill title and author');
                            return;
                          }

                          if (selectedFile == null && externalUrl.isEmpty) {
                            showMessage('Choose a file or enter an external audio URL');
                            return;
                          }

                          if (selectedFile != null && selectedFile!.bytes == null) {
                            showMessage('File bytes not found. Pick the file again.');
                            return;
                          }

                          Navigator.pop(context);
                          addAudioBook(
                            file: selectedFile,
                            title: title,
                            author: author,
                            genre: selectedGenre,
                            level: selectedLevel,
                            externalUrl: externalUrl,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Save audio book',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void openEditAudioBookSheet(Map<String, dynamic> book) {
    final id = '';
    final titleController = TextEditingController(text: '${book['title'] ?? ''}');
    final authorController = TextEditingController(text: '${book['author'] ?? ''}');
    final externalUrlController = TextEditingController(text: '${book['externalUrl'] ?? ''}');
    final rawGenre =
        ('${book['genre'] ?? 'General'}'.trim().isEmpty ? 'General' : '${book['genre']}');
    final rawLevel = '${book['level'] ?? 'A0'}';
    String selectedGenre = genres.contains(rawGenre) ? rawGenre : genres.first;
    String selectedLevel = levels.contains(rawLevel) ? rawLevel : levels.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(22, 22, 22, bottom + 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Edit audio book',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    _Input(controller: titleController, hint: 'Audio book title'),
                    const SizedBox(height: 12),
                    _Input(controller: authorController, hint: 'Author'),
                    const SizedBox(height: 12),
                    _Input(
                      controller: externalUrlController,
                      hint: 'External audio URL (optional)',
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Genre',
                      value: selectedGenre,
                      items: genres,
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedGenre = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Level',
                      value: selectedLevel,
                      items: levels,
                      onChanged: (value) {
                        if (value != null) setModalState(() => selectedLevel = value);
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final author = authorController.text.trim();
                          if (title.isEmpty || author.isEmpty) {
                            showMessage('Fill all fields');
                            return;
                          }
                          Navigator.pop(context);
                          updateAudioBookById(
                            id: id,
                            title: title,
                            author: author,
                            genre: selectedGenre,
                            level: selectedLevel,
                            externalUrl: externalUrlController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Save changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredAudioBooks;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: openAddAudioBookSheet,
        backgroundColor: purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF555555)),
                  ),
                  const Expanded(
                    child: Text(
                      'Listening Admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: fetchAudioBooks,
                    icon: const Icon(Icons.refresh_rounded, size: 30, color: Color(0xFF555555)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEAEA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF666666)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Title, author...',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? const Center(
                          child: Text(
                            'No audio books yet. Tap + to upload one.',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: list
                                  .map(
                                    (book) => _AudioAdminCard(
                                      book: book,
                                      onEdit: () => openEditAudioBookSheet(book),
                                      onDelete: () async {
                                        final id = (book['id'] ?? '').toString();
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Delete audio book?'),
                                            content: Text('Delete ' + (book['title'] ?? 'this audio book').toString() + '?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true && id.isNotEmpty) {
                                          await deleteAudioBookById(id);
                                        }
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioAdminCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AudioAdminCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${book['title'] ?? 'Untitled'}';
    final author = '${book['author'] ?? 'Unknown'}';
    final genre = ('${book['genre'] ?? 'General'}'.trim().isEmpty)
        ? 'General'
        : '${book['genre']}';
    final level = '${book['level'] ?? 'A0'}';
    final hasExternalUrl = '${book['externalUrl'] ?? ''}'.trim().isNotEmpty;

    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 108,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1240),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 42),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 18, color: Color(0xFF5A008B)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onDelete,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFD64545)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF777777)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallAudioTag(label: genre),
              _SmallAudioTag(label: level),
              _SmallAudioTag(label: hasExternalUrl ? 'Link' : 'File'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallAudioTag extends StatelessWidget {
  final String label;
  const _SmallAudioTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5A008B),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem<T>(value: item, child: Text('$item')))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _Input({
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}










