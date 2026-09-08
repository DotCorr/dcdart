// core/bench/benchmarks/data-pipeline/bench_aot.dart
//
// The stock-Dart-AOT third data point (`dart compile exe`). ORDINARY Dart,
// not DCDart -- no prelude, not compiled by dcc. INFORMATIONAL ONLY; never
// enters a gate number (see fib/bench_aot.dart for the rationale).
//
// It mirrors bench.dart's STRUCTURE, same policy as hashmap/bench_aot.dart:
// every batch materialises a Batch object, a linked list of per-sample Row
// records and two half Views, so what differs from the DCDart side is
// memory management (tracing GC reaping 9,728 short-lived objects per epoch
// vs ARC's eager per-object release vs C's stack frames). The dataset and
// index buffers are List<int>. Traversals are while-loops, how a Dart
// programmer walks a list; the visits and arithmetic are identical.
//
// Integer workload, so this column exists and is meaningful -- unlike the
// float pair (matmul-f32/attention-f32), which have no AOT column because
// stock Dart has no f32.

class Row {
  final int off;
  final Row? next;
  Row(this.off, this.next);
}

class Batch {
  final int start;
  final int rows;
  final Row? head;
  Batch(this.start, this.rows, this.head);
}

class View {
  final Batch b;
  final int begin;
  final int len;
  View(this.b, this.begin, this.len);
}

const ns = 8192;
const cols = 8;
const batchSize = 16;
const nb = ns ~/ batchSize; // 512
const mod = 1000000007;

void genData(List<int> dst, int n) {
  var x = 777;
  for (var i = 0; i < n; i++) {
    x = (x * 1103515245 + 12345) & 0x7FFFFFFF;
    dst[i] = x & 65535;
  }
}

void shuffleIdx(List<int> a, int n, int seed) {
  for (var i = 0; i < n; i++) {
    a[i] = i;
  }
  var state = seed & 0x7FFFFFFF;
  for (var k = n - 1; k > 0; k--) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    final j = state % (k + 1);
    final tmp = a[k];
    a[k] = a[j];
    a[j] = tmp;
  }
}

Row? buildRows(List<int> idx, int start, int rows) {
  Row? head;
  for (var r = rows - 1; r >= 0; r--) {
    head = Row(idx[start + r] * cols, head);
  }
  return head;
}

int viewSum(View v, List<int> data) {
  var n = v.b.head;
  var skip = v.begin;
  while (n != null && skip > 0) {
    n = n.next;
    skip -= 1;
  }
  var s = 0;
  var take = v.len;
  while (n != null && take > 0) {
    final off = n.off;
    for (var c = 0; c < cols; c++) {
      s += data[off + c];
    }
    n = n.next;
    take -= 1;
  }
  return s;
}

int epoch(List<int> data, List<int> idx, int e) {
  shuffleIdx(idx, ns, e * 2654435761 + 12345);
  var acc = 0;
  for (var bi = 0; bi < nb; bi++) {
    final start = bi * batchSize;
    final batch = Batch(start, batchSize, buildRows(idx, start, batchSize));
    final v1 = View(batch, 0, batchSize ~/ 2);
    final v2 = View(batch, batchSize ~/ 2, batchSize - batchSize ~/ 2);
    final s = viewSum(v1, data) + viewSum(v2, data);
    acc = (acc + s) % mod;
  }
  return acc;
}

int benchKernel(int rounds) {
  final data = List<int>.filled(ns * cols, 0);
  final idx = List<int>.filled(ns, 0);
  genData(data, ns * cols);
  var acc = 0;
  for (var e = 0; e < rounds; e++) {
    acc = (acc * 31 + epoch(data, idx, e)) % mod;
  }
  return acc;
}

void main(List<String> args) {
  final arg = args.isNotEmpty ? int.parse(args[0]) : 400;
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
