import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/book_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/book_service.dart';
import 'package:kazakh_learning_app/services/book_review_service.dart';
import 'package:kazakh_learning_app/widgets/book_review_section.dart';
import 'package:url_launcher/url_launcher.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _selectedGenre = 'All';
  List<BookModel> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final books = await _bookService.getBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<String> get _genres {
    final genres = _books
        .map((book) => book.genre.trim().isEmpty ? 'General' : book.genre.trim())
        .toSet()
        .toList()
      ..sort();
    return ['All', ...genres];
  }

  List<BookModel> get _filteredBooks {
    final query = _searchController.text.trim().toLowerCase();

    return _books.where((book) {
      final genreOk =
          _selectedGenre == 'All' || book.genre.toLowerCase() == _selectedGenre.toLowerCase();
      final queryOk = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
      return genreOk && queryOk;
    }).toList();
  }

  List<BookModel> _bestSeller(List<BookModel> source) {
    final sorted = [...source]..sort((a, b) => b.pageCount.compareTo(a.pageCount));
    return sorted.take(8).toList();
  }

  Future<void> _openBookFile(BookModel book) async {
    final rawUrl = book.hasExternalUrl
        ? book.externalUrl
        : '${AuthService.baseUrl}/books/${book.id}/file?disposition=inline';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the book')),
      );
    }
  }

  void _openDetails(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(
          book: book,
          allBooks: _books,
          openBook: _openBookFile,
        ),
      ),
    );
  }

  void _openAllBooks(String title, List<BookModel> books) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllBooksScreen(
          title: title,
          books: books,
          onBookTap: _openDetails,
        ),
      ),
    );
  }

  void _openAllAuthors(List<String> authors) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllAuthorsScreen(
          authors: authors,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;
    final bestSeller = _bestSeller(filtered);
    final popular = filtered.reversed.take(8).toList();
    final authors = filtered.map((book) => book.author).toSet().toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _error != null
                ? _ReadingError(message: _error!, onRetry: _loadBooks)
                : RefreshIndicator(
                    onRefresh: _loadBooks,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            ),
                            const Expanded(
                              child: Text(
                                'Reading',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _loadBooks,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F0F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Color(0xFF7A7A7A)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Title, author, ...',
                                    hintStyle: TextStyle(color: Color(0xFF999999)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _genres
                                .map(
                                  (genre) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _GenreButton(
                                      title: genre,
                                      selected: genre == _selectedGenre,
                                      onTap: () => setState(() => _selectedGenre = genre),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: 'Best seller',
                          actionText: 'See All',
                          onActionTap: () => _openAllBooks('Best seller', bestSeller),
                        ),
                        const SizedBox(height: 12),
                        _HorizontalBookStrip(books: bestSeller, onBookTap: _openDetails),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Top authors',
                          actionText: 'See All',
                          onActionTap: () => _openAllAuthors(authors),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: authors.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: _AuthorAvatar(name: authors[index]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SectionHeader(
                          title: 'Popular',
                          actionText: 'See All',
                          onActionTap: () => _openAllBooks('Popular', popular),
                        ),
                        const SizedBox(height: 12),
                        _HorizontalBookStrip(books: popular, onBookTap: _openDetails),
                        if (filtered.isEmpty) ...[
                          const SizedBox(height: 28),
                          const Center(
                            child: Text(
                              'No books found for this genre yet',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class BookDetailsScreen extends StatelessWidget {
  final BookModel book;
  final List<BookModel> allBooks;
  final Future<void> Function(BookModel book) openBook;

  const BookDetailsScreen({
    super.key,
    required this.book,
    required this.allBooks,
    required this.openBook,
  });

  List<BookModel> get relatedBooks {
    return allBooks
        .where((item) => item.id != book.id && item.genre.toLowerCase() == book.genre.toLowerCase())
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final description = book.description.isNotEmpty
        ? book.description
        : 'No description added for this book yet.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: _CoverCard(book: book, width: 136, height: 188),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF505050),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _OutlineTag(text: book.genre),
                _OutlineTag(text: book.format.toUpperCase()),
                _OutlineTag(text: '${book.pageCount} pages'),
                _OutlineTag(text: book.level),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.55,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => openBook(book),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1D49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Read',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            BookReviewSection(
              contentType: ReviewContentType.book,
              contentId: book.id,
            ),
            const SizedBox(height: 30),
            _SectionHeader(
              title: 'Most Likes',
              actionText: 'See All',
              onActionTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _AllBooksScreen(
                      title: 'Most Likes',
                      books: relatedBooks,
                      onBookTap: (item) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailsScreen(
                              book: item,
                              allBooks: allBooks,
                              openBook: openBook,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _HorizontalBookStrip(
              books: relatedBooks,
              onBookTap: (item) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookDetailsScreen(
                      book: item,
                      allBooks: allBooks,
                      openBook: openBook,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalBookStrip extends StatelessWidget {
  final List<BookModel> books;
  final void Function(BookModel book) onBookTap;

  const _HorizontalBookStrip({
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Nothing here yet',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 208,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => onBookTap(books[index]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoverCard(book: books[index], width: 104, height: 146),
                const SizedBox(height: 10),
                SizedBox(
                  width: 104,
                  child: Text(
                    books[index].title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  final BookModel book;
  final double width;
  final double height;

  const _CoverCard({
    required this.book,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF7F1DE),
      ),
      child: Column(
        children: [
          Container(
            height: height * 0.62,
            decoration: const BoxDecoration(
              color: Color(0xFF0C1D49),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFFE0B44D),
                size: 58,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF24304A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF4E4E4E),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1D49),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _GenreButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0C1D49) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBEB7B7)),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF5E5E5E),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: Color(0xFF4C4C4C),
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6C6C6C),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _AllBooksScreen extends StatelessWidget {
  final String title;
  final List<BookModel> books;
  final void Function(BookModel book) onBookTap;

  const _AllBooksScreen({
    required this.title,
    required this.books,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 18, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: books.isEmpty
                  ? const Center(
                      child: Text(
                        'Nothing here yet',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        const horizontalPadding = 18.0;
                        const spacing = 18.0;
                        const minTileWidth = 120.0;
                        const maxTileWidth = 168.0;
                        final availableWidth = constraints.maxWidth - horizontalPadding * 2;
                        final rawCount = ((availableWidth + spacing) / (minTileWidth + spacing))
                            .floor()
                            .clamp(2, 6);
                        var tileWidth =
                            (availableWidth - spacing * (rawCount - 1)) / rawCount;
                        final crossAxisCount = tileWidth > maxTileWidth
                            ? ((availableWidth + spacing) / (maxTileWidth + spacing))
                                .floor()
                                .clamp(2, 6)
                            : rawCount;
                        tileWidth =
                            (availableWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                        final cardWidth = tileWidth.clamp(minTileWidth, maxTileWidth);
                        final titleHeight = cardWidth >= 150 ? 44.0 : 38.0;
                        final itemHeight = 146 + 10 + titleHeight;

                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: 18,
                                childAspectRatio: cardWidth / itemHeight,
                              ),
                              itemCount: books.length,
                              itemBuilder: (context, index) => Align(
                                alignment: Alignment.topLeft,
                                child: SizedBox(
                                  width: cardWidth,
                                  child: GestureDetector(
                                    onTap: () => onBookTap(books[index]),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _CoverCard(
                                          book: books[index],
                                          width: cardWidth,
                                          height: 146,
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: titleHeight,
                                          child: Text(
                                            books[index].title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF313131),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllAuthorsScreen extends StatelessWidget {
  final List<String> authors;

  const _AllAuthorsScreen({
    required this.authors,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 18, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Top authors',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: authors.isEmpty
                  ? const Center(
                      child: Text(
                        'Nothing here yet',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      itemCount: authors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final author = authors[index];
                        return Row(
                          children: [
                            _AuthorAvatar(name: author),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                author,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF313131),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String name;

  const _AuthorAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();

    return SizedBox(
      width: 78,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE9E9E9),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF575757),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3F3F3F),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineTag extends StatelessWidget {
  final String text;

  const _OutlineTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBEB7B7)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5D5D5D),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ReadingError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ReadingError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.black54),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
