// ✅ Final integrated version: Global marquee loaded from Firebase

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

Widget buildArabicImagePlaceholder({double height = 120}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/image.png',
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    ),
  );
}

Widget buildArabicAyahImage(Ayah ayah, {double height = 110}) {
  final url = ayah.arabicImageUrl.trim();

  if (url.isEmpty) {
    return buildArabicImagePlaceholder(height: height);
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return buildArabicImagePlaceholder(height: height);
      },
    ),
  );
}

class Ayah {
  final int number;
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String arabicImageUrl;
  final String urdu;
  final String translation;
  final String transliteration;
  final String audioUrl;

  Ayah({
    required this.number,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.arabicImageUrl,
    required this.urdu,
    required this.translation,
    required this.transliteration,
    required this.audioUrl,
  });

  factory Ayah.fromMap(Map<String, dynamic> data) {
    final imageUrl = data['arabicImageUrl'] ??
        data['arabicImage'] ??
        data['imageUrl'] ??
        data['image'] ??
        '';

    return Ayah(
      number: _readNumber(data, const ['number', 'globalNumber']),
      surahNumber: _readNumber(
        data,
        const ['surahNumber', 'surah_number', 'surahNo', 'surah_no', 'surah'],
      ),
      ayahNumber: _readNumber(
        data,
        const ['ayahNumber', 'ayah_number', 'ayahNo', 'ayah_no'],
      ),
      arabic: data['arabic'] ?? '',
      arabicImageUrl: imageUrl is String ? imageUrl : imageUrl.toString(),
      urdu: data['urdu'] ?? '',
      translation: data['translation'] ?? '',
      transliteration: data['transliteration'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
    );
  }

  static int _readNumber(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final match = RegExp(r'\d+').firstMatch(value);
        final parsed = match == null ? null : int.tryParse(match.group(0)!);
        if (parsed != null) return parsed;
      }
      if (value is Map) {
        final nestedValue =
            value['number'] ?? value['surahNumber'] ?? value['id'];
        if (nestedValue is int) return nestedValue;
        if (nestedValue is num) return nestedValue.toInt();
        if (nestedValue is String) {
          final match = RegExp(r'\d+').firstMatch(nestedValue);
          final parsed = match == null ? null : int.tryParse(match.group(0)!);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0;
  }
}

class _SurahRange {
  final int surahNumber;
  final int startAyah;
  final int endAyah;
  final int startIndex;

  const _SurahRange({
    required this.surahNumber,
    required this.startAyah,
    required this.endAyah,
    required this.startIndex,
  });
}

class QuranScreen extends StatefulWidget {
  final String title;
  final String description;
  final String detailsID;
  final String chapter;
  final String surahId;

  const QuranScreen({
    super.key,
    required this.title,
    required this.description,
    required this.detailsID,
    required this.chapter,
    required this.surahId,
  });

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ayahListViewportKey = GlobalKey();

  List<Ayah> _ayahs = [];
  List<GlobalKey> _ayahKeys = [];
  List<_SurahRange> _surahRanges = [];
  final Map<int, String> _surahNames = {};
  bool _loading = true;
  int? _currentSurahNumber;

  double _fontSizeArabic = 24;
  double _fontSizeUrdu = 32;
  double _fontSizeTranslation = 16;
  double _fontSizeTransliteration = 16;
  String _arabicFontFamily = 'QuranJuzUthman';
  String _urduFontFamily = 'JameelNooriNastaleeq';
  bool _arabicBold = false;
  bool _urduBold = false;
  bool _translationBold = false;

  static const List<(String, String)> _arabicFontOptions = [
    ('KFGQPC Uthman Taha Naskh', 'QuranJuzUthman'),
    ('Al Mushaf Quran', 'AlMushafQuran'),
    ('Amiri', 'Amiri'),
    ('Al Qalam Quran', 'AlQalamQuran'),
  ];
  static const List<(String, String)> _urduFontOptions = [
    ('Jameel Noori Nastaleeq', 'JameelNooriNastaleeq'),
    ('Saleem Quran Font', 'SaleemQuran'),
    ('Amiri', 'Amiri'),
    ('Al Qalam Quran', 'AlQalamQuran'),
  ];

  bool _isAutoPlaying = false;
  int _currentAyahIndex = -1;
  String? _autoPlayAudioUrl;

  String _marqueeText = '';
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[QURAN_JUZ] QuranScreen opened: ${widget.title}, id: ${widget.surahId}',
    );
    _scrollController.addListener(_updateCurrentSurahFromScroll);
    _loadSurahData();
    _fetchMarqueeText();
    _marqueeTimer =
        Timer.periodic(Duration(minutes: 5), (_) => _fetchMarqueeText());
  }

