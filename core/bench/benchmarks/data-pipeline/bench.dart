// core/bench/benchmarks/data-pipeline/bench.dart
//
// NEON N2 candidate (4th of the four workloads neon/ROADMAP.md N2 names):
// the N1 data-loader shape as a benchmark -- the second half of the
// ARC-HEAVY pair with `bpe-tokenizer/`. BENCH_SUITE=diagnostic -- NOT one
// of M3's five, enters no gate mean.
//
// THE WORKLOAD, mirroring neon/native/tensor.dart's Loader/epochReduce
// (read-only reference; this file is self-contained by harness rule -- dcc
// compiles one library per object, GAP-0028, so it could not import it
// anyway): a synthetic 8192-sample x 8-column u32 dataset in one flat
// buffer; per epoch, a Fisher-Yates LCG shuffle of an index buffer, then
// batch iteration -- 512 batches of 16 -- where EVERY batch materialises
// ARC-managed descriptor objects (a Batch, a linked list of per-sample Row
// records with resolved offsets, and TWO half Views holding the Batch
// strongly, exactly N1's batch + two views shape) and reduces through the
// views. The checksum folds every batch's reduction, so it depends on the
// permutation, the gather and the sum all being right on every side.
//
// It is INTEGER data, deliberately: N2's float kernels already exist
// (matmul-f32, attention-f32) and any float benchmark is a GAP-0034
// measurement first. Integer data keeps the checksum exact, keeps the
// trapping caveat honest (integer index arithmetic DOES trap -- this pair
// does not get the float pair's trap exemption), and makes the stock Dart
// AOT column expressible (stock Dart has no f32).
//
// WHERE THE ARC IS, and the deliberate asymmetry (same stance as
// bpe-tokenizer, opposite of `hashmap`): the C baseline (kernel.c) keeps
// its descriptors ON THE STACK -- a per-batch offs[] array and two view
// structs, which is what a C data loader does and is the same natural-C
// stance closure-heavy's baseline took for its contexts. DCDart cannot put
// an object graph on the stack: every epoch allocates 512 x (1 Batch + 16
// Rows + 2 Views) = 9,728 heap objects that ARC must retain, trace through
// view->batch->rows reads, and cascade-drop at batch scope end. The ratio
// therefore prices ARC-managed descriptor materialisation against C's
// stack discipline -- N2's "ML-shaped allocation pattern" measurement, not
// a pure like-for-like structure comparison. The manifest says so.
//
// TRAVERSAL DISCIPLINE: reductions walk the Row list by borrowed-parameter
// recursion (ADR-0019, zero ARC traffic, depth <= 16), so the priced ARC is
// the churn -- allocation, the strong view->batch edges, the per-batch
// cascade -- not a traversal tax.
//
// HEAP SIZING against ADR-0058's default 2 MiB-per-class regions:
//
//   32-byte class:  Row (8 off + 8 next = 16 + 16 hdr = 32). High water 16
//                   per batch (previous batch is fully dead before the next
//                   allocates) -- capacity 65,536.
//   64-byte class:  Batch (24 + 16 = 40 -> 64), View (24 + 16 = 40 -> 64).
//                   High water 3.
//   raw bytes:      dataset 8192 x 8 x u32 = 256 KiB (256 KiB class, 8
//                   blocks/region, 1 live); index buffer 8192 x u64 =
//                   64 KiB (64 KiB class, 1 live).
//
// TRAP-SAFETY (spec section 4.1): LCG state masked to 31 bits (multiply
// < 2^62); sample values masked to 16 bits so a batch sum is <= 16*8*65535
// ~ 8.4M; offsets <= 8191*8; checksum folds are acc*31 + v with acc < 1e9.
// Nothing can overflow; kernel_trapck.c's checks never fire.
import '../../../runtime/dc-core-bare/prelude.dart';

/// One gathered sample: its resolved element offset into the dataset.
/// The N1 loader gathers rows into a fresh batch tensor; the benchmark
/// keeps the gather as a descriptor so the allocation pattern (one object
/// per sample per batch) is priced without copying 60k floats around.
class Row extends HeapObject {
  u64 off;
  Row? next;
  Row(this.off, this.next);
}

/// One batch: where it starts in the shuffled index order, how many rows,
/// and the materialised row list.
class Batch extends HeapObject {
  u64 start;
  u64 rows;
  Row? head;
  Batch(this.start, this.rows, this.head);
}

/// A half-view over a batch. `b` is a STRONG reference -- N1's tensor views
/// hold their base strongly (see tensor.dart's header for why weak was
/// rejected there), so the benchmark's views do too.
class View extends HeapObject {
  Batch b;
  u64 begin;
  u64 len;
  View(this.b, this.begin, this.len);
}

/// Fills the dataset with LCG values masked to 16 bits. Serial dependency,
/// so neither side can fold the fill away.
@bare void genData(u64 addr, u64 n) {
  var x = u64(777);
  var i = u64(0);
  while (i < n) {
    x = (x * u64(1103515245) + u64(12345)) & u64(0x7FFFFFFF);
    Pointer<u32>.fromAddress(addr + i * u64(4)).value = (x & u64(65535)).toU32();
    i = i + u64(1);
  }
}

