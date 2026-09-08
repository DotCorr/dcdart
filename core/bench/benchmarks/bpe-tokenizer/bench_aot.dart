// core/bench/benchmarks/bpe-tokenizer/bench_aot.dart
//
// The stock-Dart-AOT third data point (`dart compile exe`). ORDINARY Dart,
// not DCDart -- no prelude, not compiled by dcc. INFORMATIONAL ONLY; never
// enters a gate number (see fib/bench_aot.dart for the rationale).
//
// It mirrors bench.dart's STRUCTURE, same policy as hashmap/bench_aot.dart:
// the merge table, the per-round distinct-pair worklist and the encode
// window are linked lists of small objects, so what differs from the DCDart
// side is memory management (tracing GC vs ARC vs C's arrays), not the
// data structure. The flat corpus and count buffers are List<int>, Dart's
// plain spelling of a numeric buffer. Traversals are while-loops rather
// than DCDart's borrowed-parameter recursion -- how a Dart programmer walks
// a list; the visits and the arithmetic are identical.
//
// Unlike the float pair (matmul-f32/attention-f32, which have NO AOT column
// because stock Dart has no f32), this workload is pure integer/object code
// and the column is meaningful as-is.

class Token {
  int id;
  Token? next;
  Token(this.id, this.next);
}

class PairNode {
  final int pair;
  PairNode? next;
  PairNode(this.pair, this.next);
}

class Merge {
  final int left;
  final int right;
  final int id;
  Merge? next;
  Merge(this.left, this.right, this.id, this.next);
}

const alpha = 64;
const nMerges = 256;
const vocab = alpha + nMerges; // 320
const pairSpace = vocab * vocab; // 102400
const nTrain = 16384;
const window = 2048;
const stride = 997;
const mod = 1000000007;

void genCorpus(List<int> dst, int n) {
  var x = 20260827;
  var prev = 0;
  for (var i = 0; i < n; i++) {
    x = (x * 1103515245 + 12345) & 0x7FFFFFFF;
    final r = (x >> 16) & 15;
    final y = (x >> 8) & 63;
    var sym = (y * y) ~/ 64;
    if (r < 5 && i > 0) sym = prev;
    dst[i] = sym;
    prev = sym;
  }
}

int train(List<int> t, List<int> cnt, List<Merge?> table, int acc) {
  var len = nTrain;
  Merge? head;
  Merge? tail;
  for (var m = 0; m < nMerges; m++) {
    // Count adjacent pairs; collect distinct ones (prepend, like bench.dart
    // -- argmax tie-breaks on the pair id so order does not matter).
    PairNode? dl;
    var a = t[0];
    for (var i = 1; i < len; i++) {
      final b = t[i];
      final p = a * vocab + b;
      if (cnt[p] == 0) dl = PairNode(p, dl);
      cnt[p] = cnt[p] + 1;
      a = b;
    }
    var bestP = pairSpace;
    var bestC = 0;
    var d = dl;
    while (d != null) {
      final p = d.pair;
      final c = cnt[p];
      if (bestC < c || (c == bestC && p < bestP)) {
        bestP = p;
        bestC = c;
      }
      d = d.next;
    }
    final left = bestP ~/ vocab;
    final right = bestP % vocab;
    final nid = alpha + m;
    final node = Merge(left, right, nid, null);
    if (tail != null) {
      tail.next = node;
    } else {
      head = node;
    }
    tail = node;
    // Left-to-right non-overlapping merge, compacted in place.
    var i = 0;
    var j = 0;
    while (i < len) {
      if (i + 1 < len && t[i] == left && t[i + 1] == right) {
        t[j] = nid;
        i += 2;
      } else {
        t[j] = t[i];
        i += 1;
      }
      j += 1;
    }
    len = j;
    acc = (acc * 31 + bestP) % mod;
    // Restore the all-zero table for the next round.
    d = dl;
    while (d != null) {
      cnt[d.pair] = 0;
      d = d.next;
    }
  }
  table[0] = head;
  return (acc * 31 + len) % mod;
}

int encodeWindow(List<int> src, Merge merges, int start, int acc) {
  // One Token node per window symbol, built back to front.
  Token? head;
  for (var i = window - 1; i >= 0; i--) {
    head = Token(src[start + i], head);
  }
  // Apply the rules in rank order; a merge rewrites the left node's id and
  // unlinks the right node, continuing AFTER the pair (same rule as the
  // in-place array compaction on the C side).
  Merge? m = merges;
  while (m != null) {
    final left = m.left;
    final right = m.right;
    final nid = m.id;
    Token? n = head;
    while (n != null) {
      final nx = n.next;
      if (nx == null) break;
      if (n.id == left && nx.id == right) {
        n.id = nid;
        n.next = nx.next;
        n = n.next;
      } else {
        n = nx;
      }
    }
    m = m.next;
  }
  var n = head;
  while (n != null) {
    acc = (acc * 31 + n.id) % mod;
    n = n.next;
  }
  return acc;
}

int benchKernel(int rounds) {
  final trainBuf = List<int>.filled(nTrain, 0);
  genCorpus(trainBuf, nTrain);
  final src = List<int>.of(trainBuf);
  final cnt = List<int>.filled(pairSpace, 0);
  final table = List<Merge?>.filled(1, null);
  var acc = train(trainBuf, cnt, table, 0);
  final mh = table[0];
  if (mh != null) {
    for (var r = 0; r < rounds; r++) {
      final start = (r * stride) % (nTrain - window);
      acc = encodeWindow(src, mh, start, acc);
    }
  }
  return acc;
}

void main(List<String> args) {
  final arg = args.isNotEmpty ? int.parse(args[0]) : 40;
  final iters = args.length > 1 ? int.parse(args[1]) : 1;

  final warm = benchKernel(arg); // discarded
  final checksum = warm;

  for (var i = 0; i < iters; i++) {
    final sw = Stopwatch()..start();
    final r = benchKernel(arg);
    sw.stop();
    if (r != checksum) {
      throw StateError('kernel is not deterministic');
    }
    print('SAMPLE_NS ${sw.elapsedMicroseconds * 1000}');
  }
  print('CHECKSUM $checksum');
  print('CLOCK Stopwatch');
}