  Future<void> _fetchMarqueeText() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('global')
          .get();
      if (doc.exists) {
        setState(() {
          _marqueeText = doc.data()?['marqueeText'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Failed to load marquee text: $e');
    }
  }

  Future<void> _loadSurahData() async {
    try {
      final surahDoc = await FirebaseFirestore.instance
          .collection('quran')
          .doc(widget.surahId)
          .get();
      if (surahDoc.exists) {
        _autoPlayAudioUrl = surahDoc.data()?['audioUrl'] ?? '';
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('quran')
          .doc(widget.surahId)
          .collection('ayahs')
          .orderBy('number')
          .get();

      final data = snapshot.docs.map((e) => Ayah.fromMap(e.data())).toList();
      final missingSurahNumbers =
          data.where((ayah) => ayah.surahNumber <= 0).length;
      if (missingSurahNumbers > 0) {
        debugPrint(
          '[QURAN_JUZ] $missingSurahNumbers ayahs have no recognized Surah number field. '
          'Available fields: ${snapshot.docs.first.data().keys.join(', ')}',
        );
      }

      setState(() {
        _ayahs = data;
        _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
        _surahRanges = _buildSurahRanges(data);
        _currentSurahNumber =
            _surahRanges.isNotEmpty ? _surahRanges.first.surahNumber : null;
        _loading = false;
      });
      _loadSurahNames();
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadSurahNames() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('quransurahs').get();
      final names = <int, String>{};
      for (final document in snapshot.docs) {
        final data = document.data();
        final numberValue = data['number'];
        final number = numberValue is int
            ? numberValue
            : int.tryParse(numberValue?.toString() ?? '');
        final name = data['english']?.toString().trim() ?? '';
        if (number != null && name.isNotEmpty) {
          names[number] = name;
        }
      }
      if (mounted) {
        setState(() {
          _surahNames.addAll(names);
          _surahRanges = _buildSurahRanges(_ayahs);
          _currentSurahNumber =
              _surahRanges.isNotEmpty ? _surahRanges.first.surahNumber : null;
        });
      }
    } catch (e) {
      debugPrint('[QURAN_JUZ] Could not load Surah names: $e');
    }
  }

  List<_SurahRange> _buildSurahRanges(List<Ayah> ayahs) {
    final ranges = <_SurahRange>[];
    for (var index = 0; index < ayahs.length; index++) {
      final ayah = ayahs[index];
      final coordinates = _coordinatesFor(ayah, index);
      if (coordinates == null) continue;
      final (surahNumber, ayahNumber) = coordinates;
      if (ranges.isEmpty || ranges.last.surahNumber != surahNumber) {
        ranges.add(
          _SurahRange(
            surahNumber: surahNumber,
            startAyah: ayahNumber,
            endAyah: ayahNumber,
            startIndex: index,
          ),
        );
      } else {
        final previous = ranges.removeLast();
        ranges.add(
          _SurahRange(
            surahNumber: previous.surahNumber,
            startAyah: previous.startAyah,
            endAyah: ayahNumber,
            startIndex: previous.startIndex,
          ),
        );
      }
    }
    return ranges;
  }

  (int, int)? _coordinatesFor(Ayah ayah, int index) {
    if (ayah.surahNumber >= 1 &&
        ayah.surahNumber <= 114 &&
        ayah.ayahNumber > 0) {
      return (ayah.surahNumber, ayah.ayahNumber);
    }

    final juzNumber = int.tryParse(widget.detailsID) ??
        int.tryParse(RegExp(r'\d+').firstMatch(widget.title)?.group(0) ?? '');
    final start = _juzStarts[juzNumber];
    if (start == null || index < 0) return null;

    var surahNumber = start.$1;
    var ayahNumber = start.$2;
    for (var offset = 0; offset < index; offset++) {
      ayahNumber++;
      if (ayahNumber > _surahAyahCounts[surahNumber - 1]) {
        surahNumber++;
        ayahNumber = 1;
      }
      if (surahNumber > 114) return null;
    }
    return (surahNumber, ayahNumber);
  }

  static const List<int> _surahAyahCounts = [
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6,
  ];

  static const Map<int, (int, int)> _juzStarts = {
    1: (1, 1),
    2: (2, 142),
    3: (2, 253),
    4: (3, 93),
    5: (4, 24),
    6: (4, 148),
    7: (5, 82),
    8: (6, 111),
    9: (7, 88),
    10: (8, 41),
    11: (9, 93),
    12: (11, 6),
    13: (12, 53),
    14: (15, 1),
    15: (17, 1),
    16: (18, 75),
    17: (21, 1),
    18: (23, 1),
    19: (25, 21),
    20: (27, 56),
    21: (29, 46),
    22: (33, 31),
    23: (36, 28),
    24: (39, 32),
    25: (41, 47),
    26: (46, 1),
    27: (51, 31),
    28: (58, 1),
    29: (67, 1),
    30: (78, 1),
  };

  void _updateCurrentSurahFromScroll() {
    if (!mounted || _surahRanges.isEmpty) return;

    final viewport = _ayahListViewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.attached) return;

    final viewportTop = viewport.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewport.size.height;
    int? firstVisibleAyahIndex;
    double? firstVisibleAyahTop;

    for (var index = 0; index < _ayahKeys.length; index++) {
      final renderObject = _ayahKeys[index].currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final top = renderObject.localToGlobal(Offset.zero).dy;
      final bottom = top + renderObject.size.height;
      if (bottom <= viewportTop || top >= viewportBottom) continue;

      final visibleTop = top < viewportTop ? viewportTop : top;
      if (firstVisibleAyahTop == null || visibleTop < firstVisibleAyahTop) {
        firstVisibleAyahTop = visibleTop;
        firstVisibleAyahIndex = index;
      }
    }

    if (firstVisibleAyahIndex == null) return;
    var visibleSurahNumber = _surahRanges.first.surahNumber;
    for (final range in _surahRanges) {
      if (range.startIndex > firstVisibleAyahIndex) break;
      visibleSurahNumber = range.surahNumber;
    }
    if (_currentSurahNumber != visibleSurahNumber) {
      setState(() => _currentSurahNumber = visibleSurahNumber);
    }
  }

  Widget _buildJuzOverview() {
    final ranges = _surahRanges;
    final currentSurahName = _currentSurahNumber == null
        ? ''
        : _surahNames[_currentSurahNumber] ?? 'Surah ${_currentSurahNumber!}';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.teal, size: 21),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (currentSurahName.isNotEmpty)
                  Flexible(
                    child: Text(
                      currentSurahName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (ranges.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ranges.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final range = ranges[index];
                    final isCurrent = range.surahNumber == _currentSurahNumber;
                    final surahName = _surahNames[range.surahNumber] ??
                        'Surah ${range.surahNumber}';
                    final totalAyahs = _surahAyahCounts[range.surahNumber - 1];
                    return ActionChip(
                      onPressed: () {
                        setState(() => _currentSurahNumber = range.surahNumber);
                        final itemContext =
                            _ayahKeys[range.startIndex].currentContext;
                        if (itemContext != null) {
                          Scrollable.ensureVisible(
                            itemContext,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            alignment: 0.12,
                          );
                        }
                      },
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${range.surahNumber}. $surahName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.teal.shade900 : null,
                            ),
                          ),
                          Text(
                            '$totalAyahs ayat · Is Juz me '
                            '${range.startAyah}–${range.endAyah}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCurrent
                                  ? Colors.teal.shade900
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      side: BorderSide(
                        color: isCurrent ? Colors.teal : Colors.grey.shade300,
                      ),
                      backgroundColor: isCurrent
                          ? Colors.teal.shade50
                          : Theme.of(context).colorScheme.surface,
                      visualDensity: VisualDensity.standard,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _highlightAndScrollToAyah(int index) {
    setState(() {
      _currentAyahIndex = index;
    });
    final context = _ayahKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  Future<void> _playAyah(Ayah ayah, int index) async {
    try {
      await _player.setUrl(ayah.audioUrl);
      await _player.play();
      _highlightAndScrollToAyah(index);

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_isAutoPlaying && index + 1 < _ayahs.length) {
            _playAyah(_ayahs[index + 1], index + 1);
          } else {
            setState(() {
              _isAutoPlaying = false;
              _currentAyahIndex = -1;
            });
          }
        }
      });
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  Future<void> _startAutoPlay() async {
    if (_ayahs.isEmpty) return;
    setState(() => _isAutoPlaying = true);
    await _playAyah(_ayahs[0], 0);
  }

  void _showFontSettings() {
    debugPrint('[QURAN_JUZ] Font settings popup opened');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget fontControl({
            required String language,
            required String selectedFont,
            required List<(String, String)> fontOptions,
            required ValueChanged<String> onFontChanged,
            bool showFontDropdown = true,
            required bool isBold,
            required ValueChanged<bool> onBoldChanged,
            required double size,
            required ValueChanged<double> onChanged,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (showFontDropdown)
                  DropdownButton<String>(
                    value: selectedFont,
                    isExpanded: true,
                    items: [
                      for (final option in fontOptions)
                        DropdownMenuItem<String>(
                          value: option.$2,
                          child: Text(option.$1),
                        ),
                    ],
                    onChanged: (fontFamily) {
                      if (fontFamily == null) return;
                      setState(() => onFontChanged(fontFamily));
                      setDialogState(() {});
                    },
                  )
                else
                  Text(selectedFont),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Normal'),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Bold'),
                    ),
                  ],
                  selected: {isBold},
                  onSelectionChanged: (selection) {
                    final value = selection.first;
                    setState(() => onBoldChanged(value));
                    setDialogState(() {});
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Decrease $language font size',
                      onPressed: size <= 10
                          ? null
                          : () {
                              setState(() => onChanged(size - 1));
                              setDialogState(() {});
                            },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(size.toStringAsFixed(0),
                          textAlign: TextAlign.center),
                    ),
                    IconButton(
                      tooltip: 'Increase $language font size',
                      onPressed: size >= 60
                          ? null
                          : () {
                              setState(() => onChanged(size + 1));
                              setDialogState(() {});
                            },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Text('px'),
                  ],
                ),
                const Divider(height: 8),
              ],
            );
          }

