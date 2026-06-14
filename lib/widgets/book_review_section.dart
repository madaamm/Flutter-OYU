import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kazakh_learning_app/models/book_review_model.dart';
import 'package:kazakh_learning_app/services/auth_service.dart';
import 'package:kazakh_learning_app/services/book_review_service.dart';

class BookReviewSection extends StatefulWidget {
  final ReviewContentType contentType;
  final int contentId;

  const BookReviewSection({
    super.key,
    required this.contentType,
    required this.contentId,
  });

  @override
  State<BookReviewSection> createState() => _BookReviewSectionState();
}

class _BookReviewSectionState extends State<BookReviewSection> {
  static const Color navy = Color(0xFF0C1D49);
  static const Color gold = Color(0xFFF2BC35);

  final BookReviewService _reviewService = BookReviewService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();

  BookReviewSummary? _summary;
  int? _currentUserId;
  int _selectedRating = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _reviewService.getReviews(
          type: widget.contentType,
          contentId: widget.contentId,
        ),
        _authService.getUserId(),
      ]);

      final summary = results[0] as BookReviewSummary;
      final userId = results[1] as int?;
      BookReviewModel? ownReview;

      if (userId != null) {
        for (final review in summary.reviews) {
          if (review.user.id == userId) {
            ownReview = review;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _currentUserId = userId;
        _selectedRating = ownReview?.rating ?? 0;
        _commentController.text = ownReview?.comment ?? '';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final comment = _commentController.text.trim();

    if (_selectedRating == 0) {
      _showMessage('Choose a rating from 1 to 5 stars');
      return;
    }

    if (comment.isEmpty) {
      _showMessage('Write a comment about the book');
      return;
    }

    setState(() => _saving = true);

    try {
      await _reviewService.saveReview(
        type: widget.contentType,
        contentId: widget.contentId,
        rating: _selectedRating,
        comment: comment,
      );
      await _load();
      if (mounted) _showMessage('Review saved');
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(color: navy)),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final summary = _summary ??
        const BookReviewSummary(
          averageRating: 0,
          reviewCount: 0,
          reviews: <BookReviewModel>[],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating and reviews',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    summary.reviewCount == 0
                        ? 'No ratings yet'
                        : summary.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${summary.reviewCount} review${summary.reviewCount == 1 ? '' : 's'}',
                    style: const TextStyle(color: Color(0xFF777777)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Your rating',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _StarPicker(
                rating: _selectedRating,
                onChanged: (value) {
                  setState(() => _selectedRating = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Write your review',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD7D2DA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD7D2DA)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: navy, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentUserId == null
                              ? 'Sign in to review'
                              : 'Save review',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (summary.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Be the first to leave a review.',
              style: TextStyle(color: Color(0xFF777777)),
            ),
          )
        else
          ...summary.reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: review),
            ),
          ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF8F7FA),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6E1E8)),
    );
  }
}

class _StarPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarPicker({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= rating;

        return IconButton(
          tooltip: '$value star${value == 1 ? '' : 's'}',
          onPressed: () => onChanged(value),
          padding: const EdgeInsets.only(right: 8),
          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          icon: SvgPicture.asset(
            'assets/images/star.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
              selected ? _BookReviewSectionState.gold : const Color(0xFFD1CCD4),
              BlendMode.srcIn,
            ),
          ),
        );
      }),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final BookReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final date = review.updatedAt ?? review.createdAt;
    final dateText = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}.'
            '${date.month.toString().padLeft(2, '0')}.'
            '${date.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E1E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEDE4FF),
                child: Text(
                  review.user.displayName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6A00FF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (dateText.isNotEmpty)
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Color(0xFF8A858D),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: SvgPicture.asset(
                  'assets/images/star.svg',
                  width: 17,
                  height: 17,
                  colorFilter: ColorFilter.mode(
                    index < review.rating
                        ? _BookReviewSectionState.gold
                        : const Color(0xFFD1CCD4),
                    BlendMode.srcIn,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              color: Color(0xFF4F4A52),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