/// Identity, then Fisher-Yates with a 31-bit LCG -- the same shuffle (and
/// the same constants) as tensor.dart's loaderNew. Deterministic per seed;
/// each epoch passes a different seed so no epoch's work can be cached.
@bare void shuffleIdx(u64 idxAddr, u64 n, u64 seed) {
  var i = u64(0);
  while (i < n) {
    Pointer<u64>.fromAddress(idxAddr + i * u64(8)).value = i;
    i = i + u64(1);
  }
  var state = seed & u64(0x7FFFFFFF);
  var k = n - u64(1);
  while (u64(0) < k) {
    state = (state * u64(1103515245) + u64(12345)) & u64(0x7FFFFFFF);
    final j = state % (k + u64(1));
    final pk = Pointer<u64>.fromAddress(idxAddr + k * u64(8));
    final pj = Pointer<u64>.fromAddress(idxAddr + j * u64(8));
    final tmp = pk.value;
    pk.value = pj.value;
    pj.value = tmp;
    k = k - u64(1);
  }
}

/// Materialises the batch's row list: one Row per sample, offset resolved
/// through the shuffled index buffer. Built by recursion, depth <= 16.
@bare Row? buildRows(u64 idxAddr, u64 start, u64 r, u64 rows) {
  if (rows <= r) {
    return null;
  }
  final s = Pointer<u64>.fromAddress(idxAddr + (start + r) * u64(8)).value;
  // Bound to a local, NOT nested as `Row(off, buildRows(...))`: a fresh
  // temporary passed straight to a borrowed constructor parameter is never
  // released (GAP-0065) -- the nested form leaked all 8,192 Rows per epoch,
  // caught by the harness's dc_heap_live check on this benchmark's first run.
  final rest = buildRows(idxAddr, start, r + u64(1), rows);
  return Row(s * u64(8), rest);
}

/// Sum of one sample's 8 columns.
@bare u64 rowSum(u64 dataAddr, u64 off) {
  var s = u64(0);
  var c = u64(0);
  while (c < u64(8)) {
    s = s + Pointer<u32>.fromAddress(dataAddr + (off + c) * u64(4)).value.toU64();
    c = c + u64(1);
  }
  return s;
}

/// Skip `skip` rows, then sum `take` rows. Borrowed recursion -- the view
/// reduction pays no ARC per step, only the reads.
@bare u64 sumRows(Row n, u64 skip, u64 take, u64 dataAddr) {
  if (u64(0) < skip) {
    final nx = n.next;
    if (nx != null) {
      return sumRows(nx, skip - u64(1), take, dataAddr);
    }
    return u64(0);
  }
  final s = rowSum(dataAddr, n.off);
  if (take <= u64(1)) {
    return s;
  }
  final nx = n.next;
  if (nx != null) {
    return s + sumRows(nx, u64(0), take - u64(1), dataAddr);
  }
  return s;
}

/// The trivial per-batch reduction, through the view (view -> batch -> row
/// list -- the read path N1's exit criterion walks).
@bare u64 viewSum(View v, u64 dataAddr) {
  final b = v.b;
  final h = b.head;
  if (h != null) {
    return sumRows(h, v.begin, v.len, dataAddr);
  }
  return u64(0);
}

/// One epoch: shuffle, then 512 batches of 16, each materialising
/// 1 Batch + 16 Rows + 2 Views and reducing through the views. All 19
/// objects die by cascade at the end of each loop body -- N1's "every one
/// of them must die on time", priced.
@bare u64 epoch(u64 dataAddr, u64 idxAddr, u64 e) {
  shuffleIdx(idxAddr, u64(8192), e * u64(2654435761) + u64(12345));
  var acc = u64(0);
  var bi = u64(0);
  while (bi < u64(512)) {
    final start = bi * u64(16);
    // Local, not nested in the Batch(...) call -- GAP-0065, see buildRows.
    final rh = buildRows(idxAddr, start, u64(0), u64(16));
    final batch = Batch(start, u64(16), rh);
    final v1 = View(batch, u64(0), u64(8));
    final v2 = View(batch, u64(8), u64(8));
    final s = viewSum(v1, dataAddr) + viewSum(v2, dataAddr);
    acc = (acc + s) % u64(1000000007);
    bi = bi + u64(1);
  }
  return acc;
}

/// `rounds` epochs over the same dataset, each with a different shuffle.
@bare u64 benchKernel(u64 rounds) {
  final ns = u64(8192);
  final cols = u64(8);
  final data = Heap.allocate(ns * cols * u64(4));
  final idx = Heap.allocate(ns * u64(8));
  genData(data.address, ns * cols);
  var acc = u64(0);
  var e = u64(0);
  while (e < rounds) {
    acc = (acc * u64(31) + epoch(data.address, idx.address, e)) % u64(1000000007);
    e = e + u64(1);
  }
  Heap.free(data);
  Heap.free(idx);
  return acc;
}
