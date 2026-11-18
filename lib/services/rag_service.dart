import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RagChunk {
  final String id;
  final String source;
  final int page;
  final String text;

  const RagChunk({required this.id, required this.source, required this.page, required this.text});

  factory RagChunk.fromJson(Map<String, dynamic> j) => RagChunk(
        id: (j['id'] as String?) ?? '',
        source: (j['source'] as String?) ?? '',
        page: (j['page'] as num?)?.toInt() ?? -1,
        text: (j['text'] as String?) ?? '',
      );
}

/// Recherche documentaire hors ligne pour GreenBot (RAG).
///
/// v2 : classement BM25 sur assets/rag/chunks.json (2 993 extraits de
/// documents agronomiques). La v1 se reposait sur des vecteurs
/// (embeddings_f32.bin) calculés avec Universal Sentence Encoder (512
/// dimensions) alors que la requête devait être vectorisée par Gemini
/// text-embedding-004 (768 dimensions, service arrêté le 14 janvier 2026) :
/// la recherche vectorielle n'a donc jamais fonctionné, et le repli prenait
/// les 3 premiers extraits contenant un mot de la question, dans l'ordre du
/// fichier. BM25 classe par pertinence, ne demande aucun réseau, et le
/// fichier de vecteurs (6 Mo) n'est plus embarqué dans l'APK.
class RagService {
  RagService._();
  static final RagService instance = RagService._();

  List<RagChunk> chunks = const [];
  _Bm25Index? _index;
  Future<void>? _loading;

  bool get isInitialized => _index != null;

  Future<void> initFromAssets({String asset = 'assets/rag/chunks.json'}) =>
      _loading ??= _init(asset);

  Future<void> _init(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final parsed = (jsonDecode(raw) as List<dynamic>)
          .map((e) => RagChunk.fromJson(e as Map<String, dynamic>))
          .where((c) => c.text.trim().length > 40)
          .toList();
      final texts = parsed.map((c) => c.text).toList();
      _index = await Isolate.run(() => _Bm25Index.build(texts));
      chunks = parsed;
    } catch (e) {
      debugPrint('RAG indisponible : $e');
      _loading = null;
    }
  }

  /// Les [topK] extraits les plus pertinents pour [query] (vide si rien de
  /// pertinent ou si l'index n'est pas prêt).
  List<RagChunk> search(String query, {int topK = 3}) {
    final index = _index;
    if (index == null) return const [];
    return index.search(query, topK).map((i) => chunks[i]).toList();
  }

  @visibleForTesting
  static List<int> searchTexts(List<String> texts, String query, {int topK = 3}) =>
      _Bm25Index.build(texts).search(query, topK);
}

/// Index BM25 (k1 = 1,5 ; b = 0,75), jetons sans accents ni mots vides.
class _Bm25Index {
  static const _k1 = 1.5;
  static const _b = 0.75;

  final List<Map<String, int>> termFreqs;
  final List<int> lengths;
  final Map<String, int> docFreq;
  final double avgLength;

  _Bm25Index(this.termFreqs, this.lengths, this.docFreq, this.avgLength);

  static _Bm25Index build(List<String> texts) {
    final tfs = <Map<String, int>>[];
    final lengths = <int>[];
    final df = <String, int>{};
    var total = 0;
    for (final t in texts) {
      final tokens = tokenize(t);
      final tf = <String, int>{};
      for (final tok in tokens) {
        tf[tok] = (tf[tok] ?? 0) + 1;
      }
      for (final k in tf.keys) {
        df[k] = (df[k] ?? 0) + 1;
      }
      tfs.add(tf);
      lengths.add(tokens.length);
      total += tokens.length;
    }
    return _Bm25Index(tfs, lengths, df, texts.isEmpty ? 0 : total / texts.length);
  }

  List<int> search(String query, int topK) {
    final terms = tokenize(query).toSet();
    if (terms.isEmpty || termFreqs.isEmpty) return const [];
    final n = termFreqs.length;
    final scores = List<double>.filled(n, 0);
    for (final term in terms) {
      final dfT = docFreq[term];
      if (dfT == null) continue;
      final idf = math.log(1 + (n - dfT + 0.5) / (dfT + 0.5));
      for (var i = 0; i < n; i++) {
        final f = termFreqs[i][term];
        if (f == null) continue;
        final norm = f * (_k1 + 1) / (f + _k1 * (1 - _b + _b * lengths[i] / avgLength));
        scores[i] += idf * norm;
      }
    }
    final ranked = List<int>.generate(n, (i) => i)
      ..removeWhere((i) => scores[i] <= 0)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    return ranked.take(topK).toList();
  }

  static const _stopwords = {
    'les', 'des', 'une', 'est', 'pour', 'dans', 'que', 'qui', 'par', 'sur', 'avec', 'pas', 'plus',
    'son', 'ses', 'aux', 'mais', 'ont', 'sont', 'cette', 'ces', 'comme', 'elle', 'ils', 'leur',
    'leurs', 'peut', 'tout', 'tous', 'fait', 'faire', 'entre', 'aussi', 'bien', 'sans', 'dont',
    'the', 'and', 'for', 'with', 'are', 'that', 'this', 'from', 'was', 'were', 'which', 'has',
    'have', 'not', 'can', 'its', 'quoi', 'comment', 'quel', 'quelle', 'quels', 'quelles',
    'mon', 'mes', 'votre', 'vos', 'nous', 'vous', 'moi', 'toi', 'avoir', 'etre', 'what', 'how',
  };

  static List<String> tokenize(String text) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'œ': 'oe',
    };
    var s = text.toLowerCase();
    accents.forEach((k, v) => s = s.replaceAll(k, v));
    return s
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2 && !_stopwords.contains(w))
        .map(_stem)
        .toList();
  }

  /// Racinisation minimale (pluriels français et anglais).
  static String _stem(String w) {
    if (w.length > 4 && (w.endsWith('es') || w.endsWith('ux'))) return w.substring(0, w.length - 2);
    if (w.length > 3 && w.endsWith('s')) return w.substring(0, w.length - 1);
    return w;
  }
}
