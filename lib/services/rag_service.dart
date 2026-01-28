import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RagChunk {
  final String id;
  final String source;
  final int page;
  final int chunkIndex;
  final String text;

  RagChunk({
    required this.id,
    required this.source,
    required this.page,
    required this.chunkIndex,
    required this.text,
  });

  factory RagChunk.fromJson(Map<String, dynamic> j) => RagChunk(
        id: j['id'] ?? '',
        source: j['source'] ?? '',
        page: j['page'] ?? -1,
        chunkIndex: j['chunk_index'] ?? 0,
        text: j['text'] ?? '',
      );
}

class RagService {
  RagService._();
  static final RagService instance = RagService._();

  List<RagChunk> chunks = [];
  Float32List? embeddings; // flat array: n_chunks * dim
  int? vectorDim;

  bool _initialized = false;

  /// Load chunks.json and embeddings float32 binary from assets.
  Future<void> initFromAssets({String chunksAsset = 'assets/rag/chunks.json', String embeddingsAsset = 'assets/rag/embeddings_f32.bin'}) async {
    if (_initialized) return;
    final chunksJson = await rootBundle.loadString(chunksAsset);
    final List<dynamic> parsed = json.decode(chunksJson) as List<dynamic>;
    chunks = parsed.map((e) => RagChunk.fromJson(e as Map<String, dynamic>)).toList();

    final ByteData bd = await rootBundle.load(embeddingsAsset);
    final Uint8List bytes = bd.buffer.asUint8List();
    // Create Float32List view over the bytes
    final f32 = bytes.buffer.asFloat32List();
    embeddings = Float32List.fromList(f32);

    if (chunks.isNotEmpty) {
      vectorDim = embeddings!.length ~/ chunks.length;
    } else {
      vectorDim = 0;
    }

    _initialized = true;
  }

  /// Compute top-k matches given a query embedding (List<double> or Float32List).
  /// Runs the CPU-heavy work in a background isolate using `compute`.
  Future<List<Map<String, dynamic>>> searchByEmbedding(List<double> queryEmbedding, {int topK = 5}) async {
    if (!_initialized) throw StateError('RagService not initialized');
    if (embeddings == null || vectorDim == null || vectorDim == 0) return [];

    // prepare params for isolate
    final params = {
      'query': queryEmbedding,
      'embeddings': embeddings!,
      'n_chunks': chunks.length,
      'dim': vectorDim!,
      'top_k': topK,
    };

    final result = await compute(_isolateSimilaritySearch, params);
    // result is List<Map<String, dynamic>> with keys: index, score
    final List<Map<String, dynamic>> out = [];
    for (final item in result as List<dynamic>) {
      final idx = item['index'] as int;
      final score = item['score'] as double;
      final c = chunks[idx];
      out.add({
        'id': c.id,
        'source': c.source,
        'page': c.page,
        'chunk_index': c.chunkIndex,
        'text': c.text,
        'score': score,
      });
    }
    return out;
  }
}

/// Background isolate function to compute cosine similarity top-k.
/// Receives a Map with keys: query (List<double>), embeddings (Float32List), n_chunks, dim, top_k
List<Map<String, dynamic>> _isolateSimilaritySearch(Map<String, dynamic> params) {
  final List<dynamic> qlist = params['query'] as List<dynamic>;
  final Float32List embeddings = params['embeddings'] as Float32List;
  final int nChunks = params['n_chunks'] as int;
  final int dim = params['dim'] as int;
  final int topK = params['top_k'] as int;

  final Float32List q = Float32List(qlist.length);
  for (var i = 0; i < qlist.length; i++) {
    q[i] = (qlist[i] as num).toDouble();
  }

  // normalize query
  double qnorm = 0;
  for (var i = 0; i < dim; i++) {
    qnorm += q[i] * q[i];
  }
  qnorm = qnorm <= 0 ? 1.0 : sqrt(qnorm);

  // compute dot products and norms
  final List<Map<String, dynamic>> scores = List.generate(nChunks, (i) => {'score': 0.0, 'index': i});
  for (var ci = 0; ci < nChunks; ci++) {
    final int base = ci * dim;
    double dot = 0.0;
    double norm = 0.0;
    for (var d = 0; d < dim; d++) {
      final double v = embeddings[base + d];
      dot += v * q[d];
      norm += v * v;
    }
    final double denom = (norm <= 0.0 ? 1.0 : sqrt(norm)) * qnorm;
    final double sim = denom == 0.0 ? 0.0 : dot / denom;
    scores[ci] = {'score': sim, 'index': ci};
  }

  scores.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  final top = scores.take(topK).toList();
  return top.cast<Map<String, dynamic>>();
}