          return AlertDialog(
            title: const Text('Font settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  fontControl(
                    language: 'Arabic',
                    selectedFont: _arabicFontFamily,
                    fontOptions: _arabicFontOptions,
                    onFontChanged: (fontFamily) =>
                        _arabicFontFamily = fontFamily,
                    isBold: _arabicBold,
                    onBoldChanged: (value) => _arabicBold = value,
                    size: _fontSizeArabic,
                    onChanged: (size) => _fontSizeArabic = size,
                  ),
                  fontControl(
                    language: 'Urdu',
                    selectedFont: _urduFontFamily,
                    fontOptions: _urduFontOptions,
                    onFontChanged: (fontFamily) => _urduFontFamily = fontFamily,
                    isBold: _urduBold,
                    onBoldChanged: (value) => _urduBold = value,
                    size: _fontSizeUrdu,
                    onChanged: (size) => _fontSizeUrdu = size,
                  ),
                  fontControl(
                    language: 'English',
                    selectedFont: 'System default',
                    fontOptions: const [],
                    onFontChanged: (_) {},
                    showFontDropdown: false,
                    isBold: _translationBold,
                    onBoldChanged: (value) => _translationBold = value,
                    size: _fontSizeTranslation,
                    onChanged: (size) => _fontSizeTranslation = size,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _scrollController.dispose();
    _marqueeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Font settings',
            onPressed: _showFontSettings,
            icon: Icon(
              Icons.text_fields,
              color: Theme.of(context).appBarTheme.foregroundColor ??
                  Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ayahs.isEmpty
              ? const Center(child: Text('No ayahs found.'))
              : Column(
                  children: [
                    _buildJuzOverview(),
                    Expanded(
                      child: ListView.builder(
                        key: _ayahListViewportKey,
                        controller: _scrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        itemCount: _ayahs.length,
                        itemBuilder: (context, index) {
                          final ayah = _ayahs[index];
                          final showSurahTitle = (index == 0 ||
                                  ayah.surahNumber !=
                                      _ayahs[index - 1].surahNumber) &&
                              widget.surahId == 'chapter_01';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showSurahTitle)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Surah Al-Fatiha',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                              Card(
                                key: _ayahKeys[index],
                                color: _currentAyahIndex == index
                                    ? Colors.teal.shade50
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      buildArabicAyahImage(ayah, height: 110),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          ayah.urdu,
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            fontSize: _fontSizeUrdu,
                                            fontWeight: _urduBold
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontFamily: _urduFontFamily,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ayah.translation,
                                        style: TextStyle(
                                          fontSize: _fontSizeTranslation,
                                          fontWeight: _translationBold
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: Colors.teal,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        ayah.transliteration,
                                        style: TextStyle(
                                          fontSize: _fontSizeTransliteration,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            iconSize: 36,
                                            color: Colors.teal,
                                            icon: Icon(
                                              _currentAyahIndex == index &&
                                                      _player.playing
                                                  ? Icons.pause_circle
                                                  : Icons.play_circle,
                                            ),
                                            onPressed: () {
                                              if (_currentAyahIndex == index &&
                                                  _player.playing) {
                                                _player.pause();
                                              } else {
                                                _playAyah(ayah, index);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      height: 45,
                      width: double.infinity,
                      color: Colors.teal.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 36,
                            color: Colors.teal,
                            icon: Icon(
                              _isAutoPlaying && _player.playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                            ),
                            onPressed: () {
                              if (_isAutoPlaying && _player.playing) {
                                _player.pause();
                              } else {
                                _startAutoPlay();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Play Surah Audio",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_marqueeText.isNotEmpty)
                      Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.black,
                        child: Marquee(
                          text: _marqueeText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          blankSpace: 80.0,
                          velocity: 50.0,
                          pauseAfterRound: const Duration(seconds: 1),
                        ),
                      ),
                  ],
                ),
    );
  }
}
