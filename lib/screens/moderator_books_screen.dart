import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ModeratorBooksScreen extends StatefulWidget {
  const ModeratorBooksScreen({super.key});

  @override
  State<ModeratorBooksScreen> createState() => _ModeratorBooksScreenState();
}

class _ModeratorBooksScreenState extends State<ModeratorBooksScreen> {
  final String apiUrl = 'https://learnkz.kazi.rocks/api/moderator/books';

  final TextEditingController searchController = TextEditingController();

  List books = [];
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

  Future<void> fetchBooks() async {
    setState(() => loading = true);

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          books = decoded is List ? decoded : [];
        });
      } else {
        showMessage('Failed to load books');
      }
    } catch (e) {
      showMessage('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> addBook({
    required PlatformFile file,
    required String title,
    required String author,
    required String pageCount,
  }) async {
    setState(() => loading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );

      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['pageCount'] = pageCount;
      request.fields['format'] = 'pdf';

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
      setState(() => loading = false);
    }
  }

  Future<void> updateBookById({
    required String id,
    required String title,
    required String author,
    required String pageCount,
  }) async {
    setState(() => loading = true);

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'author': author,
          'pageCount': int.tryParse(pageCount) ?? 0,
          'format': 'pdf',
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
      setState(() => loading = false);
    }
  }

  Future<void> updateBookByTitle({
    required String oldTitle,
    required String title,
    required String author,
    required String pageCount,
  }) async {
    setState(() => loading = true);

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/by-title/${Uri.encodeComponent(oldTitle)}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'author': author,
          'pageCount': int.tryParse(pageCount) ?? 0,
          'format': 'pdf',
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
      setState(() => loading = false);
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  List get filteredBooks {
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

    PlatformFile? selectedFile;
    String? fileName;

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
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
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
                    const SizedBox(height: 14),

                    InkWell(
                      onTap: () async {
                        final picked = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'],
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
                            const Icon(Icons.picture_as_pdf_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName ?? 'Choose PDF file',
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

                          if (title.isEmpty ||
                              author.isEmpty ||
                              pageCount.isEmpty ||
                              selectedFile == null) {
                            showMessage('Fill all fields and choose PDF');
                            return;
                          }

                          if (selectedFile!.bytes == null) {
                            showMessage('File bytes not found. Pick PDF again.');
                            return;
                          }

                          Navigator.pop(context);

                          addBook(
                            file: selectedFile!,
                            title: title,
                            author: author,
                            pageCount: pageCount,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A008B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Add book',
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

  void openEditBookSheet(dynamic book) {
    final oldTitle = '${book['title'] ?? ''}';
    final id = '${book['id'] ?? book['_id'] ?? ''}';

    final titleController = TextEditingController(text: oldTitle);
    final authorController =
    TextEditingController(text: '${book['author'] ?? ''}');
    final pageController =
    TextEditingController(text: '${book['pageCount'] ?? ''}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
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
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final author = authorController.text.trim();
                      final pageCount = pageController.text.trim();

                      if (title.isEmpty || author.isEmpty || pageCount.isEmpty) {
                        showMessage('Fill all fields');
                        return;
                      }

                      Navigator.pop(context);

                      if (id.isNotEmpty && id != 'null') {
                        updateBookById(
                          id: id,
                          title: title,
                          author: author,
                          pageCount: pageCount,
                        );
                      } else {
                        updateBookByTitle(
                          oldTitle: oldTitle,
                          title: title,
                          author: author,
                          pageCount: pageCount,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A008B),
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
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredBooks;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: openAddBookSheet,
        backgroundColor: const Color(0xFF5A008B),
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Reading',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: openAddBookSheet,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 30,
                      color: Color(0xFF555555),
                    ),
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
                          hintText: 'Title, author, ...',
                          hintStyle: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Row(
                children: const [
                  _GenreChip('Romance'),
                  _GenreChip('Comedy'),
                  _GenreChip('Horror'),
                  _GenreChip('Drama'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                  ? const Center(
                child: Text(
                  'No books yet. Tap + to add a book.',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : ListView(
                padding: const EdgeInsets.only(bottom: 90),
                children: [
                  _Section(
                    title: 'Best seller',
                    books: list,
                    onEdit: openEditBookSheet,
                  ),
                  const SizedBox(height: 34),
                  _AuthorsSection(books: list),
                  const SizedBox(height: 34),
                  _Section(
                    title: 'Popular',
                    books: list,
                    onEdit: openEditBookSheet,
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

class _Section extends StatelessWidget {
  final String title;
  final List books;
  final void Function(dynamic book) onEdit;

  const _Section({
    required this.title,
    required this.books,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionTitle(title),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 42),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _BookCard(
                book: books[index],
                onEdit: () => onEdit(books[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BookCard extends StatelessWidget {
  final dynamic book;
  final VoidCallback onEdit;

  const _BookCard({
    required this.book,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final title = '${book['title'] ?? 'Untitled'}';
    final author = '${book['author'] ?? 'Unknown'}';

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                height: 170,
                width: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFF06183A),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Color(0xFF5A008B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }
}

class _AuthorsSection extends StatelessWidget {
  final List books;

  const _AuthorsSection({required this.books});

  @override
  Widget build(BuildContext context) {
    final authors =
    books.map((e) => '${e['author'] ?? 'Unknown'}').toSet().toList();

    return Column(
      children: [
        _SectionTitle('Top authors'),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 42),
            itemCount: authors.length,
            itemBuilder: (context, index) {
              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 18),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFE6E6E6),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF777777),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authors[index],
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'See All',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF777777),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String text;

  const _GenreChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 34,
      margin: const EdgeInsets.only(right: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF777777)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}