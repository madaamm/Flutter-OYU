import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/models/audio_book_model.dart';
import 'package:kazakh_learning_app/services/audio_book_service.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final AudioBookService _audioBookService = AudioBookService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String _selectedGenre = 'All';
  List<AudioBookModel> _audioBooks = [];

  @override
  void initState() {
    super.initState();
    _loadAudioBooks();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAudioBooks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final audioBooks = await _audioBookService.getAudioBooks();
      if (!mounted) return;
      setState(() {
        _audioBooks = audioBooks;
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
    final genres = _audioBooks
        .map((book) => book.genre.trim().isEmpty ? 'General' : book.genre.trim())
        .toSet()
        .toList()
      ..sort();
    return ['All', ...genres];
  }

  List<AudioBookModel> get _filteredAudioBooks {
    final query = _searchController.text.trim().toLowerCase();

    return _audioBooks.where((book) {
      final genreOk =
          _selectedGenre == 'All' || book.genre.toLowerCase() == _selectedGenre.toLowerCase();
      final queryOk = query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query);
      return genreOk && queryOk;
    }).toList();
  }

  void _openDetails(AudioBookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListeningDetailsScreen(
          book: book,
          allBooks: _audioBooks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAudioBooks;
    final featured = filtered.isNotEmpty ? filtered.first : null;
    final recentlyPlayed = filtered.take(3).toList();
    final popular = filtered.skip(filtered.length > 1 ? 1 : 0).take(8).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.black))
            : _error != null
                ? _ListeningError(message: _error!, onRetry: _loadAudioBooks)
                : RefreshIndicator(
                    onRefresh: _loadAudioBooks,
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
                                'Listening',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
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
                        const SizedBox(height: 20),
                        if (featured != null) _FeaturedAudioCard(book: featured, onTap: _openDetails),
                        const SizedBox(height: 22),
                        _SectionTitle(title: 'Recently played'),
                        const SizedBox(height: 14),
                        if (recentlyPlayed.isEmpty)
                          const _EmptySection(message: 'No audio books in this genre yet')
                        else
                          ...recentlyPlayed.map(
                            (book) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _RecentAudioTile(book: book, onTap: _openDetails),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Divider(color: Color(0xFFBABABA), thickness: 1),
                        const SizedBox(height: 18),
                        _SectionHeader(title: 'Popular podcasts', actionText: 'See all'),
                        const SizedBox(height: 14),
                        if (popular.isEmpty)
                          const _EmptySection(message: 'Nothing to play here yet')
                        else
                          SizedBox(
                            height: 170,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: popular.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: _PopularAudioCard(book: popular[index], onTap: _openDetails),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class ListeningDetailsScreen extends StatefulWidget {
  final AudioBookModel book;
  final List<AudioBookModel> allBooks;

  const ListeningDetailsScreen({
    super.key,
    required this.book,
    required this.allBooks,
  });

  @override
  State<ListeningDetailsScreen> createState() => _ListeningDetailsScreenState();
}

class _ListeningDetailsScreenState extends State<ListeningDetailsScreen> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 15);
  bool _loading = false;
  bool _isPlaying = false;

  String get _streamUrl => widget.book.hasExternalUrl
      ? widget.book.externalUrl
      : '${AuthService.baseUrl}/audio-books/${widget.book.id}/file?disposition=inline';

  List<AudioBookModel> get relatedBooks {
    return widget.allBooks
        .where(
          (item) =>
              item.id != widget.book.id &&
              item.genre.toLowerCase() == widget.book.genre.toLowerCase(),
        )
        .take(6)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _positionSub = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _durationSub = _player.onDurationChanged.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value == Duration.zero ? _duration : value);
    });
    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        _loading = state == PlayerState.playing ? false : _loading;
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        return;
      }

      setState(() => _loading = true);
      if (_position == Duration.zero) {
        await _player.play(UrlSource(_streamUrl));
      } else {
        await _player.resume();
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play this audio book')),
      );
    }
  }

  Future<void> _seekBy(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final safeTarget = target < Duration.zero
        ? Duration.zero
        : target > _duration
            ? _duration
            : target;
    await _player.seek(safeTarget);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final sliderMax = _duration.inMilliseconds <= 0 ? 1.0 : _duration.inMilliseconds.toDouble();
    final sliderValue = _position.inMilliseconds.clamp(0, sliderMax.toInt()).toDouble();

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
                const Expanded(
                  child: Text(
                    'Now playing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _AudioArtwork(book: widget.book, width: double.infinity, height: 254),
            const SizedBox(height: 42),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191919),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.book.author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7C7C7C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_rounded, color: Color(0xFFFF6F47), size: 28),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _OutlineTag(text: widget.book.genre),
                _OutlineTag(text: widget.book.level),
                _OutlineTag(text: widget.book.format.toUpperCase()),
              ],
            ),
            const SizedBox(height: 18),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF222222),
                inactiveTrackColor: const Color(0xFFD7D7D7),
                thumbColor: const Color(0xFF222222),
                overlayColor: const Color(0x33222222),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: sliderMax,
                onChanged: (value) {
                  _player.seek(Duration(milliseconds: value.round()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Color(0xFF7A7A7A)),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Color(0xFF7A7A7A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.shuffle_rounded, color: Color(0xFF1E1E1E)),
                _RoundIconButton(
                  icon: Icons.replay_10_rounded,
                  onTap: () => _seekBy(-10),
                ),
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFF191919),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                    ),
                  ),
                ),
                _RoundIconButton(
                  icon: Icons.forward_10_rounded,
                  onTap: () => _seekBy(10),
                ),
                const Icon(Icons.repeat_rounded, color: Color(0xFF1E1E1E)),
              ],
            ),
            const SizedBox(height: 34),
            if (relatedBooks.isNotEmpty) ...[
              _SectionHeader(title: 'Popular podcasts', actionText: 'See all'),
              const SizedBox(height: 14),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: relatedBooks.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: _PopularAudioCard(
                      book: relatedBooks[index],
                      onTap: (item) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListeningDetailsScreen(
                              book: item,
                              allBooks: widget.allBooks,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeaturedAudioCard extends StatelessWidget {
  final AudioBookModel book;
  final void Function(AudioBookModel book) onTap;

  const _FeaturedAudioCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(book),
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFB81C),
              Color(0xFF75C93F),
              Color(0xFFEA4E9D),
              Color(0xFFFF5B2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -14,
              left: 40,
              child: _Blob(color: const Color(0xFF22C8FF), width: 96, height: 58),
            ),
            Positioned(
              top: -16,
              right: -2,
              child: _Blob(color: const Color(0xFF2D6E2E), width: 130, height: 134),
            ),
            Positioned(
              top: 32,
              right: 66,
              child: _Blob(color: const Color(0xFFE85AA1), width: 88, height: 94),
            ),
            Positioned(
              bottom: -14,
              right: -8,
              child: _Blob(color: const Color(0xFFE6361C), width: 170, height: 84),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: const Color(0x99331313),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Color(0xFFF6E8D3),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${book.level} listening',
                                style: const TextStyle(
                                  color: Color(0xFFF6E8D3),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAudioTile extends StatelessWidget {
  final AudioBookModel book;
  final void Function(AudioBookModel book) onTap;

  const _RecentAudioTile({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(book),
      child: Row(
        children: [
          _AudioArtwork(book: book, width: 62, height: 62, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFB6B6B6)),
                    const SizedBox(width: 6),
                    Text(
                      '${book.level} level listening',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB6B6B6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularAudioCard extends StatelessWidget {
  final AudioBookModel book;
  final void Function(AudioBookModel book) onTap;

  const _PopularAudioCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(book),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AudioArtwork(book: book, width: 148, height: 132),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF313131),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioArtwork extends StatelessWidget {
  final AudioBookModel book;
  final double width;
  final double height;
  final double radius;

  const _AudioArtwork({
    required this.book,
    required this.width,
    required this.height,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFB81C),
            Color(0xFF75C93F),
            Color(0xFFEA4E9D),
            Color(0xFFFF5B2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -14,
            left: 26,
            child: _Blob(color: const Color(0xFF22C8FF), width: width * 0.34, height: height * 0.22),
          ),
          Positioned(
            top: -16,
            right: -4,
            child: _Blob(color: const Color(0xFF275C2E), width: width * 0.46, height: height * 0.5),
          ),
          Positioned(
            top: height * 0.24,
            right: width * 0.23,
            child: _Blob(color: const Color(0xFFE85AA1), width: width * 0.3, height: height * 0.36),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: _Blob(color: const Color(0xFFE6361C), width: width * 0.66, height: height * 0.27),
          ),
          Positioned.fill(
            child: Container(
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width > 170 ? 24 : 14,
                        fontWeight: FontWeight.w700,
                        shadows: const [
                          Shadow(
                            color: Color(0x77000000),
                            blurRadius: 10,
                          ),
                        ],
                      ),
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

class _Blob extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const _Blob({
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 14,
            spreadRadius: 4,
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
          color: selected ? const Color(0xFF111111) : Colors.white,
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF222222),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({
    required this.title,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        Text(
          actionText,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFFF6F47),
          ),
        ),
      ],
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1E1E1E)),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF888888)),
        ),
      ),
    );
  }
}

class _ListeningError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ListeningError({
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





