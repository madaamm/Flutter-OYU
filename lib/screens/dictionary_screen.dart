import 'package:flutter/material.dart';
import 'package:kazakh_learning_app/l10n/app_text.dart';
import 'package:kazakh_learning_app/models/dictionary_entry_model.dart';
import 'package:kazakh_learning_app/services/dictionary_service.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  static const Color purple = Color(0xFF8E5BFF);
  static const Color bg = Color(0xFFF6F1FF);

  final DictionaryService _dictionaryService = DictionaryService();
  late Future<List<DictionaryEntryModel>> _futureEntries;

  @override
  void initState() {
    super.initState();
    _futureEntries = _dictionaryService.getMyDictionary();
  }

  Future<void> _reload() async {
    setState(() {
      _futureEntries = _dictionaryService.getMyDictionary();
    });
    await _futureEntries;
  }

  Future<void> _deleteEntry(DictionaryEntryModel entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('remove_word_question')),
        content: Text(
          context.tr('remove_word_named', args: {'word': entry.word}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: purple),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _dictionaryService.deleteEntry(entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('word_removed_from_dictionary'))),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: purple,
        title: Text(context.tr('dictionary_title')),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: purple,
        onRefresh: _reload,
        child: FutureBuilder<List<DictionaryEntryModel>>(
          future: _futureEntries,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.menu_book_outlined, size: 64, color: purple),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _reload,
                    style: ElevatedButton.styleFrom(backgroundColor: purple),
                    child: Text(context.tr('try_again')),
                  ),
                ],
              );
            }

            final entries = snapshot.data ?? const <DictionaryEntryModel>[];
            if (entries.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(
                    Icons.bookmark_border_rounded,
                    size: 72,
                    color: purple,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.tr('dictionary_empty'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.word,
                              style: const TextStyle(
                                color: Color(0xFF241A3B),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteEntry(entry),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: context.tr('translation'),
                        value: entry.primaryTranslation,
                      ),
                      if (entry.translationRu.trim().isNotEmpty &&
                          entry.translationEn.trim().isNotEmpty &&
                          entry.translationRu.trim() != entry.translationEn.trim()) ...[
                        const SizedBox(height: 6),
                        _InfoRow(label: 'EN', value: entry.translationEn),
                      ],
                      const SizedBox(height: 6),
                      _InfoRow(
                        label: context.tr('transcription'),
                        value: entry.transcription.trim().isNotEmpty
                            ? entry.transcription
                            : context.tr('no_transcription_yet'),
                      ),
                      if (entry.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          entry.description,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF6D2DFF),
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
