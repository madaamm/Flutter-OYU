import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kazakh_learning_app/services/auth_service.dart';

class ModeratorBooksScreen extends StatefulWidget {
  const ModeratorBooksScreen({super.key});

  @override
  State<ModeratorBooksScreen> createState() => _ModeratorBooksScreenState();
}

class _ModeratorBooksScreenState extends State<ModeratorBooksScreen> {
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

  final String apiUrl = '${AuthService.baseUrl}/admin/books';
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> books = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchBooks();
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

  Future<void> fetchBooks() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          books = decoded is List
              ? decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : [];
        });
      } else {
        showMessage('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  String _inferFormat(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.epub')) return 'epub';
    if (lower.endsWith('.txt')) return 'txt';
    if (lower.endsWith('.docx')) return 'docx';
    if (lower.endsWith('.doc')) return 'doc';
    return 'pdf';
  }

  Future<void> addBook({
    PlatformFile? file,
    required String title,
    required String author,
    required String pageCount,
    required String genre,
    required String description,
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
      request.fields['pageCount'] = pageCount;
      request.fields['genre'] = genre;
      request.fields['description'] = description;
      request.fields['level'] = level;
      request.fields['format'] = file != null ? _inferFormat(file.name) : 'pdf';

      if (externalUrl != null && externalUrl.trim().isNotEmpty) {
        request.fields['externalUrl'] = externalUrl.trim();
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMessage('Book added successfully');
        await fetchBooks();
      } else {
        showMessage('Upload error: ${response.body}');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> updateBookById({
    required String id,
    required String title,
    required String author,
    required String pageCount,
    required String genre,
    required String description,
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
          'pageCount': int.tryParse(pageCount) ?? 0,
          'genre': genre,
          'description': description,
          'level': level,
          'externalUrl': externalUrl?.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMessage('Book updated successfully');
        await fetchBooks();
      } else {
        showMessage('Update error: ${response.body}');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> deleteBookById(String id) async {
    setState(() => loading = true);
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        showMessage('Book deleted successfully');
        await fetchBooks();
      } else {
        showMessage('Delete error: ' + response.body);
      }
    } catch (e) {
      showMessage('Error: ' + e.toString());
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }
  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<Map<String, dynamic>> get filteredBooks {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return books;

    return books.where((book) {
      final title = '${book['title'] ?? ''}'.toLowerCase();
      final author = '${book['author'] ?? ''}'.toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();
  }

  void openAddBookSheet() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pageController = TextEditingController();
    final descriptionController = TextEditingController();
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
                      'Add book',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    _Input(controller: titleController, hint: 'Book title'),
                    const SizedBox(height: 12),
                    _Input(controller: authorController, hint: 'Author'),
                    const SizedBox(height: 12),
                    _Input(
                      controller: pageController,
                      hint: 'Page count',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _Input(
                      controller: descriptionController,
                      hint: 'Short description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _Input(
                      controller: externalUrlController,
                      hint: 'External book URL (optional)',
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Genre',
                      value: selectedGenre,
                      items: genres,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedGenre = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Level',
                      value: selectedLevel,
                      items: levels,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedLevel = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'epub', 'txt', 'doc', 'docx'],
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
                            const Icon(Icons.upload_file_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName ?? 'Choose book file (or use link above)',
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
                          final pageCount = pageController.text.trim();
                          final description = descriptionController.text.trim();
                          final externalUrl = externalUrlController.text.trim();

                          if (title.isEmpty || author.isEmpty || pageCount.isEmpty) {
                            showMessage('Fill title, author and page count');
                            return;
                          }

                          if (selectedFile == null && externalUrl.isEmpty) {
                            showMessage('Choose a file or enter an external book URL');
                            return;
                          }

                          if (selectedFile != null && selectedFile!.bytes == null) {
                            showMessage('File bytes not found. Pick the file again.');
                            return;
                          }

                          Navigator.pop(context);
                          addBook(
                            file: selectedFile,
                            title: title,
                            author: author,
                            pageCount: pageCount,
                            genre: selectedGenre,
                            description: description,
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
                          'Save book',
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

  void openEditBookSheet(Map<String, dynamic> book) {
    final id = '';
    final titleController = TextEditingController(text: '${book['title'] ?? ''}');
    final authorController = TextEditingController(text: '${book['author'] ?? ''}');
    final pageController = TextEditingController(text: '${book['pageCount'] ?? ''}');
    final descriptionController = TextEditingController(text: '${book['description'] ?? ''}');
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
                      'Edit book',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 18),
                    _Input(controller: titleController, hint: 'Book title'),
                    const SizedBox(height: 12),
                    _Input(controller: authorController, hint: 'Author'),
                    const SizedBox(height: 12),
                    _Input(
                      controller: pageController,
                      hint: 'Page count',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _Input(
                      controller: descriptionController,
                      hint: 'Short description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    _Input(
                      controller: externalUrlController,
                      hint: 'External book URL (optional)',
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Genre',
                      value: selectedGenre,
                      items: genres,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedGenre = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _DropdownField<String>(
                      label: 'Level',
                      value: selectedLevel,
                      items: levels,
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedLevel = value);
                        }
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
                          final pageCount = pageController.text.trim();
                          final description = descriptionController.text.trim();

                          if (title.isEmpty || author.isEmpty || pageCount.isEmpty) {
                            showMessage('Fill all fields');
                            return;
                          }

                          Navigator.pop(context);
                          updateBookById(
                            id: id,
                            title: title,
                            author: author,
                            pageCount: pageCount,
                            genre: selectedGenre,
                            description: description,
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
    final list = filteredBooks;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: openAddBookSheet,
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
                      'Reading Admin',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: fetchBooks,
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
                            'No books yet. Tap + to upload a book.',
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
                                    (book) => _AdminBookCard(
                                      book: book,
                                      onEdit: () => openEditBookSheet(book),
                                      onDelete: () async {
                                        final id = (book['id'] ?? '').toString();
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Delete book?'),
                                            content: Text('Delete ' + (book['title'] ?? 'this book').toString() + '?'),
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
                                          await deleteBookById(id);
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

class _AdminBookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminBookCard({
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
                  child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 42),
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
              _SmallTag(label: genre),
              _SmallTag(label: level),
              _SmallTag(label: hasExternalUrl ? 'Link' : 'File'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;

  const _SmallTag({required this.label});

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
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text('$item'),
                ),
              )
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
  final TextInputType? keyboardType;
  final int maxLines;

  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines > 1 ? maxLines : 1,
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










